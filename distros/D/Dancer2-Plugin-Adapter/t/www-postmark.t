use strict;
use warnings;
use Test::More 0.96 import => ['!pass'];

use HTTP::Tiny;
use Plack::Test;
use HTTP::Request::Common;

use Class::Load qw/try_load_class/;
try_load_class('WWW::Postmark')
  or plan skip_all => "WWW::Postmark required to run these tests";

HTTP::Tiny->new->get("http://api.postmarkapp.com/")->{success}
  or plan skip_all => "api.postmarkapp.com not available";

{
  package Test::Adapter::WWWPostmark;
  use Dancer2;
  use Dancer2::Plugin::Adapter;

  set show_errors => 0;

  set plugins => {
    Adapter => {
      postmark => {
        class   => 'WWW::Postmark',
        options => 'POSTMARK_API_TEST',
      },
    },
  };

  get '/' => sub {
    eval {
      service("postmark")->send(
        from    => 'me@domain.tld',
        to      => 'you@domain.tld, them@domain.tld',
        subject => 'an email message',
        body    => "hi guys, what's up?"
      );
    };

    return $@ ? "Error: $@" : "Mail sent";
  };

}

my $test = Plack::Test->create( Test::Adapter::WWWPostmark->to_app );

my $res = $test->request( GET '/' );
ok $res->is_success, "Request success";
like $res->content, qr/Mail sent/i, "WWW::Postmark pretended to send mail";

done_testing;
# COPYRIGHT
