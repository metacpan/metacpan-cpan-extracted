package Crypt::OpenPGP::Key::Public;
use strict;
use warnings;

our $VERSION = '1.20'; # VERSION

use parent qw( Crypt::OpenPGP::Key Crypt::OpenPGP::ErrorHandler );

sub all_props { $_[0]->public_props }
sub is_secret { 0 }
sub public_key { $_[0] }

1;
