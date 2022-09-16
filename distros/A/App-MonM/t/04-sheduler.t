#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use Test::More;
eval "use Time::Local qw/timelocal/";
plan skip_all => 'Time::Local not installed' if($@);
plan tests => 4;

use App::MonM::Util qw//;

my $scheduler = App::MonM::Util::Scheduler->new();

$scheduler->add(all => "Sun-Sat");
$scheduler->add(none => "Sun-Sat[off]");
$scheduler->add(foo => "Mon[6:30-12:00,14-20:30];Thu[7:00-20:30];Thursday-Fri[9:00-17:00];Fri-Sat;Wed[10:00-15:00]");
$scheduler->add(bar => "Wed[7:00-9:20,15:22-20:27]");

#note(explain($scheduler));

ok($scheduler->check(all => time), "Curtime - on");
ok(!$scheduler->check(none => time), "Curtime - off");

# $sec, $min, $hour, $mday, $mon, $year );
my $oldtime = timelocal( 0, 50, 14, 17, 8-1, 2022-1900 ); # Wed 17 Aug 2022 14:50:00
ok($scheduler->check(foo => $oldtime), "Wed 17 Aug 2022 14:50:00 on foo");
ok(!$scheduler->check(bar => $oldtime), "Wed 17 Aug 2022 14:50:00 on bar");

1;

__END__