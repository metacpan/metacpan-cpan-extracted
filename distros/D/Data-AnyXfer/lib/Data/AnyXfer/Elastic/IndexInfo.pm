package Data::AnyXfer::Elastic::IndexInfo;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use DateTime::Format::Strptime ();
use DateTime ();
use Data::AnyXfer::Elastic::Utils;


=head1 NAME

Data::AnyXfer::Elastic::IndexInfo - Object representing
Elasticsearch information

=head1 SYNOPSIS

    my %ad_hoc_info = (
        alias => 'interiors',
        silo => 'public_data',
        type => 'some_document_type', );

    my $info =
        Data::AnyXfer::Elastic::IndexInfo->new(%ad_hoc_info);

    # supplied to some routine and object requiring connection
    # information / an IndexInfo field or argument...

    my $datafile =
        Data::AnyXfer::Elastic::Import::DataFile->new(
        index_info => $info );

    # or, do something with the IndexInfo interface...

    my $index = $info->get_index;
    $index->search( ... );

=head1 DESCRIPTION

This object can be used by
L<Data::AnyXfer::Elastic> to retrieve or supply Elasticsearch
indexing / storage information.

This basically acts as connection information. This is a basic
implementation and consumer of the
L<Data::AnyXfer::Elastic::Role::IndexInfo> role.

This module may be subclassed and pre-populated with connection
information to provide useful per-package or project Elasticsearch
information, which can then be used or advertised by any related
modules.

=head1 SEE ALSO

L<Data::AnyXfer::Elastic::ImplementingAProject>,
L<Data::AnyXfer::Elastic>

=head1 INDEXINFO INTERFACE

All
L<Data::AnyXfer::Elastic::Role::IndexInfo/"REQUIRED METHODS">
 are implemented as attributes.

Only C<mappings>, C<settings>, C<warmers>, and C<aliases> are not
required. All others are required (C<alias>, C<silo>, C<index> and
C<type>)

Please see
L<Data::AnyXfer::Elastic::Role::IndexInfo/"REQUIRED METHODS">
 for more details on the fields.

=head2 Extensions

=head3 C<connect_hint>

 A connection hint for use with L<Data::AnyXfer::Elastic>.

 Currently supports C<undef> (unspecified), C<readonly>, or C<readwrite>.

=head2 as_hash

    my $info = $index_info->as_hash;

Export all index information as a hash.

=cut

sub as_hash {

    my $self = $_[0];

    return {
      map { $_ => $self->$_ }
          qw/
          index type mappings es235_mappings settings warmers alias silo aliases
          /
    };
}


# ATTRIBUTE DEFINITIONS

has alias => (
    is       => 'rw',
    isa      => Maybe[Str],
    required => 1,
);

has silo => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has index => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has type => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has mappings => (
    is      => 'rw',
    isa     => HashRef[HashRef],
    default => sub { {} },
);

has settings => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { {} },
);

has warmers => (
    is      => 'rw',
    isa     => HashRef[HashRef],
    default => sub { {} },
);

has aliases => (
    is      => 'bare',
    isa     => HashRef[HashRef],
    default => sub { {} },
);

has timestamp_format => (
    is  => 'ro',
    isa => Str,
);

has autocreate_index => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has connect_hint => (
    is  => 'ro',
    isa => Maybe[Str],
);

has _fields => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);


# ROLE IMPLEMENTATION
with 'Data::AnyXfer::Elastic::Role::IndexInfo';
with 'Data::AnyXfer::Elastic::Role::IndexInfo_ES2';


# CONSTRUCTION ROUTINES

sub BUILDARGS {

    my $class = shift;

    # initialise index info field values
    my %fields = $class->_process_index_fields(@_);

    # create instance
    return $class->SUPER::BUILDARGS(%fields);
}


sub BUILD {

    my $self = shift;
    if ( $self->autocreate_index ) {

        # Setup index (we don't care about errors here)
        my $indices = $self->get_indices;
        my $index   = $self->index;

        eval {
          # try to create the index if it doesn't exist
          unless ( $indices->exists( index => $index ) ) {

              my $api_version = $indices->elasticsearch->api_version;
              my $mappings;

              if ( $api_version =~ /^2/ ) {
                  # XXX : Support ES 2.3.5 (TO BE REMOVED)
                  $mappings = $self->es235_mappings;
              } else {
                  # XXX : Support ES 6.x
                  $mappings = $self->mappings;
              }

              $indices->create(
                  index => $index,
                  body  => {
                      mappings => $mappings,
                      settings => $self->settings,
                      warmers  => $self->warmers,
                      aliases  => $self->aliases,
                  }
              );
          }
        };

        unless ( $indices->exists( index => $index ) ) {
            croak
                "Could not find index at the end of autocreate (index=$index)";
        }
    }
}


sub _generate_index_name {

    my ( $self, $info, $hostname ) = @_;

    my $alias = $info ? $info->{alias} : $self->alias;

    # if the alias contains multiple names, just take the first one
    # these types of index info instances shouldn't be used for writes
    # in any case
    $alias = ( split ',', $alias )[0];

    # add a timestamp
    my $index_name = $self->_add_index_timestamp( $alias, $info );

    return $alias
        ? Data::AnyXfer::Elastic::Utils->configure_index_name(
        $index_name, $hostname )
        : undef;
}

sub _process_index_fields {

    my $self = shift;
    my %info;

    # check if we have a default index definition
    if ( UNIVERSAL::can( $self, 'define_index_info' ) ) {

        # read index definition into a hash
        # so we error here instead of at construction
        # if not key-value data
        %info = $self->define_index_info();
    }

    my %args = @_;

    # override explicitly supplied args (with defined values)
    foreach ( grep { defined $args{$_} } keys %args ) {
        $info{$_} = $args{$_};
    }

    # set the default timestamp format precision (to seconds)
    $info{timestamp_format} ||= '%Y%m%d%H%M%S';

    # record the original fields for later use
    $info{_fields} = {%info};

    # apply default index name
    $info{index} ||= $self->_generate_index_name( \%info );

    # process arguments
    $self->_configure_fields( \%info );
    return %info;
}

sub _configure_fields {

    my ( $self, $fields ) = @_;

    # allow multiple comma separated index / alias names
    my @aliases = split ',', $fields->{alias};

    $fields->{alias} = join ',', map {
        Data::AnyXfer::Elastic::Utils->configure_alias_name($_)
    } @aliases;

    return;
}

sub _add_index_timestamp {

    my ( $self, $index_name, $info ) = @_;

    my $date_now = DateTime->now;

    my $formatter = DateTime::Format::Strptime->new(
        pattern => $info->{timestamp_format} );

    my $timestamp
        = $formatter->format_datetime( $info->{datetime} || $date_now );
    return $index_name . "_${timestamp}";
}

# CUSTOM ACCESSOR ROUTINES

sub aliases {

    my ( $self, $value ) = @_;

    if ($value) {
        return $self->{aliases} = $value;
    }

    # return aliases map
    # allow the entire aliases map to be explicitly defined
    # but silently ensure that the 'alias' attribute alias
    # is defined
    my $alias = $self->alias;
    return {
        # silently add the 'alias' value
        $alias && ($alias ne $self->index) ? ( $alias, {} ) : (),

        # then override with the explicit aliases
        %{ $self->{aliases} },
    };
}


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

