#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::NoSpam' );
}

my $module = 'Data::Validate::WithYAML::Plugin::NoSpam';

my @emails = (
    'This is a small test',
);

my @blacklist = (
    'test <a href="test.de">Test.de</a>',
    '123 [url]http://feature-addons.de[/url]',
    'Buy some viagra',
);

for my $mail ( @emails ){
    ok( $module->check($mail) );
}

for my $check ( @blacklist ){
    my $retval = $module->check( $check );
    ok( !$retval );
}

my $error;
eval {
    $module->check( undef );
    1;
} or $error = $@;

like $error, qr/no value to check/;

done_testing();
