package Acme::Anything;
use strict;
use 5.008;
use warnings;

our $VERSION = '0.04';

push @main::INC, \ &handler_of_last_resort;

sub handler_of_last_resort {
    my $fake_source_code = '1';
    open my ($fh), '<', \ $fake_source_code;
    return $fh;
};

no warnings;    ## no critic (warning)
'Warning! The consumption of alcohol may cause you to think you have mystical kung-fu powers.'

__END__

=head1 NAME

Acme::Anything - Anything, even imaginary modules are loadable

=head1 SYNOPSIS

  use Acme::Anything;
  use Fish; # OK!
  use CGI; # Also OK!

=head1 DESCRIPTION

This module inserts a hook into C<@INC> to load imaginary
modules. Things that would ordinarily work continue to work. Things
that would fail because the module doesn't exist won't fail anymore.

=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Acme::Anything

You can also look for information at:

=over

=item RT, CPAN's request tracker L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Anything>

=item AnnoCPAN, Annotated CPAN documentation L<http://annocpan.org/dist/Acme-Anything>

=item CPAN Ratings L<http://cpanratings.perl.org/d/Acme-Anything>

=item Search CPAN L<http://search.cpan.org/dist/Acme-Anything>

=back

=head1 AUTHOR

Josh ben Jore, E<gt>jjore@cpan.orgE<lt>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Anything

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Anything>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Anything>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Anything>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Anything>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2009, 2011 Joshua Jore

This program is distributed WITHOUT ANY WARRANTY, including but not
limited to the implied warranties of merchantability or fitness for a
particular purpose.

The program is free software.  You may distribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation (either version 2 or any later version) and
the Perl Artistic License as published by O’Reilly Media, Inc.  Please
open the files named Copying and Artistic for a copy of these
licenses.

=begin emacs

## Local Variables:
## mode: pod
## mode: auto-fill
## End:

=end emacs
