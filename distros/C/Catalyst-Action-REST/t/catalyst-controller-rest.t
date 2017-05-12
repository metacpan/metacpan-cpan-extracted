use strict;
use warnings;
use Test::More;
use Test::Requires qw(YAML::Syck);
use YAML::Syck;
use FindBin;

use lib ("$FindBin::Bin/lib", "$FindBin::Bin/../lib", "$FindBin::Bin/broken");
use Test::Rest;

my $t = Test::Rest->new(content_type => 'text/x-yaml');

use_ok 'Catalyst::Test', 'Test::Catalyst::Action::REST';

my $data = { your => 'face' };
is_deeply(
  Load(
    request($t->put(url => '/rest/test', data => Dump($data)))->content
  ),
  { test => 'worked', data => $data },
  'round trip (deserialize/serialize)',
);


ok my $res = request( $t->get( url => '/rest/test_status_created' ) );
is $res->code, 201, "... status created";
is $res->header('Location'), '/rest', "...location of what was created";

ok $res = request( $t->get( url => '/rest/test_status_accepted' ) );
is $res->code, 202, "... status accepted";
is $res->header('Location'), '/rest', "...location of what was accepted";

ok $res = request( $t->get( url => '/rest/test_status_no_content' ) );
is $res->code, 204, "... status no content";
is $res->content, '', '... no content';

ok $res = request( $t->get( url => '/rest/test_status_found' ) );
is $res->code, 302, '... status found';
is_deeply Load( $res->content ),
    { status => 'found' },
    "...  status found message";
is $res->header('Location'), '/rest', "...location of what was found";

ok $res = request( $t->get( url => '/rest/test_status_see_other' ) );
is $res->code, 303, "... status see other";
is $res->header('Location'), '/rest', "...location to redirect to";


ok $res = request( $t->get( url => '/rest/test_status_bad_request' ) );
is $res->code, 400, '... status bad request';
is_deeply Load( $res->content ),
    { error => "Cannot do what you have asked!" },
    "...  status bad request message";

ok $res = request( $t->get( url => '/rest/test_status_forbidden' ) );
is $res->code, 403, '... status forbidden';
is_deeply Load( $res->content ),
    { error => "access denied" },
    "...  status forbidden";

ok $res = request( $t->get( url => '/rest/test_status_not_found' ) );
is $res->code, 404, '... status not found';
is_deeply Load( $res->content ),
    { error => "Cannot find what you were looking for!" },
    "...  status bad request message";

ok $res = request( $t->get( url => '/rest/test_status_gone' ) );
is $res->code, 410, '... status gone';
is_deeply Load( $res->content ),
    { error => "Document have been deleted by foo" },
    "...  status gone message";

ok $res = request( $t->get( url => '/rest/test_status_multiple_choices' ) );
is $res->code, 300, "... multiple choices";
is_deeply Load($res->content),
    { choices => [qw(/rest/choice1 /rest/choice2)] },
    "... 300 multiple choices has response body";
is $res->header('Location'), '/rest/choice1', "...main location of what was found";

done_testing;

