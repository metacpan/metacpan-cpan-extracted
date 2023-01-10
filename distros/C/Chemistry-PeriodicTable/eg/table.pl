#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Chemistry-PeriodicTable);
use Chemistry::PeriodicTable ();

get '/' => sub ($c) {
  my $pt = Chemistry::PeriodicTable->new;
  my $headers = $pt->header;
  my $elements = $pt->data;
  $c->render(
    template => 'index',
    headers  => $headers,
    elements => $elements,
  );
} => 'index';

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
<table class="table table-sm table-hover">
  <thead>
    <tr>
% for my $i (@$headers) {
      <th scope="col"><%= $i %></th>
% }
    </tr>
  </thead>
  <tbody>
% for my $i (sort { $elements->{$a}[19] <=> $elements->{$b}[19] || $elements->{$a}[20] <=> $elements->{$b}[20] } keys %$elements) {
    <tr>
%   for my $j (@{ $elements->{$i} }) {
      <td><%= $j %></td>
%   }
    </tr>
% }
  </tbody>
</table>

@@ layouts/default.html.ep
% title 'Periodic Table';
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    <script src="https://cdn.jsdelivr.net/npm/jquery@3.5.1/dist/jquery.slim.min.js" integrity="sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/js/bootstrap.min.js" integrity="sha384-+sLIOodYLS7CIrQpBjl+C7nPvqq+FbNUBDunl/OZv93DB7Ln/533i8e/mZXLi/P+" crossorigin="anonymous"></script>
    <title><%= title %></title>
    <style>
      .padpage {
        padding-top: 10px;
        padding-left: 10px;
        padding-bottom: 10px;
        padding-right: 10px;
      }
      .small {
        font-size: small;
        color: darkgrey;
      }
      .danger {
        color: red;
      }
    </style>
  </head>
  <body>
    <div class="padpage">
<%= content %>
      <p></p>
      <div class="small">
        <hr>
        Built by <a href="http://gene.ology.net/">Gene</a>
        with <a href="https://www.perl.org/">Perl</a> and
        <a href="https://mojolicious.org/">Mojolicious</a>
      </div>
    </div>
  </body>
</html>
