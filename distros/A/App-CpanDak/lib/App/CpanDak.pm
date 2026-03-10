package App::CpanDak;

use strict;
use warnings;
use mro;
use App::CpanDak::Specials;
use App::cpanminus::fatscript ();
our @ISA=('App::cpanminus::script'); ## no critic(ProhibitExplicitISA)

our $VERSION = '0.1.0'; # VERSION
# ABSTRACT: cpanm, with some sort of distroprefs


sub new {
    my ($class) = @_;

    my $self = $class->next::method();
    $self->{dak_specials} = App::CpanDak::Specials->new();

    return $self;
}

# These are for tracking which distribution we're building: the data
# structure is set inside `install_module` as a lexical, and passed to
# *some* methods, but we need it in all methods.

# `resolve_name` is the method that creates that data structure, so we
# capture its result

# `install_module` is indirectly recursive, so we need to keep a stack

sub install_module {
    my $self = shift;

    push @{$self->{dak_dist}}, undef;
    my $ret = $self->next::method(@_);
    pop @{$self->{dak_dist}};

    return $ret;
}

sub resolve_name {
    my $self = shift;

    my $ret = $self->next::method(@_);
    $self->{dak_dist}[-1] //= $ret;

    return $ret;
}

sub dak_dist {
    return shift->{dak_dist}[-1];
}

# cpanm has a bug here: it localises the mirrors badly, it puts
# backpan first *and leaves it there*; see
# https://github.com/miyagawa/cpanminus/issues/689
sub search_cpanmetadb_history {
    my ($self, $module, $version) = @_;

    my @mirrors = @{$self->{mirrors}};

    my $result = $self->next::method($module, $version);

    $self->{mirrors} = \@mirrors;

    return $result;
}

# here we actually do the things

sub _match_module {
    my ($self, $module, $version_spec) = @_;

    return $version_spec unless ref($version_spec);
    if (my $module_version = $version_spec->{$module}) {
        return $module_version;
    }
    if (my $star_version = $version_spec->{'*'}) { ## no critic(ProhibitNoisyQuotes)
        return $star_version;
    }
    return undef;
}

sub search_module {
    my ($self, $module, $version) = @_;

    my $found = $self->next::method($module, $version)
        or return;

    my $version_spec = $self->{dak_specials}->option_for($found, 'add_version_spec')
        or return $found;

    my $add_module_version = $self->_match_module($module, $version_spec)
        or return $found;

    my $specials_file = $self->{dak_specials}->match_for($found,'.options.yml');
    my $msg = "for $module";
    $msg .= ", $version was requested" if $version;
    $msg .= ", $specials_file added $add_module_version, we found $found->{module_version}";

    my $combined_version = $version
        ? "$version, $add_module_version"
        : $add_module_version;

    my $found_already;
    my $satisfy_worked = eval {
        $found_already = $self->satisfy_version(
            $module, $found->{module_version},
            $combined_version,
        );
        1;
    };

    if (!$satisfy_worked) {
        my $error = $@;
        $self->diag("$msg, checking the combined version failed\n");
        die $error; ## no critic(RequireCarping)
    }

    if ($found_already) {
        $self->diag("$msg, no need to search again\n");
        return $found;
    }

    $self->diag("$msg, searching again\n");
    return $self->next::method($module, $combined_version);
}

sub fetch_module {
    my $self = shift;
    my ($dist, $dir) = $self->next::method(@_);

    return unless $dir;

    # note that this patching happens *after* `unpack` has verified
    # the checksum of the distribution tarball, so patches will not
    # break that verification
    $self->{dak_specials}->apply_patch_to($dist, "$self->{base}/$dir");

    return $dist, $dir;
}

sub configure {
    my $self = shift;
    my $env = $self->{dak_specials}->env_for($self->dak_dist, 'configure');

    local @ENV{keys %{$env}} = values %{$env};
    delete local @ENV{grep { !defined $env->{$_} } keys %{$env}};

    return $self->next::method(@_);
}

sub build {
    my $self = shift;
    my $env = $self->{dak_specials}->env_for($self->dak_dist, 'build');

    local @ENV{keys %{$env}} = values %{$env};
    delete local @ENV{grep { !defined $env->{$_} } keys %{$env}};

    return $self->next::method(@_);
}

sub test {
    my $self = shift;
    return 1 if $self->{dak_specials}->option_for($self->dak_dist, 'notest');

    my $env = $self->{dak_specials}->env_for($self->dak_dist, 'test');

    local @ENV{keys %{$env}} = values %{$env};
    delete local @ENV{grep { !defined $env->{$_} } keys %{$env}};

    return $self->next::method(@_);
}

sub install {
    my $self = shift;
    my $env = $self->{dak_specials}->env_for($self->dak_dist, 'install');

    local @ENV{keys %{$env}} = values %{$env};
    delete local @ENV{grep { !defined $env->{$_} } keys %{$env}};

    return $self->next::method(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CpanDak - cpanm, with some sort of distroprefs

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    cpandak Foo::Bar

    cpandak --installdeps .

Exactly the same way as C<cpanm>.

=head1 DESCRIPTION

This is a subclass of C<App::cpanminus::script> that wraps some of its
methods to add the ability to apply patches, set environment
variables, and skip tests, to specific distributions.

The idea comes from L<Distroprefs|CPAN/Configuration for individual
distributions (Distroprefs)>.

=head2 Warning

This is mostly a hack; it will I<not> work on C<cpanminus> 1.79 or
later (those future versions are a complete rewrite, based on
C<Menlo>).

=head1 Special instructions

You add special instructions in a directory, then set the full path to
that directory in the C<PERL_CPANDAK_SPECIALS_PATH> environment
variable.

Files should be named after the full name of the distribution they
apply to, with optional full version. So to define a patch for all
versions of C<Test-mysqld>, you create
F<$PERL_CPANDAK_SPECIALS_PATH/Test-mysqld.patch>. To define test
environment variables for version 1.2.3 of C<Foo-Bar> you create
F<$PERL_CPANDAK_SPECIALS_PATH/Foo-Bar-1.2.3.test.env.yml>.

B<NOTE> the use of dash, not double colon! It's a I<distribution>
name, not a I<module> name!

These files are currently supported:

=over 4

=item C<.patch>

unified patch to apply to the distribution contents immediately after
unpacking (it is applied by calling C<patch -p1>)

the main use of this is for fixing a distribution while you wait for
the author to release a fixed version; another good use is to make
changes to a distribution to adapt it to your particular runtime
environment

=item C<.options.yml>

general processing options:

=over 4

=item C<notest>

Perl-style boolean, if true, no tests will be run for this
distribution

    ---
    notest: 1

=item C<add_version_spec>

version specification that will be added to the requirements for this
distribution (but see L</Additional Version Specifications> for
details).

    ---
    add_version_spec: "> 0.9.3, != 1.1.0"

=back

=item C<.configure.env.yml>

=item C<.build.env.yml>

=item C<.test.env.yml>

=item C<.install.env.yml>

environment variables to set before running running those phases

    ---
    TMP_SOCKET_PATH: '/tmp/'
    SKIP_NETWORK: '1'
    PLACK_ENV: ~  # remove this variable from the environment

=back

See also L<App::CpanDak::Specials>.

=head2 Additional Version Specifications

As far as Perl is concerned, I<modules> carry versions, distributions
don't (mainly because neither Perl-the-language nor perl-the-runtime
know what a distribution is).

I<CPAN distributions> do carry versions, though, and while most recent
distributions have the same version as all the modules they contain,
this is never guaranteed.

So, adding version specifications at the distribution level is just
not going to work reliably.

When asked to install a module (possibly with some version
specification of its own), this application does the following:

=over 4

=item *

find the distribution that contains the module (with a version that satisfies the specification)

=item *

find the C<.options.yml> file matching that distribution

=item *

get the C<add_version_spec> value from it, for the module we're installing (see below)

=item *

combine the original version specification with this additional one

=item *

if the module we found satisfies the combined specification, use it

=item *

otherwise, find a distribution that contains the module with a version that satisfies the combined specification

=back

Notice that the process is I<not> recursive: we search at most twice.

C<add_version_spec> can be a string, or a dictionary mapping module
names to strings:

=over 4

=item *

if it's a string, it's used for any module found in that distribution

=item *

if it's a dictionary, the value for the module we're installing is used

=item *

unless there's no such value, in which case we use the value for C<*>

=back

So, in F<specials/ACME-Example.options.yml>:

    add_version_spec: "== 1.0.0"

would pin all modules found in the C<ACME-Example> distribution to
version 1.0.0,

    add_version_spec:
      "*": "== 1.0.0"

would do the same,

    add_version_spec:
      "ACME::Example::Weird": "== 1.0.0"

would only pin the C<ACME::Example::Weird> module, so if we're asked
to install C<ACME::Example::Plain>, we'd install the latest version of
the distribution.

When would this be useful? C<Module-Release-2.136> contains
C<Module::Release> 2.136 and C<Module::Release::MetaCPAN> 2.131, so if
you wanted to pin that distribution regardless of which of its modules
is requested, you would need to write a F<Module-Release.options.yml>
containing:

    add_version_spec:
      "Module::Release": "== 2.136"
      "*": "== 2.131"

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
