package Config::Locale;
use 5.008001;
use strict;
use warnings;
our $VERSION = '0.10';

=encoding utf8

=head1 NAME

Config::Locale - Load and merge locale-specific configuration files.

=head1 SYNOPSIS

    use Config::Locale;
    
    my $locale = Config::Locale->new(
        identity => \@values,
        directory => $config_dir,
    );
    
    my $config = $locale->config();

=head1 DESCRIPTION

This module takes an identity array, determines the permutations of the identity using
L<Algorithm::Loops>, loads configuration files using L<Config::Any>, and finally combines
the configurations using L<Hash::Merge>.

So, given this setup:

    Config::Locale->new(
        identity => ['db', '1', 'qa'],
    );

The following configuration stems will be looked for (listed from least specific to most):

    default
    all.all.qa
    all.1.all
    all.1.qa
    db.all.all
    db.all.qa
    db.1.all
    db.1.qa
    override

For each file found the contents will be parsed and then merged together to produce the
final configuration hash.  The hashes will be merged so that the most specific configuration
file will take precedence over the least specific files.  So, in the example above,
"db.1.qa" values will overwrite values from "db.1.all".

The term C<stem> comes from L<Config::Any>, and means a filename without an extension.

=cut

use Config::Any;
use Hash::Merge;
use Algorithm::Loops qw( NestedLoops );
use Carp qw( croak );
use Path::Tiny;
use Types::Standard -types;
use Types::Common::String -types;
use Type::Utils -all;

use Moo;
use namespace::clean;

my $path_type = declare as Str;

coerce $path_type,
  from InstanceOf[ 'Path::Tiny' ],
  via { '' . $_ };

coerce $path_type,
  from InstanceOf[ 'Path::Class::File' ],
  via { '' . $_ };

coerce $path_type,
  from InstanceOf[ 'Path::Class::Dir' ],
  via { '' . $_ };

=head1 ARGUMENTS

=head2 identity

The identity that configuration files will be loaded for.  In a typical hostname-based
configuration setup this will be the be the parts of the hostname that declare the class,
number, and cluster that the current host identifies itself as.  But, this could be any
list of values.

=cut

has identity => (
  is       => 'ro',
  isa      => ArrayRef[ NonEmptySimpleStr ],
  requires => 1,
);

=head2 directory

The directory to load configuration files from.  Defaults to the current
directory.

=cut

has directory => (
  is      => 'ro',
  isa     => $path_type,
  coerce  => 1,
  default => '.',
);

=head2 wildcard

The wildcard string to use when constructing the configuration filenames.
Defaults to C<all>.  This may be explicitly set to undef wich will cause
the wildcard string to not be added to the filenames at all.

=cut

has wildcard => (
  is      => 'ro',
  isa     => NonEmptySimpleStr,
  default => 'all',
);

=head2 default_stem

A filename stem to load first, before all other stems.

Defaults to C<default>.  A relative path may be specified which will be assumed
to be relative to L</directory>.  If an absolute path is used then no change
will be made.

Note that L</prefix> and L</suffix> are not applied to this stem.

=cut

has default_stem => (
  is      => 'ro',
  isa     => $path_type,
  coerce  => 1,
  default => 'default',
);

=head2 override_stem

A filename stem to load last, after all other stems.

Defaults to C<override>.  A relative path may be specified which will be assumed
to be relative to L</directory>.  If an absolute path is used then no change
will be made.

Note that L</prefix> and L</suffix> are not applied to this stem.

=cut

has override_stem => (
  is      => 'ro',
  isa     => $path_type,
  coerce  => 1,
  default => 'override',
);

=head2 require_defaults

If true, then any key that appears in a non-default configuration file must exist
in the default configuration or an error will be thrown.  Defaults to C<0>.

=cut

has require_defaults => (
  is      => 'ro',
  isa     => Bool,
  default => 0,
);

=head2 separator

The character that will be used to separate the identity keys in the
configuration filenames.  Defaults to C<.>.

=cut

has separator => (
  is      => 'ro',
  isa     => (NonEmptySimpleStr) & (StrLength[1,1]),
  default => '.',
);

=head2 prefix

An optional prefix that will be prepended to the configuration filenames.

=cut

has prefix => (
  is      => 'ro',
  isa     => SimpleStr,
  default => '',
);

=head2 suffix

An optional suffix that will be appended to the configuration filenames.
While it may seem like the right place, you probably should not be using
this to specify the extension of your configuration files.  L<Config::Any>
automatically tries many various forms of extensions without the need
to explicitly declare the extension that you are using.

=cut

has suffix => (
  is      => 'ro',
  isa     => SimpleStr,
  default => '',
);

=head2 algorithm

Which algorithm used to determine, based on the identity, what configuration
files to consider for inclusion.

The default, C<NESTED>, keeps the order of the identity.  This is most useful
for identities that are derived from the name of a resource as resource names
(such as hostnames of machines) typically have a defined structure.

C<PERMUTE> finds configuration files that includes any number of the identity
values in any order.  Due to the high CPU demands of permutation algorithms this does
not actually generate every possible permutation - instead it finds all files that
match the directory/prefix/separator/suffix and filters those for values in the
identity and is very fast.

=cut

has algorithm => (
  is      => 'ro',
  isa     => Enum['NESTED', 'PERMUTE'],
  default => 'NESTED',
);

=head2 merge_behavior

Specify a L<Hash::Merge> merge behavior.  The default is C<LEFT_PRECEDENT>.

=cut

has merge_behavior => (
  is      => 'ro',
  isa     => NonEmptySimpleStr,
  default => 'LEFT_PRECEDENT',
);

=head1 ATTRIBUTES

=head2 config

Contains the final configuration hash as merged from the hashes in L</default_config>,
L</stem_configs>, and L</override_configs>.

=cut

has config => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_config {
    my ($self) = @_;
    return $self->_merge_configs([
        { default => $self->default_config() },
        @{ $self->stem_configs() },
        @{ $self->override_configs() },
    ]);
}

=head2 default_config

A merged hash of all the hashrefs in L</default_configs>.  This is computed
separately, but then merged with, L</config> so that the L</stem_configs> and
L</override_configs> can be checked for valid keys if L</require_defaults>
is set.

=cut

has default_config => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_default_config {
    my ($self) = @_;
    return $self->_merge_configs( $self->default_configs() );
}

=head2 default_configs

An array of hashrefs, each hashref containing a single key/value pair as returned
by L<Config::Any>->load_stems() where the key is the filename found, and the value
is the parsed configuration hash for any L</default_stem> configuration.

=cut

has default_configs => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_default_configs {
    my ($self) = @_;
    return $self->_load_configs( [$self->_default_stem_path()] );
}

=head2 stem_configs

Like L</default_configs>, but for any L</stems> configurations.

=cut

has stem_configs => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_stem_configs {
    my ($self) = @_;
    return $self->_load_configs( $self->stems(), $self->default_config() );
}

=head2 override_configs

Like L</default_configs>, but for any L</override_stem> configurations.

=cut

has override_configs => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_override_configs {
    my ($self) = @_;
    return $self->_load_configs( [$self->_override_stem_path()], $self->default_config() );
}

sub _merge_configs {
    my ($self, $configs) = @_;

    my $merge = $self->merge_object();

    my $config = {};
    foreach my $hash (@$configs) {
        foreach my $file (keys %$hash) {
            my $this_config = $hash->{$file};
            $config = $merge->merge( $this_config, $config );
        }
    }

    return $config;
}

sub _load_configs {
    my ($self, $stems, $defaults) = @_;

    my $configs = Config::Any->load_stems({
        stems   => $stems,
        use_ext => 1,
    });

    if ($defaults and $self->require_defaults()) {
        foreach my $hash (@$configs) {
            foreach my $file (keys %$hash) {
                my $config = $hash->{$file};
                foreach my $key (keys %$config) {
                    next if exists $defaults->{$key};
                    croak "The $key key is defined in $file but does not have a default set";
                }
            }
        }
    }

    return $configs;
}

=head2 stems

Contains an array of file paths for each value in L</combinations>.

=cut

has stems => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_stems {
    my ($self) = @_;

    my $directory = $self->_directory_path();
    my $separator = $self->separator();
    my $prefix    = $self->prefix();
    my $suffix    = $self->suffix();

    my @combinations = @{ $self->combinations() };

    my @stems;
    foreach my $combination (@combinations) {
        my @parts = @$combination;
        push @stems, $directory->child( $prefix . join($separator, @parts) . $suffix );
    }

    return \@stems;
}

=head2 combinations

Holds an array of arrays containing all possible permutations of the
identity, per the specified L</algorithm>.

=cut

has combinations => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build_combinations {
    my ($self) = @_;

    if ($self->algorithm() eq 'NESTED') {
        return $self->_nested_combinations();
    }
    elsif ($self->algorithm() eq 'PERMUTE') {
        return $self->_permute_combinations();
    }

    die 'Unknown algorithm'; # Shouldn't ever get to this.
}

sub _nested_combinations {
    my ($self) = @_;

    my $wildcard = $self->wildcard();

    my $options = [
        map { [$wildcard, $_] }
        @{ $self->identity() }
    ];

    return [
        # If the wildcard is undef then we will have one empty array that needs removal.
        grep { @$_ > 0 }

        # If the wildcard is undef then we need to strip out the undefs.
        map { [ grep { defined($_) } @$_ ] }

        # Run arbitrarily deep foreach loop.
        NestedLoops(
            $options,
            sub { [ @_ ] },
        )
    ];
}

sub _permute_combinations {
    my ($self) = @_;

    my $wildcard  = $self->wildcard();
    my $prefix    = $self->prefix();
    my $suffix    = $self->suffix();
    my $separator = $self->separator();

    my $id_lookup = {
        map { $_ => 1 }
        @{ $self->identity() },
    };

    $id_lookup->{$wildcard} = 1 if defined $wildcard;

    my @combos;
    foreach my $file (path( $self->directory() )->children()) {
        next if -d $file;

        if ($file->basename() =~ m{^$prefix(.*)$suffix\.}) {
            my @parts = split(/[$separator]/, $1);
            my $matches = 1;
            foreach my $part (@parts) {
                next if $id_lookup->{$part};
                $matches = 0;
                last;
            }
            if ($matches) { push @combos, \@parts }
        }
    }

    return [
        sort { @$a <=> @$b }
        @combos
    ];

    return \@combos;
}

=head2 merge_object

The L<Hash::Merge> object that will be used to merge the configuration
hashes.

=cut

has merge_object => (
  is       => 'lazy',
  init_arg => undef,
);
sub _build_merge_object {
    my ($self) = @_;
    return Hash::Merge->new( $self->merge_behavior() );
}

has _directory_path => (
    is       => 'lazy',
    init_arg => undef,
);
sub _build__directory_path {
    my ($self) = @_;
    return path( $self->directory() )->absolute();
}

has _default_stem_path => (
  is       => 'lazy',
  init_arg => undef,
);
sub _build__default_stem_path {
  my ($self) = @_;
  return path( $self->default_stem() )->absolute( $self->_directory_path() );
}

has _override_stem_path => (
  is       => 'lazy',
  init_arg => undef,
);
sub _build__override_stem_path {
  my ($self) = @_;
  return path( $self->override_stem() )->absolute( $self->_directory_path() );
}

1;
__END__

=head1 SUPPORT

Please submit bugs and feature requests to the
Config-Locale GitHub issue tracker:

L<https://github.com/bluefeet/Config-Locale/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

