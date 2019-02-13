package Calendar::Dates::CFA;

our $DATE = '2019-02-13'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

with 'Calendar::DatesRoles::FromData';

our @ENTRIES = (
    # dec2018exam
    {date=>'2019-01-23', summary=>'Exam results announcement (Dec 2018, Levels I & II)', tags=>['dec2018exam']},

    # jun2019exam
    {date=>'2018-10-15', summary=>'First deadline to request disability accommodations', tags=>['jun2019exam']},
    {date=>'2018-10-17', summary=>'Early registration fee deadline', tags=>['jun2019exam']},
    {date=>'2019-02-13', summary=>'Standard registration fee deadline', tags=>['jun2019exam']},
    {date=>'2019-02-18', summary=>'Second deadline to request disability accommodations', tags=>['jun2019exam']},
    {date=>'2019-03-13', summary=>'Final (late) registration fee deadline', tags=>['jun2019exam']},
    {date=>'2019-03-18', summary=>'Final deadline to request disability accommodations', tags=>['jun2019exam']},
    # mid-may 2019, admission tickets available
    {date=>'2019-06-11', summary=>'Deadline for submission of test center change requests', tags=>['jun2019exam']},
    {date=>'2019-06-15', summary=>'Exam day: Asia-Pacific (Levels II & III); Americas and EMEA (all levels)', tags=>['jun2019exam']},
    {date=>'2019-06-16', summary=>'Exam day: Asia-Pacific (Level I only)', tags=>['jun2019exam']},
    {date=>'2019-06-16', summary=>'Religious alternate exam date (Americas and EMEA, all levels)', tags=>['jun2019exam']},
    {date=>'2019-06-17', summary=>'Religious alternate exam date (Asia Pacific, all levels)', tags=>['jun2019exam']},
    # TODO: result announcement

    # dec2019exam
    {date=>'2019-01-24', summary=>'Exam registration open', tags=>['dec2019exam']},
    {date=>'2019-03-27', summary=>'Early registration fee deadline', tags=>['dec2019exam']},
    {date=>'2019-08-14', summary=>'Standard registration fee deadline', tags=>['dec2019exam']},
    {date=>'2019-09-11', summary=>'Final (late) registration fee deadline', tags=>['dec2019exam']},
    {date=>'2019-12-07', summary=>'Exam day', tags=>['dec2019exam']},
);

1;
# ABSTRACT: CFA exam calendar

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::Dates::CFA - CFA exam calendar

=head1 VERSION

This document describes version 0.001 of Calendar::Dates::CFA (from Perl distribution Calendar-Dates-CFA), released on 2019-02-13.

=head1 DESCRIPTION

This module provides CFA exam calendar using the L<Calendar::Dates> interface.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Dates-CFA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Dates-CFA>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Dates-CFA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://www.cfainstitute.org/programs/cfa>

L<https://en.wikipedia.org/wiki/Chartered_Financial_Analyst>

L<Calendar::Dates>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
