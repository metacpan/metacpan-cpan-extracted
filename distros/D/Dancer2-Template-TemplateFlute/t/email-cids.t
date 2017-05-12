use strict;
use warnings;

use Test::More;
use Test::Deep;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestApp;
    use Dancer2;
    use Test::Deep;

    get '/one' => sub {

        my $email_cids = {};

        my $mail = template mail => { email_cids => $email_cids, };

        $email_cids->{foopng}->{filename} eq 'foo.png'
          && $email_cids->{fooblapng}->{filename} eq 'foo-bla.png'
          && return $mail;
    };

    get '/two' => sub {

        return template mail => {};
    };

    get '/three' => sub {

        my $email_cids = {};

        my $mail = template mail => {
            email_cids => $email_cids,
            mylist     => [
                {
                    image => 'pippo1.png',
                },
                {
                    image => 'pippo2.png',
                },
                {
                    image => 'http://example.com/image.jpg',
                }
            ],
        };

             $email_cids->{foopng}->{filename} eq 'foo.png'
          && $email_cids->{fooblapng}->{filename} eq 'foo-bla.png'
          && $email_cids->{pippo1png}->{filename} eq 'pippo1.png'
          && $email_cids->{pippo2png}->{filename} eq 'pippo2.png'
          && return $mail;
    };

    get '/four' => sub {

        my $email_cids = {};

        my $mail = template mail => {
            email_cids => $email_cids,
            cids       => { base_url => 'http://example.com/' },
            mylist     => [
                {
                    image => 'pippo1.png',
                },
                {
                    image => 'pippo2.png',
                },
                {
                    image => 'http://example.com/image.jpg',
                }
            ],
        };

             $email_cids->{foopng}->{filename} eq 'foo.png'
          && $email_cids->{fooblapng}->{filename} eq 'foo-bla.png'
          && $email_cids->{pippo1png}->{filename} eq 'pippo1.png'
          && $email_cids->{pippo2png}->{filename} eq 'pippo2.png'
          && $email_cids->{httpexamplecomimagejpg}->{filename} eq 'image.jpg'
          && return $mail;
    };

}

my $test = Plack::Test->create( TestApp->to_app );

my $res = $test->request( GET '/one' );
ok $res->is_success, "GET /one successful";
like $res->content, qr/cid:foopng.*cid:fooblapng/, "img src replaced";

$res = $test->request( GET '/two' );
ok $res->is_success,  "GET /two successful";
like $res->content,   qr/src="foo\.png".*src="foo-bla.png"/, "content OK";
unlike $res->content, qr/cid:/, "No hashref passed, no cid replaced";

$res = $test->request( GET '/three' );
ok $res->is_success, "GET /three successful";
like $res->content,  qr/src="cid:pippo1png".*src="cid:pippo2png"/,
  "Found the cids";
like $res->content, qr!src="http://example.com/image.jpg"!, "URL left intact";

$res = $test->request( GET '/four' );
ok $res->is_success, "GET /four successful";
like $res->content, qr/src="cid:pippo1png".*src="cid:pippo2png"/,
  "Found the cids";
like $res->content, qr/src="cid:pippo1png".*src="cid:httpexamplecomimagejpg"/,
  "Found the cids";

done_testing;
