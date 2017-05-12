BEGIN {
  use FindBin;
  use lib "$FindBin::Bin/lib";
}

use Test::Most;
use Catalyst::Test 'MyApp';
use Template::Lace::DOM;

{
  ok my $res = request '/list';
  ok my $dom = Template::Lace::DOM->new($res->content);

  is $dom->find('meta')->[0]->attr('charset'), 'utf-8';
  is $dom->find('meta')->[1]->attr('name'), 'viewport';
  is $dom->find('link')->[0]->attr('href'), '/static/base.css';
  is $dom->find('link')->[1]->attr('href'), '/static/index.css';
  like $dom->find('style')->[0]->content, qr'div { border: 1px }';

  is $dom->find('#todos li')->[0]->content, 'Buy Milk';
  is $dom->find('#todos li')->[1]->content, 'Walk Dog';
  is $dom->find('ol.errors')->[0]->find('li')->[0]->content, 'too short';
  is $dom->find('ol.errors')->[0]->find('li')->[1]->content, 'too similar it existing item';

  is $dom->at('title')->content, 'Things To Do';
  is $dom->at('#copy')->content, 'copyright 2015';
}

{
  ok my $res = request '/user';
  ok my $dom = Template::Lace::DOM->new($res->content);
  is $dom->at('#name')->content, 'John';
  is $dom->at('#age')->content, '42';
  is $dom->at('#motto')->content, 'Why Not?';
  is $dom->at('a')->attr('href'), 'http://localhost/user';
  is $dom->find('link')->[0]->attr('href'), '/static/base.css';
  is $dom->find('link')->[1]->attr('href'), '/static/index.css';
  is $dom->at('h1')->content, 'Intro';
  is $dom->at('title')->content, 'User Info';
  is $dom->find('meta')->[0]->attr('charset'), 'utf-8';
}

done_testing;
