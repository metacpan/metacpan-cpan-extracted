package Calendar::Dates::Academic::ID::UT::PPs;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

with 'Calendar::DatesRoles::DataPreparer::CalendarVar::FromDATA::Simple';
with 'Calendar::DatesRoles::DataUser::CalendarVar';

1;
# ABSTRACT: Academic calendar of Universitas Terbuka (postgraduate programs, program pascasarjana)

=pod

=encoding UTF-8

=head1 NAME

Calendar::Dates::Academic::ID::UT::PPs - Academic calendar of Universitas Terbuka (postgraduate programs, program pascasarjana)

=head1 VERSION

This document describes version 0.003 of Calendar::Dates::Academic::ID::UT::PPs (from Perl distribution Calendar-Dates-Academic-ID-UT-PPs), released on 2019-06-20.

=head1 SYNOPSIS

=head2 Using from Perl

 use Calendar::Dates::Academic::ID::UT::PPs;
 my $min_year = Calendar::Dates::Academic::ID::UT::PPs->get_min_year; # => 2019
 my $max_year = Calendar::Dates::Academic::ID::UT::PPs->get_max_year; # => 2019
 my $entries  = Calendar::Dates::Academic::ID::UT::PPs->get_entries(2019);

C<$entries> result:

 [
   {
     date => "2019-03-04",
     day => 4,
     default_lang => "id",
     month => 3,
     summary => "Pendaftaran/Admisi Mahasiswa Baru Periode I (begin)",
     tags => ["begin:admission1", "smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-03-27",
     day => 27,
     default_lang => "id",
     month => 3,
     summary => "Pendaftaran/Admisi Mahasiswa Baru Periode I (end)",
     tags => ["end:admission1", "smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-03-04",
     day => 4,
     default_lang => "id",
     month => 3,
     summary => "Pembayaran Admisi Periode I (begin)",
     tags => ["begin:payment1", "smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-04-03",
     day => 3,
     default_lang => "id",
     month => 4,
     summary => "Pembayaran Admisi Periode I (end)",
     tags => ["end:payment1", "smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-04-08",
     day => 8,
     default_lang => "id",
     month => 4,
     summary => "Pendaftaran/Admisi Mahasiswa Baru Periode II (begin)",
     tags => ["begin:admission2", "smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-05-15",
     day => 15,
     default_lang => "id",
     month => 5,
     summary => "Pendaftaran/Admisi Mahasiswa Baru Periode II (end)",
     tags => ["end:admission2", "smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-04-08",
     day => 8,
     default_lang => "id",
     month => 4,
     summary => "Pembayaran Admisi Periode II (begin)",
     tags => ["begin:payment2", "smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-05-22",
     day => 22,
     default_lang => "id",
     month => 5,
     summary => "Pembayaran Admisi Periode II (end)",
     tags => ["end:payment2", "smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-04-27",
     day => 27,
     default_lang => "id",
     month => 4,
     summary => "Tes Masuk Periode I",
     tags => ["smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-05-13",
     day => 13,
     default_lang => "id",
     month => 5,
     summary => "Pengumuman Hasil Tes Masuk Periode I",
     tags => ["smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-06-29",
     day => 29,
     default_lang => "id",
     month => 6,
     summary => "Tes Masuk Periode II",
     tags => ["smt2019/20.1"],
     year => 2019,
   },
   {
     date => "2019-07-08",
     day => 8,
     default_lang => "id",
     month => 7,
     summary => "Pengumuman Hasil Tes Masuk Periode II",
     tags => ["smt2019/20.1"],
     year => 2019,
   },
 ]

=head2 Using from CLI (requires L<list-calendar-dates> and L<calx>)

 % list-calendar-dates -l -m Academic::ID::UT::PPs
 % calx -c Academic::ID::UT::PPs

=head1 DESCRIPTION

This module provides academic calendar of Indonesia's open university
Universitas Terbuka (postgraduate programs, program pascasarjana).

=head1 DATES STATISTICS

 +---------------+-------+
 | key           | value |
 +---------------+-------+
 | Earliest year | 2019  |
 | Latest year   | 2019  |
 +---------------+-------+

=head1 DATES SAMPLES

Entries for year 2019:

 +------------+-----+--------------+-------+------------------------------------------------------+--------------------------------+------+
 | date       | day | default_lang | month | summary                                              | tags                           | year |
 +------------+-----+--------------+-------+------------------------------------------------------+--------------------------------+------+
 | 2019-03-04 | 4   | id           | 3     | Pendaftaran/Admisi Mahasiswa Baru Periode I (begin)  | begin:admission1, smt2019/20.1 | 2019 |
 | 2019-03-27 | 27  | id           | 3     | Pendaftaran/Admisi Mahasiswa Baru Periode I (end)    | end:admission1, smt2019/20.1   | 2019 |
 | 2019-03-04 | 4   | id           | 3     | Pembayaran Admisi Periode I (begin)                  | begin:payment1, smt2019/20.1   | 2019 |
 | 2019-04-03 | 3   | id           | 4     | Pembayaran Admisi Periode I (end)                    | end:payment1, smt2019/20.1     | 2019 |
 | 2019-04-08 | 8   | id           | 4     | Pendaftaran/Admisi Mahasiswa Baru Periode II (begin) | begin:admission2, smt2019/20.1 | 2019 |
 | 2019-05-15 | 15  | id           | 5     | Pendaftaran/Admisi Mahasiswa Baru Periode II (end)   | end:admission2, smt2019/20.1   | 2019 |
 | 2019-04-08 | 8   | id           | 4     | Pembayaran Admisi Periode II (begin)                 | begin:payment2, smt2019/20.1   | 2019 |
 | 2019-05-22 | 22  | id           | 5     | Pembayaran Admisi Periode II (end)                   | end:payment2, smt2019/20.1     | 2019 |
 | 2019-04-27 | 27  | id           | 4     | Tes Masuk Periode I                                  | smt2019/20.1                   | 2019 |
 | 2019-05-13 | 13  | id           | 5     | Pengumuman Hasil Tes Masuk Periode I                 | smt2019/20.1                   | 2019 |
 | 2019-06-29 | 29  | id           | 6     | Tes Masuk Periode II                                 | smt2019/20.1                   | 2019 |
 | 2019-07-08 | 8   | id           | 7     | Pengumuman Hasil Tes Masuk Periode II                | smt2019/20.1                   | 2019 |
 +------------+-----+--------------+-------+------------------------------------------------------+--------------------------------+------+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Dates-Academic-ID-UT-PPs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Dates-Academic-ID-UT-PPs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Dates-Academic-ID-UT-PPs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://www.ut.ac.id/>

L<https://www.ut.ac.id/kalender-akademik/pps>

L<Calendar::Dates>

L<App::CalendarDatesUtils> contains CLIs to list dates from this module, etc.

L<calx> from L<App::calx> can display calendar and highlight dates from Calendar::Dates::* modules

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__

#!default_lang: id

#smt2019/20.1

2019-03-04;Pendaftaran/Admisi Mahasiswa Baru Periode I (begin);begin:admission1,smt2019/20.1
2019-03-27;Pendaftaran/Admisi Mahasiswa Baru Periode I (end);end:admission1,smt2019/20.1

2019-03-04;Pembayaran Admisi Periode I (begin);begin:payment1,smt2019/20.1
2019-04-03;Pembayaran Admisi Periode I (end);end:payment1,smt2019/20.1

2019-04-08;Pendaftaran/Admisi Mahasiswa Baru Periode II (begin);begin:admission2,smt2019/20.1
2019-05-15;Pendaftaran/Admisi Mahasiswa Baru Periode II (end);end:admission2,smt2019/20.1

2019-04-08;Pembayaran Admisi Periode II (begin);begin:payment2,smt2019/20.1
2019-05-22;Pembayaran Admisi Periode II (end);end:payment2,smt2019/20.1

2019-04-27;Tes Masuk Periode I;smt2019/20.1

2019-05-13;Pengumuman Hasil Tes Masuk Periode I;smt2019/20.1

2019-06-29;Tes Masuk Periode II;smt2019/20.1

2019-07-08;Pengumuman Hasil Tes Masuk Periode II;smt2019/20.1
