use Test::More;
use Test::Exception;

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

use Capture::Tiny;
diag("Testing App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();
my $appt = App::Kit->new( 'test' => 1 );

TODO: {
    local $TODO = "rt 89239 needs addressed for this to work";
    is( App::Kit->new(), $app, "new() is multiton - no args" );
}

isnt( $app, $appt, "new() is multiton - diff args" );

TODO: {
    local $TODO = "rt 89239 needs addressed for this to work";
    is( $appt, App::Kit->new( 'test' => 1 ), "new() is multiton - same args via hash" );
    is( $appt, App::Kit->new( { 'test' => 1 } ), "new() is multiton - same args via hashref" );
}

my @roles = (
    [ 'Locale' => { isa => 'Locale::Maketext::Utils::Mock::en' } ],
    [ 'HTTP'   => { isa => 'HTTP::Tiny' } ],
    [ 'NS'     => { isa => 'App::Kit::Obj::NS' } ],
    [ 'FS'     => { isa => 'App::Kit::Obj::FS' } ],
    [ 'Str'    => { isa => 'App::Kit::Obj::Str' } ],
    [ 'CType'  => { isa => 'App::Kit::Obj::CType' } ],
    [ 'Detect' => { isa => 'App::Kit::Obj::Detect' } ],
    [ 'DB'     => { isa => 'App::Kit::Obj::DB' } ],
    [ 'Log'    => { isa => 'Log::Dispatch' } ],
);

for my $role_ar (@roles) {
    my $role    = $role_ar->[0];
    my $role_hr = $role_ar->[1];

    my $has = lc($role);
    ok( !exists $app->{$has}, "'$has' does not exist before it is called" );
    is( ref $app->$has(), $role_hr->{'isa'}, "'$has' returns the expected object" );
    ok( exists $app->{$has}, "'$has' exists after it is called" );

    throws_ok { $app->$has( bless {}, 'Foo' ) } qr/$has is a read-only accessor/, "'$has' is readonly by default";
}

done_testing;
