use strict;
use warnings;

use lib 't/lib';
use Test::More;

use B::Hooks::EndOfScope;

plan tests => 1;

my @warnings;
BEGIN { $SIG{__WARN__} = sub {
  ( $_[0] =~ /unref/ )
    ? push @warnings, $_[0]
    : warn @_
}}

BEGIN { on_scope_end { 1 } }

use OtherClass;

is $warnings[0], undef,
  'on_scope_end used in module where loading module used on_scope_end'
or diag join '', "\nAll unexpected warnings:\n========\n", @warnings, "\n";
