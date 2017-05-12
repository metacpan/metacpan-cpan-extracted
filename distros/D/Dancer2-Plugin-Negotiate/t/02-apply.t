#!perl -T

use Test::Most import => ['!pass'];
use Plack::Test;
use HTTP::Request::Common;

sub islc   { is lc(shift),   lc(shift), shift; }
sub isntlc { isnt lc(shift), lc(shift), shift; }

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::Negotiate;

    get '/' => sub {
        apply_variant(
            var1 => {
                Quality  => 1.000,
                Type     => 'text/html',
                Charset  => 'iso-8859-1',
                Language => 'en'
            },
            var2 => {
                Quality  => 0.950,
                Type     => 'text/plain',
                Charset  => 'us-ascii',
                Language => 'no'
            },
        );
    };

}

my $PT = Plack::Test->create( Webservice->to_app );

plan tests => 2;

subtest var1 => sub {
    plan tests => 5;
    my $R = $PT->request( GET('/') );
    ok $R->is_success;
    islc $R->content                         => 'var1';
    like $R->header( lc 'Content-Type' )     => qr'^text/html(\s*;.*)?$';
    islc $R->header( lc 'Content-Charset' )  => 'iso-8859-1';
    islc $R->header( lc 'Content-Language' ) => 'en';
};

subtest var2 => sub {
    plan tests => 5;
    my $R = $PT->request( GET( '/', Accept => 'text/plain' ) );
    ok $R->is_success;
    islc $R->content                         => 'var2';
    like $R->header( lc 'Content-Type' )     => qr'^text/plain(\s*;.*)?$';
    islc $R->header( lc 'Content-Charset' )  => 'us-ascii';
    islc $R->header( lc 'Content-Language' ) => 'no';
};

done_testing;
