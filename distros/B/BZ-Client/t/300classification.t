#!/usr/bin/env perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        print qq{1..0 # SKIP these tests only run with AUTHOR_TESTING set\n};
        exit
    }
}

use strict;
use warnings 'all';

use lib 't/lib';

use BZ::Client::Test();
use BZ::Client::Classification();
use Test::More;

use Data::Dumper;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;

# these next three lines need more thought
use Test::RequiresInternet ( 'landfill.bugzilla.org' => 443 );
my @bugzillas = do 't/servers.cfg';

plan tests => ( scalar @bugzillas * 3 );

my $tester;

my %quirks = (
    '4.4' => [
  {
    'description' => 'Unassigned to any classifications',
    'id' => '1',
    'name' => 'Unclassified',
    'products' => [
      {
        'description' => 'Software that controls a piece of hardware that will create any food item through a voice interface.',
        'id' => '2',
        'name' => 'FoodReplicator'
      },
      {
        'description' => 'Test product description',
        'id' => '20',
        'name' => 'LJL Test Product'
      },
      {
        'description' => 'Spider secretions',
        'id' => '4',
        'name' => "Spider S\x{e9}\x{e7}ret\x{ed}\x{f8}ns"
      },
      {
        'description' => 'Hyphen testing product',
        'id' => '21',
        'name' => 'testing-funky-hyphens'
      }
    ],
    'sort_key' => '0'
  },
  {
    'description' => 'Because classifications do exist',
    'id' => '2',
    'name' => 'Mercury',
    'products' => [
      {
        'description' => 'feh.',
        'id' => '3',
        'name' => 'MyOwnBadSelf'
      },
      {
        'description' => "A small little program for controlling the world. Can be used\r\nfor good or for evil. Sub-components can be created using the WorldControl API to extend control into almost any aspect of reality.",
        'id' => '1',
        'name' => 'WorldControl'
      }
    ],
    'sort_key' => '16'
  },
  {
    'description' => 'All widgets get classiciation of widget',
    'id' => '3',
    'name' => 'Widgets',
    'products' => [
      {
        'description' => 'Special SAM widgets',
        'id' => '19',
        'name' => 'Sam\'s Widget'
      }
    ],
    'sort_key' => '0'
  },
    ],
    '5.0' => [
  {
    'description' => 'Unassigned to any classifications',
    'id' => '1',
    'name' => 'Unclassified',
    'products' => [
      {
        'description' => 'Software that controls a piece of hardware that will create any food item through a voice interface.',
        'id' => '2',
        'name' => 'FoodReplicator'
      },
      {
        'description' => 'Spider secretions',
        'id' => '4',
        'name' => "\x{405}p\x{457}d\x{454}r S\x{e9}\x{e7}ret\x{ed}\x{f8}ns"
      }
    ],
    'sort_key' => '0'
  },
  {
    'description' => 'Because classifications do exist',
    'id' => '2',
    'name' => 'Mercury',
    'products' => [
      {
        'description' => 'feh.',
        'id' => '3',
        'name' => 'MyOwnBadSelf'
      },
      {
        'description' => "A small little program for controlling the world. Can be used\r\nfor good or for evil. Sub-components can be created using the WorldControl API to extend control into almost any aspect of reality.",
        'id' => '1',
        'name' => 'WorldControl'
      }
    ],
    'sort_key' => '16'
  },
  {
    'description' => 'All widgets get classiciation of widget',
    'id' => '3',
    'name' => 'Widgets',
    'products' => [
      {
        'description' => 'Special SAM widgets',
        'id' => '19',
        'name' => 'Sam\'s Widget'
      }
    ],
    'sort_key' => '0'
  },
    ],

);

sub TestClassification {
    my ( $params, $emptyOk ) = @_;
    my $client = $tester->client();
    my $class;
    eval {
        $class = BZ::Client::Classification->get( $client, $params );
        $client->logout();
    };
    if ($@) {
        my $err = $@;
        my $msg;
        if ( ref($err) eq 'BZ::Client::Exception' ) {
            $msg = 'Error: '
              . ( defined( $err->http_code() ) ? $err->http_code()     : 'undef' ) . ', '
              . ( defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code() : 'undef' ) . ', '
              . ( defined( $err->message() ) ? $err->message()         : 'undef' );
        }
        else {
            $msg = "Error: $err";
        }
        diag("$msg\n");
        return;
    }
    if ( !$class || ref($class) ne 'ARRAY' || ( !$emptyOk && !@$class ) ) {
        diag "No class returned.\n";
        return;
    }
    return $class;
}

for my $server (@bugzillas) {

    diag sprintf 'Trying server: %s', $server->{testUrl} || '???';

    $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

  SKIP: {

        skip( 'No Bugzilla server configured, skipping', 6 )
          if $tester->isSkippingIntegrationTests();

       for my $c (@{$quirks{ $tester->{version} }}) {
           my $class = TestClassification( { ids => [ $c->{id} ] } );
           is_deeply([$c], $class, sprintf('ID %d for bz version %s',$c->{id},$tester->{version}))
               or print Dumper $class;
       }

    }

} # for my $server
