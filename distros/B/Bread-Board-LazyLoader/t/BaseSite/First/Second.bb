use strict;
use warnings;
use Bread::Board;

sub {
    container shift() => as {
	service tag => 'created by BaseSite';

    };
};

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 
