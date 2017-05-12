use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;
use Test::FailWarnings;
use Capture::Tiny qw/capture/;
use File::Spec;
use lib 't/lib';

plan skip_all => "Your filesystem respects case"
  unless -f 't/lib/foo.pm'; # it's really Foo.pm

use Acme::require::case;

my ($n, $err);

#--------------------------------------------------------------------------#
# Fails because of case
#--------------------------------------------------------------------------#

$err = exception { require foo };
like( $err, qr/incorrect case/, "foo: caught wrong case" );

$err = exception { require Foo::bar::Baz };
like( $err, qr/incorrect case/, "Foo::bar::Baz: caught wrong case" );

#--------------------------------------------------------------------------#
# Works like CORE::require
#--------------------------------------------------------------------------#

$err = exception { require Foo::Bar::Baz };
is( $err, undef, "Foo::Bar::Baz: required OK" );
ok( $INC{'Foo/Bar/Baz.pm'}, "Foo::Bar::Baz correct in \%INC" );

$err = exception { require 5 };
is( $err, undef, "5: required OK" );

$err = exception { require 5.000 };
is( $err, undef, "5.000: required OK" );

$err = exception { $n = 5; require $n };
is( $err, undef, "\$n = 5: required OK" );

$err = exception { $n = "5"; require $n if $n > 0 };
is( $err, undef, "\$n = '5': required numerized \$n OK" );

$err = exception { require only_once };
is( $err, undef, "only_once: required OK" );
$err = exception { require only_once };
is( $err, undef, "only_once: required again without dying" );

my $abs = File::Spec->rel2abs('t/lib/Absolute.pm');
$err = exception { require $abs };
is( $err, undef, "absolute path" );

#--------------------------------------------------------------------------#
# Fails like CORE::require
#--------------------------------------------------------------------------#

$err = exception { require dies };
like( $err, qr{error at t/lib/dies\.pm}, "dies.pm: caught 'error at' exception" );

$err = exception { require dies };
like( $err, qr{Compilation failed}, "dies.pm: caught 'Compilation failed' reload exception" );

$err = exception { require false };
like(
    $err,
    qr{false\.pm did not return a true value},
    "false.pm: caught did not return a true value"
);

$err = exception { require 6.0.0 };
like( $err, qr/\Qv6.0.0\E required--this is only/, "6.0.0: caught this is only" );

$err = exception { require 6.0 };
like( $err, qr/\Qv6.0.0\E required--this is only/, "6.0: caught this is only" );

$err = exception { require v6 };
like( $err, qr/\Qv6.0.0\E required--this is only/, "v6: caught this is only" );

$err = exception { require "v6.pm" };
like( $err, qr/Can't locate v6\.pm/, "'v6.pm': caught can't locate" );

$err = exception { require "6" };
like( $err, qr/Can't locate 6/, "'6': caught can't locate" );

$err = exception { $n = "6"; require $n };
like( $err, qr/Can't locate 6/, "\$n = '6': caught can't locate" );

{
    no warnings 'numeric';
    $err = exception { $n = "6a"; require $n if $n > 0 };
    like( $err, qr/Invalid version format|this is only/, "\$n = '6a': require numerized \$n caught invalid version" );
}

#--------------------------------------------------------------------------#
# call stack
#--------------------------------------------------------------------------#

my @output = split "\n", capture { require wrapper };
my $oops = 0;
like( $output[0], qr/^0 wrapper/, "saw wrapper first in call stack" ) or $oops++;
like( $output[1], qr/^1 main /,   "saw main next in call stack" ) or $oops++;
diag( "OUTPUT:\n", join("\n", @output) ) if $oops;

done_testing;
#
# This file is part of Acme-require-case
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
