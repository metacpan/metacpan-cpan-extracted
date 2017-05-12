package Data::Petitcom::PTC;

use strict;
use warnings;
use bytes ();

use Carp ();
use Digest::MD5;
use List::Util;
use Data::Petitcom::Resource;

use constant PTC                => 'PETITCOM';
use constant PTC_NAME_MAXLENGTH => 8;
use constant PTC_SIGNATURE      => 'PX01';
use constant PTC_VERSION        => [ 'PETC0100', 'PETC0300' ];
use constant PTC_RESOURCE => {
    PRG => 0x00,
    GRP => 0x02,
    CHR => 0x03,
    COL => 0x05,
};

use constant PTC_OFFSET_RESOURCE => 0x08;
use constant PTC_OFFSET_NAME     => 0x0C;
use constant PTC_OFFSET_VERSION  => 0x24;
use constant PTC_OFFSET_DATA     => 0x30;

my %defaults = (
    data     => '',
    resource => 'PRG',
    version  => 'PETC0300',
    name     => 'DPTC',
);

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = bless {}, $class;
    $self->init(@_) if ( $self->can('init') );
    return $self;
}

sub init {
    my $self = shift;
    my %args = @_;
    for ( keys %defaults ) {
        my $value = $args{$_} || $defaults{$_};
        ( $self->can($_) ) ? $self->$_($value) : ( $self->{$_} = $value );
    }
    return $self;
}

sub resource {
    my $self = shift;
    if (@_) {
        my $resource = uc(shift);
        ( defined PTC_RESOURCE->{$resource} )
            ? $self->{resource} = $resource
            : Carp::croak "unsupported resource: $resource";
    }
    return $self->{resource};
}

sub name {
    my $self = shift;
    if (@_) {
        my $name = shift;
        $name =~ s/\x00//g;
        Carp::croak "name allows '_0-9A-Z': $name"
            unless ( $name =~ /^[_0-9a-zA-Z]+$/ );
        $self->{name}
            = bytes::substr uc($name), 0, PTC_NAME_MAXLENGTH;
    }
    return $self->{name};
}

sub version {
    my $self = shift;
    if (@_) {
        my $version = uc(shift);
        $self->{version}
            = List::Util::first { $_ eq $version } @{ PTC_VERSION() }
            or Carp::croak "unsupported version: $version";
    }
    return $self->{version};
}

sub data {
    my $self = shift;
    $self->{data} = shift if ( @_ > 0 );
    my $format = $self->version . uc( 'R' . $self->resource );
    return $format . $self->{data};
}

sub dump {
    my $self = shift;
    my $header .= PTC_SIGNATURE;
    $header .= pack 'V', bytes::length( $self->data );
    $header .= pack 'V', PTC_RESOURCE->{ $self->resource };
    $header .= bytes::substr $self->name . "\x00" x PTC_NAME_MAXLENGTH, 0, PTC_NAME_MAXLENGTH;
    $header .= Digest::MD5::md5(PTC . $self->data);
    my $raw_ptc = $header . $self->data;
    return $raw_ptc;
}

sub load {
    my $self    = ref $_[0] ? shift : shift->new;
    my $raw_ptc = shift;
    Carp::croak "unsupported data:" unless ( $self->is_ptc($raw_ptc) );
    my $r_int = unpack 'V', bytes::substr( $raw_ptc, PTC_OFFSET_RESOURCE, 4 );
    $self->resource(List::Util::first { PTC_RESOURCE->{$_} == $r_int } keys %{ PTC_RESOURCE() });
    $self->name( bytes::substr $raw_ptc, PTC_OFFSET_NAME, 8 );
    $self->version( bytes::substr $raw_ptc, PTC_OFFSET_VERSION, 8 );
    $self->data( bytes::substr $raw_ptc, PTC_OFFSET_DATA );
    return $self;
}

sub restore {
    my $self = shift;
    my $resource = get_resource( resource => $self->resource );
    $resource->load($self, @_);
    return $resource;
}

sub is_ptc {
    my $class = shift;
    return 1 if ( bytes::substr( $_[0], 0, 4 ) eq PTC_SIGNATURE );
}

1;
