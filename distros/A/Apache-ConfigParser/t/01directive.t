#!/usr/bin/perl -w
#
# Copyright (C) 2001-2005 Blair Zajac.  All rights reserved.

$| = 1;

use strict;
use Test::More tests => 1162;
use File::Spec;

BEGIN { use_ok('Apache::ConfigParser::Directive'); }

# Cd into t if it exists.
chdir 't' if -d 't';

package EmptySubclass;
use Apache::ConfigParser::Directive;
use vars qw(@ISA);
@ISA = qw(Apache::ConfigParser);
package main;

my $d = Apache::ConfigParser::Directive->new;
ok($d, 'Apache::ConfigParser::Directive created');

# Check the initial values of the object.
is($d->name,        '', 'initial name is empty');
is($d->value,       '', 'initial value is empty');
is($d->orig_value,  '', 'initial `original\' value is empty');

my @value = $d->get_value_array;
ok(eq_array(\@value, []), 'initial value array is empty');

@value = $d->get_orig_value_array;
ok(eq_array(\@value, []), 'initial `original\' value array is empty');

is($d->filename,    '', 'initial filename is empty');
is($d->line_number, -1, 'initial line number is -1');

is($d->filename('file.txt'), '',         'filename is empty and set it');
is($d->filename,             'file.txt', 'filename is now file.txt');

is($d->line_number(123),  -1, 'line number is -1 and set it to 123');
is($d->line_number,      123, 'line number is now 123');

# Test setting and getting parameters.
is($d->name('SomeDirective'), '',              'name is empty and set it');
is($d->name,                  'somedirective', 'name is no somedirective');

is($d->value('SomeValue1 Value2'), '', 'initial value is empty and set it');
is($d->value, 'SomeValue1 Value2', 'value is now SomeValue1 Value2');

@value = $d->get_value_array;
ok(eq_array(\@value, [qw(SomeValue1 Value2)]), 'value array has two elements');
ok(eq_array(\@value, $d->value_array_ref),     'value array ref matches');

# Check that the `original' value has not changed.
is($d->orig_value, '', '`original\' value has not changed');
@value = $d->get_orig_value_array;
ok(eq_array(\@value, []), '`original\' value array has not changed');
ok(eq_array([], $d->orig_value_array_ref),
   '`original\' value array ref has not changed');

# Try a more complicates value string.
my $str1 = '"%h \"%r\" %>s \"%{Referer}i\" \"%{User-Agent}i\"" \foo  bar';
is($d->value($str1), 'SomeValue1 Value2', 'setting a new complicated value');
is($d->value,
   '"%h \"%r\" %>s \"%{Referer}i\" \"%{User-Agent}i\"" \foo  bar',
   'complicated string value matched');
@value = $d->get_value_array;
ok(eq_array(\@value,
            ['%h "%r" %>s "%{Referer}i" "%{User-Agent}i"', '\foo', 'bar']),
   'complicated value array matches');
ok(eq_array($d->value_array_ref,
            ['%h "%r" %>s "%{Referer}i" "%{User-Agent}i"', '\foo', 'bar']),
   'complicated value array ref matches');

# Set the value using the array interface.
$d->set_orig_value_array;
is($d->orig_value, '', 'set empty array results in empty string value');
@value = $d->get_orig_value_array;
ok(eq_array(\@value, []), 'set empty array results in empty array value');
ok(eq_array([], $d->orig_value_array_ref),
   'set empty array results in empty array value ref');

@value = ('this', 'value', 'has whitespace and quotes in it ""\ \ ');
$d->set_orig_value_array(@value);
my @v = $d->get_orig_value_array;
ok(eq_array(\@v, \@value), 'complicated set value array matches array');
ok(eq_array(\@v, $d->orig_value_array_ref),
   'complicates set value array matches array ref');
is($d->orig_value,
   'this value "has whitespace and quotes in it \"\"\\\\ \\\\ "',
   'complicated set value array string matches');

# Test setting and getting undefined values.
is($d->value(undef),    $str1, 'value matches and set to undef');
is($d->value_array_ref, undef, 'value array ref is undef');
is($d->value(''),       undef, 'value is now undef');
ok(eq_array([], $d->value_array_ref), 'value array ref to empty array');
ok(eq_array([], $d->value_array_ref(undef)), 'value array ref to empty array');
is($d->value,           undef, 'value is not undef again');
is($d->value_array_ref, undef, 'value array ref is again undef');
is(scalar $d->get_value_array, undef, 'getting value array returns undef');
@value = $d->get_value_array;
ok(eq_array(\@value, []), 'value array is empty');

# Test value_is_path, value_is_rel_path and value_is_abs_path.
my $one_pipe     = '| some_program_to_pipe_to';
my @pipe         = ($one_pipe, $one_pipe);
my $pipe         = "'$one_pipe' '$one_pipe'";
my $one_syslog   = 'syslog:local7';
my @syslog       = ($one_syslog, $one_syslog);
my $syslog       = "'$one_syslog' '$one_syslog'";
my $one_abs_path = File::Spec->rel2abs('.');
my @abs_path     = ($one_abs_path, $one_abs_path);
my $abs_path     = "$one_abs_path $one_abs_path";
my $one_rel_path = File::Spec->catfile('some', 'relative', 'path'); 
my @rel_path     = ($one_rel_path, $one_rel_path);
my $rel_path     = "@rel_path";
my $one_dev_null = File::Spec->devnull;
my @dev_null     = ($one_dev_null, $one_dev_null);
my $dev_null     = "@dev_null";

# This array is grouped into sets of 13 elements.  The elements are:
#  1) Directive name
#  2) value_is_path($pipe)
#  3) value_is_abs_path($pipe)
#  4) value_is_rel_path($pipe)
#  5) value_is_path($syslog)
#  6) value_is_abs_path($syslog)
#  7) value_is_rel_path($syslog)
#  8) value_is_path($abs_path)
#  9) value_is_abs_path($abs_path)
# 10) value_is_rel_path($abs_path)
# 11) value_is_path($rel_path)
# 12) value_is_abs_path($rel_path)
# 13) value_is_rel_path($rel_path);
my @tests = qw(aaa               0 0 0 0 0 0 0 0 0 0 0 0
               AccessConfig      1 0 1 1 0 1 1 1 0 1 0 1
               AgentLog          0 0 0 1 0 0 1 1 0 1 0 0
               AuthDBGroupFile   1 0 0 1 0 0 1 1 0 1 0 0
               AuthDBMGroupFile  1 0 0 1 0 0 1 1 0 1 0 0
               AuthDBMUserFile   1 0 0 1 0 0 1 1 0 1 0 0
               AuthDBUserFile    1 0 0 1 0 0 1 1 0 1 0 0
               AuthDigestFile    1 0 0 1 0 0 1 1 0 1 0 0
               AuthGroupFile     1 0 1 1 0 1 1 1 0 1 0 1
               AuthUserFile      1 0 1 1 0 1 1 1 0 1 0 1
               CacheRoot         1 0 0 1 0 0 1 1 0 1 0 0
               CookieLog         1 0 1 1 0 1 1 1 0 1 0 1
               CoreDumpDirectory 1 0 0 1 0 0 1 1 0 1 0 0
               CustomLog         0 0 0 1 0 1 1 1 0 1 0 1
               Directory         1 0 0 1 0 0 1 1 0 1 0 0
               DocumentRoot      1 0 0 1 0 0 1 1 0 1 0 0
               ErrorLog          0 0 0 0 0 0 1 1 0 1 0 1
               Include           1 0 1 1 0 1 1 1 0 1 0 1
               LoadFile          1 0 1 1 0 1 1 1 0 1 0 1
               LoadModule        1 0 1 1 0 1 1 1 0 1 0 1
               LockFile          1 0 1 1 0 1 1 1 0 1 0 1
               MimeMagicFile     1 0 1 1 0 1 1 1 0 1 0 1
               MMapFile          1 0 0 1 0 0 1 1 0 1 0 0
               PidFile           1 0 1 1 0 1 1 1 0 1 0 1
               RefererLog        0 0 0 1 0 1 1 1 0 1 0 1
               ResourceConfig    1 0 1 1 0 1 1 1 0 1 0 1
               RewriteLock       1 0 0 1 0 0 1 1 0 1 0 0
               ScoreBoardFile    1 0 1 1 0 1 1 1 0 1 0 1
               ScriptLog         1 0 1 1 0 1 1 1 0 1 0 1
               ServerRoot        1 0 0 1 0 0 1 1 0 1 0 0
               TransferLog       0 0 0 1 0 1 1 1 0 1 0 1
               TypesConfig       1 0 1 1 0 1 1 1 0 1 0 1);
is(@tests % 13, 0, 'number of elements in @tests is a multiple of 13');
while (@tests > 6) {
  my ($dn, @a) = splice(@tests, 0, 13);

  $d->name($dn);

  # Check that a pipe is treated properly.
  $d->set_value_array(@pipe);
  $d->set_orig_value_array(@pipe);
  is($d->value_is_path,          $a[0], "$dn $pipe value path");
  is($d->value_is_abs_path,      $a[1], "$dn $pipe value abs path");
  is($d->value_is_rel_path,      $a[2], "$dn $pipe value rel path");

  is($d->orig_value_is_path,     $a[0], "$dn $pipe value path");
  is($d->orig_value_is_abs_path, $a[1], "$dn $pipe value abs path");
  is($d->orig_value_is_rel_path, $a[2], "$dn $pipe value rel path");

  # Check that a syslog is treated properly.
  ok(eq_array(\@pipe, [$d->set_value_array(@syslog)]), "old value is @pipe");
  ok(eq_array(\@pipe, [$d->set_orig_value_array(@syslog)]), "old orig value is @pipe");

  is($d->value_is_path,          $a[3], "$dn $syslog value path");
  is($d->value_is_abs_path,      $a[4], "$dn $syslog value abs path");
  is($d->value_is_rel_path,      $a[5], "$dn $syslog value rel path");

  is($d->orig_value_is_path,     $a[3], "$dn $syslog value path");
  is($d->orig_value_is_abs_path, $a[4], "$dn $syslog value abs path");
  is($d->orig_value_is_rel_path, $a[5], "$dn $syslog value rel path");

  # Test setting to the /dev/null equivalent on this operating system.
  is($d->value($dev_null),      "@syslog", "old value is $syslog");
  is($d->orig_value($dev_null), "@syslog", "old orig value is $syslog");
  is($d->value_is_path,     0, "$dn $dev_null is not a path");
  is($d->value_is_abs_path, 0, "$dn $dev_null is not a abs path");
  is($d->value_is_rel_path, 0, "$dn $dev_null is not a rel path");

  is($d->value($abs_path),      $dev_null, "old value is $dev_null");
  is($d->orig_value($abs_path), $dev_null, "old orig value is $dev_null");

  is($d->value_is_path,          $a[6], "$dn $abs_path path value");
  is($d->value_is_abs_path,      $a[7], "$dn $abs_path abs path value");
  is($d->value_is_rel_path,      $a[8], "$dn $abs_path rel path value");

  is($d->orig_value_is_path,     $a[6], "$dn $abs_path path orig value");
  is($d->orig_value_is_abs_path, $a[7], "$dn $abs_path abs path orig value");
  is($d->orig_value_is_rel_path, $a[8], "$dn $abs_path rel path orig value");

  is($d->value($rel_path),       $abs_path, "old value is $abs_path");
  is($d->orig_value($rel_path),  $abs_path, "old orig value is $abs_path");

  is($d->value_is_path,          $a[9], " $dn $rel_path path value");
  is($d->value_is_abs_path,      $a[10], "$dn $rel_path abs path value");
  is($d->value_is_rel_path,      $a[11], "$dn $rel_path rel path value");

  is($d->orig_value_is_path,     $a[9],  "$dn $rel_path path orig value");
  is($d->orig_value_is_abs_path, $a[10], "$dn $rel_path abs path orig value");
  is($d->orig_value_is_rel_path, $a[11], "$dn $rel_path rel path orig value");
}
