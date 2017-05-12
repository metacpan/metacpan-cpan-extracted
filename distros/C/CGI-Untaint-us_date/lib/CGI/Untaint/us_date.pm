package CGI::Untaint::us_date;

use warnings;
use strict;
use base qw/CGI::Untaint::date/;

=head1 NAME

CGI::Untaint::us_date - CGI::Untaint::date for US-formatted dates

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Where CGI::Untaint::date has 'UK' hardcoded, this has 'US' hardcoded.
That is the only difference.  

  use CGI::Untaint;
  my $handler = CGI::Untaint->new($q->Vars);

  my $date = $handler->extract(-as_us_date => 'date');

=head1 SUBROUTINES/METHODS

=head2 date_format

Overrides the date_format sub in CGI::Untaint::date so that
dates like 4/20/2112 are valid, but 20/4/2112 is an error.

=cut

sub date_format { 'US' }

=head1 AUTHOR

mike south, C<< <msouth at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-untaint-us_date at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Untaint-us_date>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Untaint::us_date


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Untaint-us_date>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Untaint-us_date>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Untaint-us_date>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Untaint-us_date/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 mike south.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CGI::Untaint::us_date
