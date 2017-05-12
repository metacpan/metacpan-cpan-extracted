package App::Math::Tutor;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor - lets one generate exercises for mathematical topic

=cut

our $VERSION = '0.005';

use Moo;
use MooX::Cmd;
use MooX::Options;

=head1 SYNOPSIS

  # shows which categories of exercises are supported
  mtut
  # shows which exercises for unit calculations can be generated
  mtut unit
  # generates 15 addition and subtraction exercises for natural number (15 each)
  mtut natural add -n 25 -f nnn -r "[0..999"
  # generates 40 multiplication and division exercises for vulgar fractions (40 each)
  mtut vulfrac mul -n 40 -f nn/nnn -r "59/999 .. 02/002"

=head1 DESCRIPTION

Provides a command line tool to generate math (calculating) exercides.

=cut

sub execute
{
    shift->options_usage();
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-math-tutor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Math-Tutor>.  I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Math::Tutor

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Math-Tutor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Math-Tutor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Math-Tutor>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Math-Tutor/>

=back

I try to answer any support request within a week and tell how fast it's
probably solved and a fix is released. However, this is free time and it's
spare. Please be patient or buy support to receive an answer in a
guaranteed time.

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of App::Math::Tutor
