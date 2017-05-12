#!/usr/bin/perl 

use strict;
use lib '../lib';
use Data::Dumper;
use Continuity;

Continuity->new->loop;

sub main {
  my $r = shift;
  $r->print(qq|
    <h2>Parameter Passing Example</h2>
    <p>Fill out this form, and I will show you what I learned! This is an
    example of some Continuity::Request parameter-getting methods.</p>
    <form>
      Name: <input type=text name=name>
      <br>
      Favorite Thing #1: <input type=text name=favorite>
      <br>
      Favorite Thing #2: <input type=text name=favorite>
      <br>
      Favorite Thing #3: <input type=text name=favorite>
      <br>
      <input type=submit name="show_results" value="Show Params">
    </form>
  |);
  $r->next;
  my $name = $r->param('name');
  my $first_fav = $r->param('favorite');
  my @favs = $r->param('favorite');
  my %all_hash  = $r->params;
  my @all_array = $r->params;
  my @alt_array = $r->param;

  $r->print(qq|
    <h2>Okay... this is what I got...</h2>
    Name: "$name"<br>
    First Fav: "$first_fav"<br>
    Favs: @{[ join ',', map { "'$_'" } @favs ]}<br>
    All hash:
    <pre>
      @{[ Dumper(\%all_hash) ]}
    </pre>
    <br>
    All array:
    <pre>
      @{[ Dumper(\@all_array) ]}
    </pre>
    <br>
    Alternate array:
    <pre>
      @{[ Dumper(\@alt_array) ]}
    </pre>

  |);
}

