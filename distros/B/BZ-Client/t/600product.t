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
use utf8;

use lib 't/lib';

use BZ::Client::Test;
use BZ::Client::Product;
use Test::More;

#use Data::Dumper;
#$Data::Dumper::Indent   = 1;
#$Data::Dumper::Sortkeys = 1;

# these next three lines need more thought
use Test::RequiresInternet ( 'landfill.bugzilla.org' => 443 );
my @bugzillas = do 't/servers.cfg';

plan tests => ( scalar @bugzillas * 19 ) + 20;

my $tester;

sub quoteme {
    my @args = @_;
    for my $foo (@args) {
        $foo =~ s{\n}{\\n}g;
        $foo =~ s{\r}{\\r}g;
    }
    @args;
}

my %quirks = (

    '5.0' => {
        products => {
            1 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'WorldControl',
                description =>
"A small little program for controlling the world. Can be used\r\nfor good or for evil. Sub-components can be created using the WorldControl API to extend control into almost any aspect of reality."
            },
            2 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'FoodReplicator',
                description =>
'Software that controls a piece of hardware that will create any food item through a voice interface.'
            },
            3 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'MyOwnBadSelf',
                description             => 'feh.'
            },
            4 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'Ѕpїdєr Séçretíøns',
                description             => 'Spider secretions'
            },
            19 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'Sam\'s Widget',
                description             => 'Special SAM widgets'
            },
        },
    },

    '4.4' => {
        products => {

        # Method: get_enterable_products
        # # Data: $VAR1 = [
        # #   '2',
        # #   '3',
        # #   '19',
        # #   '1',
        # #   '4'
        # # ];
        # ok 34 - Test out get_enterable_products
        # ok 35 - BZ::Client::Product implements method: get_accessible_products
        # ok 36 - No errors: get_accessible_products
        # # Method: get_accessible_products
        # # Data: $VAR1 = [
        # #   '2',
        # #   '3',
        # #   '19',
        # #   '1',
        # #   '4'
        # # ];
        #

            1 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'WorldControl',
                description =>
"A small little program for controlling the world. Can be used\r\nfor good or for evil. Sub-components can be created using the WorldControl API to extend control into almost any aspect of reality.",
            },
            2 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'FoodReplicator',
                description =>
'Software that controls a piece of hardware that will create any food item through a voice interface.'
            },
            3 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'MyOwnBadSelf',
                description             => 'feh.'
            },
            4 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'Spider Séçretíøns',
                description             => 'Spider secretions'
            },
            19 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'Sam\'s Widget',
                description             => 'Special SAM widgets'
            },
            20 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'LJL Test Product',
                description             => 'Test product description'
            },
            21 => {
                get_enterable_products  => 1,
                get_accessible_products => 1,
                get_selectable_products => 1,
                name                    => 'testing-funky-hyphens',
                description             => 'Hyphen testing product'
            },
        },
    },

);

sub TestGetList {
    my ( $method, $allowEmpty ) = @_;
    my $client = $tester->client();
    my $ids;
  SKIP: {
        skip( "BZ::Client::Product cannot do method: $method ?", 1 )
          unless ok( BZ::Client::Product->can($method),
            "BZ::Client::Product implements method: $method" );

        eval {
            $ids = BZ::Client::Product->$method($client);
            $client->logout();
        };

        if ($@) {
            my $err = $@;
            my $msg;
            if ( ref($err) eq 'BZ::Client::Exception' ) {
                $msg =
                  'Error: '
                  . (
                    defined( $err->http_code() ) ? $err->http_code() : 'undef' )
                  . ', '
                  . (
                    defined( $err->xmlrpc_code() )
                    ? $err->xmlrpc_code()
                    : 'undef'
                  )
                  . ', '
                  . ( defined( $err->message() ) ? $err->message() : 'undef' );
            }

            else {
                $msg = "Error $err";
            }
            ok( 0, 'No errors: ' . $method );
            diag($msg);
            return;
        }
        else {
            ok( 1, 'No errors: ' . $method );
        }

        if ( !$ids or ref $ids ne 'ARRAY' or ( !$allowEmpty and !@$ids ) ) {
            diag q/No product ID's returned./;
            return;
        }

        {
            is_deeply( # this may prove too fragile, as changes on landfil will break it
                [ sort @$ids ],
                [
                    sort grep {
                        $quirks{ $tester->{version} }{products}{$_}{$method}
                    } keys %{ $quirks{ $tester->{version} }{products} }
                ],
                'IDs returned correctly for: ' . $method
            ) or diag $method . ', ID: ' . join( ', ', sort @$ids );
        }

        return $ids

    }
}

sub TestGet {
    my $client = $tester->client();

    my $ids;
    my $products;
    eval {
        $ids = BZ::Client::Product->get_accessible_products($client);
        $products = BZ::Client::Product->get( $client, { ids => $ids } );
        $client->logout();
    };

    if ($@) {
        my $err = $@;
        my $msg;
        if ( ref $err eq 'BZ::Client::Exception' ) {
            $msg =
                'Error: '
              . ( defined( $err->http_code() ) ? $err->http_code() : 'undef' )
              . ', '
              . (
                defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code() : 'undef' )
              . ', '
              . ( defined( $err->message() ) ? $err->message() : 'undef' );
        }
        else {
            $msg = "Error $err\n";
        }
        ok( 0, 'No errors: get' );
        diag($msg);
        return;
    }
    else {
        ok( 1, 'No errors: get' );
    }

    my $return;

    # careful of the list context, scalar () forces it to be a number
    ok(
        scalar @$ids == scalar(
            grep {
                my $id = $_;
                grep { $_->id() eq $id } @$products
            } @$ids
        ),
'A corresponding product for every product ID returned by the server was found.'
    ) and $return = 1;

    {
        is_deeply(
            [ sort @$ids ],
            [
                sort grep {
                    $quirks{ $tester->{version} }{products}{$_}
                      {get_accessible_products}
                } keys %{ $quirks{ $tester->{version} }{products} }
            ],
            'Found every ID known to this test'
          )
          ? $return = 1
          : diag 'ID: ' . join( ', ', sort @$ids );
    }

    my @unnamed = grep { !$_->name() } @$products;
    ok( !@unnamed, 'All products have a name' )
      and $return = 1;

    diag( map { 'The name of product ' . $_->id() . ' is not set.' } @unnamed )
      if @unnamed;

    for my $p ( sort { $a->id <=> $b->id } @$products ) {
        my $product = $quirks{ $tester->{version} }{products}{ $p->id };
        unless ($product)
        { # since landfill can be changed by *anyone*, we diag but otherwise ignore unknowns
            diag 'Server provided unknown product, ID: ' . $p->id;
            diag sprintf(
                q|name: '%s' description: '%s'|,
                quoteme( $p->name ),
                quoteme( $p->description )
            );
            next;
        }
        ok( $product->{name} eq $p->name,
            'Product name of ID: ' . $p->id . ' matches' )
          and ok(
            $product->{description} eq $p->description,
            'Product description of ID: ' . $p->id . ' matches'
          )
          or diag 'Got: '
          . $p->id
          . ' => { name => "'
          . $p->name
          . '", description => "'
          . $p->description
          . qq|"}, \nAim: name = "|
          . $product->{name}
          . '" description = "'
          . $product->{description} . '"';
    }

    return $return;
}

for my $server (@bugzillas) {

    diag sprintf 'Trying server: %s', $server->{testUrl} || '???';

    $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

  SKIP: {
        skip( 'No Bugzilla server configured, skipping', 4 )
          if $tester->isSkippingIntegrationTests();

        ok(
            TestGetList('get_selectable_products'),
            'Test out get_selectable_products'
        );
        ok(
            TestGetList( 'get_enterable_products', 1 ),
            'Test out get_enterable_products'
        );
        ok(
            TestGetList('get_accessible_products'),
            'Test out get_accessible_products'
        );
        ok( TestGet(), 'Test out getting each product one by one' );

    }

}
