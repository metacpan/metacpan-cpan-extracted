package App::CpanDak::Specials;

use strict;
use warnings;
use CPAN::Meta::YAML;

our $VERSION = '0.0.2'; # VERSION
# ABSTRACT: fetch and expose the "special" instructions for distributions


sub new {
    my ($class, $path) = @_;
    $path ||= $ENV{PERL_CPANDAK_SPECIALS_PATH};

    return bless {
        path => $path,
    }, $class;
}

sub _vname {
    my ($dist) = @_;

    return $dist->{distvname} if $dist->{distvname};
    return "$dist->{meta}{name}-$dist->{meta}{version}" if $dist->{meta};
    return "$dist->{dist}-$dist->{version}" if $dist->{dist} && $dist->{version};
    return undef;
}

sub _name {
    my ($dist) = @_;

    return $dist->{meta}{name} if $dist->{meta};
    return $dist->{dist};
}


sub match_for {
    my ($self, $dist, $ext) = @_;
    $ext //= '';

    # no point looking for matches if we don't have a "specials"
    # directory to look into
    my $path = $self->{path}
        or return;

    for my $name (
        _vname($dist),
        _name($dist),
    ) {
        next unless $name;
        $name = "$path/$name$ext";
        return $name if -e $name;
    }

    return undef;
}


sub all_options_for {
    my ($self, $dist) = @_;

    my $options_file = $self->match_for($dist, '.options.yml')
        or return;

    return CPAN::Meta::YAML::LoadFile($options_file);
}


sub option_for {
    my ($self, $dist, $key) = @_;

    my $options = $self->all_options_for($dist)
        or return;

    return $options->{$key};
}


sub env_for {
    my ($self, $dist, $phase) = @_;

    my $env_file = $self->match_for($dist, ".$phase.env.yml")
        or return {};

    return CPAN::Meta::YAML::LoadFile($env_file);
}


sub apply_patch_to {
    my ($self, $dist, $dir) = @_;

    my $patch_file = $self->match_for($dist, '.patch')
        or return;

    my $rc = system patch => (
        -d => $dir,
        '-f',
        -i => $patch_file,
        -p => 1,
    );

    return if $rc == 0;

    require Carp;
    Carp::croak('! Patching '._vname($dist).' failed');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CpanDak::Specials - fetch and expose the "special" instructions for distributions

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    my $distribution_to_build = 'Foo-Bar-1.2.3';

    my $specials = App::CpanDak::Specials->new();

    $specials->apply_patch_to($distribution_to_build, $path_to_source);

    unless ($specials->option_for('Foo-Bar-1.2.3', 'notest')) {
       run_the_tests();
    }

=head1 DESCRIPTION

Given a directory containing specially-named YAML and patch files,
this class matches them to CPAN-style distribution names, and exposes
their contents.

B<NOTE>: the YAML files are parsed by L<< C<CPAN::Meta::YAML> >>,
which does not understand I<all> of YAML; we're using it because it's
already a dependency of C<App::cpanminus>.

=head1 METHODS

=head2 C<new>

    my $specials = App::CpanDak::Specials->new();

    my $specials = App::CpanDak::Specials->new($path_to_specials);

Constructor. Looks for the special instructions files in the path
contained in the C<PERL_CPANDAK_SPECIALS_PATH> environment variable,
or in the given path.

Normally you just use the first form.

=head2 C<match_for>

    my $file_path = $specials->match_for($cpandak->dak_dist, '.patch');

Tries to find a file with the given extension, whose name matches the
given distribution.

If we're building C<Foo-Bar> version 1.2.3, the example above would
look for:

=over 4

=item *

C<$path_to_specials/Foo-Bar-1.2.3.patch>

=item *

C<$path_to_specials/Foo-Bar.patch>

=back

and return the first filename that exists, or C<undef> if none does.

=head2 C<all_options_for>

    my $options_hash = $specials->all_options_for($cpandak->dak_dist);

Returns the contents of the options file for the given distribution,
or C<undef> if it doesn't exist. An options file has extension
C<.options.yml>.

Options files should contain a single YAML dictionary, with simple
strings as keys. Example:

    ---
    notest: 1

=head2 C<option_for>

    my $option_value = $specials->option_for($cpandak->dak_dist, 'notest');

Same as:

    my $option_value = $specials->all_options_for($cpandak->dak_dist)->{notest};

but simpler and safer. Returns C<undef> if the file, or the option,
doesn't exist.

=head2 C<env_for>

    my $env_hash = $specials->env_for($cpandak->dak_dist, $phase);

Returns the contents of the environment file for the given
distribution and phase, or C<undef> if it doesn't exist. An environment
file has extension C<.$phase.env.yml>.

Environment files should contain a single YAML dictionary, with simple
strings as keys, and simple strings (or null/undef) as
values. Example:

    ---
    TMP_SOCKET_PATH: '/tmp/'
    SKIP_NETWORK: '1'
    PLACK_ENV: ~  # remove this variable from the environment

=head2 C<apply_patch_to>

    $specials->apply_patch_to($cpandak->dak_dist, $directory);

Applies the patch for the given distribution to the files under the
given directory, or does nothing if the patch doesn't exist. If the
patch exists but can't be applied cleanly, this method will die.

A patch file has extension C<.patch>. It is applied by calling C<patch
-p1>. The file should contain a unified patch like those generated by
C<git diff> or C<diff -ru>.

=head1 AUTHOR

Gianni Ceccarelli <dakkar@thenautilus.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gianni Ceccarelli <dakkar@thenautilus.net>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
