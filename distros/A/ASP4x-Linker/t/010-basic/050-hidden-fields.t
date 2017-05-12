#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use ASP4::API;
use ASP4x::Linker;

my $api; BEGIN { $api = ASP4::API->new }

$api->ua->get('/');

ok( my $linker = ASP4x::Linker->new );

$linker->add_widget(
  name  => 'artists',
  attrs => [qw( page_number page_size )]
);

$linker->add_widget(
  name  => 'albums',
  attrs => [qw( page_number page_size )]
);

is
  $linker->hidden_fields() =>
  q(<input type="hidden" name="albums.page_size" value="" />
<input type="hidden" name="artists.page_number" value="" />
<input type="hidden" name="albums.page_number" value="" />
<input type="hidden" name="artists.page_size" value="" />),
  "Hidden Fields look right";

$linker->widget('albums')->set( page_number => 1 );
is
  $linker->hidden_fields() =>
  q(<input type="hidden" name="albums.page_size" value="" />
<input type="hidden" name="artists.page_number" value="" />
<input type="hidden" name="albums.page_number" value="1" />
<input type="hidden" name="artists.page_size" value="" />),
  "Hidden Fields look right";

is
  $linker->hidden_fields() =>
  q(<input type="hidden" name="albums.page_size" value="" />
<input type="hidden" name="artists.page_number" value="" />
<input type="hidden" name="albums.page_number" value="" />
<input type="hidden" name="artists.page_size" value="" />),
  "Auto-reset works";

my $args = {
  albums => { page_size => 20, page_number => 4 },
  artists => { page_size => 5, page_number => 10 }
};
is
  $linker->hidden_fields($args) =>
  q(<input type="hidden" name="albums.page_size" value="20" />
<input type="hidden" name="artists.page_number" value="10" />
<input type="hidden" name="albums.page_number" value="4" />
<input type="hidden" name="artists.page_size" value="5" />),
  "Auto-reset works";



