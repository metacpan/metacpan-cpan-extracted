#!perl -wT
# $Id: /local/CPAN/AxKit-XSP-Minisession/t/004_xsp.t 1418 2005-03-05T18:07:22.924154Z claco  $
use strict;
use warnings;
# Using require instead of use to avoid redefining errors
# when Apache::Test < 1.16 is installed
require Test::More;

eval 'use Apache::Test 1.16';
Test::More::plan(skip_all =>
        'Apache::Test 1.16 required for AxKit Taglib tests') if $@;

eval 'use LWP::UserAgent';
Test::More::plan(skip_all =>
        'LWP::UserAgent required for Apache::Test cookie tests') if $@;

Apache::TestRequest->import(qw(GET));
Apache::TestRequest::user_agent( cookie_jar => {});
Apache::Test::plan(tests => 3, need('AxKit', 'mod_perl', &have_apache(1), &
have_lwp));

my $setreq = GET('/set-value.xsp');
ok($setreq->code == 200);

my $getreq = GET('/get-value.xsp');
ok($getreq->code == 200);

ok( $getreq->content =~ /<body>claco<\/body\>/i );

