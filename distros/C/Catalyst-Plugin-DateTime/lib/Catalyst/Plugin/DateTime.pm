package Catalyst::Plugin::DateTime;

use strict;
use warnings;

use Catalyst::Exception;
use DateTime;

our $VERSION = "0.03";

=pod
=head1 NAME

Catalyst::Plugin::DateTime - DateTime plugin for Catalyst.

=head1 SYNOPSIS

    # In your application class	
    use Catalyst qw/DateTime/;


    # Use DateTime objects within your Catalyst app:
    my $dt = $c->datetime(); # will return a DateTime object with local date and time
    my $dt = $c->datetime(year => '2005', month => '01');
 
    $c->datetime->mdy(); # returns current date in mdy format (i.e. 01/01/2006)

    $c->dt(time_zone => 'Asia/Taipei'); # returns current date & time for argued time zone

=head1 METHODS

=over 4

=item datetime

Returns a L<DateTime> object.  If params are argued they will be passed to the 
C<< DateTime->new() >> method.  Exceptions thrown by L<DateTime> will be caught by
L<Catalyst::Exception>.
 
If the argument list is empty, a L<DateTime> object with the local date and time
obtained via C<< DateTime->now() >> will be returned.

Uses C<< time_zone => local >> as a default.

=item dt

Alias to datetime.

=back

=cut

sub datetime {
	my $c = shift;
	my %params = @_;
	my $tz = delete $params{time_zone} || 'local';

	# use params if argued
	if (%params) {
		return DateTime->new(\%params)->set_time_zone($tz);
	}
	else { # otherwise use now
		return DateTime->now(time_zone => $tz);
	}
}

# alias $c->dt
*dt = \&datetime;

 
1;

=pod

=head1 DESCRIPTION

This module's intention is to make the wonders of L<DateTime> easily accesible within
a L<Catalyst> application via the L<Catalyst::Plugin> interface. 

It adds the methods C<datetime> and C<dt> to the C<Catalyst> namespace.

=head1 AUTHOR

James Kiser L<james.kiser@gmail.com>

=head1 SEE ALSO

L<Catalyst>, L<DateTime>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2006 the aforementioned author(s). All rights
    reserved. This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut


