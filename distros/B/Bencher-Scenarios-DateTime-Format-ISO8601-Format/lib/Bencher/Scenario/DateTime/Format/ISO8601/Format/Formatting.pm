package Bencher::Scenario::DateTime::Format::ISO8601::Format::Formatting;

use 5.010001;
use strict;
use warnings;

use DateTime;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Bencher-Scenarios-DateTime-Format-ISO8601-Format'; # DIST
our $VERSION = '0.002'; # VERSION

my $dt_float = DateTime->new(year => 2000, month => 12, day => 31, hour => 12, minute => 34, second => 56);
my $dt_utc   = DateTime->new(year => 2000, month => 12, day => 31, hour => 12, minute => 34, second => 56, time_zone => 'UTC');
my $dt_jkt   = DateTime->new(year => 2000, month => 12, day => 31, hour => 12, minute => 34, second => 56, time_zone => 'Asia/Jakarta');

our $scenario = {
    summary => 'Benchmark formatting with DateTime::Format::ISO8601::Format',
    participants => [
        {
            name => 'format_date',
            fcall_template => 'DateTime::Format::ISO8601::Format->new->format_date(<dt>)',
            tags => ['format_date'],
        },
        {
            name => 'format_time',
            fcall_template => 'DateTime::Format::ISO8601::Format->new->format_time(<dt>)',
            tags => ['format_time'],
        },
        {
            name => 'format_datetime',
            fcall_template => 'DateTime::Format::ISO8601::Format->new->format_datetime(<dt>)',
            tags => ['format_datetime'],
        },
    ],
    datasets => [
        {args => {'dt@' => [$dt_float, $dt_utc, $dt_jkt]}},
    ],
};

1;
# ABSTRACT: Benchmark formatting with DateTime::Format::ISO8601::Format

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::DateTime::Format::ISO8601::Format::Formatting - Benchmark formatting with DateTime::Format::ISO8601::Format

=head1 VERSION

This document describes version 0.002 of Bencher::Scenario::DateTime::Format::ISO8601::Format::Formatting (from Perl distribution Bencher-Scenarios-DateTime-Format-ISO8601-Format), released on 2023-01-19.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTime::Format::ISO8601::Format::Formatting

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTime::Format::ISO8601::Format::Formatting

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::ISO8601::Format> 0.005

=head1 BENCHMARK PARTICIPANTS

=over

=item * format_date (perl_code) [format_date]

Function call template:

 DateTime::Format::ISO8601::Format->new->format_date(<dt>)



=item * format_time (perl_code) [format_time]

Function call template:

 DateTime::Format::ISO8601::Format->new->format_time(<dt>)



=item * format_datetime (perl_code) [format_datetime]

Function call template:

 DateTime::Format::ISO8601::Format->new->format_datetime(<dt>)



=back

=head1 BENCHMARK DATASETS

=over

=item * do{my$var=[bless({formatter=>undef,local_c=>{day=>31,day_of_quarter=>92,day_of_week=>7,day_of_year=>366,hour=>12,minute=>34,month=>12,quarter=>4,second=>56,year=>2000},local_rd_days=>730485,local_rd_secs=>45296,locale=>bless({am_pm_abbreviated=>["AM","PM"],available_formats=>{Bh=>"h B",Bhm=>"h:mm B",Bhms=>"h:mm:ss B",E=>"ccc",EBhm=>"E h:mm B",EBhms=>"E h:mm:ss B",EHm=>"E HH:mm",EHms=>"E HH:mm:ss",Ed=>"d E",Ehm=>"E h:mm a",Ehms=>"E h:mm:ss a",Gy=>"y G",GyMMM=>"MMM y G",GyMMMEd=>"E, MMM d, y G",GyMMMd=>"MMM d, y G",H=>"HH",Hm=>"HH:mm",Hms=>"HH:mm:ss",Hmsv=>"HH:mm:ss v",Hmv=>"HH:mm v",M=>"L",MEd=>"E, M/d",MMM=>"LLL",MMMEd=>"E, MMM d","MMMMW-count-one"=>"'week' W 'of' MMMM","MMMMW-count-other"=>"'week' W 'of' MMMM",MMMMd=>"MMMM d",MMMd=>"MMM d",Md=>"M/d",d=>"d",h=>"h a",hm=>"h:mm a",hms=>"h:mm:ss a",hmsv=>"h:mm:ss a v",hmv=>"h:mm a v",ms=>"mm:ss",y=>"y",yM=>"M/y",yMEd=>"E, M/d/y",yMMM=>"MMM y",yMMMEd=>"E, MMM d, y",yMMMM=>"MMMM y",yMMMd=>"MMM d, y",yMd=>"M/d/y",yQQQ=>"QQQ y",yQQQQ=>"QQQQ y","yw-count-one"=>"'week' w 'of' Y","yw-count-other"=>"'week' w 'of' Y"},code=>"en-US",date_format_full=>"EEEE, MMMM d, y",date_format_long=>"MMMM d, y",date_format_medium=>"MMM d, y",date_format_short=>"M/d/yy",datetime_format_full=>"{1} 'at' {0}",datetime_format_long=>"{1} 'at' {0}",datetime_format_medium=>"{1}, {0}",datetime_format_short=>"{1}, {0}",day_format_abbreviated=>["Mon","Tue","Wed","Thu","Fri","Sat","Sun"],day_format_narrow=>["M","T","W","T","F","S","S"],day_format_wide=>["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"],day_stand_alone_abbreviated=>["Mon","Tue","Wed","Thu","Fri","Sat","Sun"],day_stand_alone_narrow=>["M","T","W","T","F","S","S"],day_stand_alone_wide=>["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"],default_date_format_length=>"medium",default_time_format_length=>"medium",era_abbreviated=>["BC","AD"],era_narrow=>["B","A"],era_wide=>["Before Christ","Anno Domini"],first_day_of_week=>7,glibc_date_1_format=>"%a %b %e %r %Z %Y",glibc_date_format=>"%m/%d/%Y",glibc_datetime_format=>"%a %d %b %Y %r %Z",glibc_time_12_format=>"%I:%M:%S %p",glibc_time_format=>"%r",language=>"English",locale_data=>{am_pm_abbreviated=>'$var->[0]{locale}{am_pm_abbreviated}',available_formats=>'$var->[0]{locale}{available_formats}',code=>"en-US",date_format_full=>"EEEE, MMMM d, y",date_format_long=>"MMMM d, y",date_format_medium=>"MMM d, y",date_format_short=>"M/d/yy",datetime_format_full=>"{1} 'at' {0}",datetime_format_long=>"{1} 'at' {0}",datetime_format_medium=>"{1}, {0}",datetime_format_short=>"{1}, {0}",day_format_abbreviated=>'$var->[0]{locale}{day_format_abbreviated}',day_format_narrow=>'$var->[0]{locale}{day_format_narrow}',day_format_wide=>'$var->[0]{locale}{day_format_wide}',day_stand_alone_abbreviated=>'$var->[0]{locale}{day_stand_alone_abbreviated}',day_stand_alone_narrow=>'$var->[0]{locale}{day_stand_alone_narrow}',day_stand_alone_wide=>'$var->[0]{locale}{day_stand_alone_wide}',era_abbreviated=>'$var->[0]{locale}{era_abbreviated}',era_narrow=>'$var->[0]{locale}{era_narrow}',era_wide=>'$var->[0]{locale}{era_wide}',first_day_of_week=>7,glibc_date_1_format=>"%a %b %e %r %Z %Y",glibc_date_format=>"%m/%d/%Y",glibc_datetime_format=>"%a %d %b %Y %r %Z",glibc_time_12_format=>"%I:%M:%S %p",glibc_time_format=>"%r",language=>"English",month_format_abbreviated=>["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],month_format_narrow=>["J","F","M","A","M","J","J","A","S","O","N","D"],month_format_wide=>["January","February","March","April","May","June","July","August","September","October","November","December"],month_stand_alone_abbreviated=>["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],month_stand_alone_narrow=>["J","F","M","A","M","J","J","A","S","O","N","D"],month_stand_alone_wide=>["January","February","March","April","May","June","July","August","September","October","November","December"],name=>"English United States",native_language=>"English",native_name=>"English United States",native_script=>undef,native_territory=>"United States",native_variant=>undef,quarter_format_abbreviated=>["Q1","Q2","Q3","Q4"],quarter_format_narrow=>[1,2,3,4],quarter_format_wide=>["1st quarter","2nd quarter","3rd quarter","4th quarter"],quarter_stand_alone_abbreviated=>["Q1","Q2","Q3","Q4"],quarter_stand_alone_narrow=>[1,2,3,4],quarter_stand_alone_wide=>["1st quarter","2nd quarter","3rd quarter","4th quarter"],script=>undef,territory=>"United States",time_format_full=>"h:mm:ss a zzzz",time_format_long=>"h:mm:ss a z",time_format_medium=>"h:mm:ss a",time_format_short=>"h:mm a",variant=>undef,version=>39},month_format_abbreviated=>'$var->[0]{locale}{locale_data}{month_format_abbreviated}',month_format_narrow=>'$var->[0]{locale}{locale_data}{month_format_narrow}',month_format_wide=>'$var->[0]{locale}{locale_data}{month_format_wide}',month_stand_alone_abbreviated=>'$var->[0]{locale}{locale_data}{month_stand_alone_abbreviated}',month_stand_alone_narrow=>'$var->[0]{locale}{locale_data}{month_stand_alone_narrow}',month_stand_alone_wide=>'$var->[0]{locale}{locale_data}{month_stand_alone_wide}',name=>"English United States",native_language=>"English",native_name=>"English United States",native_script=>undef,native_territory=>"United States",native_variant=>undef,quarter_format_abbreviated=>'$var->[0]{locale}{locale_data}{quarter_format_abbreviated}',quarter_format_narrow=>'$var->[0]{locale}{locale_data}{quarter_format_narrow}',quarter_format_wide=>'$var->[0]{locale}{locale_data}{quarter_format_wide}',quarter_stand_alone_abbreviated=>'$var->[0]{locale}{locale_data}{quarter_stand_alone_abbreviated}',quarter_stand_alone_narrow=>'$var->[0]{locale}{locale_data}{quarter_stand_alone_narrow}',quarter_stand_alone_wide=>'$var->[0]{locale}{locale_data}{quarter_stand_alone_wide}',script=>undef,territory=>"United States",time_format_full=>"h:mm:ss a zzzz",time_format_long=>"h:mm:ss a z",time_format_medium=>"h:mm:ss a",time_format_short=>"h:mm a",variant=>undef,version=>39},"DateTime::Locale::FromData"),offset_modifier=>0,rd_nanosecs=>0,tz=>bless({name=>"floating",offset=>0},"DateTime::TimeZone::Floating"),utc_rd_days=>730485,utc_rd_secs=>45296,utc_year=>2001},"DateTime"),bless({formatter=>undef,local_c=>{day=>31,day_of_quarter=>92,day_of_week=>7,day_of_year=>366,hour=>12,minute=>34,month=>12,quarter=>4,second=>56,year=>2000},local_rd_days=>730485,local_rd_secs=>45296,locale=>'$var->[0]{locale}',offset_modifier=>0,rd_nanosecs=>0,tz=>bless({name=>"UTC"},"DateTime::TimeZone::UTC"),utc_rd_days=>730485,utc_rd_secs=>45296,utc_year=>2001},"DateTime"),bless({formatter=>undef,local_c=>{day=>31,day_of_quarter=>92,day_of_week=>7,day_of_year=>366,hour=>12,minute=>34,month=>12,quarter=>4,second=>56,year=>2000},local_rd_days=>730485,local_rd_secs=>45296,locale=>'$var->[0]{locale}',offset_modifier=>0,rd_nanosecs=>0,tz=>bless({is_olson=>1,max_year=>2031,name=>"Asia/Jakarta",spans=>[["-Inf",58904383968,"-Inf",58904409600,25632,0,"LMT"],[58904383968,60683964000,58904409600,60683989632,25632,0,"BMT"],[60683964000,60962776800,60683990400,60962803200,26400,0,"+0720"],[60962776800,61259041800,60962803800,61259068800,27000,0,"+0730"],[61259041800,61369628400,61259074200,61369660800,32400,0,"+09"],[61369628400,61451800200,61369655400,61451827200,27000,0,"+0730"],[61451800200,61514870400,61451829000,61514899200,28800,0,"+08"],[61514870400,61946267400,61514897400,61946294400,27000,0,"+0730"],[61946267400,"Inf",61946292600,"Inf",25200,0,"WIB"]]},"DateTime::TimeZone::Asia::Jakarta"),utc_rd_days=>730485,utc_rd_secs=>20096,utc_year=>2001},"DateTime")];$var->[0]{locale}{locale_data}{am_pm_abbreviated}=$var->[0]{locale}{am_pm_abbreviated};$var->[0]{locale}{locale_data}{available_formats}=$var->[0]{locale}{available_formats};$var->[0]{locale}{locale_data}{day_format_abbreviated}=$var->[0]{locale}{day_format_abbreviated};$var->[0]{locale}{locale_data}{day_format_narrow}=$var->[0]{locale}{day_format_narrow};$var->[0]{locale}{locale_data}{day_format_wide}=$var->[0]{locale}{day_format_wide};$var->[0]{locale}{locale_data}{day_stand_alone_abbreviated}=$var->[0]{locale}{day_stand_alone_abbreviated};$var->[0]{locale}{locale_data}{day_stand_alone_narrow}=$var->[0]{locale}{day_stand_alone_narrow};$var->[0]{locale}{locale_data}{day_stand_alone_wide}=$var->[0]{locale}{day_stand_alone_wide};$var->[0]{locale}{locale_data}{era_abbreviated}=$var->[0]{locale}{era_abbreviated};$var->[0]{locale}{locale_data}{era_narrow}=$var->[0]{locale}{era_narrow};$var->[0]{locale}{locale_data}{era_wide}=$var->[0]{locale}{era_wide};$var->[0]{locale}{month_format_abbreviated}=$var->[0]{locale}{locale_data}{month_format_abbreviated};$var->[0]{locale}{month_format_narrow}=$var->[0]{locale}{locale_data}{month_format_narrow};$var->[0]{locale}{month_format_wide}=$var->[0]{locale}{locale_data}{month_format_wide};$var->[0]{locale}{month_stand_alone_abbreviated}=$var->[0]{locale}{locale_data}{month_stand_alone_abbreviated};$var->[0]{locale}{month_stand_alone_narrow}=$var->[0]{locale}{locale_data}{month_stand_alone_narrow};$var->[0]{locale}{month_stand_alone_wide}=$var->[0]{locale}{locale_data}{month_stand_alone_wide};$var->[0]{locale}{quarter_format_abbreviated}=$var->[0]{locale}{locale_data}{quarter_format_abbreviated};$var->[0]{locale}{quarter_format_narrow}=$var->[0]{locale}{locale_data}{quarter_format_narrow};$var->[0]{locale}{quarter_format_wide}=$var->[0]{locale}{locale_data}{quarter_format_wide};$var->[0]{locale}{quarter_stand_alone_abbreviated}=$var->[0]{locale}{locale_data}{quarter_stand_alone_abbreviated};$var->[0]{locale}{quarter_stand_alone_narrow}=$var->[0]{locale}{locale_data}{quarter_stand_alone_narrow};$var->[0]{locale}{quarter_stand_alone_wide}=$var->[0]{locale}{locale_data}{quarter_stand_alone_wide};$var->[1]{locale}=$var->[0]{locale};$var->[2]{locale}=$var->[0]{locale};$var}

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.34.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.4.0-91-generic >>.

Benchmark with default options (C<< bencher -m DateTime::Format::ISO8601::Format::Formatting >>):

 #table1#
 +-----------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | participant     | p_tags          | rate (/s) | time (μs) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+
 | format_datetime | format_datetime |     20000 |        49 |                 0.00% |                 7.48% | 1.2e-07 |      20 |
 | format_time     | format_time     |     21000 |        47 |                 5.90% |                 1.50% | 1.1e-07 |      20 |
 | format_date     | format_date     |     22000 |        46 |                 7.48% |                 0.00% |   1e-07 |      22 |
 +-----------------+-----------------+-----------+-----------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  f_d format_datetime  f_t format_time  f_d format_date 
  f_d format_datetime  20000/s                   --              -4%              -6% 
  f_t format_time      21000/s                   4%               --              -2% 
  f_d format_date      22000/s                   6%               2%               -- 
 
 Legends:
   f_d format_date: p_tags=format_date participant=format_date
   f_d format_datetime: p_tags=format_datetime participant=format_datetime
   f_t format_time: p_tags=format_time participant=format_time

Benchmark module startup overhead (C<< bencher -m DateTime::Format::ISO8601::Format::Formatting --module-startup >>):

 #table2#
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | participant                       | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors | samples |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+
 | DateTime::Format::ISO8601::Format |       8.7 |               2.6 |                 0.00% |                42.28% | 4.6e-05 |      20 |
 | perl -e1 (baseline)               |       6.1 |               0   |                42.28% |                 0.00% | 2.7e-05 |      20 |
 +-----------------------------------+-----------+-------------------+-----------------------+-----------------------+---------+---------+


Formatted as L<Benchmark.pm|Benchmark> result:

                          Rate  DFI:F  perl -e1 (baseline) 
  DFI:F                114.9/s     --                 -29% 
  perl -e1 (baseline)  163.9/s    42%                   -- 
 
 Legends:
   DFI:F: mod_overhead_time=2.6 participant=DateTime::Format::ISO8601::Format
   perl -e1 (baseline): mod_overhead_time=0 participant=perl -e1 (baseline)

To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTime-Format-ISO8601-Format>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTime-Format-ISO8601-Format>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTime-Format-ISO8601-Format>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
