package DBIx::ObjectMapper::Metadata::Table::Column::Type::Datetime;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Metadata::Table::Column::Type);

sub _init {
    my $self = shift;
    if( @_ > 0 and @_ % 2 == 0 ) {
        my %opt = @_;
        $self->{realtype} = $opt{realtype} if exists $opt{realtype};
    }
}

sub set_engine_option {
    my ( $self, $engine ) = @_;
    $self->{datetime_parser} = $engine->datetime_parser;
    $self->{time_zone}       = $engine->time_zone;
}

sub datetime_parser { $_[0]->{datetime_parser} }
sub time_zone        { $_[0]->{time_zone} }

sub default_type { 'datetime' }

sub datetime_type {
    my $self = shift;
    my $real_type = $self->{realtype} || $self->default_type;
    $real_type =~ s/ /_/g;
    return $real_type;
}

sub parse_method { 'parse_' . $_[0]->datetime_type() }

sub format_method { 'format_' . $_[0]->datetime_type() }

sub from_storage {
    my ( $self, $val ) = @_;
    return $val unless length($val) > 0;
    return $val if ref($val) and ref($val) =~ /^DateTime/;
    return if $val eq '0000-00-00 00:00:00';

    my $method = $self->parse_method;
    my $dt = $self->datetime_parser->$method($val);
    if( ref($dt) eq 'DateTime' and $self->time_zone ) {
        $dt->set_time_zone($self->time_zone);
    }
    return $dt;
}

sub to_storage {
    my ( $self, $val ) = @_;
    return $val unless $val and ref($val) =~ /^DateTime/;
    my $method = $self->format_method;

    if( ref($val) eq 'DateTime' and $self->time_zone ) {
        $val->set_time_zone( $self->time_zone );
    }

    return $self->datetime_parser->$method($val);
}

1;
