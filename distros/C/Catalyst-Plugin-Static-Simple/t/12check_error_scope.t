#!perl

use strict;
use warnings;
no strict 'refs';
no warnings 'redefine';

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 3;
BEGIN {
    use Catalyst::Plugin::Static::Simple;
    Catalyst::Plugin::Static::Simple->meta->add_before_method_modifier(
        'prepare_action',
        sub {
            my ($c) = @_;
            eval { die("FOO"); };

            ok( $@, '$@ has a value.' );
        }
    );
}
use Catalyst::Test 'TestApp';

TestApp->config->{'Plugin::Static::Simple'}->{dirs} = [qr{stuff/}];

ok( my $res = request("http://localhost/"), 'request ok' );
ok( $res->code == 200, q{Previous error doesn't crash static::simple} );
