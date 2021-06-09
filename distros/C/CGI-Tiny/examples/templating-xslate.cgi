#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use CGI::Tiny;
use Text::Xslate;
use Data::Section::Simple 'get_data_section';

cgi {
  my $cgi = $_;

  # from templates/
  my $tx = Text::Xslate->new(path => ['templates']);

  # or from __DATA__
  my $tx = Text::Xslate->new(path => [get_data_section]);

  my $foo = $cgi->query_param('foo');
  $cgi->render(html => $tx->render('index.tx', {foo => $foo}));
};

__DATA__
@@ index.tx
<html><body><h1><: $foo :></h1></body></html>
