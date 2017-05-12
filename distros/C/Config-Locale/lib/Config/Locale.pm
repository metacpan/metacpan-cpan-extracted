package Config::Locale;
{
  $Config::Locale::VERSION = '0.05';
}
use strict;
use warnings;

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

The following configuration files will be looked for (listed from least specific to most):

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

=cut

use Config::Any;
use Hash::Merge;
use Algorithm::Loops qw( NestedLoops );
use Carp qw( croak );
use Scalar::Util qw( blessed );
use Path::Class qw( dir file );
use List::MoreUtils qw( any );

sub new {
    my $class = shift;
    croak __PACKAGE__ . '->new() cannot be called on an instance' if blessed $class;

    my $args = { @_ };

    croak 'The identity argument is required' if !$args->{identity};
    croak 'The identity argument must be an array ref' if ref($args->{identity}) ne 'ARRAY';

    $args->{directory} ||= '.';
    $args->{directory} = dir( $args->{directory} ) if !blessed $args->{directory};
    croak 'The directory argument must be a Path::Class::Dir object' if ref($args->{directory}) ne 'Path::Class::Dir';

    $args->{wildcard} = 'all' if !exists $args->{wildcard};
    croak 'The wildcard argument must be a scalar' if ref $args->{wildcard};

    $args->{default_stem} ||= 'default';
    $args->{default_stem} = file( $args->{default_stem} ) if !blessed $args->{default_stem};
    croak 'The default_stem argument must be a Path::Class::File object' if ref($args->{default_stem}) ne 'Path::Class::File';
    $args->{default_stem} = $args->{default_stem}->absolute( $args->{directory} );

    $args->{require_defaults} = 0 if !$args->{require_defaults};
    croak 'The require_defaults argument must be a scalar' if ref $args->{require_defaults};

    $args->{override_stem} ||= 'override';
    $args->{override_stem} = file( $args->{override_stem} ) if !blessed $args->{override_stem};
    croak 'The override_stem argument must be a Path::Class::File object' if ref($args->{override_stem}) ne 'Path::Class::File';
    $args->{override_stem} = $args->{override_stem}->absolute( $args->{directory} );

    $args->{separator} ||= '.';
    croak 'The separator argument must be a scalar' if ref $args->{separator};
    croak 'The separator argument must be a single character' if length($args->{separator}) != 1;

    $args->{prefix} ||= '';
    croak 'The prefix argument must be a scalar' if ref $args->{prefix};

    $args->{suffix} ||= '';
    croak 'The suffix argument must be a scalar' if ref $args->{suffix};

    $args->{algorithm} ||= 'NESTED';
    croak 'The algorithm argument must be a scalar' if ref $args->{algorithm};
    croak 'The algorithm argument must be NESTED or PERMUTE' if !any { $args->{algorithm} eq $_ } qw( NESTED PERMUTE );

    $args->{merge_behavior} ||= 'LEFT_PRECEDENT';
    croak 'The merge_behavior argument must be a scalar' if ref $args->{merge_behavior};

    return bless( $args, $class );
}

=head1 ARGUMENTS

=head2 identity

The identity that configuration files will be loaded for.  In a typical hostname-basedc
configuration setup this will be the be the parts of the hostname that declare the class,
number, and cluster that the current host identifies itself as.  But, this could be any
list of values.

=cut

sub identity { $_[0]->{identity} }

=head2 directory

The directory to load configuration files from.  Defaults to the current
directory.

=cut

sub directory { $_[0]->{directory} }

=head2 wildcard

The wildcard string to use when constructing the configuration filenames.
Defaults to "all".  This may be explicitly set to undef wich will cause
the wildcard string to not be added to the filenames at all.

=cut

sub wildcard { return $_[0]->{wildcard} }

=head2 default_stem

A stem used to load default configuration values before any other
configuration files are loaded.

Defaults to "default".  A relative path may be specified which will be assumed
to be relative to L</directory>.  If an absolute path is used then no change
will be made.  Either a scalar or a L<Path::Class::File> object may be used.

Note that L</prefix> and L</suffix> are not applied to this stem.

=cut

sub default_stem { $_[0]->{default_stem} }

=head2 require_defaults

If true, then any key that appears in a non-default stem must exist in the
default stem or an error will be thrown.  Defaults to false.

=cut

sub require_defaults { $_[0]->{require_defaults} }

=head2 override_stem

This works just like L</default_stem> except that the configuration values
from this stem will override those from all other configuration files.

Defaults to "override".

=cut

sub override_stem { $_[0]->{override_stem} }

=head2 separator

The character that will be used to separate the identity keys in the
configuration filenames.  Defaults to ".".

=cut

sub separator { $_[0]->{separator} }

=head2 prefix

An optional prefix that will be prepended to the configuration filenames.

=cut

sub prefix { $_[0]->{prefix} }

=head2 suffix

An optional suffix that will be apended to the configuration filenames.
While it may seem like the right place, you probably should not be using
this to specify the extension of your configuration files.  L<Config::Any>
automatically tries many various forms of extensions without the need
to explicitly declare the extension that you are using.

=cut

sub suffix { $_[0]->{suffix} }

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

sub algorithm { $_[0]->{algorithm} }

=head2 merge_behavior

Specify a L<Hash::Merge> merge behavior.  The default is C<LEFT_PRECEDENT>.

=cut

sub merge_behavior { $_[0]->{merge_behavior} }

=head1 ATTRIBUTES

=head2 config

Contains the final configuration hash as merged from the hashes in L</default_config>,
L</stem_configs>, and L</override_configs>.

=cut

sub config {
    my ($self) = @_;
    $self->{config} ||= $self->_build_config();
    return $self->{config};
}
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

sub default_config {
    my ($self) = @_;
    $self->{default_config} ||= $self->_build_default_config();
    return $self->{default_config};
}
sub _build_default_config {
    my ($self) = @_;
    return $self->_merge_configs( $self->default_configs() );
}

=head2 default_configs

An array of hashrefs, each hashref containing a single key/value pair as returned
by L<Config::Any>->load_stems() where the key is the filename found, and the value
is the parsed configuration hash for any L</default_stem> configuration.

=cut

sub default_configs {
    my ($self) = @_;
    $self->{default_configs} ||= $self->_build_default_configs();
    return $self->{default_configs};
}
sub _build_default_configs {
    my ($self) = @_;
    return $self->_load_configs( [$self->default_stem()] );
}

=head2 stem_configs

Like L</default_configs>, but for any L</stems> configurations.

=cut

sub stem_configs {
    my ($self) = @_;
    $self->{stem_configs} ||= $self->_build_stem_configs();
    return $self->{stem_configs};
}
sub _build_stem_configs {
    my ($self) = @_;
    return $self->_load_configs( $self->stems(), $self->default_config() );
}

=head2 override_configs

Like L</default_configs>, but for any L</override_stem> configurations.

=cut

sub override_configs {
    my ($self) = @_;
    $self->{override_configs} ||= $self->_build_override_configs();
    return $self->{override_configs};
}
sub _build_override_configs {
    my ($self) = @_;
    return $self->_load_configs( [$self->override_stem()], $self->default_config() );
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

Contains an array of L<Path::Class::File> objects for each value in L</combinations>.

=cut

sub stems {
    my ($self) = @_;
    $self->{stems} ||= $self->_build_stems();
    return $self->{stems};
}
sub _build_stems {
    my ($self) = @_;

    my $directory = $self->directory();
    my $separator = $self->separator();
    my $prefix    = $self->prefix();
    my $suffix    = $self->suffix();

    my @combinations = @{ $self->combinations() };

    my @stems;
    foreach my $combination (@combinations) {
        my @parts = @$combination;
        push @stems, $directory->file( $prefix . join($separator, @parts) . $suffix );
    }

    return \@stems;
}

=head2 combinations

Holds an array of arrays containing all possible permutations of the
identity, per the specified L</algorithm>.

=cut

sub combinations {
    my ($self) = @_;
    $self->{combinations} ||= $self->_build_combinations();
    return $self->{combinations};
}
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
    foreach my $file ($self->directory->children()) {
        next if $file->is_dir();

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

sub merge_object {
    my ($self) = @_;
    $self->{merge_object} ||= $self->_build_merge_object();
    return $self->{merge_object};
}
sub _build_merge_object {
    my ($self) = @_;
    return Hash::Merge->new( $self->merge_behavior() );
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

