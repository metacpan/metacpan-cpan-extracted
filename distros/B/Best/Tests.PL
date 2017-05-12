#!perl
use strict;
use warnings FATAL => 'all';

write_test( file => 'basic', tests => 4, best => <<'BEST', code => <<'CODE' );
use Best qw/A::Module AnAlternative LastChance/;
BEST
is "@attempted", 'A::Module AnAlternative LastChance', 'tried all modules';
is "@loaded",    'LastChance', 'loaded correct one - trace evidence';
is (Best->which('A::Module'), 'LastChance', 'loaded correct one - which()');

{
    package Someother;
    Test::More::is (Best->which('A::Module'), 'LastChance', 'loaded correct one - which() from other module'); 
}
CODE

write_test(
    file  => 'basic-a',
    tests => 2,
    best  => <<'BEST', code => <<'CODE' );
use Best [ qw/A::Module AnAlternative LastChance/ ];
BEST
is "@attempted", 'A::Module AnAlternative LastChance', 'tried all modules';
is "@loaded",    'LastChance', 'loaded correct one - trace evidence';
CODE

write_test(
    file  => 'best',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
use Best [ [qw/A::Module AnAlternative LastChance/], qw/moose elk/ ];
BEST
is "@attempted", 'A::Module AnAlternative LastChance', 'tried all modules';
is "@loaded",    'LastChance', 'loaded correct one';
is "@args",      'LastChance moose elk', '->import';
CODE

write_test(
    file  => 'onearg',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
# miyagawa++ noticed a crash when there was exactly one element on the
# import list. Oops!
use Best [ [qw/A::Module AnAlternative LastChance/], qw/moose/ ];
BEST
is "@attempted", 'A::Module AnAlternative LastChance', 'tried all modules';
is "@loaded",    'LastChance', 'loaded correct one';
is "@args",      'LastChance moose', '->import';
CODE

write_test(
    file  => 'args-a',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
use Best [ [qw/A::Module AnAlternative LastChance/], [qw/moose elk/] ];
BEST
is "@attempted", 'A::Module AnAlternative LastChance', 'tried all modules';
is "@loaded",    'LastChance', 'loaded correct one';
is "@args",      'LastChance moose elk', '->import';
CODE

write_test(
    file  => 'noargs',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
use Best [ [qw/A::Module AnAlternative LastChance/], [] ];
BEST
is "@attempted", 'A::Module AnAlternative', 'tried all modules';
is "@loaded",    '', q[->import wasn't called]; # AnAlternative's import was not called
is "@args",      '', q[->import];
CODE

write_test( file => 'ver', tests => 3, best => <<'BEST', code => <<'CODE' );
use Best [ [qw/Version::TooLow 2.00 Version::Ok 1.00/], qw/moose elk/ ];
BEST
is "@attempted", 'Version::TooLow Version::Ok', 'attempted';
is "@loaded",    'Version::Ok', 'loaded';
is "@args",      'Version::Ok moose elk', 'args';
CODE

write_test(
    file  => 'exist-a',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
use Best [ [qw/Doesn't::Exist LastChance/], qw/moose elk/ ];
BEST
is "@attempted", q[Doesn::t::Exist LastChance];
is "@loaded", 'LastChance';
is "@args",   'LastChance moose elk';
CODE

write_test( file => 'exist', tests => 3, best => <<'BEST', code => <<'CODE' );
use Best qw/Doesn't::Exist LastChance/;
BEST
is "@attempted", q[Doesn::t::Exist LastChance];
is "@loaded", 'LastChance';
is "@args",   'LastChance';
CODE

write_test( file => 'code', tests => 3, best => <<'BEST', code => <<'CODE' );
use Best [ [sub {
                push @attempted, 'Failed code';
                return;
            },
            'LastChance'], qw/moose elk/ ];
BEST
is "@attempted", 'Failed code LastChance';
is "@loaded",    'LastChance';
is "@args",      'LastChance moose elk';
CODE

write_test( file => 'hash', tests => 3, best => <<'BEST', code => <<'CODE' );
use Best ( 'A::Module' => {},
           AnAlternative => {},
           LastChance => {}, );
BEST
is "@attempted", 'A::Module AnAlternative LastChance';
is "@loaded",    'LastChance';
is "@args",      'LastChance'
CODE

write_test(
    file  => 'hash-a',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
use Best [ 'A::Module' => {},
           AnAlternative => {},
           LastChance => {}, ];
BEST
is "@attempted", 'A::Module AnAlternative LastChance';
is "@loaded",    'LastChance';
is "@args",      'LastChance'
CODE

write_test(
    file  => 'hash-aa',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
use Best [[ 'A::Module' => {},
            AnAlternative => {},
            LastChance => {}, ]];
BEST
is "@attempted", 'A::Module AnAlternative LastChance';
is "@loaded",    'LastChance';
is "@args",      'LastChance'
CODE

write_test(
    file  => 'ver-h',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
use Best [ [ 'Version::TooLow' => { version => '2.00', },
             'Version::Ok'     => { version => '2.00', }, ],
           [qw/moose elk/], ];
BEST
is "@attempted", 'Version::TooLow Version::Ok';
is "@loaded",    'Version::Ok';
is "@args",      'Version::Ok moose elk';
CODE

write_test(
    file  => 'ok-h',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
use Best [ [ 'Loads::Ok' => { ok => sub { return } },
             'LastChance', ],
           [qw/moose elk/], ];
BEST
is "@attempted", 'Loads::Ok LastChance', 'attempted';
is "@loaded",    'LastChance',           'loaded';
is "@args",      'LastChance moose elk', 'args';
CODE

write_test( file => 'if-h', tests => 2, best => <<'BEST', code => <<'CODE' );
use Best [ [ 'A::Module' => { if => sub { 0 }, },
             qw/AnAlternative LastChance/ ], ];
BEST
is "@attempted", 'AnAlternative LastChance';
is "@loaded",    'LastChance';
CODE

write_test(
    file  => 'args-h',
    tests => 3,
    best  => <<'BEST', code => <<'CODE' );
use Best [ [ qw/A::Module AnAlternative/,
             LastChance => { args => [qw/moose elk/] } ],
           qw/Unused arguments/];
BEST
is "@attempted", 'A::Module AnAlternative LastChance';
is "@loaded",    'LastChance';
is "@args",      'LastChance moose elk';
CODE

write_test(
    file  => 'code-h',
    tests => 2,
    best  => <<'BEST', code => <<'CODE' );
use Best [ [ sub { push @attempted, 'ignored' } => { if => sub { 0 } },
             sub { push @attempted, 'ok'; push @loaded, 'ok' } => { ok => sub { 1 } } ] ];
BEST
is "@attempted", 'ok';
is "@loaded",    'ok';
CODE

use constant TEMPLATE => <<'TEMPLATE';
#!perl
## DO NOT EDIT THIS FILE. It is generated by t/Tests.PL
use strict;
use warnings;
use vars qw/@attempted @loaded @args/;

use Test::More tests => 1 + TESTS;
use lib qw(t t/lib);

# preload for Load::Trace
use Carp ();
use Best ();
use overload ();
BEGIN { eval { require mro } }  # fixes failure on bleadperl as of 2009-01-17
BEGIN {
    overload::Overloaded( sub {} );
    overload::Method( sub{}, '&{}' );
    overload::StrVal( sub{} );
}

use Load::Trace { port => \@attempted };

BEST

pass q[Best didn't crash];

CODE

TEMPLATE

{
    my $num;
    BEGIN { $num = 50 }

    sub write_test {
        my %p = @_;
        my ( $tests, $best, $code, $file ) = map {
            if ( not exists $p{$_} )
            {
                require Carp;
                Carp::croak("Missing parameter: $_");
            }
            elsif ( not defined $p{$_} ) {
                require Carp;
                Carp::croak("Undefined parameter: $_");
            }
            delete $p{$_}
        } qw(tests best code file);
        die "Unknown parameters: @{[sort keys %p]}"
            if keys %p;

        my $src = TEMPLATE;

        $src =~ s/TESTS/$tests/ or die;
        $src =~ s/BEST/$best/   or die;
        $src =~ s/CODE/$code/   or die;

        $file = sprintf 't/%02d-%s.t', $num++, $file;

        print "Writing test $file\n";
        open my $fh, '>', $file
            or die "Can't open $file: $!";
        print {$fh} $src
            or die "Can't write to $file: $!";
        close $fh
            or die "Can't flush $file: $!";
        return;
    }
}
