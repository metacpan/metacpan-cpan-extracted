
use strict;
use warnings;

use Test::More;
use Test::Fatal qw( exception );
use App::cpanoutdated::fresh;

# FILENAME: attributes.t
# CREATED: 08/30/14 22:00:04 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test attributs

my $instance = App::cpanoutdated::fresh->new();

sub attr {
  my ($name) = @_;
  my $value;
  is( exception { $value = $instance->$name(); 1 }, undef, "Get attribute $name" );
  return $value;
}

sub bad_attr {
  my ($name) = @_;
  my $value;
  isnt( exception { $value = $instance->$name(); 1 }, undef, "Attribute $name should bail" )
    or diag "Got: $value";
}

attr('trace');
attr('es');
attr('_sort');
attr('scroll_size');
attr('age');
attr('age_seconds');
attr('min_timestamp');
attr('developer');
attr('all_versions');
attr('authorized');
attr('_inc_scanner');

use HTTP::Tiny;
$instance = App::cpanoutdated::fresh->new( ua => HTTP::Tiny->new() );

attr('es');

$instance = App::cpanoutdated::fresh->new(
  trace => 1,
  ua    => HTTP::Tiny->new()
);

attr('es');

$instance = App::cpanoutdated::fresh->new( age => '7notoneletter', );
bad_attr('age_seconds');

$instance = App::cpanoutdated::fresh->new( age => '7z', );
bad_attr('age_seconds');

$instance = App::cpanoutdated::fresh->new( age => '7Y', );
attr('age_seconds');

$instance = App::cpanoutdated::fresh->new( age => '7', );
attr('age_seconds');

$instance = App::cpanoutdated::fresh->new( age => '7.7.7', );
bad_attr('age_seconds');

done_testing;

