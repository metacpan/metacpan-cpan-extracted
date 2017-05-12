package Acme::NameGen;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.010100';

use vars qw($VERSION @EXPORT_OK);
require Exporter;
*import    = \&Exporter::import;
@EXPORT_OK = qw(gen gen_lc gen_uc);

my @adjectives = (
    'admiring',      'adoring',     'affectionate',  'agitated',
    'amazing',       'angry',       'awesome',       'blissful',
    'boring',        'brave',       'clever',        'cocky',
    'compassionate', 'competent',   'condescending', 'confident',
    'cranky',        'dazzling',    'determined',    'distracted',
    'dreamy',        'eager',       'ecstatic',      'elastic',
    'elated',        'elegant',     'eloquent',      'epic',
    'fervent',       'festive',     'flamboyant',    'focused',
    'friendly',      'frosty',      'gallant',       'gifted',
    'goofy',         'gracious',    'happy',         'hardcore',
    'heuristic',     'hopeful',     'hungry',        'infallible',
    'inspiring',     'jolly',       'jovial',        'keen',
    'kind',          'laughing',    'loving',        'lucid',
    'mystifying',    'modest',      'musing',        'naughty',
    'nervous',       'nifty',       'nostalgic',     'objective',
    'optimistic',    'peaceful',    'pedantic',      'pensive',
    'practical',     'priceless',   'quirky',        'quizzical',
    'relaxed',       'reverent',    'romantic',      'sad',
    'serene',        'sharp',       'silly',         'sleepy',
    'stoic',         'stupefied',   'suspicious',    'tender',
    'thirsty',       'trusting',    'unruffled',     'upbeat',
    'vibrant',       'vigilant',    'vigorous',      'wizardly',
    'wonderful',     'xenodochial', 'youthful',      'zealous',
    'zen'
);

sub gen {
    my ( $adjective_element, $subjects, $subjects_element ) = @_;
    $adjectives[ $adjective_element || rand scalar @adjectives ] . '_'
      . $subjects->[ $subjects_element || rand scalar @$subjects ];
}

sub gen_lc { lc gen(@_) }

sub gen_uc { uc gen(@_) }

1;

__END__

=pod


=head1 NAME

Acme::NameGen - A simple and dumb name generator based by cpan authors.

=head1 VERSION

Version 0.010100

=head1 SYNOPSIS

    use Acme::NameGen qw/gen gen_lc gen_uc/;

    # generates a random name like affectionate_MZIESCHA
    my $random_author = gen;

    # Same as gen but upper case
    my $random_author = gen_uc;
    
    # Same as gen but lower case
    my $random_author = gen_lc;
    
=head1 SUBROUTINES/METHODS

=head2 gen

=head2 gen_lc

=head2 gen_uc

=head1 AUTHOR

Mario Zieschang, C<< <mzieschacpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-namegen-CPAN-authors at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-NameGen-CPAN-Authors>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::NameGen


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-NameGen-CPAN-Authors>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-NameGen-CPAN-Authors>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-NameGen-CPAN-Authors>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-NameGen-CPAN-Authors/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Acme::NameGen
