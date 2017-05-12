use Test::More;
eval "use Test::Signature;";
if ($@) {
    plan( skip_all => "Test::Signature wasn't installed" );
}
else {
    plan( tests => 1 );
    signature_ok();
}
