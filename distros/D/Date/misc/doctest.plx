#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use POSIX();
use Date qw/now now_hires today date rdate :const idate/;
use Time::XS qw/tzget tzset/;
use Class::Date;
use Data::Dumper qw/Dumper/;
use Storable qw/freeze nfreeze thaw dclone/;
say "START";

my $cdate = new Class::Date("2013-06-05 23:45:56");
my $date  = new Date("2013-06-05 23:45:56");
my $crel = Class::Date::Rel->new("1M");
my $rel  = rdate("1M");

timethese(-1, {
    cdate_new_str    => sub { new Class::Date("2013-01-25 21:26:43"); },
    xsdate_new_str   => sub { state $date = new Date(0); $date->set("2013-01-25 21:26:43"); },
    cdate_new_epoch  => sub { new Class::Date(1000000000); },
    xsdate_new_epoch => sub { new Date(1000000000); },
    xsdate_new_reuse => sub { state $date = new Date(0); $date->set(1000000000); },
    
    cdate_now        => sub { Class::Date->now },
    xsdate_now       => sub { now() },
    xsdate_now_hires => sub { now_hires() },
    
    cdate_truncate      => sub { $cdate->truncate },
    xsdate_truncate_new => sub { $date->truncated },
    xsdate_truncate     => sub { $date->truncate },
    cdate_today         => sub { Class::Date->now->truncate; },
    xsdate_today1       => sub { now()->truncate; },
    xsdate_today2       => sub { today(); },
    cdate_stringify     => sub { $cdate->string },
    xsdate_stringify    => sub { $date->to_string },
    cdate_strftime      => sub { $cdate->strftime("%H:%M:%S") },
    xsdate_strftime     => sub { $date->strftime("%H:%M:%S") },
    cdate_clone_simple  => sub { $cdate->clone },
    xsdate_clone_simple => sub { $date->clone },
    cdate_clone_change  => sub { $cdate->clone(year => 2008, month => 12) },
    xsdate_clone_change => sub { $date->clone({year => 2008, month => 12}) },
    cdate_rel_new_sec   => sub { new Class::Date::Rel 1000 },
    pdate_rel_new_sec   => sub { new Date::Rel 1000 },
    xsdate_rel_new_str  => sub { new Class::Date::Rel "1Y 2M 3D 4h 5m 6s" },
    xsdate_rel_new_str  => sub { new Date::Rel "1Y 2M 3D 4h 5m 6s" },
    cdate_add           => sub { $cdate = $cdate + '1M' },
    xsdate_add_new      => sub { $date = $date + '1M' },
    xsdate_add          => sub { $date += '1M' },
    xsdate_add2         => sub { $date += MONTH },
    xsdate_add3         => sub { $date->month($date->month+1) },
    cdate_compare       => sub { $cdate == $cdate },
    xsdate_compare      => sub { $date == $date },
});
