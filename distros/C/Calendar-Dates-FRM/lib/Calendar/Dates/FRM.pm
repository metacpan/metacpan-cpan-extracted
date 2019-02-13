package Calendar::Dates::FRM;

our $DATE = '2019-02-13'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

with 'Calendar::DatesRoles::FromData';

our @ENTRIES = (
    # nov2018exam
    {date=>'2019-01-03', summary=>'Exam results sent via email', tags=>['nov2018exam']},

    # may2019exam
    {date=>'2018-12-01', summary=>'Early registration opened', tags=>['may2019exam']},
    {date=>'2019-01-31', summary=>'Early registration closed', tags=>['may2019exam']},
    {date=>'2019-02-01', summary=>'Standard registration opened', tags=>['may2019exam']},
    {date=>'2019-02-28', summary=>'Standard registration closed', tags=>['may2019exam']},
    {date=>'2019-03-01', summary=>'Late registration opened', tags=>['may2019exam']},
    {date=>'2019-04-15', summary=>'Late registration closed', tags=>['may2019exam']},
    {date=>'2019-04-15', summary=>'Defer deadline', tags=>['may2019exam']},
    {date=>'2019-05-01', summary=>'Admission tickets released', tags=>['may2019exam']},
    {date=>'2019-05-18', summary=>'Exam day', tags=>['may2019exam']},
    {date=>'2019-06-28', summary=>'Exam results sent via email', tags=>['may2019exam']},

    # nov2019exam
    {date=>'2019-05-01', summary=>'Early registration opened', tags=>['nov2019exam']},
    {date=>'2019-07-31', summary=>'Early registration closed', tags=>['nov2019exam']},
    {date=>'2019-08-01', summary=>'Standard registration opened', tags=>['nov2019exam']},
    {date=>'2019-08-31', summary=>'Standard registration closed', tags=>['nov2019exam']},
    {date=>'2019-09-01', summary=>'Late registration opened', tags=>['nov2019exam']},
    {date=>'2019-10-15', summary=>'Late registration closed', tags=>['nov2019exam']},
    {date=>'2019-10-15', summary=>'Defer deadline', tags=>['nov2019exam']},
    {date=>'2019-11-01', summary=>'Admission tickets released', tags=>['nov2019exam']},
    {date=>'2019-11-16', summary=>'Exam day', tags=>['nov2019exam']},
    {date=>'2020-01-02', summary=>'Exam results sent via email', tags=>['nov2019exam']},
);

1;
# ABSTRACT: FRM exam calendar

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::Dates::FRM - FRM exam calendar

=head1 VERSION

This document describes version 0.001 of Calendar::Dates::FRM (from Perl distribution Calendar-Dates-FRM), released on 2019-02-13.

=head1 DESCRIPTION

This module provides FRM exam calendar using the L<Calendar::Dates> interface.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Dates-FRM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Dates-FRM>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Dates-FRM>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://www.garp.org/#!/frm/program-exams>

L<https://en.wikipedia.org/wiki/Financial_risk_management>

L<Calendar::Dates>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
