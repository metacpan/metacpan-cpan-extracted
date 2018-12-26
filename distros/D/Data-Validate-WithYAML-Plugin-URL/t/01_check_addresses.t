#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::URL' );
}

my $module = 'Data::Validate::WithYAML::Plugin::URL';

my @urls = (
    'http://perl-magazin.de',
    'https://otrs.org',
    'http://127.0.0.1:3000/hallo.php',
    'http://localhost:8080/test.cgi',
    'http://test/test.cgi?schluessel=name&key=value',
);

my @blacklist = (
    'test',
    '123',
    '+12as',
    'htttp://test.de',
    'ftp://ftp.otrs.org',
    'file://c/test.txt',
    'gopher://test',
);

for my $url ( @urls ){
    ok( $module->check($url), "test: $url" );
}

for my $check ( @blacklist ){
    my $retval = $module->check( $check );
    ok( !$retval, "test: $check" );
}

my $error;
eval {
    $module->check( undef );
    1;
} or $error = $@;

like $error, qr/no value to check/;

done_testing();
