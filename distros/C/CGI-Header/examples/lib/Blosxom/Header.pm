package Blosxom::Header;
use strict;
use warnings;
use parent 'CGI::Header';
use Carp qw/croak/;

our $INSTANCE;

sub new {
    my $class = shift;
    croak "Private method 'new' called for $class";
}

sub instance {
    my $class = shift;
    $INSTANCE ||= $class->SUPER::new( header => $blosxom::header );
}

sub has_instance {
    $INSTANCE;
}

1;
