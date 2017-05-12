package Bencher::Scenario::HumanDateParsingModules::Parsing;

our $DATE = '2017-01-25'; # DATE
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark human date parsing modules e.g. DF:Natural, DF:Alami, etc.',
    modules => {
        'DateTime::Format::Alami::EN' => {version => 0.13},
        'DateTime::Format::Alami::ID' => {version => 0.13},
    },
    participants => [
        {
            module=>'DateTime::Format::Alami::EN',
            code_template => 'state $parser = DateTime::Format::Alami::EN->new; $parser->parse_datetime(<text>)',
            tags => ['lang:en'],
        },
        {
            module=>'DateTime::Format::Alami::ID',
            code_template => 'state $parser = DateTime::Format::Alami::ID->new; $parser->parse_datetime(<text>)',
            tags => ['lang:id'],
        },
        {
            module=>'Date::Extract',
            code_template => 'state $parser = Date::Extract->new; $parser->extract(<text>)',
            tags => ['lang:en'],
        },
        {
            module=>'DateTime::Format::Natural',
            code_template => 'state $parser = DateTime::Format::Natural->new; $parser->parse_datetime(<text>)',
            tags => ['lang:en'],
        },
        {
            module=>'DateTime::Format::Flexible',
            code_template => 'DateTime::Format::Flexible->parse_datetime(<text>)',
            tags => ['lang:en'],
        },
    ],
    datasets => [
        {args => {text => '18 feb'}},
        {args => {text => '18 feb 2011'}},
        {args => {text => '18 feb 2011 06:30:45'}},
        {args => {text => 'today'}, include_participant_tags => ['lang:en']},
        {args => {text => 'hari ini'}, include_participant_tags => ['lang:id']},
    ],
};

1;
# ABSTRACT: Benchmark human date parsing modules e.g. DF:Natural, DF:Alami, etc.

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Scenario::HumanDateParsingModules::Parsing - Benchmark human date parsing modules e.g. DF:Natural, DF:Alami, etc.

=head1 VERSION

This document describes version 0.006 of Bencher::Scenario::HumanDateParsingModules::Parsing (from Perl distribution Bencher-Scenarios-HumanDateParsingModules), released on 2017-01-25.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher -m HumanDateParsingModules::Parsing

To run module startup overhead benchmark:

 % bencher --module-startup -m HumanDateParsingModules::Parsing

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

Packaging a benchmark script as a Bencher scenario makes it convenient to include/exclude/add participants/datasets (either via CLI or Perl code), send the result to a central repository, among others . See L<Bencher> and L<bencher> (CLI) for more details.

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Date::Extract> 0.05.01

L<DateTime::Format::Alami::EN> 0.13

L<DateTime::Format::Alami::ID> 0.13

L<DateTime::Format::Flexible> 0.26

L<DateTime::Format::Natural> 1.04

=head1 BENCHMARK PARTICIPANTS

=over

=item * DateTime::Format::Alami::EN (perl_code) [lang:en]

Code template:

 state $parser = DateTime::Format::Alami::EN->new; $parser->parse_datetime(<text>)



=item * DateTime::Format::Alami::ID (perl_code) [lang:id]

Code template:

 state $parser = DateTime::Format::Alami::ID->new; $parser->parse_datetime(<text>)



=item * Date::Extract (perl_code) [lang:en]

Code template:

 state $parser = Date::Extract->new; $parser->extract(<text>)



=item * DateTime::Format::Natural (perl_code) [lang:en]

Code template:

 state $parser = DateTime::Format::Natural->new; $parser->parse_datetime(<text>)



=item * DateTime::Format::Flexible (perl_code) [lang:en]

Code template:

 DateTime::Format::Flexible->parse_datetime(<text>)



=back

=head1 BENCHMARK DATASETS

=over

=item * 18 feb

=item * 18 feb 2011

=item * 18 feb 2011 06:30:45

=item * today

=item * hari ini

=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.24.0 >>, CPU: I<< Intel(R) Core(TM) M-5Y71 CPU @ 1.20GHz (2 cores) >>, OS: I<< GNU/Linux LinuxMint version 17.3 >>, OS kernel: I<< Linux version 3.19.0-32-generic >>.

Benchmark with default options (C<< bencher -m HumanDateParsingModules::Parsing >>):

 #table1#
 {dataset=>"18 feb"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | DateTime::Format::Flexible  |       380 |     2.6   |       1    | 1.5e-05 |      20 |
 | Date::Extract               |       960 |     1     |       2.5  | 4.5e-06 |      20 |
 | DateTime::Format::Alami::EN |       991 |     1.01  |       2.6  | 4.3e-07 |      20 |
 | DateTime::Format::Natural   |      2000 |     0.7   |       4    | 1.7e-05 |      33 |
 | DateTime::Format::Alami::ID |      1660 |     0.602 |       4.37 | 4.3e-07 |      20 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

=begin html

<img src="data:image/png;base64,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" />

=end html


 #table2#
 {dataset=>"18 feb 2011"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | DateTime::Format::Natural   |       200 |      5    |       1    | 8.9e-05 |      20 |
 | Date::Extract               |       310 |      3.2  |       1.5  | 5.6e-06 |      20 |
 | DateTime::Format::Flexible  |       400 |      2.5  |       1.9  | 1.6e-05 |      20 |
 | DateTime::Format::Alami::EN |       410 |      2.4  |       2    | 1.3e-05 |      20 |
 | DateTime::Format::Alami::ID |       736 |      1.36 |       3.49 | 1.1e-06 |      20 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAALdQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/wAA/wAAAAAA/wAAAAAA/wAA/wAA/wAAAAAAAAAAAAAA/wAA/wAA/wAA/wAA8gAA1AAAlAAA7QAA5wAAuQAAaAAAawAAPwAAUAAAYgAAIgAAJgAACgAAEwAAHQAAAAAA/wAA3wAAdwAAaAAA////yssKTAAAADd0Uk5TABFEZiKq7pm7zDPdiHdVcNXkxz/w/HXsEXWORKPH31v59vSEt6fP68p18Pbnp/3g+fLr1crO0rXyogEAAAABYktHRACIBR1IAAAACXBIWXMAAABIAAAASABGyWs+AAAScklEQVR42u3di3rruHVAYRCkeIWYk8mknfQ0k1uvSe9NgzR9//cqQJCyLMnHJijTW9vr/zKGbcmkhbNCQ7RkGQMAAAAAAAAAAAAAAAAAAADgfRV2fscWH/2tALnKannP+vkdb0+XVgdfN/SNx9Ge6r0VdHfo+6796O8ReKtyaKwpnbMx6Goap6Ctc70xvQ9H58r3H/1dAm8Ug24H5+oyBF03jXdT0GXtGl+aKnwUgq427wbYSVhytOEI7A4h6GMIPByTvZ0Oysd6ukLBkgMPZFpD2zFUm9bQ4fDsbTnYYFpqHOuWO4V4HCFo59umfRa0q9uoD4fnzm7dA7Cj1o51WCO7GHQ4FBdT0ONg0nnprvno7w9YpR3LIS2UrQ/1NkM8SBfhPqJxgxl9XHpwjMbjOAw/6YZ2aOrSdt0w1P18lqPrwrvOTz76ewTerLCVsbYwNp6bs6ffeheWX4ADAAAAAAAAAAAAwPuLT+B08QFiTRhPA/CgusbaISTcdHasy2UAHlR8Lqdrp0fwGtfNw0d/U0Cu+mjM4ZCeaGH9PHz0NwXk6n3bDYUZU8njRdBffjr5Dnhvw5Ta8LONQXfxyRbOlKnk8iJov1PQe/1/5sv3++znu++/7LOf3Q42/t33kIL++V9t67msp4KrF5Ycey0+3E5nVuxef0yg3ekZV3tN3G4l/PXGoKc7gEX8GxJV/Hsp87D7zSDoTAR9oV/+GEoXZqZ1y7D3zSDoTAR96ei76Tmdfd0NXbEMe98Mgs5E0Feq+YmcRXqiffHs+fYEnYmgM20PWsTN2OuvVlR7/RK03OlPM+725z72+j+OkqAhnb3x3nsgaLy7+OPmTady7/BziaDx7uIdgjcdoZ/uOfzwizf64WITBI17qsoivQDB/IIEYe18/Jv4+gQufSr+RcpbVyrdcX4hg+Trn9/o68U3QNC4J9vNL0AwvyCB8U33t7FTH/8EpTvUVXjvxpXC6Aga4pxegGB+QQIzdWtjCX38LXLrYtC3rlS250sOgoYIp7/XPr8gwfRuCtrN5/D97StZgoY8p1bnFyT4dtDnVyJoCLS8AMHyggTnQcfHsdlyCvrGlQgaAk0vQOBqs7wgQQp6jCVU4d1iOE5B37jSFPS4bIegIYL17TDUY+g0vSDB1OphiMflcDewjQ9c87evFIOOV0x++PpGnIfGewrL4/nBaqcXJEivTxBV8yNHbl7p/IobEDTu6U1PkH7PZ1ETNO6JoIF7ImioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWjs4pc/vupX99gPQWMXP77+l3F/cY/9EDR2QdBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKHKowRt/cSaovG1M8uwIGgkjxJ0YYNjXZims2NdLsOCoJE8StCTbjRFOEgb183D6RKCRvJIQR8Pcelh4pt5OF1E0EgeKOiirowZU8kjQeOmBwraNeFNmUouL4NOPmgSIcf7B91Oqf16c9BFHZbNLDnwbY9zhC6H+LbyVXx3Hk4XEjSSxwn60ExD58JB3y3DgqCRPE7Q81nnvu6GrliGBUEjeZygF4W1Z8OMoJE8XtA3ETQSgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VHmcoN3gm8KYovG1Ow0LgkbyMEG7brRdY0zT2bEul2FB0EgeJuh6NMa2pvA2xj0Pp0sJGsmjBG29qWwa45t5OF1M0EgeJ+iD90NvxlTySNC46VGCdj6unwdTppLLy6DbyQdOJGR4/6DdlNpvti85jKl8/9KSw04+ejbx4d4/6H5K7fuNQfcx3sL3la+MKYd5OF3MkgPJoyw5zHCMp6KN6ZwxrVuGBUEjeZig+7ob6j6NXbEMC4JG8jBBm8LaYh7PhhlBI3mcoL+JoJEQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqsoLu+8zNEzQSSUGXtW/tkNU0QSMRFHTvj7YtXF1kbJ6gkQgK2jXGtsZ0NmPzBI1EUtCOoLGVoKBt3YegS5Yc2EBQ0Kb0Qz3UZc7mCRqJpKBNVbrxpeOz80FYkRSNr91pWBA0EkFBV2nxXFY3Lz001tremKazYziKz8OCoJGICbqyx5isHYfbdwrbVG/hw8Wum4fTpQSNREzQZdsNbXS4vejwpXMhYhvTtX4eni796HmEEGKCNqZPx+AXlhx+cI0vzZhKHi+DdpOPnk18uPcPupxS++1bznIc4hG6vrnkqFw4cB9rU6aSS4LGTYKCtrXrWtc1L18jrJxZcuCbBC05wgF2bEwx3FxD27geqXxf+bAiKYd5OF1M0EhkBd23xrQ3lxzWT6fsjOnCuqJ1y7AgaCSCgi6H3oQD7wun7Zxvh/jQ0r7uhq5YhgVBIxEUtGlb4+qhe+HSyqbSizTOw4ygkUgKOhrLnMcmETRmgoK2WQ9LSggaiaCgj90btvMCgkYiKGjTuPhgjpzH9xM0ZoKCtj7J2TxBIxEU9BYEjYSgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGqoQNFQhaKhC0FCFoKEKQUMVgoYqBA1VCBqqEDRUIWioQtBQhaChCkFDFYKGKgQNVQgaqhA0VCFoqELQUIWgoQpBQxWChioEDVUIGnv44evr7rIjgsYevr7e2Z/vsiOCxh4I+oZjG94Uja/daVgQtHAEfa2vY9BNZ8e6XIYFQQtH0FeKrgtBF94a47p5OF1I0MIR9BXXuBC0jelaPw+nCwlaOIK+NA5FDHpMJY8E/VgI+kJR9yYGXaaSy8ugk7tMyafyux9f9Xf32I+ioNsptV9vDNp1zrWDq1hy3Nffv/7v/8t77EdR0MnWI7R1KejKV+EwPczD6WKCzkTQme5xHjouOUznwkHfLcOCoDMRdKa7Bd3X3dAVy7Ag6EwEnel+v/ourD0bZgSdiaAz8VgOmQg6E0HLRNCZCFomgs5E0DIRdCaClomgMxG0TASdiaBlIuhMBC0TQWciaJkIOhNBy0TQmQhaJoLORNAyEXQmgpaJoDMRtEwEnYmgZSLoTAQtE0FnImiZCDoTQctE0JkIWiaCzkTQMhF0JoKWiaAzEbRMBJ2JoGUi6EwELRNBZyJomQg6E0HLRNCZCFomgs5E0DIRdCaClomgMxG0TASdiaBlIuhMBC0TQWciaJkIOhNBy0TQmQhaJoLORNAyEXQmgpaJoDMRtEwEnYmgZSLoTAQtE0FnImiZCDoTQctE0JkIWiaCzkTQMhF0JoKWiaAzEbRMBJ2JoGUi6EwELRNBZyJomQg6E0HLRNCZCFomgs5E0DIRdCaClomgMxG0TASdiaBlIuhMBC0TQWciaJkIOhNBy0TQmQhaJoLORNDr/MOPr/rVPfZD0JkIep29/l0IOtPmoPvW164wpmjCeBoWBJ2JoDNtDbqom2ocQsJNZ8e6XIYFQWci6Exbg7YxWdeawtswdvNwupigMxF0ps1H6BCwaQ4pbOvn4XQxQWci6Ex3uFPYdl1vxlTySNAE/aETd4egnQt3A8tUcnkZdDu5y5SIQNBiJ85Nqf3mHqftwnH5pSWHndxlSkQgaLET10+pfb8xaBePvqHgylfGlMM8nC5myZGJoDNtP8vRhzuFoeDOhdW0W4YFQWci6Eyb19CNb4c6RN3X3dAVy7Ag6EwEnWn7ncJqXiIXaSyerZgJOhNBZ+KxHOsQtPCJI+h1CFr4xBH0OgQtfOIIeh2CFj5xBL0OQQufOIJeh6CFTxxBr0PQwieOoNchaOETR9DrELTwiSPodQha+MQR9DoELXziCHodghY+cQS9DkELnziCXoeghU8cQa9D0MInjqDXIWjhE0fQ6xC08Ikj6HUIWvjEEfQ6BC184gh6HYIWPnEEvQ5BC584gl6HoIVPHEGvQ9DCJ46g1yFo4RNH0OsQtPCJI+h1CFr4xBH0OgQtfOIIeh2CFj5xBL0OQQufOIJeh6CFTxxBr0PQwieOoNchaOETR9DrELTwiSPodQha+MQR9DoELXziCHodghY+cQS9DkELnziCXoeghU8cQa9D0MInjqDXIWjhE0fQ6xC08Ikj6HUIWvjEEfQ6BC184gh6HYIWPnEEvQ5BC584gl6HoIVPHEGvQ9DCJ46g1yFo4RNH0OsQtPCJI+h1CFr4xBH0OgQtfOIIeh2CFj5xBL0OQQufOIJeh6CFTxxBr0PQwieOoNchaOETR9DrELTwiSPodQha+MQR9DoELXziCHodghY+cUqCtnaf/VT/uNO/yz/tFPQ/7xX07wl6Def22Y/9w07/Lv+yU9D/ulfQ//soQVcHXzeFMUXja3caFgSdiaAzbQ66O/R91xrTdHasy2VYEHQmgs60Nejeh6Nz5fvCh1Ws6+bhdDFBZyLoTFuDrmJJla9sTNf6eThdTNCZCDrTPe4UFmHJMaaSx8ugfzr57r3tsIvJl3/7y6v+/R47+o/X9/Of99jPf72+n7/cZeb+790nbphS+/n2oI91W5gylVxeBP1lp6B389+v++M99vM/r+/nT/fYzx/fcIPuMnF/eveJS0EPP9t8eO7sEvH1kgN4MF0zDWEZbUw5zMNHf1NAptHbKIQd7pa1bhmAx+T8xJi+7oauWAbg0RXp8RTFXg+rAAAAeC99vAdaLO/M7z9dcvaxreLbImP90z/bzo1Nf8wNyvk2bmz9eitFmqrr3ayawpxdVf2N2f5c2ukuqFve8d4+v+TpY1/HWco5JX7ax0ubNmV18wtf+PSdbtD1J7K2fr2V0g/XXxOvsGoKc3bl2huz/blMZwRteoDq85m+PFeYHsWaFfTZPm5u2rS3o2ozfhy8/QblnA29sfXrrRxa39/czaopzNnVFPTlbH8uaY7KOr5N02Zd+u80e+GD+LE/xkNDdtDTPuZtP236GN4cbTk01rjwjimdmyIOY2WmT2+/Qdd7vbyFm7a+bGXZanyoZOfOJu4s6DVT+I1dLVt+tqv43yno+es+oXTzpwepztPmfPrvNHvhg/ixt27YEnTcx7zt06aLejRjXUzl+qYr28G5+ODvZnCHutoQ9PkNutrr1S3ctPVlK8tWzXGI/3uauLOg10zhN3a1bPnZrqZPts+/7hOa58iP5uon9NAGZ08tsMXgNgSd9nG26Tb8sBzrqrZpbTEtF8On3MH08ff94auylxxvukHXn8ja+tVWwjGzOs/p6daumsKcXT0FfTbbn8ty88+OA8slTby7/HS3LFzF+n5L0Pb5pqe74odpsTcFPV1sx66d/l2M2bCGftMNuv5E1tYvt1L50tqhudxNvLWrpjBnV+dBf+ojdDXdtXjlTqGdnhaWHXT1dPflbNOljwecJWjn26a9R9BvuUH5S45nW7/cSnrsQn35NaunMGdXT0FXz+4sfiLp5rtpIfZ60EV9yA7aDRefiIraxVNZc9BhATL9o0xPObPlhqDfcoPyg3629cutDOne2njxNaunMGdXT0G7z/oAzemnmEtz8spZjljX6HOCPu1jOd+Qfgj3004OhzCM0/bjw2Tjs3XiurAYjtOnt9+gu57luN76xVmOaf2fHgS8nOU43dpVU/iNXc1bfr6r01mOs6/7hKbT8F269a+d5UjX37KP5XxD+gVBG+6iF6aqR3MYyrj9ohvaoanLsBBp40MM46e336C7nuW43vrFWY4mPaH56IvTWY7l1q6bwm/sat7y812dznKcfR0+yOk3uPG+U3y/mh5iWKy7xwYAAAAAAAAAAPT4f8TGcXXW1pyFAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDE3LTAxLTI1VDE0OjQ2OjI4KzA3OjAwaktVgAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAxNy0wMS0yNVQxNDo0NjoyOCswNzowMBsW7TwAAAAhdEVYdHBzOkhpUmVzQm91bmRpbmdCb3gANTA0eDcyMCs1MCs1MNbiIsMAAAATdEVYdHBzOkxldmVsAEFkb2JlLTIuMAo5k3QNAAAAAElFTkSuQmCC" />

=end html


 #table3#
 {dataset=>"18 feb 2011 06:30:45"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | Date::Extract               |       310 |      3.2  |       1    | 4.3e-06 |      22 |
 | DateTime::Format::Flexible  |       390 |      2.5  |       1.3  | 1.6e-05 |      20 |
 | DateTime::Format::Natural   |       625 |      1.6  |       2.01 | 6.4e-07 |      20 |
 | DateTime::Format::Alami::EN |      1500 |      0.65 |       4.9  | 2.6e-06 |      26 |
 | DateTime::Format::Alami::ID |      1600 |      0.62 |       5.2  | 6.9e-07 |      20 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAJ9QTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEwAAJgAACgAAAAAAAAAAAAAAUAAAPwAAAAAAuQAA/wAAAAAA1AAA/wAA/wAArwAA/wAAAAAA/wAAAAAA/wAA/wAAlAAAxAAAaAAAngAAIgAAYgAAOgAAAAAAdwAA/wAA////KXHxsAAAADF0Uk5TABFEZiIzu+6ImVXdqnfMjnXk1cfO1co/9vD54PzndezKpxGsRKMi9Mc/dZmnvuvy8ODf5qIAAAABYktHRACIBR1IAAAACXBIWXMAAABIAAAASABGyWs+AAAUEUlEQVR42u3dC3viyJmG4VLpVJKw0p2eTLI5zGZ7Z9N73q3s//9vK6nEwRIemw818wLPfSWUzXTzAX4aFxiMcwAAAAAAAAAAAAAAAAAAAAC+v8zPH/js1z4rgFVe7D/ycf4g+sN/LatYB/rG/agO9Z4JOqubou3Cr30egY/Ku2bINw/BD0EX45KC9iGUc+Oh+rXPJPBRU9BVF0Kd+1g3TQxT0HkdmpinbXWz+7XPJPBh45ajGm6Mw87HlyHwmA1BF3E45qWe/nvfl7/2eQQ+LO2hfdtXaQ893DxHn3d+MFbthttu9tC4H2PQIVZNdRp0qKtRumlu41UDgFsagm7rYrzr54fdhsumoNvOTY9LT/cHPUHjflTtcMdwqHfccjTDPcBuvJHO6nxIvHPTrmM8CrgTuy7P+q7qmvo3fd91dTk/ytH344dNrKajgDuR+WG/4X3m9uv+6PRh4f0VJw4AAAAAAAAAAAAA+CVFeg5Y6GIzPkmsidPTdvcrcF/K3RR06Fvfj08S6307PkNsvwJ3JcQ4BV23zvlqehbvEPdhBe7N9LTz4aDwJ5/sV+DezO3uYuzK9Cqh4Zj2ddCfPk9++wXP6offvevHqwZ0U2Ld77cJOswvssjnkPPXQX/5w02C/vz5Jl+bxxrzD7e5mfnj39/1p6sGpKD//GmrW2g3Pt5RvrHl+PLlJt8swm0eV3msMdVtXjjwl/97108bjPnHT1efxJRtOR5ksSxiMf7OFLdfZwStO4agF9LtcPcyvZjT9cNXoQrHNSFo3TEEvZCCLut+ehHnuPbZcU0IWncMQZ+3fzFnNr+YMzt9USdB644haIMbBX2jF0Y/1pjj76X+rv5K0Hgg/p8IGg9i/B4QPxL0Bt8sCBrf3bhL/9At9HE7//WnD/q6mEXQ2FKRZ+nNB9J7EQz3bN3Lb8Zf5R4+EPQ/T29iMPn5/T+d/Lw4AwSNLfl+fvOB9F4Ew1aj6f9l7PQjWw6ChprDmw+k9yIYgg5py/GhPfRxy0HQkHD4Xe3pvQjShwSNe3UIOr0XAUHjvu3ffGB+LwKCxn2b3nwg1Pv3IpiDbj8adLs/HYKGBB+rrqtbN78XQT4FvevyjwU9/sHk688fxOPQ+J7G13akJ6nt34vAze9N8JGgM3/1jwoJGlt6+3XRPJcDd4ig8SQIGg+FoPFQCBoPhaDxUAgaD4Wg8VAIGg+FoPFQCBq38bfLnwFkQdC4jRuVRtC4DYI2IGhdBG1A0LoI2oCgdRG0AUHrImgDgtZF0AYErYugDQhaF0EbELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdAGBK2LoA0IWhdBGxC0LoJeKPbvE/NSDQdZE+twsiYErYugXyt3c9BlPQbd9L6t8+OaELQugn4lxJiCzvrxnXCz8Z1DQ39YZwSti6AX5remC834XuXTJ+PbiUZ3+qZ1BK2LoBdStm2XjUG3c8jtIujPYeQ3OMfY2KMEnU+Jfft09Tmdss3q0o1B53PIOUHfC4JemLINfQhVFwq2HHfnUYJOttpy+JCCLmIx/Fvp3H6dEbQugl443A6PWw7XB+eqcFwTgtZF0Auvgy7rvuuz45oQtC6C/mWZ96/WCUHrImgDgtZF0AYErYugDQhaF0EbELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdAGBK2LoA0IWhdBGxC0LoI2IGhdBG1A0LoI2oCgdRG0AUHrImgDgtZF0AYErYugDQhaF0EbELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdAGBK2LoA0IWhdBGxC0LoI2IGhdBG1A0LoI2oCgdRG0AUHrImgDgtZF0AYErYugDQhaF0EvFHE63MW6yZzLmlgHd1wTgtZF0K+VuynofleWfeVc0/u2zo9rQtC6CPqVEOMYdBmz8ba6zKIfjuvdfp0RtC6CXvBj0MW4vShiMX0yHOzXGUHrIuiFQ7bZsOVo55DbRdCfw8hvcI6xsUcJOp8S+/bp6nO6z/alrjKXzyHnBH0vCHohZZv1vd9/wpbjnjxK0MlmW46+mT4ZttHDv5XusM4IWhdBL0xBt9GPhrCHe4dVOK4JQesi6IUp6PHRu+kBvLLuuz47rglB6yLoX5Z5/2qdELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdAGBK2LoA0IWhdBGxC0LoI2IGhdBG1A0LoI2oCgdRG0AUHrImgDgtZF0AYErYugDQhaF0EbELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdAGBK2LoA0IWhdBGxC0LoI2IGhdBG1A0LoI2oCgdRG0AUHrImgDgtZF0AYErYugDQhaF0EbELQugjYgaF0EbUDQugjagKB1EfRCEcfDrIl1OLMmBK2LoF8rd1PQTe/bOl+vCUHrIuhXQoxj0Fn0w8f9ap0RtC6CXvDx5GC5zghaF0EvTNm2c8DLdfblcxj5Dc4xNvYoQedTYt8+XX1Op2zzOeDlOiNoXQS9wJbjvj1K0MlWW44iFsO/kW61zghaF0EvpNvhPjhXhfWaELQugl5IQZd13/XZek0IWhdBn5d5f3adELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LW9YxBl+WVYwha1/MFndex8t1VTRO0rqcLuowvvspCnb1/am8iaF1PF3RonK+c6695yTZB63q+oANBP7KnC9rX5RB0zpbjQT1d0C6PXd0df/GiBUHrer6gXZGH9prbZ4JW9nRBF2nznBdXjCFoXU8WdOFfGj9oO+4UPqYnCzqv+q4a7bhT+JieLGjnynR3kC3Hg3q6oF2+G2+ha7Ycj+npgvZ16KvQN9eMIWhdTxd0CK5tXNaxh35Mzxh0WTlXseV4TE8XdN6VLhaOh+0e1NMF7arKhbrr3/+DbyNoXc8X9KjNr/rZN0Hrerqg/VVPS0oIWtfTBf1y1WYjIWhdTxe0a8L4ZI6r3mOQoHU9XdA+JteMIWhdTxf0FghaF0EbELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdBnFbtYh8y5rBlWd1wTgtZF0Gf1jffdUHDT+3b85ej7NSFoXQR9VvTOhcpl09of1hlB6yLos+oX53Y758dXag0H+3VG0LoI+qwyVn2XuXYOuV0E/TmMrnqhLb6PRwk6nxL79mmjq6Wv2nzYQ+dzyDlB3wuCPntqtRsDLthy3J1HCTrZassx3f8b7gkWsRh/vaPbrzOC1kXQ55SxdO5luJnug3NVOK4JQesi6LNeYt/VQ9Rl3Xd9dlwTgtZF0OcV3k/9ZvMvDctOf3kYQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdAGBK2LoA0IWhdBGxC0LoI2IGhdBG1A0LoI2oCgdRG0AUHrImgDgtZF0AYErYugDQhaF0EbELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdAGBK2LoA0IWhdBGxC0LoI2IGhdBG1A0LoI2oCgdRG0AUHrImgDgtZF0AYErYugDQhaF0EbELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOCNvjp/QT+dYMxBG1A0AYEbUDQugjaYLugQxebzLmsiXVwxzUhaAOCNtgs6NC3vm+ca3rf1vlxTQjagKANNgu6bp3zlcuiH+M+rDOCNiBog62C9tEVPq3TwX6dEbQBQRtsF/Quxq507Rxyuwj6cxj5bYY9CYK+SD4l9u3TFlf9sLuI4/65c/kcck7QVyPoi2wb9NRuEUu2HNshaIOtthzl2G4WyyIWw7+Vzu3XGUEbELTBZo9ydC/jQ9HO9cG5KhzXhKANCNpgs6DLuu/qMq19dlwTgjYgaIPtflKYeZ/NqztdJwRtQNAGPJdDF0EbELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdAGBK2LoA0IWhdBGxC0LoI2IGhdBG1A0LoI2oCgdRG0AUHrImgDgtZF0AYErYugDQhaF0EbELQugjYgaF0EbUDQugjagKB1EbQBQesiaAOC1kXQBgSti6ANCFoXQRsQtC6CNiBoXQRtQNC6CNqAoHURtAFB6yJoA4LWRdAGBK2LoA0IWhdBGxC0LoI2IGhdBG1A0LoI2oCgdRG0AUHrImgDgtZF0AYErYugDQhaF0EbELQugjYgaF0EbbBl0C/VcJA1sQ4na0LQBgRtsGHQZT0G3fS+rfPjmhC0AUEbbBd01vdD0Fn0zoX+sM4I2oCgDbYLOjRhCNpHNx3s1xlBGxC0wWZBt102Bt3OIbeLoD+Hkd9o2HMg6IvkU2LfPm1x1Q9bjbp0Y9D5HHJO0Fcj6ItsG3ToQ6i6ULDl2A5BG2y15fAhBV3EYvi30rn9OnusoL/+/K6/bTCGoA22fBx63HK4PjhXheOaPFbQNyqNoA02D7qs+67PjmtC0LpjCPqXZd6/WicErTuGoA0IWncMQRsQtO4YgjYgaN0xBG1A0LpjCNqAoHXHELQBQeuOIWgDgtYdQ9AGBK07hqANCFp3DEEbELTuGII2IGjdMQRtQNC6YwjagKB1xxC0AUHrjiFoA4LWHUPQBgStO4agDQhadwxBGxC07hiCNiBo3TEEbUDQumMI2oCgdccQtMGNgv7607v+bYMxBK075rGC/vmhSiNoA4I2IGjdMQRtQNC6YwjagKB1xxC0AUHrjiFoA4LWHUPQBgStO4agDQhadwxBGxC07hiCNiBo3TEEbUDQumMI2oCgdccQtAFB644haAOC1h1D0AYErTuGoA0IWncMQRsQtO4YgjYgaN0xBG1A0LpjCNqAoHXHELQBQeuOIWgDgtYdQ9AGBK07hqANCFp3DEEbELTuGII2IGjdMQRtQNC6Yx4r6H+/TQL/8VBj/nqb0m405rGC/s/bJPBfDzXmL7cp7UZjNgu62MW6yZzLmlgHd1wTgtYdQ9Bn9buy7Cvnmt63dX5cE4LWHUPQ55RxuHUuYplF71zo3X6dEbTuGII+pxi3F0UsfBzW4WC/zghadwxBvyUbthztHHK7CPoPn0e//fJ9/fff3/U/G4z534ca88f3x/zpHsZ0U2J/3i7ol7rKXD6HnL8O+tPnmwT94+/e9QNjFn54f8yP9zAmBd39frOb597vG15vOYA70zfTMmyjncu7wwrcpTb60RD2cO+wCscVuEchTpwr677rs+MK3LdsvJ0+WQEAAO5POd73zFbHLI7beNY84mTGcugVZ+J4iVZjlqfqi/Ewu2Qvd+YyrM9rlk54NfaieetJZ66UxaSiPPcVfSrVdOczrI6Jh2s9L87/zbeO/8CsecRxxmro8nPTJVqNWZ5qrMcv/EUP75+5DOvzmsdu/XeGP3DRvPWkM1fKYlKozn1Fn8r0UKA/eWbq6sHB6o2qqotrO521+Kquhtq/IK8u0esxy1NNz8i9LOj1ZVif110Vy3NjL5q3nnTmSllMmoJefUWfSrqS8nq4DkL6//5q8y/DwYvPu8a7MHww/KkQpoiHtXDT8dZZh6/qauji86su0WHMW1Piy3hzd3nQry/D8lTHZ0n24dyFuWjeetLhdN6cdAh6f/mfT7r447NTQ3TT//dXW1a3rq2zKdzY9LmruhCmp2Z3YVcX5qCnZ8Luv6rLocvPr7pEhzFvTYk+dKagX12G5am6l27835kLc9G89aTD6bw56Rh0ZtquPYD5Sort8ZiuGpVDzUXt09YibUmHb25h58rxp/DDXzNuOeZZyy3HNDR/83PrJVpsORanGn3WBUvQry7D6rwON5rFaU+Ha/SieetJ6ytlOekY9OlX9KnsL/7J/bNmf196N23EpqDTf/ZtX01XmnPmPfR8Ysugp6HFm59bL9Ei6MWpDn/Gx9IU9Okt9OJUi5h73zXLscM1etG89aTVlbKadBr0U99CFyd3LY7f7fM43hocgg6xaqrrg06zvvOdwv0leudOoZ9e23Z50K8uw/JU09MW6uXfuXTeetLqSllNOgZdvLqz+ETSxQ/d8hg3bqLD+DDTPuhhBzJdY9MLwXxuDjrN+t5Bz5fo/aCzend50K8uw/JUu3R3rV38nUvnrSetrpTVpGPQ4VmfmTl9GwvjdXK4T56+QZbjNbPbDZ+36SsxPnl1fBHNuGnLupfpeOus7/oox8mU9x7lGP9NtvGioNeXYXGq032M6fm/q2v0onnrSctHOdaTpqBPL//zmR6G78dLf7hPnh6+r166zBV163Zdnm5a+q7qmjofdiLV+MS/8XjrrO/6KMfJlHcf5Uh/4brLsDjVJr2U+SVmy2v0snnrSctHOdaTDj9Y6Z+15w84/nR1/9PbYnriX2a7zwYAAAAAAAAAAPCu/wdAmnaobz6dtQAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAxNy0wMS0yNVQxNDo0NjoyOCswNzowMGpLVYAAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMTctMDEtMjVUMTQ6NDY6MjgrMDc6MDAbFu08AAAAIXRFWHRwczpIaVJlc0JvdW5kaW5nQm94ADUwNHg3MjArNTArNTDW4iLDAAAAE3RFWHRwczpMZXZlbABBZG9iZS0yLjAKOZN0DQAAAABJRU5ErkJggg==" />

=end html


 #table4#
 {dataset=>"hari ini"}
 +-----------------------------+----------+------+-----------+-----------+------------+---------+---------+
 | participant                 | dataset  | perl | rate (/s) | time (μs) | vs_slowest |  errors | samples |
 +-----------------------------+----------+------+-----------+-----------+------------+---------+---------+
 | DateTime::Format::Alami::ID | hari ini | perl |      4000 |       250 |          1 | 4.3e-07 |      20 |
 +-----------------------------+----------+------+-----------+-----------+------------+---------+---------+

=begin html

<img src="data:image/png;base64,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" />

=end html


 #table5#
 {dataset=>"today"}
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | participant                 | rate (/s) | time (ms) | vs_slowest |  errors | samples |
 +-----------------------------+-----------+-----------+------------+---------+---------+
 | DateTime::Format::Flexible  |       400 |     2.5   |       1    |   1e-05 |      20 |
 | Date::Extract               |      1200 |     0.8   |       3.1  | 8.3e-07 |      21 |
 | DateTime::Format::Natural   |      2690 |     0.371 |       6.75 | 2.7e-07 |      20 |
 | DateTime::Format::Alami::EN |      4000 |     0.25  |       9.9  |   9e-07 |      31 |
 +-----------------------------+-----------+-----------+------------+---------+---------+

=begin html

<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAtAAAAH4CAMAAABUnipoAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAALpQTFRF////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJgAAEwAAAAAAAAAAawAAYgAAAAAA5wAA/wAAAAAA8gAA/wAA/wAA/wAA5gAA/wAA7QAAzgAA8gAA9wAA4gAA9AAA7wAAAAAAAAAA/wAAAAAA/wAA/wAA3wAAlAAAaAAAIgAAHQAACgAAAAAAdwAA/wAA3wAAxwAAXQAA////t98i3wAAADd0Uk5TABFEZiKIu6qZM93ud1XMjnXk1cfVzj/2/fL89sfs698Rdd1E8PfSzvzp1fD5z/Qip+R1p+vSyjVPUroAAAABYktHRACIBR1IAAAACXBIWXMAAABIAAAASABGyWs+AAATJUlEQVR42u3dCZ/buHmAcQAkKB5DdmwncY5tuuk2vZz0bpE0/f6fqwBBzYxFyauVAGj48vn/dgWNxhaPeUxDHI2pFAAAAAAAAAAAAAAAAAAAAID8tFnuGP3oVQFuVdXHe8Ytd5x5+ax1XvPodQSu1rzUey7oQ2uM6R69jsC1qr71+VbWGh90HYYYtLE2dNxUj15B4KeYg256a4fKuKFtnZ2DrgbbOh+zq2LjwEaEKUfjD8b2YNyTD9xpH3Tt/CNPgw+6j2EDGxHn0GacmjiH9odnZ6reT52N62qrY9jARoSgrWva5m3QdmiC+GpQOyYd2Awf9DjUPmoftI71OjP2aj4vbcJsY55/ANvQjP6Foa83TDlapdo+HKT14Eu2vTKh5XZ69DoCVzv0lZ76pm+Hv5qmvh+65SzHNIW7fjLS9xygsR3a+PmGMVodx+PD8W5tmEADAAAAAAAAAAAAQDZP4Wc3desGe2YENqYbQtDtZMbwzrDTEdgWPU3N8t5zO61GYGNsa5vlJ+/9zekIbMvY6xD0uAR8Oi6eP8w+fsIe/OxaP0+40H5OrP/FfT3roVMh6GoJ+HRcfPr8uKDdIxYaffjwuGU/cLM//vJPV/pVwqXGoH/9fF/QdrK26W39I1OOT5/K/r3x1gPnPfaB53keuNnmN3++0nfJl/3Xz3euu41B164O/1aKOh0XBL2nzd5y0EGYcqjJf+0aux4jgt7TZosIuhumftLrMSLoPW321oOO9PJDnKfjjKD3tNkygv6mRwb9wKge+YPaD9zs+rcEDUn+hqAhya1Bv17E4GYEjfRuDfr1Igbf/+5K358smqCRUl1pa83VQf9t/Ffcrars0/EiBrMfrn2GH05WgKCRkpnCxQf+7tocfx8uWKCUa/1oCRrvTrz4wP9em+PfhwsW+KCt/03N2ykHQeNdiG/fuTro78IFC5aLIxE03p+fGPRfwgULCBrvVrz4wNVB/0N84wRB452aLz5g//HqKUe4YMGboMfj8xA03gUTLjQw/NO1Of4+XLCgegn60B9/rPr7H670/ckKEDRSCj/bYfTV56H/eblgwUKbu79VSNBIKb4o5L0cEIKgIRBBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVG2HHTXuMFqpazzGqV06z9Wr2NE0Luy4aD10NZj78s9tMaYTql2MmO4UtdxjAh6VzYc9PzPp4bLZDQxXh3+MXY7vYwLgt6VDQetw2Ve2nCpuWq+KOgcePhn3JdxQdC7suGgvWaa/FTD9bZ1lRqXkMeToD+a4P5rk2MLHhJ0Nyf25fnuJ5qvaluHF4ZPg6qWkKuToL80QXX7UrAhDwnazol9fk7wVOMSrp84M+XApqcc4fXgHHA4+Nauq52fVlS9Oo4Lgt6VDQdtXDhV1y/jpNRk/azavo4RQe/KhoNWrWv6oQvfWGn63o/dMPWTfh0jgt6VLQetamO+GvXJOCPoXdl00Fch6F0haIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEGXLQXeNG6xWSrd+VOsxIuhd2XDQemjrsffltpMZh2o9RgS9KxsO2jh/YxulnfHjtBoXBL0rGw5a+25Ve4hh+5vTcUHQu7LhoL1mmjo1LgGfjguC3pVtB22tf/VXLQGfjotPbmZvXgi25CFBN3Nif3hO8FSjY8qBNzZ8hPavB+dwa1crVfWrcUHQu7LhoI3r/ItCH+7kpxONXY8RQe/KhoNWrWv6wUfdDVM/6fUYEfSubDloVRszj/rCOCPoXdl00Fch6F0haIhC0BCFoCEKQUMUgoYoBA1RCBqiEDREIWiIQtAQhaAhCkFDFIKGKAQNUQgaohA0RCFoiELQEIWgIQpBQxSChigEDVEIGqIQNEQhaIhC0BCFoCEKQSO5P14b1Z/TL5ugkdx3BJ0RQRdH0DkRdHEEnRNBF0fQORF0cQSdE0EXR9A5EXRxBJ0TQRdH0DkRdHEEnRNBF0fQORF0cQSdE0EXR9A5EXRxBJ0TQRdH0LepD25otVLWeY1SunWDVa9jRNDFEfRtpkPXTT7kQ2uM6ZRqJzMO1esYEXRxBH2Tzvmjc+061cR4tTP+aD29jAuCLo6gb1KHaUXtauUqa33Dxqn55jguCLo4gr6ZDlMO19vWVWpcQh4J+sEI+lZPQ6P9kVqHe6paQq5Ogv7SBNXtS8FPtLug7ZzY5+c7n0ZPk3m578ylKcdHE9Tp9x0u2F3Q3ZzYl+c7n2Zq58GEg69/cRim06rq1XFcMOUobndBR/dOOUY3/7nwB+P5lJ0P3L9KbOzrGBF0cQR9k/n7Kc6FO03f+6i7Yeon/TpGBF0cQd+pNnEurU/GGUEXR9A5EXRxBJ0TQRdH0DkRdHEEnRNBF0fQORF0cQSdE0EXR9A5EXRxBJ0TQRdH0DkRdHEEnRNBF0fQORF0cQSdE0EXR9A5EXRxBJ0TQRdH0DkRdHEEnRNBF0fQORF0cQSdE0EXR9A5EXRxBJ0TQRdH0DkRdHEEnRNBF0fQORF0cQSdE0EXR9A5EXRxBJ0TQRdH0DkRdHEEnRNBF0fQORF0cQSdE0EXR9A5EXRxBJ0TQRdH0DkRdHEEnRNBF0fQORF0cQSdE0EXR9A5EXRxBP0NXXfnYgi6OIK+qBpcY/q7mibo4gj6ks49mUbbQf/4s11E0MUR9CW2VaZRajI//mwXEXRxBH2JtQS9QQR9iRk6H3TFlGNbCPqiyvVDP1T3LIagiyPoy+rKjpeOz/XBDa3/pG7dYNV6jAi6OIK+pI6T56o++9np0HWTn2K3kxnDUfx0jAi6OII+rzZPrfHG/uyLws75o3PtOu38p+2kTscFQRdH0OdVzdQ3weHspKMO04ra1cb50d+cjguCLo6gL+nixOHClMPTfsoxLgGfjotPH2xwz5k//DS7C7qaE/uX5yt+5SEcoYdLNT4NjVbVEvDpuCDo4gj6EjPYqbFTe/6zepq/48KU473ZXdDRdd8pHFul+/Mn7pbQ/TTa/xnpV+OCoIsj6Et80F2jVHN2vjC6cArEf2ryrw4bux4jgi6OoC+p+k754+3503bWzfxLx2HqJ70eI4IujqAvahplh376kV+ljTk7zgi6OIL+prG6571JBF0eQV9i7npbUkTQxRH0JU8/Ntm4AkEXR9AXtXY5k3E7gi6OoC8x7ngm43YEXRxB50TQxRF0TgRdHEHnRNDFEXROBF0cQedE0MURdE4EXRxB50TQxRF0TgRdHEHnRNDFEXROBF0cQedE0MURdE4EXRxB50TQxRF0TgRdHEHnRNDFEXROBF0cQedE0MURdE4EXRxB50TQxRF0TgRdHEHnRNDFEXROBF0cQedE0MURdE4EXRxB50TQxRF0TgRdHEHnRNDFEXROBF0cQedE0MURdE4EXRxB50TQxRF0TgRdHEHnRNDFEXROBF0cQedE0MURdE4EXRxB50TQxRF0TgRdHEHfqp4v+DZfxb5RSrdusOp1jAi6OIK+UXeYgz60xphOqXYy41C9jhFBF0fQt7HLJTmbGK92xj82vYwLgi6OoG9l5qBdZa1ZPvA3x3FB0MUR9K2WoHvbukqNS8jjSdAf58uF1+n3HS7YXdDdnNiX57ufaM62tlqpp0FVS8jVSdBfmqC6eSH4qXYXtJ0T+/x89xO9Zusnzkw53ovdBR2lmnKYcPCtXVc7P62oenUcFwRdHEHfajkYz6fslJqsUo19HSOCLo6gb2WWb6w0fe+j7oapn/TrGBF0cQR9p9qYedQn44ygiyPonAi6OILOiaCLI+icCLo4gs6JoIsj6JwIujiCzomgiyPonAi6OILOiaCLI+icCLo4gs6JoIsj6JwIujiCzomgiyPonAi6OILOiaCLI+icCLo4gs6JoIsj6JwIujiCzomgiyPonAi6OILOiaCLI+icCLo4gs6JoIsj6JwIujiCzomgiyPonAi6OILOiaCLI+icdhr0v353rd8lXzZB57TToH+4Oqr0X1mCzomgCZqgt4+gCVoUgiZoUQiaoEUhaIIWhaAJWhSCJmhRCJqgRSFoghaFoAlaFIImaFEImqBFIWiCFoWgCVoUgt5i0PV88XrdusGeGSOCJuitBN0d5qDbyYxDtR4jgibojQRtnQtBa2f8/Wk1LgiaoDcStFLGvbk5HRcETdDbCnpcAj4dFwRN0NsKuloCPh0Xn9zM3rqMjSLogpvdzIn94fnuJ2LKcRFBb/YIXbvaH6b71bggaILeVtBq8tOJxq7HiKAJemNBd8PUT3o9RgRN0JsJeqGNOTvOCJqgtxb0NxE0QRP09hE0QYtC0AQtCkETtCgETdCiEDRBi0LQBC0KQRO0KARN0KIQNEGLQtAELQpBE7QoBE3QohA0QYtC0AQtCkETtCgETdCiEDRBi0LQBC0KQRO0KARN0KIQNEGLQtAELQpBE7QoBE3QohA0QYtC0AQtCkETtCgETdCiEDRBi0LQBC0KQRO0KARN0KIQNEGLQtAELQpBE7QoBE3QohA0QYtC0AQtCkETtCgETdCiEDRBi0LQ2w3aOq9RSrdusOp1jAiaoDcW9KE1xnRKtZMZh+p1jAiaoDcWdBPj1c74o/X0Mi4ImqA3FrSrrPUNG6fmm+O4IGiC3lrQvW1dpcYl5JGgFUFvOOjaaqWeBlUtIVcnQX9pgur2BWwSQRfcbDsn9vk54VP6ifOlKcdHE9Tp9927RtAFN7ubE/vynObZTDj41q6rnY+26tVxXDDlIOgym51qymHcfMpOqckq1djXMSJogt5W0Mq6pu991N0w9ZN+HSOCJuiNBa1qY+ZRn4wzgiborQX9TQRN0AS9fQRN0KIQNEGLQtAELQpBE3R6//bdlf6YfNEETdDpPfArS9AEnR5BE3RyBE3QBJ0IQRN0cgRN0ASdCEETdHIETdAEnQhBE3RyBE3QBJ0IQRN0cgRN0ASdCEETdHIETdAEnQhBE3RyBE3QBJ0IQRN0cgRN0ASdCEETdHIETdAEnQhBE3RyBE3QBJ0IQRN0cgRN0ASdCEETdHIETdAEnQhBE3RyBE3QBJ0IQRN0cgRN0ASdCEETdHIETdAEnQhBE3RyBE3QBJ0IQRN0cgRN0ASdCEETdHKPDPrfH/eV/Y8HBv3Aza5/S9AZ/eVxX9n/fGDQD9xs8xuBQevWDfblI4Im6I0H3U5mHKrjRwRN0NsOWjujlJ2OHxI0QW87aOOONzOCJuhtBz2eBP35Q/Dx0wP835+ulXzR/3X1on8labM//vIRm93Pif06U9DV10E/f3hc0P/9s2slX/T/XL3on0va7E8P2ewYdP+LPEGfTDmAbatd7Q/T/aNXA0hksko19v7nAd6Fbpj6ST96LYBUtDGPXgUAAIDkOuPp453l/utn3ny8fiDBUnM8+V1bvVoRU4dbfe9M8HWLXxa53mQdF7Zel0QrsQeNC+zxjnPm68+8frx+IMFSLz95VZ/9nRceTrbVqxVxQyju7m8OvG7xyyLX+7Ny/Znf5H9FopXYg/kkoYnvWf16h61OHyY8n/h2qZeWdv4PTpPkKHV5q1crEt/Pe3/Qb7c4Ptt6fx4a151dl0QrsQdxn1VDuI07zNj4/8veXD2QcqnrpT35mydT9a1/+MnnW1k7R+zHWoWHs2z1akWOH7uncAxNE/SyxNOgj4uqXTfZs3s80UrsQdxn8/tWlx1mXfz/ZW+uHki51NWT62FU46BDua6dKtX01oa3iLe9PQx10qDfbvVqRY4fO2P7ZEHHJZ4GfVzUUx/+O7fHE63EHiz7zI1qNeXoG6/6xgNplvr2yRv/N+441IOZ5xZxyukfsgfVhXcF+N+WcMpxdqtXW+mM7m2qoJctXoI+3Z/+8Fx/9RLlZackWok9OO7oN8eq42fa8Aq7/sYDaZb69snnl/yHecIYgo6fNuPUKNssvy5p0OutXm2l/zXGdcmCfnuEPllS7Spj+na1Ln6nJFqJPYg7up5fjBR+UbgsdfXklQtHrWPQ1jVtkyfoc1u9flFo5p+MSxP0ssXnXxTa+ZTGcG5dEq3EHsR9ZuepW+mgbX/6SKAHG05SLUH7CYgKNc8/mGaqpEGf2+qzQevhkCboZYvPB92Hj+s307Cvg06wEnsw/61m307tipzleFnqy5PHv127eTGHgx/G+csY3kyr/ZQjTC51/xQezrLVl89yhD9Bo7s76DdLPH+WY36V4CfS7Zmdkmgl9mA+dz+93c9FznK8LPXlyeP3EBr/Ol+rehjVoa/m49LUN307VH4i0oQ3IvqHs2z1N85yxN+QcInnz3K08Yejn5xe75REK4EHevk28PFbv/X8RkSd5lUpAAAAAAAAAAB4B/4fMCOzQATqA6UAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTctMDEtMjVUMTQ6NDY6MjkrMDc6MDDMPF40AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE3LTAxLTI1VDE0OjQ2OjI5KzA3OjAwvWHmiAAAACF0RVh0cHM6SGlSZXNCb3VuZGluZ0JveAA1MDR4NzIwKzUwKzUw1uIiwwAAABN0RVh0cHM6TGV2ZWwAQWRvYmUtMi4wCjmTdA0AAAAASUVORK5CYII=" />

=end html


Benchmark module startup overhead (C<< bencher -m HumanDateParsingModules::Parsing --module-startup >>):

 #table6#
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | participant                 | proc_private_dirty_size (MB) | proc_rss_size (MB) | proc_size (MB) | time (ms) | mod_overhead_time (ms) | vs_slowest |  errors   | samples |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+
 | DateTime::Format::Flexible  | 0.83                         | 4.1                | 16             |     100   |                   94.6 |        1   |   0.00025 |      20 |
 | Date::Extract               | 16                           | 20                 | 56             |      93   |                   87.6 |        1.1 |   0.00021 |      20 |
 | DateTime::Format::Natural   | 16                           | 20                 | 56             |      91   |                   85.6 |        1.1 |   0.00016 |      20 |
 | DateTime::Format::Alami::ID | 16                           | 20                 | 56             |      22   |                   16.6 |        4.7 |   0.00013 |      20 |
 | DateTime::Format::Alami::EN | 2.8                          | 6.4                | 20             |      22   |                   16.6 |        4.8 |   0.00011 |      20 |
 | perl -e1 (baseline)         | 2.7                          | 6.4                | 20             |       5.4 |                    0   |       19   | 2.6e-05   |      20 |
 +-----------------------------+------------------------------+--------------------+----------------+-----------+------------------------+------------+-----------+---------+


=begin html

<img src="data:image/png;base64,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" />

=end html


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-HumanDateParsingModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-DateTimeFormatAlami>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-HumanDateParsingModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
