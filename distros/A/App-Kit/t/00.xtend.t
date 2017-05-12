use Test::More;

use lib 't/lib';
use MyTest;

# do these no()'s to ensure they are off before testing App::Kit’s behavior regarding them
no strict;      ## no critic
no warnings;    ## no critic

use App::Kit;
ok( defined &try,     'try is there w/out -no-try' );
ok( defined &catch,   'catch is there w/out -no-try' );
ok( defined &finally, 'finally is there w/out -no-try' );

eval 'print $x;';
like( $@, qr/Global symbol "\$x" requires explicit package name/, 'strict enabled' );
{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn = join( '', @_ );
    };
    eval 'my $foo=1;42/99;$foo=2;';
    like( $warn, qr/Useless use of a constant \(.*\) in void context/i, 'warnings enabled' );
}

my $app = MyTest->new;
diag("Testing App::Kit $App::Kit::VERSION");

isa_ok( $app, 'MyTest' );
isa_ok( $app, 'App::Kit' );

can_ok( $app, 'foo' );
is( $app->foo, 42, 'new attr works' );

can_ok( $app, 'bar' );
is( $app->bar, 23, 'new method works' );

can_ok( $app, 'log' );
is( $app->log, 'busted log', 'overridden attr works' );

can_ok( $app, 'locale' );
isa_ok( $app->locale, 'Locale::Maketext::Utils::Mock::en', 'non-overridden attr works' );

my $m = MyTest->multiton();
isa_ok( $m, 'MyTest' );
isa_ok( $m, 'App::Kit' );
is( $m, MyTest->multiton, 'multiton() w/ no args is same' );
is( MyTest->multiton( a => 1 ), MyTest->multiton( { a => 1 } ), 'multiton() w/ list and ref are same' );
isnt( $m, MyTest->multiton( { a => 1 } ), 'multiton() w/ diff args are diff' );

package zong;

no strict;
no warnings;

Test::More::ok( !defined &try,     'sanity: try is not there already' );
Test::More::ok( !defined &catch,   'sanity: catch is not there already' );
Test::More::ok( !defined &finally, 'sanity: finally is not there already' );

eval 'print $x;';
Test::More::unlike( $@, qr/Global symbol "\$x" requires explicit package name/, 'sanity: strict not enabled' );
{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn = join( '', @_ );
    };
    eval 'print @X[0]';
    Test::More::unlike( $warn, qr/Scalar value \@x\[0\] better written as \$x\[0\]/i, 'sanity warnings not enabled' );
}

use MyTest qw(-no-try);

Test::More::ok( !defined &try,     'try not there under -no-try' );
Test::More::ok( !defined &catch,   'catch not there under -no-try' );
Test::More::ok( !defined &finally, 'finally not there under -no-try' );

{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn = join( '', @_ );
    };
    eval 'print $x;';
    Test::More::like( $@, qr/Global symbol "\$x" requires explicit package name/, 'strict enabled still under -no-try' );
    Test::More::like( $warn, qr/Variable "\$x" is not imported at/i, 'warnings enabled still under -no-try' );
}

package main;

done_testing;
