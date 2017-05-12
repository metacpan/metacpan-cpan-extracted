package CGI::Header::Extended;
use strict;
use warnings;
use parent 'CGI::Header';
use Carp qw/croak/;

sub get {
    my ( $self, @keys ) = @_;
    my @values = map { $self->SUPER::get($_) } @keys;
    wantarray ? @values : $values[-1];
}

sub set {
    my ( $self, @pairs ) = @_;
    my $header = $self->header;

    croak "Odd number of elements passed to 'set'" if @pairs % 2;

    my @values;
    while ( my ($key, $value) = splice @pairs, 0, 2 ) {
        push @values, $self->SUPER::set( $key => $value );
    }

    @values;
}

sub delete {
    my ( $self, @keys ) = @_;
    my @values = map { $self->SUPER::delete($_) } @keys;
    wantarray ? @values : $values[-1];
}

1;
