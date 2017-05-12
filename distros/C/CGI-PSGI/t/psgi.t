# copy of request.t

use strict;
use warnings;

use Test::More;

eval "use 5.008";
plan skip_all => "$@" if $@;
plan tests => 36;

use CGI::PSGI ();
use Config;

my $loaded = 1;

$| = 1;

######################### End of black magic.

# Set up a CGI environment
my $env;
$env->{REQUEST_METHOD}  = 'GET';
$env->{QUERY_STRING}    = 'game=chess&game=checkers&weather=dull';
$env->{PATH_INFO}       = '/somewhere/else';
$env->{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$env->{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$env->{SERVER_PROTOCOL} = 'HTTP/1.0';
$env->{SERVER_PORT}     = 8080;
$env->{SERVER_NAME}     = 'the.good.ship.lollypop.com';
$env->{REQUEST_URI}     = "$env->{SCRIPT_NAME}$env->{PATH_INFO}?$env->{QUERY_STRING}";
$env->{HTTP_LOVE}       = 'true';

my $q = CGI::PSGI->new($env);
ok $q,"CGI::new()";
is $q->request_method => 'GET',"CGI::request_method()";
is $q->query_string => 'game=chess;game=checkers;weather=dull',"CGI::query_string()";
is $q->param(), 2,"CGI::param()";
is join(' ',sort $q->param()), 'game weather',"CGI::param()";
is $q->param('game'), 'chess',"CGI::param()";
is $q->param('weather'), 'dull',"CGI::param()";
is join(' ',$q->param('game')), 'chess checkers',"CGI::param()";
ok $q->param(-name=>'foo',-value=>'bar'),'CGI::param() put';
is $q->param(-name=>'foo'), 'bar','CGI::param() get';
is $q->query_string, 'game=chess;game=checkers;weather=dull;foo=bar',"CGI::query_string() redux";
is $q->http('love'), 'true',"CGI::http()";
is $q->script_name, '/cgi-bin/foo.cgi',"CGI::script_name()";
is $q->url, 'http://the.good.ship.lollypop.com:8080/cgi-bin/foo.cgi',"CGI::url()";
is $q->self_url,
     'http://the.good.ship.lollypop.com:8080/cgi-bin/foo.cgi/somewhere/else?game=chess;game=checkers;weather=dull;foo=bar',
     "CGI::url()";
is $q->url(-absolute=>1), '/cgi-bin/foo.cgi','CGI::url(-absolute=>1)';
is $q->url(-relative=>1), 'foo.cgi','CGI::url(-relative=>1)';
is $q->url(-relative=>1,-path=>1), 'foo.cgi/somewhere/else','CGI::url(-relative=>1,-path=>1)';
is $q->url(-relative=>1,-path=>1,-query=>1), 
     'foo.cgi/somewhere/else?game=chess;game=checkers;weather=dull;foo=bar',
     'CGI::url(-relative=>1,-path=>1,-query=>1)';
$q->delete('foo');
ok !$q->param('foo'),'CGI::delete()';

$q->_reset_globals;
$env->{QUERY_STRING}='mary+had+a+little+lamb';
ok $q=CGI::PSGI->new($env),"CGI::new() redux";
is join(' ',$q->keywords), 'mary had a little lamb','CGI::keywords';
is join(' ',$q->param('keywords')), 'mary had a little lamb','CGI::keywords';

# test posting
$q->_reset_globals;
{
  my $test_string = 'game=soccer&game=baseball&weather=nice';
  local $env->{REQUEST_METHOD}='POST';
  local $env->{CONTENT_LENGTH}=length($test_string);
  local $env->{QUERY_STRING}='big_balls=basketball&small_balls=golf';

  open my $input, '<', \$test_string;
  use IO::Handle;
  $env->{'psgi.input'} = $input;

  ok $q=CGI::PSGI->new($env),"CGI::new() from POST";
  is $q->param('weather'), 'nice',"CGI::param() from POST";
  is $q->url_param('big_balls'), 'basketball',"CGI::url_param()";
}

# test url_param 
{
    local $env->{QUERY_STRING} = 'game=chess&game=checkers&weather=dull';

    my $q = CGI::PSGI->new($env);
    # params present, param and url_param should return true
    ok $q->param,     'param() is true if parameters';
    ok $q->url_param, 'url_param() is true if parameters';

    $env->{QUERY_STRING} = '';

    $q = CGI::PSGI->new($env);
    ok !$q->param,     'param() is false if no parameters';
    if (eval { CGI->VERSION(3.46) }) {
      ok !$q->url_param, 'url_param() is false if no parameters';
    } else {
      # CGI.pm before 3.46 had an inconsistency with url_param and an empty
      # query string
      my %p = map { $_ => [ $q->url_param($_) ] } $q->url_param;
      is_deeply \%p, { keywords => [] };
    }

    $env->{QUERY_STRING} = 'tiger dragon';
    $q = CGI::PSGI->new($env);

    is_deeply [$q->$_] => [ 'keywords' ], "$_ with QS='$env->{QUERY_STRING}'" 
        for qw/ param url_param /;

    is_deeply [ sort $q->$_( 'keywords' ) ], [ qw/ dragon tiger / ],
        "$_ keywords" for qw/ param url_param /;
}

{
    my $q = CGI::PSGI->new($env);
    $q->charset('utf-8');
    my($status, $headers) = $q->psgi_header(-status => 302, -content_type => 'text/plain');

    is $status, 302;
    is_deeply $headers, [ 'Content-Type', 'text/plain; charset=utf-8' ];
}

