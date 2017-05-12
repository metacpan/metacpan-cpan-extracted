use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Chain;

    my $continent = chain '/continent/:continent' =>
      sub { var 'site' => param('continent'); };

    my $country =
      chain '/country/:country' => sub { var 'site' => param('country'); };

    my $event = chain '/event/:event' => sub { var 'event' => param('event'); };

    my $continent_event = chain $continent, $event;

    get chain $country, $event, '/schedule' => sub {
        return sprintf( "Schedule of %s in %s", var('event'), var('site') );
    };

    get chain $continent_event, '/schedule' => sub {
        return sprintf( "Schedule of %s in %s", var('event'), var('site') );
    };

    get chain $continent, sub { var 'temp' => var('site') },
      $country, sub { var 'site' => join( ', ', var('site'), var('temp') ) },
      $event, '/schedule' => sub {
        return sprintf( "Schedule of %s in %s", var('event'), var('site') );
      };
}

my $test = Plack::Test->create( TestApp->to_app );

subtest 'get chain $country, $event' => sub {

    my $res =
      $test->request( GET "/country/Malta/event/Qormi_Wine_Festival/schedule" );

    ok $res->is_success,
      "get /country/Malta/event/Qormi_Wine_Festival/schedule";

    is $res->content, "Schedule of Qormi_Wine_Festival in Malta",
      "Content is good";

};

subtest 'get chain $continent_event' => sub {

    my $res =
      $test->request(
        GET "/continent/Europe/event/Qormi_Wine_Festival/schedule" );

    ok $res->is_success,
      "get /continent/Europe/event/Qormi_Wine_Festival/schedule";

    is $res->content, "Schedule of Qormi_Wine_Festival in Europe",
      "Content is good";

};

subtest 'get chain $continent, $country, $event' => sub {

    my $res =
      $test->request(
        GET "/continent/Europe/country/Malta/event/Qormi_Wine_Festival/schedule"
      );

    ok $res->is_success,
      "get /continent/Europe/country/Malta/event/Qormi_Wine_Festival/schedule";

    is $res->content, "Schedule of Qormi_Wine_Festival in Malta, Europe",
      "Content is good";

};

done_testing;
