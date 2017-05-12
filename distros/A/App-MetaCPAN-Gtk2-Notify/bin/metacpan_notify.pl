#!/usr/bin/perl 

use strict;
use warnings;

my %params;
my $arg = shift;
if ( $arg && $arg eq '-debug' ) {
    $params{debug} = 1;
}

use App::MetaCPAN::Gtk2::Notify;
App::MetaCPAN::Gtk2::Notify->run(%params);

=head1 NAME

metacpan_notify.pl

=head1 DESCRIPTION

Script displays notifications about modules recently uploaded on CPAN

=head1 ACKNOWLEGEMENTS

I borrowed idea from metacpan-growler.pl script by Hideaki Ohno.
See https://github.com/hideo55/metacpan-growler.

=head1 AUTHOR

Pavel Shaydo, C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Pavel Shaydo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
