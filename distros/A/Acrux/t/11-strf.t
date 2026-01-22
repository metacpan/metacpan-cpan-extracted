#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use Test::More;

use Acrux::Util qw/strf/;

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";

my %d = (
    f => 'foo',
    b => 'bar',
    baz => 'test',
    u => undef,
    t => time,
    d => 1,
    i => 2000,
    n => "\n",
);

is( strf(">test %f string<", %d), ">test foo string<", "test foo string" );
ok( strf(">%{baz} time string = %t<", %d), "time string" )
    and note strf(">%{baz} time string = %t<", %d);
is( strf(">test %f%b%i string<", %d), ">test foobar2000 string<", "test foobar2000 string" );
is( strf(">%d%% %{baz}<", \%d), ">1% test<", "1% test" );
is( strf(">%f%n%b<", \%d), ">foo\nbar<", "new line test" );
is( strf(">%f%u%b<", \%d), ">foobar<", "undef test" );
is( strf(">%f%X%b<", \%d), ">foo%Xbar<", "not exists test" );
#diag strf(">%f%X%b<", \%d);


# Strftime (short version)
# See: https://cplusplus.com/reference/ctime/strftime/
#      https://www.programiz.com/python-programming/datetime/strftime
#
# a   Abbreviated weekday name                                Sun, Mon, ...
# A   Full weekday name                                       Sunday, Monday, ...
# b   Abbreviated month name                                  Jan, Feb, ...
# B   Full month name                                         January, February, ...
# d   Day of the month as a zero-padded decimal               01, 02, ..., 31
# e   Day of the month                                        1, 2, ..., 31
# H   Hour (24-hour clock) as a zero-padded decimal number    00, 01, ..., 23
# I   Hour (12-hour clock) as a zero-padded decimal number    01, 02, ..., 12
# j   Day of the year as a zero-padded decimal number         001, 002, ..., 366
# m   Month as a zero-padded decimal number                   01, 02, ..., 12
# M   Minute as a zero-padded decimal number                  00, 01, ..., 59
# p   AM or PM designation                                    AM, PM
# S   Second as a zero-padded decimal number                  00, 01, ..., 59
# U   Week number of the year (Sunday as the first day)       00, 01, ..., 53
# w   Weekday as a decimal number with Sunday as 0 (0-6)      0, 1, ..., 6
# W   Week number of the year (Monday as the first day)       00, 01, ..., 53
# y   Year without century as a zero-padded decimal number    00, 01, ..., 99
# Y   Year                                                    2001, 2024 etc.

use POSIX qw/strftime/;
my $now = time; # The number of seconds since the Epoch, 1970-01-01 00:00:00 +0000 (UTC)
my %t = ('s' => $now);
my @fmt = qw/%a %A %b %B %d %e %H %I %j %m %M %p %S %U %w %W %y %Y/;
my @adt = split /#+/, strftime(join('#', @fmt), localtime($now));
#diag explain \@adt;
for (@fmt) { s/%//; $t{$_} = shift @adt };
#diag explain \%t;

# RFC 3339/ISO 8601
my $rfc = '%Y-%m-%dT%H:%M:%S';
is( strf($rfc, %t), strftime($rfc, localtime($now)), "RFC 3339/ISO 8601" ); # 2024-06-05T10:37:47

done_testing;

__END__

prove -lv t/11-strf.t
