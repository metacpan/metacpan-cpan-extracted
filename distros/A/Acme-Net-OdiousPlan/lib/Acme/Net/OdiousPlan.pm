package Acme::Net::OdiousPlan;

our $VERSION = '0.001';

use warnings;
use strict;
use Carp;
use LWP::Simple qw();


# Module implementation here

sub new {
    return LWP::Simple::get('http://odio.us/plan/bingo.cgi');
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Acme::Net::OdiousPlan - Your odio.us Gateway to Web 2.0 Riches


=head1 SYNOPSIS

    use Acme::Net::OdiousPlan;

    my $plan = Acme::Net::OdiousPlan->new();

    print "MAKE MONEY FAST:\n ".$plan;
  
=head1 DESCRIPTION

    A client for the odio.us business plan generator

=head1 INTERFACE 

=head2 new

You'd think that this method would return an object. And if this were real software, you'd
be right. But it's not. So you're wrong.  L<odio.us/plan> is part of B<boom 2.0>. We've optimized
the internet entrepreneurship experience. 

You simply go straight from a new plan to profit.


=head1 DIAGNOSTICS


This module is a parody. It does no error checking

=head1 DEPENDENCIES

L<LWP::Simple>

=head1 INCOMPATIBILITIES

Anything serious.

=head1 AUTHOR

Jesse Vincent  C<< <jesse@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

You've got to be kidding. I certainly am.

=cut
