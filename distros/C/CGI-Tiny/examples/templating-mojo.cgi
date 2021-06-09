#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use CGI::Tiny;
use Mojo::Template;
use Mojo::File 'curfile';
use Mojo::Loader 'data_section';

cgi {
  my $cgi = $_;

  my $mt = Mojo::Template->new(auto_escape => 1, vars => 1);

  my $foo = $cgi->query_param('foo');

  # from templates/
  my $template_path = curfile->sibling('templates', 'index.html.ep');
  my $output = $mt->render_file($template_path, {foo => $foo});

  # or from __DATA__
  my $template = data_section __PACKAGE__, 'index.html.ep';
  my $output = $mt->render($template, {foo => $foo});

  $cgi->render(html => $output);
};

__DATA__
@@ index.html.ep
<html><body><h1><%= $foo %></h1></body></html>
