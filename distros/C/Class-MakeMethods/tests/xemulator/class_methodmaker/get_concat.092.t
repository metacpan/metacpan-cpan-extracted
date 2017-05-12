#!/usr/local/bin/perl

package X;

BEGIN { unshift @INC, ( $0 =~ /\A(.*?)[\w\.]+\z/ )[0] }
use Test;

use Class::MakeMethods::Emulator::MethodMaker 'get_concat --noundef' => 'x';
sub new { bless {}, shift; }
my $o = new X;

TEST { 1 };
TEST { $o->x eq "" };
TEST { $o->x('foo') };
TEST { $o->x eq 'foo' };
TEST { $o->x('bar') };
TEST { $o->x eq 'foobar' };
TEST { ! defined $o->clear_x };
TEST { $o->x eq "" };

exit 0;

