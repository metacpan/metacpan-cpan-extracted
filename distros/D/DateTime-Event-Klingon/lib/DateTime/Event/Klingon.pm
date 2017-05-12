# $Id: /svn/DateTime-Event-Klingon/tags/VERSION_1_0_1/lib/DateTime/Event/Klingon.pm 323 2008-04-01T06:37:25.246199Z jaldhar  $
package DateTime::Event::Klingon;

use warnings;
use strict;
use Carp qw/croak/;
use Filter::Util::Call;
use UNIVERSAL qw/isa/;

=head1 NAME

DateTime::Event::Klingon - Determine events of Klingon cultural significance

=head1 VERSION

Version 1.0

=cut

our $VERSION = '1.0';

=head1 SYNOPSIS

    use DateTime;
    use DateTime::Event::Klingon qw/Heghlu'meH QaQ jajvam'a'/;

    my $dt = DateTime->now;
    print 'Today ', Heghlu'meH QaQ jajvam'a'($dt) ? 'is' : 'is not', 
        " a good day to die!\n";  

=head1 DESCRIPTION

Use this module to determine dates and times with special significance to the 
Star Trek universe's Klingons.

Function names are given in tlhIngan Hol.  No functions are exported by default.

=head1 FUNCTIONS

=cut 

sub import {
    my ( $self, @args ) = @_;

    my $joinedargs = join q{ }, @args;
    if ( $joinedargs =~ /Heghlu'meH\ QaQ\ jajvam'a'/mx ) {
        {
            no strict 'refs';
            my $caller = caller;

            *{"${caller}::_heghlu_meh_qaq_jajvam_a_"}
                = \&{'_heghlu_meh_qaq_jajvam_a_'};
        }

        return filter_add(
            sub {
                my $count = 0;
                my $status;
                my $data = q{};
                while ( $status = filter_read() ) {
                    if ( $status < 0 ) {
                        return $status;
                    }
                    if ( $status == 0 ) {
                        last;
                    }
                    $data .= $_;
                    $count++;
                    $_ = q{};
                }
                if ( $count == 0 ) {
                    return 0;
                }
                $_ = $data;
                s{ Heghlu'meH\ QaQ\ jajvam'a'(\s*\() }
                 { _heghlu_meh_qaq_jajvam_a_$1  }gmx;
                return $count;
            }
        );
    }
}

=head2 Heghlu'meH QaQ jajvam'a' ($dt)

Is today a good day to die?  Given a C<DateTime> object, this function will 
return true if it is and false if it is not.

=cut

sub _heghlu_meh_qaq_jajvam_a_ {
    my ($dt) = @_;

    if ( !isa( $dt, 'DateTime' ) ) {
        croak q{Hab SoSlI' Quch!};
    }
    return 1;
}

=head1 AUTHOR

Jaldhar H. Vyas, C<< <jaldhar at braincells.com> >>

=head1 BUGS

Please report any other bugs or feature requests to C<bug-datetime-event-klingon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Event-Klingon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Event::Klingon

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Event-Klingon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Event-Klingon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Event-Klingon>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Event-Klingon>

=back

=head1 SEE ALSO

L<DateTime>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008  Consolidated Braincells Inc., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of DateTime::Event::Klingon
