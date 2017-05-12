package Acme::MomoiroClover::Z;

use strict;
use warnings;

use Carp  qw(croak);
use Date::Simple ();

use base qw(Acme::MomoiroClover);

our $change_date = Date::Simple->new('2011-04-10');

sub _check {
    Date::Simple::today() >= shift->change_date() or croak('MomoiroClover Z is not found yet.');
}

sub change_date {
    $change_date;
}

1;
