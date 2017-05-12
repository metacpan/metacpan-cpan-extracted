# -*- mode: cperl; cperl-indent-level: 4; cperl-continued-statement-offset: 4; indent-tabs-mode: nil -*-
use strict;
use warnings FATAL => 'all';

use Apache::Test qw/-withtestmore/;
use Apache::TestUtil;
use Apache::TestUtil qw/t_write_file t_catfile t_debug
                        t_start_error_log_watch t_finish_error_log_watch/;
use Apache::TestRequest qw{GET_BODY GET};
use File::Spec;
use Compress::Zlib;
use Time::HiRes ();

#plan 'no_plan';
plan tests => 85;

Apache::TestRequest::user_agent(reset => 1,
				requests_redirectable => 0);

my $droot=Apache::Test::vars->{documentroot};
my $resp;

t_write_file(t_catfile($droot, 'd', 'p.pod'), <<'POD');

=head1 NAME bla

=head1 SYNOPSIS

=head2 Head2

some paragraph

L<other::module/Head2>

L<missing::module/section>

POD

t_write_file(t_catfile($droot, 'other', 'module.pod'), <<'POD');

=head1 NAME bla

=head1 SYNOPSIS

=head2 Head2

some paragraph

L<d::p/Head2>

L<missing::module/section>

POD

##########################################
# direct access mode
##########################################
t_debug 'Testing direct access mode';

$resp=GET_BODY("/d/p.pod");

like $resp, qr!NAME bla</a></h1>!, 'got it';
unlike $resp, qr!class="uplink"!, 'without uplink';
like $resp, qr!a href="/other/module\.pod#Head2"!, 'link to existing module';
like $resp, qr!a href="/perldoc/missing::module#section"!,
    'link to missing module';

##########################################
# POD index
##########################################
t_debug 'Testing POD index';

$resp=GET("/perldoc?open");     # expect redirect

like $resp->header('Location'), qr!/perldoc/\?open!, 'redirect location';
is $resp->code, 302, 'redirect code';

$resp=GET_BODY("/perldoc/");

# <a href="perlfunc" title="perlfunc">perlfunc</a>
like $resp, qr!<a href="\./perlpod" title="perlpod">perlpod</a>!,
    'POD Index: found perlpod';
unlike $resp, qr!href="\./"!, 'POD Index: no "Pod Index" link';
like $resp, qr!href="\./\?\?"!, 'POD Index: "Function Index" link';

# this test also covers unescaped colons in title=...
# <a href="./d::p" title="d::p">d::p</a>
like $resp, qr!<a href="\./d::p" title="d::p">d::p</a>!,
    'POD Index: found d::p (probably found in PODDIR)';

##########################################
# Function index
##########################################
t_debug 'Testing Function index';

$resp=GET("/perldoc??");     # expect redirect

like $resp->header('Location'), qr!/perldoc/\?\?!, 'redirect location';
is $resp->code, 302, 'redirect code';

$resp=GET_BODY("/perldoc/??");

like $resp, qr!<a href="\./\?\$_" title="\$_">\$_</a>!,
    'Function Index: found $_';
like $resp, qr!<a href="\./\?ref" title="ref">ref</a>!,
    'Function Index: found ref';
like $resp, qr!href="\./"!, 'Function Index: "Pod Index" link';
unlike $resp, qr!href="\./\?\?"!, 'Function Index: no "Function Index" link';

##########################################
# POD index / NOINC
##########################################
t_debug 'Testing POD/Function index with NOINC';

$resp=GET_BODY("/NOINC/");

unlike $resp, qr!perlpod!, 'POD Index: perlpod not found';
unlike $resp, qr!href="\./"!, 'POD Index: no "Pod Index" link';
like $resp, qr!href="\./\?\?"!, 'POD Index: "Function Index" link';

# this test also covers unescaped colons in title=...
# <a href="./d::p" title="d::p">d::p</a>
like $resp, qr!<a href="\./d::p" title="d::p">d::p</a>!,
    'POD Index: but found d::p';

$resp=GET_BODY("/NOINC/??");

like $resp, qr!<a href="\./\?\$_" title="\$_">\$_</a>!,
    'Function Index: found $_';
like $resp, qr!<a href="\./\?ref" title="ref">ref</a>!,
    'Function Index: found ref';
like $resp, qr!href="\./"!, 'Function Index: "Pod Index" link';
unlike $resp, qr!href="\./\?\?"!, 'Function Index: no "Function Index" link';

##########################################
# POD index: content compression
##########################################
t_debug 'Testing content compression with POD index';

my $expected=GET_BODY("/perldoc/"); # save a body we know for next tests
$expected=~s/<!--.*?-->//sg;

$resp=GET '/perldoc/', 'Accept-Encoding'=>'gzip,deflate';
like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
is $resp->header('Content-Encoding'), 'deflate', 'Content-Encoding';

{
    my $got=uncompress($resp->content);
    $got=~s/<!--.*?-->//sg;
    is $got, $expected, 'inflated body';
}

$resp=GET '/perldoc/', 'Accept-Encoding'=>'gzip';
like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
is $resp->header('Content-Encoding'), 'gzip', 'Content-Encoding';

{
    my $got=Compress::Zlib::memGunzip($resp->content);
    $got=~s/<!--.*?-->//sg;
    is $got, $expected, 'ungzipped body';
}

$resp=GET '/perldoc/';
like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
is $resp->header('Content-Encoding'), undef, 'Content-Encoding';
is $resp->content, $expected, 'plain body';

SKIP: {
    skip "need MMapDB to test POD index caching", 7
        unless have_module 'MMapDB';
    ##########################################
    # POD index: cached
    ##########################################
    t_debug 'Testing cached POD index';

    unlink t_catfile Apache::Test::vars->{t_dir}, 'cache.mmdb';

    $expected=~s!(\<a href=\"\./\?\?\"\>Function and Variable Index\<\/a\>)!
        $1.qq{\n    <a href="./-">Update POD Cache</a>}!e;

    die 'Please remove '.t_catfile Apache::Test::vars->{t_dir}, 'cache.mmdb'
        if( -e t_catfile Apache::Test::vars->{t_dir}, 'cache.mmdb' );

    {
        my $time=Time::HiRes::time;
        $resp=GET '/cached/';
        t_debug 'Cache creation took '.(Time::HiRes::time-$time).' sec.';
    }

    {
        my $got=$resp->content;
        $got=~s/<!--.*?-->//sg;
        is $got, $expected, 'cached index 1';

        #    for([got=>$got], [expected=>$expected]) {
        #        my $f; open $f, '>', $_->[0] and print $f $_->[1];
        #    }
    }
    ok -f (t_catfile Apache::Test::vars->{t_dir}, 'cache.mmdb'),
        "cache.mmdb created";

    t_write_file(t_catfile($droot, 'd', 'p2.pod'), <<'POD');

=head1 NAME bla

=head1 SYNOPSIS

=head2 Head2

some paragraph

POD

    {
        my $time=Time::HiRes::time;
        $resp=GET '/cached/';
        t_debug 'Cache usage took '.(Time::HiRes::time-$time).' sec.';
    }

    unlike $resp->content, qr/>d::p2</, 'd::p2 not found';

    {
        my $got=$resp->content;
        $got=~s/<!--.*?-->//sg;
        is $got, $expected, 'cached index 2';
    }

    {
        my $time=Time::HiRes::time;
        $resp=GET '/cached/-';
        t_debug 'Cache rebuild took '.(Time::HiRes::time-$time).' sec.';
    }

    is $resp->code, 302, 'cached index rebuild: http code';
    like $resp->header('Location'), qr!/cached/$!,
        'cached index rebuild: Location';

    {
        my $time=Time::HiRes::time;
        $resp=GET '/cached/';
        t_debug 'Cache usage took '.(Time::HiRes::time-$time).' sec.';
    }

    like $resp->content, qr/>d::p2</, 'd::p2 now found';
}

##########################################
# perldoc -f mode
##########################################
t_debug 'Testing perldoc -f mode';

$resp=GET_BODY("/perldoc/?abs");

like $resp, qr!href="\./"!, '"Pod Index" link';
like $resp, qr!href="\./\?\?"!, '"Function Index" link';

like $resp, qr!>abs VALUE\b!, 'abs VALUE (first =item)';
like $resp, qr~>abs(?! VALUE\b)~, 'abs (2nd =item)';

# in NOINC mode it must generate the same output
$expected=$resp;
$resp=GET_BODY("/NOINC/?abs");
$resp=~s/NOINC/perldoc/g;

is $resp, $expected, 'same output with NOINC';

$expected=GET_BODY("/perldoc/?ref");
$resp=GET '/perldoc/?ref', 'Accept-Encoding'=>'gzip,deflate';
like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
is $resp->header('Content-Encoding'), 'deflate', 'Content-Encoding';

$expected=~s/<!--.*?-->//sg;
{
    my $got=uncompress($resp->content);
    $got=~s/<!--.*?-->//sg;
    is $got, $expected, 'inflated body';
}

##########################################
# perldoc mode
##########################################
t_debug 'Testing perldoc mode';

$resp=GET_BODY("/perldoc/d::p");

like $resp, qr!NAME bla</a></h1>!, 'got it';
like $resp, qr!href="\./"!, '"Pod Index" link';
like $resp, qr!href="\./\?\?"!, '"Function Index" link';

like $resp, qr!a href="\./other::module#Head2"!, 'link to existing module';
like $resp, qr!a href="\./missing::module#section"!,
    'link to missing module';

$resp=GET_BODY("/perldoc/perlfunc");

like $resp, qr!>Alphabetical Listing of Perl Functions</a></h2>!, 'perlfunc';

$resp=GET("/NOINC/perlfunc");

is $resp->code, 404, '/NOINC/perlfunc: 404';

$expected=GET_BODY("/perldoc/d::p");
$resp=GET '/perldoc/d::p', 'Accept-Encoding'=>'gzip,deflate';
like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
is $resp->header('Content-Encoding'), 'deflate', 'Content-Encoding';

$expected=~s/<!--.*?-->//sg;
{
    my $got=uncompress($resp->content);
    $got=~s/<!--.*?-->//sg;
    is $got, $expected, 'inflated body';
}

##########################################
# stylesheets
##########################################
t_debug 'Testing stylesheet access';

foreach (qw!/perldoc/dummy.css /NOINC/dummy.css!) {
    is GET($_)->code, 404, $_.': 404';
}

foreach (qw!/perldoc/auto.css /NOINC/fancy.css
            /perldoc/sub/dir/auto.css /NOINC/sub/dir/fancy.css!) {
    is GET($_)->code, 200, $_.': 200';
}

$expected=GET_BODY("/perldoc/fancy.css");
$resp=GET '/perldoc/fancy.css', 'Accept-Encoding'=>'gzip,deflate';
like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
is $resp->header('Content-Encoding'), 'gzip', 'Content-Encoding';

$expected=~s/<!--.*?-->//sg;
{
    my $got=Compress::Zlib::memGunzip($resp->content);
    $got=~s/<!--.*?-->//sg;
    is $got, $expected, 'ungzipped body';
}

##########################################
# torsten-foertsch.jpg
##########################################
t_debug 'Testing torsten-foertsch.jpg';

$resp=GET("/perldoc/Apache2::PodBrowser/torsten-foertsch.jpg");
is $resp->code, 200, 'Code';
is $resp->header('Content-Length'),
    (-s t_catfile Apache::Test::vars->{top_dir},
                  qw/blib lib Apache2 PodBrowser torsten-foertsch.jpg/),
    'Image Size';
is $resp->header('Content-Type'), 'image/jpeg', 'Content Type';

my $bodylen=length $resp->content;
is $bodylen, $resp->header('Content-Length'), 'resp body size';

$resp=GET("/perldoc/Apache2::PodBrowser/torsten-foertsch.jpg?ct=text/plain");
is length $resp->content, $bodylen, 'resp body size 2';
is $resp->header('Content-Type'), 'text/plain', 'Content Type 2';

SKIP: {
    skip "BrowserMatch needs mod_setenvif", 12
        unless have_module 'mod_setenvif.c';
    ##########################################
    # BrowserMatch
    ##########################################
    t_debug 'Testing BrowserMatch';

    Apache::TestRequest::user_agent(reset => 1,
                                    requests_redirectable => 0,
                                    agent => 'I am MSIE. Nice to meet you!');

    $expected=GET_BODY("/perldoc/fancy.css");
    $resp=GET '/perldoc/fancy.css', 'Accept-Encoding'=>'gzip,deflate';
    like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
    is $resp->header('Content-Encoding'), undef, 'Content-Encoding';
    is $resp->content, $expected, 'plain body';

    $expected=GET_BODY("/perldoc/d::p");
    $resp=GET '/perldoc/d::p', 'Accept-Encoding'=>'gzip,deflate';
    like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
    is $resp->header('Content-Encoding'), undef, 'Content-Encoding';
    is $resp->content, $expected, 'plain body';

    Apache::TestRequest::user_agent(reset => 1,
                                    requests_redirectable => 0,
                                    agent => 'I am HUHU. Nice to meet you!');

    $expected=GET_BODY("/perldoc/fancy.css");
    $resp=GET '/perldoc/fancy.css', 'Accept-Encoding'=>'gzip,deflate';
    like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
    is $resp->header('Content-Encoding'), undef, 'Content-Encoding';
    is $resp->content, $expected, 'plain body';

    $expected=GET_BODY("/perldoc/d::p");
    $resp=GET '/perldoc/d::p', 'Accept-Encoding'=>'gzip,deflate';
    like $resp->header('Vary'), qr/\bAccept-Encoding\b/i, 'Vary Header';
    is $resp->header('Content-Encoding'), 'deflate', 'Content-Encoding';

    $expected=~s/<!--.*?-->//sg;
    {
        my $got=uncompress($resp->content);
        $got=~s/<!--.*?-->//sg;
        is $got, $expected, 'inflated body';
    }
}
