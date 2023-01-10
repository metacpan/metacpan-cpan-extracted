#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Chemistry-PeriodicTable);
use Chemistry::PeriodicTable ();

get '/' => sub ($c) {
  my $pt = Chemistry::PeriodicTable->new;
  my $elements = $pt->data;
  $c->render(
    template => 'index',
    elements => $elements,
  );
} => 'index';

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
<table class="table table-sm table-bordered">
  <tbody>
% my $phases = {
%   gas     => 'red',
%   liquid  => 'blue',
%   solid   => 'black',
%   unknown => 'gray',
% };
% my $types = {
%   '' => 'gainsboro',
%   'Actinide'              => 'pink',
%   'Alkali Metal'          => 'gold',
%   'Alkaline Earth Metal'  => 'lightyellow',
%   'Lanthanide'            => 'wheat',
%   'Transition Metal'      => 'sandybrown',
%   'Metalloid'             => 'lightcyan',
%   'Noble Gas'             => 'plum',
%   'Reactive Nonmetal'     => 'lightgreen',
%   'Transactinide'         => 'lavender',
%   'Post-transition Metal' => 'lightblue',
% };
% for my $row (1 .. 9) {
    <tr>
%   my $col = 0;
%   for my $i (sort { $elements->{$a}[19] <=> $elements->{$b}[19] || $elements->{$a}[0] <=> $elements->{$b}[0] } keys %$elements) {
%     next if $elements->{$i}[19] < $row;
%     last if $elements->{$i}[19] > $row;
%     $col++;
%     if ($elements->{$i}[20] - 1 > $col) {
%       for my $j ($col + 1 .. $elements->{$i}[20]) {
      <td>&nbsp;</td>
%         $col++;
%       }
%     }
%     if ($row >= 6 && $col == 3) {
      <td>&nbsp;</td>
%     }
      <td title="<%= $elements->{$i}[1] %>" style="background-color: <%= $types->{ $elements->{$i}[8] } %>;">
        <%= $elements->{$i}[0] %>
        <br>
        <b><span style="color: <%= $phases->{ $elements->{$i}[6] } %>"><%= $elements->{$i}[2] %></span></b>
        <br>
        <%= sprintf '%.3f', $elements->{$i}[3] %>
      </td>
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
