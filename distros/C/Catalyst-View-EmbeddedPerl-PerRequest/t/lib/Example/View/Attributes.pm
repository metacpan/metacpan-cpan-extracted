package Example::View::Attributes;

use Moose;
extends 'Catalyst::View::EmbeddedPerl::PerRequest';

__PACKAGE__->meta->make_immutable;

__DATA__
<tag
  <%= attr(foo=>'1') %>
  <%= style('font: big')%>
  <%= class('aaa')%>
  <%= checked(1)%>
  <%= selected(1)%>
  <%= disabled(1)%>
  <%= readonly(1)%>
  <%= required(1)%>
  <%= href('http://example.com','vvv')%>
  <%= src('http://example.com','vvv')%>
>
<tag <%= attr(foo=>'1') %> <%= class(['aaa','bbb'])%> <%= data({aaa=>'foo', bbb=>'bar'})%><%= checked(0)%><%= selected(0)%><%= disabled(0)%><%= readonly(0)%><%= required(0)%>>