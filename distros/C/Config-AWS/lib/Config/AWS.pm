package Config::AWS;
# ABSTRACT: Parse AWS config files

use strict;
use warnings;

use File::Glob qw( bsd_glob );
use Ref::Util qw( is_ref is_arrayref is_scalarref is_blessed_ref );
use Carp qw( carp croak );
use Scalar::Util qw();

use Exporter::Shiny qw(
    read
    read_all
    list_profiles
    read_file
    read_string
    read_handle
    config_file
    credentials_file
    default_profile
);

our $VERSION = '0.05';
our %EXPORT_TAGS = (
    ini  => [qw( read_file read_string read_handle )],
    aws  => [qw( config_file default_profile credentials_file )],
    read => [qw( read read_all list_profiles )],
    all  => [qw( :ini :aws :read )],
);

# Config parsing interface

sub read {
    my $input = _prepare( shift );
    _read( $input, shift // default_profile() );
}

sub read_all {
    my $input = _prepare( shift );
    _read( $input );
}

sub list_profiles {
    my $lines = _prepare( shift );

    my @profiles;

    for (@{$lines}) {
        push @profiles, $1 if /^\[(?:profile )?([\w-]+)\]/;
    }

    return @profiles;
}

# AWS information methods

sub default_profile {
    $ENV{AWS_DEFAULT_PROFILE} // 'default';
}

sub credentials_file {
    $ENV{AWS_SHARED_CREDENTIALS_FILE} // bsd_glob( '~/.aws/credentials' );
}

sub config_file {
    $ENV{AWS_CONFIG_FILE} // bsd_glob( '~/.aws/config' );
}

# Methods for compatibility with Config::INI interface

sub read_file {
    croak 'Filename is missing' unless @_ >= 1;
    croak 'Argument was not a string' if is_ref $_[0];
    require Path::Tiny;
    _read( [ Path::Tiny::path(shift)->lines({ chomp => 1 }) ], @_ );
}

sub read_string {
    croak 'String is missing' unless @_ >= 1;
    croak 'Argument was not a string' if is_ref $_[0];
    _read( [ split /\n/, shift ], @_ );
}

sub read_handle {
    require Scalar::Util;
    croak 'Handle is missing' unless @_ >= 1;
    croak 'Argument was not a handle'
        unless Scalar::Util::openhandle( $_[0] );
    _read( [ map { s/\015?\012/\n/; chomp; $_ } shift->getlines ], @_ );
}

# Internal methods for parsing and validation

sub _prepare {
    my ($input) = @_;

    unless (defined $input) {
        my $file = credentials_file();
        $input = $file if -r $file;
    }

    $input = config_file() unless defined $input;

    unless (is_ref $input) {
        require Path::Tiny;
        return [ Path::Tiny::path( $input )->lines({ chomp => 1 }) ];
    }

    return [ map { chomp } $input->getlines ]
        if Scalar::Util::openhandle( $input );

    if (is_blessed_ref $input) {
        return [ $input->slurp( chomp => 1 ) ]
            if $input->isa('Path::Class::File');

        return [ $input->lines({ chomp => 1 }) ]
            if $input->isa('Path::Tiny');

        croak 'Cannot read from objects of type ' . ref $input;
    }

    return [ split /\n/, ${ $input } ] if is_scalarref $input;
    return $input                      if is_arrayref $input;

    croak "Could not use $input as source for " . (caller(1))[3];
}

sub _read {
    my ($lines, $target_profile) = @_;

    carp 'Reading config with only one line or less. Faulty input?'
        if scalar @{$lines} <= 1;

    my $hash = {};
    my $nested = {};

    my $profile = q{};
    for my $i (0 .. $#{$lines}) {
        my $line = $lines->[$i];
        chomp $line;

        if ($line =~ /^\[(?:profile )?([\w-]+)\]/) {
            $profile = $1;
            next;
        }

        next if $target_profile && $profile ne $target_profile;

        my ($indent, $key, $value) = $line =~ /^(\s*)([\w]+)\s*=\s*(.*)/;

        next unless defined $key;

        if (length $indent) {
            $nested->{$key} = $value;
        }
        else {
            if ($value) {
                $hash->{$profile}{$key} = $value;
            }
            else {
                my ($next_indent) = $lines->[$i + 1] =~ /^(\s*)/;
                if (length $next_indent) {
                    $hash->{$profile}{$key} = $nested;
                }
                else {
                    $hash->{$profile}{$key} = $value;
                }
            }
            $nested = {} if keys %{$nested};
        }
    }

    return $target_profile ? ( $hash->{$target_profile} // {} ) : $hash;
}

1;

__END__

=encoding utf8

=head1 NAME

Config::AWS - Parse AWS config files

=head1 SYNOPSIS

    use Config::AWS ':all';

    # Read the data for a specific profile
    $config = read( $source, $profile );

    # Or read the default profile from the default file
    $config = read();

    # Which is the same as
    $config = read(
        -r credentials_file() ? credentials_file() : config_file(),
        default_profile()
    );

    # Read all of the profiles from a file
    $profiles = read_all( $source );

    # Or if you have cycles to burn
    $profiles = {
        map { $_ => read( $source, $_ ) } list_profiles( $source )
    };

=head1 DESCRIPTION

Config::AWS is a small distribution with generic methods to correctly parse
the contents of config files for the AWS CLI client as described in
L<the AWS documentation|https://docs.aws.amazon.com/cli/latest/topic/config-vars.html>.

Although it is common to see these files parsed as standard INI files, this
is not appropriate since AWS config files have an idiosyncratic format for
nested values (as shown in the link above).

Standard INI parsers (like L<Config::INI>) are not made to parse this sort of
structure (nor should they). So Config::AWS exists to provide a suitable
and lightweight ad-hoc parser that can be used in other applications.

=head1 ROUTINES

Config::AWS does not export anything by default. All the functions
described in this document can be requested by name at the time of import.
Alternatively, the C<:all> tag can be used to import all of them into your
namespace in one go. Other tags are explained in the sections below.

=head2 Parsing routines

These are the prefered methods for parsing AWS config data. These can be
imported with the C<:read> tag.

=over 4

=item B<read>

=item B<read_all>

=item B<list_profiles>

    $profiles = read_all();                       # Use defaults
    $profiles = read_all( $source );              # Specify source

    @profile_names = list_profiles();             # Use default file
    @profile_names = list_profiles( $source );    # Specify source

    $profile = read();                            # Use defaults
    $profile = read( $source );                   # Use default profile
    $profile = read( $source, $profile );         # Specify source and profile
    $profile = read( undef,   $profile );         # Use default file

Parse AWS config data. All these functions take the data source to use as
their first argument. The source can be any of the following:

=over 4

=item * A B<string> with the path to the file

=item * A B<Path::Tiny object> for the config file

=item * An B<array reference> of lines to parse

=item * A B<scalar reference> with the entire slurped contents of the file

=item * An B<undefined> value

=back

If the source is undefined, a default file name will be used. This will be
the result of calling B<credentials_file> (if it is a readable file) or the
result of calling B<config_file> otherwise.

B<read_all> will return the results of parsing all of the content in the
source, for all profiles that may be defined in it.

B<read> will instead return the data I<for a single profile only>. This
profile can be specified as the second argument. If no profile is provided,
B<read> will use the result of calling B<default_profile> as the default.

B<list_profiles> will return only the names of the profiles specified in the
config as a list. The order will be the same as that used in the source.

=back

=head2 AWS defaults

These routines provide information about the default values, as understood
by the AWS CLI interface. These can be imported with the C<:aws> tag.

=over 4

=item B<default_profile>

Returns the contents of the C<AWS_DEFAULT_PROFILE> environment variable, or
C<default> if undefined.

=item B<config_file>

Returns the contents of the C<AWS_CONFIG_FILE> environment variable, or
C<~/.aws/config> if undefined.

=item B<credentials_file>

Returns the contents of the C<AWS_SHARED_CREDENTIALS_FILE> environment
variable, or C<~/.aws/credentials> if undefined.

=back

=head2 Compatibility with Config::INI

=for Pod::Coverage read_file read_string read_handle

This module includes routines that allow it to be used as a drop-in
replacement of L<Config::INI>. The B<read_file>, B<read_string>, and
B<read_handle> functions behave like those described in the documentation
for that distribution. They can be imported with the C<:ini> tag.

Unlike the functions described above, they do not use the default values
for AWS config files or profiles, and require the source to be explicitly
stated.

To more closely mimic the behaviour of the methods they emulate, they return
the entire parsed config data. As a concesion, an optional profile can be
specified as a second argument, in which case only the data for that profile
will be returned.

=head1 CONTRIBUTIONS AND BUG REPORTS

Contributions of any kind are most welcome!

The main repository for this distribution is on
L<GitLab|https://gitlab.com/jjatria/Config-AWS>, which is where patches
and bug reports are mainly tracked.

Bug reports can also be sent through the CPAN RT system, or by mail directly
to the developers at the address below, although these might not be as
closely tracked.

=head1 AUTHOR

=over 4

=item *

José Joaquín Atria <jjatria@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
