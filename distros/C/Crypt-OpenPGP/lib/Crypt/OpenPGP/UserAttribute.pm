package Crypt::OpenPGP::UserAttribute;
use strict;

use Crypt::OpenPGP::ErrorHandler;
use base qw( Crypt::OpenPGP::ErrorHandler );

sub new {
    my $id = bless { }, shift;
    $id->init(@_);
}

sub init {
    my $id = shift;
    $id;
}

sub id { $_[0]->{blob} }
sub parse {
    my $class = shift;
    my($buf) = @_;
    my $id = $class->new;
    $id->{blob} = $buf->bytes;
    $id;
}

sub save { $_[0]->{blob} }

1;
