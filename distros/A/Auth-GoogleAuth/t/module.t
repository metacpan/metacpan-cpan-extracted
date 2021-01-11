use Test2::V0;
use Auth::GoogleAuth;

my $obj;
ok( $obj = Auth::GoogleAuth->new, 'new' );
is( ref $obj, 'Auth::GoogleAuth', 'ref $object' );

my $secret32 = $obj->generate_secret32;
ok( $secret32 =~ /^[a-z2-7]{16}$/, 'generate_secret32() length and content' );
is( $secret32, $obj->secret32, 'generate_secret32() stored as secret32()' );

ok(
    lives { $obj = Auth::GoogleAuth->new( { map { $_ => 'data' } qw( secret secret32 issuer key_id ) } ) },
    'new({...})',
) or note $@;
is( $obj->$_, 'data', "$_ set in instantiator" ) for ( qw( secret secret32 issuer key_id ) );

ok( lives { $obj->clear }, 'clear' ) or note $@;
is( $obj->$_, undef, "$_ unset after clear" ) for ( qw( secret secret32 issuer key_id ) );

ok( $obj->qr_code =~ m|
    https://chart.googleapis.com/chart
    \?
    chs=200x200&cht=qr&chl=
    otpauth%3A%2F%2Ftotp%2FUndefined%3AUndefined%3Fsecret%3D
    [a-z0-9]{16}
    %26issuer%3DUndefined
|x, 'qr_code from clear state' );

ok( $obj->qr_code( 'bv5o3disbutz4tl3', 'gryphon@cpan.org', 'Gryphon Shafer' ) =~ m|
    https://chart.googleapis.com/chart
    \?
    chs=200x200&cht=qr&chl=
    otpauth%3A%2F%2Ftotp%2FGryphon%2520Shafer%3Agryphon%2540cpan.org%3Fsecret%3D
    bv5o3disbutz4tl3
    %26issuer%3DGryphon%2520Shafer
|x, 'qr_code from specific state' );

ok( $obj->qr_code( 'bv5o3disbutz4tl3', 'gryphon@cpan.org', 'Gryphon Shafer', 1 ) =~ m|
    otpauth://totp/Gryphon%20Shafer:gryphon%40cpan.org\?secret=bv5o3disbutz4tl3&issuer=Gryphon%20Shafer
|x, 'qr_code otpauth from specific state' );

is( $obj->code( undef, 1438643789 ), '007176', 'code()' );
is( $obj->code( 'utz4tl3bv5o3disb', 1438643789 ), '879364', 'code( $s32, $time )' );
is( $obj->code( 'utz4tl3bv5o3disb', 1438643789, 30 ), '879364', 'code( $s32, $time, 30 )' );
is( $obj->code( undef, 1438643789 ), '879364', 'code() again' );

is( $obj->verify( '879364', 0, 'utz4tl3bv5o3disb', 1438643789 ), 1, 'verify(tight) works' );
is( $obj->verify( '879364', 0, 'utz4tl3bv5o3disb', 1438643790 ), 0, 'verify(tight, mis-time) fails' );
is( $obj->verify( '879364', 1, 'utz4tl3bv5o3disb', 1438643790 ), 1, 'verify(loose, mis-time) works' );
is( $obj->verify( '879364', 1, 'utz4tl3bv5o3disb', 1438643820 ), 0, 'verify(loose, mis-time++) fails' );
is( $obj->verify( '879364', 2, 'utz4tl3bv5o3disb', 1438643820 ), 1, 'verify(looser, mis-time++) works' );

done_testing;
