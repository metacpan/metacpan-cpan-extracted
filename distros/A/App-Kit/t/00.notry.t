use Test::More;

use App::Kit qw(-no-try);

diag("Testing App::Kit $App::Kit::VERSION");

ok( !defined &try,     'try not there under -no-try' );
ok( !defined &catch,   'catch not there under -no-try' );
ok( !defined &finally, 'finally not there under -no-try' );

eval 'print $x;';
like( $@, qr/Global symbol "\$x" requires explicit package name/, 'strict enabled still under -no-try' );
{
    my $warn = '';
    local $SIG{__WARN__} = sub {
        $warn = join( '', @_ );
    };
    eval 'my $foo=1;42/99;$foo=2;';
    like( $warn, qr/Useless use of a constant \(.*\) in void context/i, 'warnings enabled still under -no-try' );
}

done_testing;
