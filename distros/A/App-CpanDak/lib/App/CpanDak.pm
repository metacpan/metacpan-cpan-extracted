package App::CpanDak;

use strict;
use warnings;
use mro;
use App::CpanDak::Specials;
use App::cpanminus::fatscript ();
our @ISA=('App::cpanminus::script'); ## no critic(ProhibitExplicitISA)

our $VERSION = '0.0.2'; # VERSION
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

version 0.0.2

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

This is a mostly a hack; it will I<not> work on C<cpanminus> 1.79 or
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

general processing options; currently only C<notest> (Perl-style
boolean) is implemented: if set, no tests will be run for this
distribution

    ---
    notest: 1

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

See also L<App::CpanDak::Specials> for more details.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
