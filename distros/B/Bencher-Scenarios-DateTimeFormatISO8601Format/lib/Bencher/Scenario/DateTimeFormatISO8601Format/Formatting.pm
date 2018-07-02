package Bencher::Scenario::DateTimeFormatISO8601Format::Formatting;

our $DATE = '2018-07-01'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use DateTime;

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

Bencher::Scenario::DateTimeFormatISO8601Format::Formatting - Benchmark formatting with DateTime::Format::ISO8601::Format

=head1 VERSION

This document describes version 0.001 of Bencher::Scenario::DateTimeFormatISO8601Format::Formatting (from Perl distribution Bencher-Scenarios-DateTimeFormatISO8601Format), released on 2018-07-01.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m DateTimeFormatISO8601Format::Formatting

To run module startup overhead benchmark:

 % bencher --module-startup -m DateTimeFormatISO8601Format::Formatting

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<DateTime::Format::ISO8601::Format> 0.003

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

=item * do{my$a=[bless({formatter=>undef,local_c=>{day=>31,day_of_quarter=>92,day_of_week=>7,day_of_year=>366,hour=>12,minute=>34,month=>12,quarter=>4,second=>56,year=>2000},local_rd_days=>730485,local_rd_secs=>45296,locale=>bless({am_pm_abbreviated=>["AM","PM"],available_formats=>{Bh=>"h B",Bhm=>"h:mm B",Bhms=>"h:mm:ss B",E=>"ccc",EBhm=>"E h:mm B",EBhms=>"E h:mm:ss B",EHm=>"E HH:mm",EHms=>"E HH:mm:ss",Ed=>"d E",Ehm=>"E h:mm a",Ehms=>"E h:mm:ss a",Gy=>"y G",GyMMM=>"MMM y G",GyMMMEd=>"E, MMM d, y G",GyMMMd=>"MMM d, y G",H=>"HH",Hm=>"HH:mm",Hms=>"HH:mm:ss",Hmsv=>"HH:mm:ss v",Hmv=>"HH:mm v",M=>"L",MEd=>"E, M/d",MMM=>"LLL",MMMEd=>"E, MMM d","MMMMW-count-one"=>"'week' W 'of' MMMM","MMMMW-count-other"=>"'week' W 'of' MMMM",MMMMd=>"MMMM d",MMMd=>"MMM d",Md=>"M/d",d=>"d",h=>"h a",hm=>"h:mm a",hms=>"h:mm:ss a",hmsv=>"h:mm:ss a v",hmv=>"h:mm a v",ms=>"mm:ss",y=>"y",yM=>"M/y",yMEd=>"E, M/d/y",yMMM=>"MMM y",yMMMEd=>"E, MMM d, y",yMMMM=>"MMMM y",yMMMd=>"MMM d, y",yMd=>"M/d/y",yQQQ=>"QQQ y",yQQQQ=>"QQQQ y","yw-count-one"=>"'week' w 'of' Y","yw-count-other"=>"'week' w 'of' Y"},code=>"en-US",date_format_full=>"EEEE, MMMM d, y",date_format_long=>"MMMM d, y",date_format_medium=>"MMM d, y",date_format_short=>"M/d/yy",datetime_format_full=>"{1} 'at' {0}",datetime_format_long=>"{1} 'at' {0}",datetime_format_medium=>"{1}, {0}",datetime_format_short=>"{1}, {0}",day_format_abbreviated=>["Mon","Tue","Wed","Thu","Fri","Sat","Sun"],day_format_narrow=>["M","T","W","T","F","S","S"],day_format_wide=>["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"],day_stand_alone_abbreviated=>["Mon","Tue","Wed","Thu","Fri","Sat","Sun"],day_stand_alone_narrow=>["M","T","W","T","F","S","S"],day_stand_alone_wide=>["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"],default_date_format_length=>"medium",default_time_format_length=>"medium",era_abbreviated=>["BC","AD"],era_narrow=>["B","A"],era_wide=>["Before Christ","Anno Domini"],first_day_of_week=>7,glibc_date_1_format=>"%a %b %e %H:%M:%S %Z %Y",glibc_date_format=>"%m/%d/%Y",glibc_datetime_format=>"%a %d %b %Y %r %Z",glibc_time_12_format=>"%I:%M:%S %p",glibc_time_format=>"%r",language=>"English",month_format_abbreviated=>["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],month_format_narrow=>["J","F","M","A","M","J","J","A","S","O","N","D"],month_format_wide=>["January","February","March","April","May","June","July","August","September","October","November","December"],month_stand_alone_abbreviated=>["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],month_stand_alone_narrow=>["J","F","M","A","M","J","J","A","S","O","N","D"],month_stand_alone_wide=>["January","February","March","April","May","June","July","August","September","October","November","December"],name=>"English United States",native_language=>"English",native_name=>"English United States",native_script=>undef,native_territory=>"United States",native_variant=>undef,quarter_format_abbreviated=>["Q1","Q2","Q3","Q4"],quarter_format_narrow=>[1,2,3,4],quarter_format_wide=>["1st quarter","2nd quarter","3rd quarter","4th quarter"],quarter_stand_alone_abbreviated=>["Q1","Q2","Q3","Q4"],quarter_stand_alone_narrow=>[1,2,3,4],quarter_stand_alone_wide=>["1st quarter","2nd quarter","3rd quarter","4th quarter"],script=>undef,territory=>"United States",time_format_full=>"h:mm:ss a zzzz",time_format_long=>"h:mm:ss a z",time_format_medium=>"h:mm:ss a",time_format_short=>"h:mm a",variant=>undef,version=>32},"DateTime::Locale::FromData"),offset_modifier=>0,rd_nanosecs=>0,tz=>bless({name=>"floating",offset=>0},"DateTime::TimeZone::Floating"),utc_rd_days=>730485,utc_rd_secs=>45296,utc_year=>2001},"DateTime"),bless({formatter=>undef,local_c=>{day=>31,day_of_quarter=>92,day_of_week=>7,day_of_year=>366,hour=>12,minute=>34,month=>12,quarter=>4,second=>56,year=>2000},local_rd_days=>730485,local_rd_secs=>45296,locale=>'fix',offset_modifier=>0,rd_nanosecs=>0,tz=>bless({name=>"UTC"},"DateTime::TimeZone::UTC"),utc_rd_days=>730485,utc_rd_secs=>45296,utc_year=>2001},"DateTime"),bless({formatter=>undef,local_c=>{day=>31,day_of_quarter=>92,day_of_week=>7,day_of_year=>366,hour=>12,minute=>34,month=>12,quarter=>4,second=>56,year=>2000},local_rd_days=>730485,local_rd_secs=>45296,locale=>'fix',offset_modifier=>0,rd_nanosecs=>0,tz=>bless({is_olson=>1,max_year=>2027,name=>"Asia/Jakarta",spans=>[["-Inf",58904383968,"-Inf",58904409600,25632,0,"LMT"],[58904383968,60683964000,58904409600,60683989632,25632,0,"BMT"],[60683964000,60962776800,60683990400,60962803200,26400,0,"+0720"],[60962776800,61259041800,60962803800,61259068800,27000,0,"+0730"],[61259041800,61369628400,61259074200,61369660800,32400,0,"+09"],[61369628400,61451800200,61369655400,61451827200,27000,0,"+0730"],[61451800200,61514870400,61451829000,61514899200,28800,0,"+08"],[61514870400,61946267400,61514897400,61946294400,27000,0,"+0730"],[61946267400,"Inf",61946292600,"Inf",25200,0,"WIB"]]},"DateTime::TimeZone::Asia::Jakarta"),utc_rd_days=>730485,utc_rd_secs=>20096,utc_year=>2001},"DateTime")];$a->[1]{locale}=$a->[0]{locale};$a->[2]{locale}=$a->[0]{locale};$a}

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.26.1 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 18.3 >>, OS kernel: I<< Linux version 4.10.0-38-generic >>.

Benchmark with default options (C<< bencher -m DateTimeFormatISO8601Format::Formatting >>):

 #table1#
 +-----------------+-----------------+-----------+-----------+------------+---------+---------+
 | participant     | p_tags          | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------+-----------------+-----------+-----------+------------+---------+---------+
 | format_datetime | format_datetime |     27000 |        37 |        1   | 6.7e-08 |      20 |
 | format_time     | format_time     |     28000 |        36 |        1   | 5.2e-08 |      21 |
 | format_date     | format_date     |     29000 |        35 |        1.1 | 1.1e-07 |      20 |
 +-----------------+-----------------+-----------+-----------+------------+---------+---------+


Benchmark module startup overhead (C<< bencher -m DateTimeFormatISO8601Format::Formatting --module-startup >>):

 #table2#
 +-----------------------------------+-----------+------------------------+------------+---------+---------+
 | participant                       | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors | samples |
 +-----------------------------------+-----------+------------------------+------------+---------+---------+
 | DateTime::Format::ISO8601::Format |       7.7 |                    2.4 |        1   | 4.1e-05 |      20 |
 | perl -e1 (baseline)               |       5.3 |                    0   |        1.5 | 1.9e-05 |      20 |
 +-----------------------------------+-----------+------------------------+------------+---------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-DateTimeFormatISO8601Format>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeFormatISO8601Format>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-DateTimeFormatISO8601Format>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
