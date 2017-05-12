#!/usr/bin/perl 

use warnings;
use strict;
use lib '../web/framelibs';

use CDBI::Example::example;

my @users = CDBI::Example::example::users->retrieve_all();

foreach my $user ( @users ) {
    foreach my $field ( qw ( uid username fullname password ) ) {
	print $user->$field, "\t";
    }
    print "\n";
}

exit 0;
