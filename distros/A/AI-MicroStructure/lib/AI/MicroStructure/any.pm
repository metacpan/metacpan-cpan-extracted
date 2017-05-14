package AI::MicroStructure::any;
use strict;
use List::Util 'shuffle';
use AI::MicroStructure ();
our $VERSION = '0.20';

our $Theme = 'any';

sub import {
    # export the metaany function
    my $callpkg = caller;
    my $meta    = AI::MicroStructure::any->new();
    no strict 'refs';
    *{"$callpkg\::metaany"} = sub { $meta->name( @_ ) };
}

sub name {
    my $self  = shift;
    my $structure =
      ( shuffle( grep { !/^(?:any|random)$/ } AI::MicroStructure->structures() ) )[0];
      $self->{meta}->name( $structure, @_ );
}

sub new {
    my $class = shift;

    # we need a full AI::MicroStructure object, to support AMS::Locale
    return bless { meta => AI::MicroStructure->new( @_ ) }, $class;
}

sub structure { $Theme };

sub has_remotelist { };

1;
