package Acme::Buga;
# ABSTRACT: Buga buga text encode

use strict;
use warnings;

# original idea from @PACMAN, thank you man!
our $VERSION = '1.002';

use Convert::BaseN;

use Exporter 'import';
our @EXPORT_OK = qw/buga/;

# constants
use constant BUGA_LIST => [qw/Buga bUga buGa BugA buga BUGA BUga buGA/];
use constant OCTALS    => {map{ BUGA_LIST->[$_] => $_ } 0 .. 7};

sub new {
    my $class = shift;
    my $args = (@_ % 2 == 0) ? {@_} : undef;

    return bless {_value => $args->{value} || undef}, $class;
}

# accessors
sub base8 {
    return Convert::BaseN->new( base => 8 );
}

sub value {
    $_[0]->{_value} = $_[1] if $_[1];
    return $_[0]->{_value};
}

# methods
sub encode {
    my ($self, $value) = @_;
    my $en = $self->base8->encode( $value || $self->value );
    $en =~ s/\D//g;
    return join ' ', map { BUGA_LIST->[$_]} split(//,$en);
}

sub decode {
    my ($self, $value) = @_;
    $value = $value ? $value : $self->value; 

    $value = join '', map { OCTALS->{$_} } split(/ /, $value);
    return $self->base8->decode($value .'==');
}


sub buga {
    return __PACKAGE__->new(value => $_[0]);
}

1;
__END__

=encoding utf8

=head1 NAME

Acme::Buga - Buga text encoding


=head1 SYNOPSIS

    use Acme::Buga;

    # Default
    my $b = Acme::Buga->new;
    say $b->encode('Test');

    # Alternative constructor
    use Acme::Buga 'buga';
    say buga('Another Test')->encode;


=head1 DESCRIPTION

This module encode any text into a Buga buga bUga string value.


=head1 FUNCTIONS

Acme::Buga exports the following functions...

=head2 buga

    my $obj = buga('Daniel Vinciguerra');

Alternative constructor that returns a Acme::Buga object.


=head1 METHODS

Acme::Buga contains this methods...

=head2 new

    my $b = Acme::Buga->new;
    my $b = Acme::Buga->new( value => 'Test' );

Default class constructor    

=head2 encode

    my $encoded = $b->encode;
    my $encoded = $b->encode('Test');

Encode string into buga text


=head2 decode

    my $decoded = $b->decode;
    my $decoded = $b->decode('buGa BUGA Buga BUga buGa BUGA BUga BugA BugA BUGA Buga BUga buGa buga');

Decode string into buga text


=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra@bivee.com.br>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Vinciguerra.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

