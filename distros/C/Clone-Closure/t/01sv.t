#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Builder;
use Clone::Closure  qw/clone/;
use Scalar::Util    qw/blessed dualvar/;
use B               qw/SVf_IVisUV/;

BEGIN { *b = \&B::svref_2object }

my $tests;

BEGIN { $tests += 1 }

my $undef = clone undef;

ok      !defined $undef,            'undef cloned correctly';

BEGIN { $tests += 2 }

my $iv = clone 2;

isa_ok  b(\$iv),    'B::IV',        'IV cloned';
is      $iv,        2,              '...correctly';

BEGIN { $tests += 3 }

my $uv = clone 1<<63;

isa_ok  b(\$uv),    'B::IV',        'IVisUV cloned';
is      $uv,        1<<63,          '...correctly';
is      b(\$uv)->FLAGS       & SVf_IVisUV,
        b( \(1<<63) )->FLAGS & SVf_IVisUV,
                                    '...preserving IVisUV';
BEGIN { $tests += 2 }

my $nv = clone 2.2;

isa_ok  b(\$nv),    'B::NV',        'NV cloned';
is      $nv,        2.2,            '...correctly';

BEGIN { $tests += 2 }

my $pv = clone 'hello world';

isa_ok  b(\$pv),    'B::PV',        'PV cloned';
is      $pv,        'hello world',  '...correctly';


BAIL_OUT('basic values won\'t clone correctly')
    if grep !$_, Test::Builder->new->summary;


SKIP: {
    my $skip;
    eval 'require utf8';
    defined &utf8::is_utf8 or skip 'no utf8 support', $skip;

    BEGIN { $skip += 3 }

    my $utf8 = clone "\x{fff}";

    isa_ok  b(\$utf8),  'B::PV',    'utf8 cloned';
    ok      utf8::is_utf8($utf8),   '...preserving utf8';
    is      $utf8,      "\x{fff}",  '...correctly';

    BEGIN { $skip += 3 }

    my $ascii = 'foo';
    utf8::upgrade($ascii);
    my $upg   = clone $ascii;

    isa_ok  b(\$upg),   'B::PV',    'upgraded utf8 clones';
    ok      utf8::is_utf8($upg),    '...preserving utf8';
    is      $upg,       'foo',      '...correctly';

    BEGIN { $tests += $skip }
}

BEGIN { $tests += 3 }

my $dualvar = dualvar 5, 'bar';
# dualvar sometimes seems to make a PVNV when it doesn't need to
my $pviv_c  = blessed b(\$dualvar);
my $pviv = clone $dualvar;

isa_ok  b(\$pviv),  $pviv_c,    'PVIV clones';
cmp_ok  $pviv, '==', 5,         '...correctly';
is      $pviv,      'bar',      '...correctly';

BEGIN { $tests += 3 }

my $pvnv = clone dualvar 3.1, 'baz';

isa_ok  b(\$pvnv),  'B::PVNV',  'PVNV clones';
cmp_ok  $pvnv, '==', 3.1,       '...correctly';
is      $pvnv,      'baz',      '...correctly';

# PVBM/PVGV/PVLV in t/06mg.t

BEGIN { plan tests => $tests }
