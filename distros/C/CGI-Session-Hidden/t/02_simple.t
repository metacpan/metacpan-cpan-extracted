#!/usr/bin/perl -w

use strict;

use Test::More import => ['!plan'];
BEGIN{
    eval "use Apache::Test qw(-withtestmore); use HTML::Form; use Test::LongString";
    Test::More::plan( skip_all => "Apache::Test, HTML::Form, Test::LongString required" )
          if $@;
}
Apache::Test::plan( skip_all => 'using compatibility Makefile.PL' )
    if -f 'Makefile' || -f 'makefile';
Apache::Test::plan( tests => 8,
                    Apache::Test::need_module( 'cgi', 'env' ) );

use Apache::TestRequest qw(GET POST);

Apache::TestRequest::user_agent( cookie_jar => {} );

my $res = GET '/cgi-bin/foo.pl';
ok( $res->is_success );
like_string( $res->content, qr/value=2/ );

my $form = HTML::Form->parse( $res->content, $res->base );
my $res3 = POST '/cgi-bin/foo.pl', [ map { ( $_->name, $_->value ) }
                                         $form->inputs ];
ok( $res3->is_success );
like_string( $res3->content, qr/value=4/ );

# freash request
Apache::TestRequest::user_agent( cookie_jar => {} );

my $res2 = GET '/cgi-bin/foo.pl';
ok( $res2->is_success );
like_string( $res2->content, qr/value=2/ );

my $form2 = HTML::Form->parse( $res2->content, $res2->base );
my $res4 = POST '/cgi-bin/foo.pl', [ map { ( $_->name, $_->value ) }
                                         $form2->inputs ];
ok( $res4->is_success );
like_string( $res4->content, qr/value=4/ );
