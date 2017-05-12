###########################################
package Acme::HashKeyOrderBrokenAgain;
###########################################

use strict;
use warnings;
use Test::More;

our $VERSION = "0.02";

sub hash_key_order_reproducable {
    local $ENV{ PERL_PERTURB_KEYS } = "DETERMINISTIC";

    my %hash = ( one   => 1,  two  => 2, three => 3, 
                 four  => 4,  five => 5,   six => 6,
                 seven => 7, eight => 8,  nine => 9, 
                 ten   => 10 );

    my @first  = keys %hash;
    my @second = keys %hash;

    return is_deeply 
        \@first, \@second, "compare hash key order for subsequent calls " .
        "with PERL_PERTURB_KEYS=$ENV{ PERL_PERTURB_KEYS }";
}

1;

__END__

=head1 NAME

Acme::HashKeyOrderBrokenAgain - Request reproducable hash keys order within a script and verify if Perl complies

=head1 SYNOPSIS

    use Acme::HashKeyOrderBrokenAgain

    if( Acme::HashKeyOrderBrokenAgain::hash_key_order_reproducable() ) {
        print "Whoa! PERL_PERTURB_KEYS=DETERMINISTIC doesn't work!\n";
    }

=head1 DESCRIPTION

We all know that Perl's keys() function will return the keys of a hash in 
unpredictable order. However, for testing purposes, we sometimes need
the keys by keys() to be returned in deterministic order, which means that
although the order can't be predicted up front, subsequent calls to
keys() within the same script should return the keys in the same order if
(and only if)

    $ENV{ PERL_PERTURB_KEYS } = "DETERMINISTIC"

is set. 

This module checks if the feature actually works, and will hopefully alert 
Perl Porters via automatic CPAN smoke tests if it's broken. If the above 
assumption is incorrect, please drop me a message, I'll adapt this module
accordingly.

See 

    http://perlmonks.org/?node_id=1056280

and

   https://github.com/mschilli/php-httpbuildquery-perl/pull/3

for details on this issue.

=head1 LEGALESE

Copyright 2014 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2014, Mike Schilli <m@perlmeister.com>
