#!/usr/bin/perl -w
use strict;
use Test::More tests => 5;
use URI::Escape;
use HTML::Entities;

use vars qw( $wiki @all_nodes );
BEGIN {
  @all_nodes = (
    { name => 'foo', last_modified => 1 },
    { name => 'bar', last_modified => 3 },
    { name => 'baz', last_modified => 2 },
    { name => 'foo:bar', last_modified => 4 },
    { name => 'foo:baz', last_modified => 0 },
    { name => 'foo:foo', last_modified => 6 },
  );

  use Test::MockObject;
  $wiki = Test::MockObject->new();
  $wiki->set_list('list_recent_changes',@all_nodes);
  $wiki->mock( node_url => sub {
    my ($self,%args) = @_;
    $args{mode} ||= 'display';
    "/wiki/$args{mode}/" . uri_escape($args{node});
  } );
  $wiki->mock( inside_link => sub {
    my ($self,%args) = @_;
    "<a href='" . $self->node_url(%args) . "'>" . HTML::Entities::encode_entities($args{title}) . "</a>";
  } );
};

BEGIN {
  use_ok('CGI::Wiki::Simple');
};

{ package CGI::Wiki::Simple::Plugin::NodeListTest1;
  use strict;
  use Test::More;
  my $wiki = $main::wiki->clear;
  eval q!use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'Test::Test1' )!;

  is_deeply([CGI::Wiki::Simple::Plugin::RecentChanges::retrieve_node(wiki => $wiki, name => 'Test::Test1')],
  ["<table class='RecentChanges'><tr><td><a href='/wiki/display/foo%3Afoo'>foo:foo</a></td><td>6</td></tr>
<tr><td><a href='/wiki/display/foo%3Abar'>foo:bar</a></td><td>4</td></tr>
<tr><td><a href='/wiki/display/bar'>bar</a></td><td>3</td></tr>
<tr><td><a href='/wiki/display/baz'>baz</a></td><td>2</td></tr>
<tr><td><a href='/wiki/display/foo'>foo</a></td><td>1</td></tr>
<tr><td><a href='/wiki/display/foo%3Abaz'>foo:baz</a></td><td>0</td></tr></table>",0,""],"All nodes");
};

{ package CGI::Wiki::Simple::Plugin::NodeListTest2;
  use strict;
  use Test::More;
  my $wiki = $main::wiki->clear;
  eval q!use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'Test::Test2', re => '^foo:(.*)$' )!;

  is_deeply([CGI::Wiki::Simple::Plugin::RecentChanges::retrieve_node(wiki => $wiki, name => 'Test::Test2')],
  ["<table class='RecentChanges'><tr><td><a href='/wiki/display/foo%3Afoo'>foo</a></td><td>6</td></tr>
<tr><td><a href='/wiki/display/foo%3Abar'>bar</a></td><td>4</td></tr>
<tr><td><a href='/wiki/display/foo%3Abaz'>baz</a></td><td>0</td></tr></table>",0,""],"String re");
};

{ package CGI::Wiki::Simple::Plugin::NodeListTest3;
  use strict;
  use Test::More;
  my $wiki = $main::wiki->clear;
  eval q!use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'Test::Test3', re => '^(foo:.*)$' )!;

  is_deeply([CGI::Wiki::Simple::Plugin::RecentChanges::retrieve_node(wiki => $wiki, name => 'Test::Test3')],
  ["<table class='RecentChanges'><tr><td><a href='/wiki/display/foo%3Afoo'>foo:foo</a></td><td>6</td></tr>
<tr><td><a href='/wiki/display/foo%3Abar'>foo:bar</a></td><td>4</td></tr>
<tr><td><a href='/wiki/display/foo%3Abaz'>foo:baz</a></td><td>0</td></tr></table>",0,""],"Complete string re");
};

{ package CGI::Wiki::Simple::Plugin::NodeListTest4;
  use strict;
  use Test::More;
  my $wiki = $main::wiki->clear;
  eval q!use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'Test::Test4', re => qr/foo:(.*)/ )!;

  is_deeply([CGI::Wiki::Simple::Plugin::RecentChanges::retrieve_node(wiki => $wiki, name => 'Test::Test4')],
  ["<table class='RecentChanges'><tr><td><a href='/wiki/display/foo%3Afoo'>foo</a></td><td>6</td></tr>
<tr><td><a href='/wiki/display/foo%3Abar'>bar</a></td><td>4</td></tr>
<tr><td><a href='/wiki/display/foo%3Abaz'>baz</a></td><td>0</td></tr></table>",0,""],"qr() re");
};
