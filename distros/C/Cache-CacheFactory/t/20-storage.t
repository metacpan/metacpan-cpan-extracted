#!perl -T

use strict;
use warnings;

use Test::More;
use Cache::CacheFactory;
use Cache::CacheFactory::Storage;

my @storage_types = Cache::CacheFactory::Storage->get_registered_types();

my %vals = (
    'scalar'   => 'value for scalar key',
    'arrayref' => [ qw/value for arrayref key/ ],
    'hashref'  => { value => 'for', hashref => 'key' },
    );
my %replace_vals = (
    'scalar'   => 'value for scalar key for replace',
    'arrayref' => [ qw/value for arrayref key for replace/ ],
    'hashref'  => { value => 'for', hashref => 'key', 'for' => 'replace', },
    );
my @sorted_keys = sort( keys( %vals ) );

my $namespace = 'CacheFactory_test_namespace';

my $tests_per_data_type         = 9;
my $tests_per_storage_type_only = 6;

my $tests_per_storage_type =
    $tests_per_storage_type_only +
    ( $tests_per_data_type * scalar( keys( %vals ) ) );

plan tests => ( $tests_per_storage_type * scalar( @storage_types ) );

foreach my $storage_type ( @storage_types )
{
    SKIP:
    {
        my ( $storage_module, $cache );

        $storage_module = Cache::CacheFactory::Storage->get_registered_class( $storage_type );
        eval "use $storage_module";
        skip "$storage_module required for testing $storage_type storage policies" => $tests_per_storage_type if $@;

        ok( $cache = Cache::CacheFactory->new(
            storage   => $storage_type,
            namespace => $namespace,
            ), "construct $storage_type cache" );

        foreach my $key ( qw/scalar arrayref hashref/ )
        {
            $cache->set(
                key          => $key,
                data         => $vals{ $key },
                );

            if( $storage_type eq 'null' )
            {
                is( $cache->get( $key ), undef, "$storage_type $key fetch" );
                is( $cache->exists( $key ), 0,  "$storage_type $key exists" );
            }
            elsif( $key eq 'scalar' )
            {
                is( $cache->get( $key ), $vals{ $key },
                    "$storage_type $key fetch" );
                is( $cache->exists( $key ), 1,  "$storage_type $key exists" );
            }
            else
            {
                is_deeply( $cache->get( $key ), $vals{ $key },
                    "$storage_type $key fetch" );
                is( $cache->exists( $key ), 1,  "$storage_type $key exists" );
            }

            $cache->remove( $key );

            is( $cache->get( $key ), undef,
                "$storage_type post-remove $key fetch" );



            #  Test add/replace combinations.
            $cache->set(
                key          => $key,
                data         => $vals{ $key },
                );

            $cache->add(
                key          => $key,
                data         => "this shouldn't overwrite",
                );

            if( $storage_type eq 'null' )
            {
                is( $cache->get( $key ), undef,
                    "$storage_type $key pre-existing add fetch" );
            }
            elsif( $key eq 'scalar' )
            {
                is( $cache->get( $key ), $vals{ $key },
                    "$storage_type $key pre-existing add fetch" );
            }
            else
            {
                is_deeply( $cache->get( $key ), $vals{ $key },
                    "$storage_type $key pre-existing add fetch" );
            }

            $cache->replace(
                key          => $key,
                data         => $replace_vals{ $key },
                );

            if( $storage_type eq 'null' )
            {
                is( $cache->get( $key ), undef,
                    "$storage_type $key pre-existing replace fetch" );
            }
            elsif( $key eq 'scalar' )
            {
                is( $cache->get( $key ), $replace_vals{ $key },
                    "$storage_type $key pre-existing replace fetch" );
            }
            else
            {
                is_deeply( $cache->get( $key ), $replace_vals{ $key },
                    "$storage_type $key pre-existing replace fetch" );
            }



            $cache->delete( $key );

            is( $cache->get( $key ), undef,
                "$storage_type post-delete $key fetch" );

            $cache->replace(
                key          => $key,
                data         => $replace_vals{ $key },
                );

            if( $storage_type eq 'null' )
            {
                is( $cache->get( $key ), undef,
                    "$storage_type $key non-existing replace fetch" );
            }
            elsif( $key eq 'scalar' )
            {
                is( $cache->get( $key ), undef,
                    "$storage_type $key non-existing replace fetch" );
            }
            else
            {
                is( $cache->get( $key ), undef,
                    "$storage_type $key non-existing replace fetch" );
            }

            $cache->add(
                key          => $key,
                data         => $vals{ $key },
                );

            if( $storage_type eq 'null' )
            {
                is( $cache->get( $key ), undef,
                    "$storage_type $key non-existing add fetch" );
            }
            elsif( $key eq 'scalar' )
            {
                is( $cache->get( $key ), $vals{ $key },
                    "$storage_type $key non-existing add fetch" );
            }
            else
            {
                is_deeply( $cache->get( $key ), $vals{ $key },
                    "$storage_type $key non-existing add fetch" );
            }

            $cache->remove( $key );
        }

        foreach my $key ( qw/scalar arrayref hashref/ )
        {
            $cache->set(
                key          => $key,
                data         => $vals{ $key },
                );
        }

        if( $storage_type eq 'null' )
        {
            my ( %namespaces );

            is_deeply( [ sort( $cache->get_keys() ) ], [],
                "$storage_type get_keys" );
            is_deeply( [ sort( $cache->get_identifiers() ) ], [],
                "$storage_type get_identifiers" );
            #  Check that we're _not_ finding our namespace
            %namespaces = map { $_ => 1 } $cache->get_namespaces();
            ok( !$namespaces{ $namespace }, "$storage_type get_namespaces" );
        }
        else
        {
            my ( %namespaces );

            is_deeply( [ sort( $cache->get_keys() ) ], \@sorted_keys,
                "$storage_type get_keys" );
            is_deeply( [ sort( $cache->get_identifiers() ) ], \@sorted_keys,
                "$storage_type get_identifiers" );
            #  Can only check that we're finding our namespace, not the
            #  results of the entire call, because we can't predict what
            #  persistent namespaces already exist on the target system.
            %namespaces = map { $_ => 1 } $cache->get_namespaces();
            ok( $namespaces{ $namespace }, "$storage_type get_namespaces" );
        }

        #  Method tests to see that we trigger no errors:
        #  we can't predict the results of these, so we're
        #  just limited to seeing that they don't error.
        ok( $cache->size() || 1, "$storage_type size" );
        ok( $cache->Size() || 1, "$storage_type Size" );

        #  Finally, test that clear() works.
        $cache->clear();
        foreach my $key ( qw/scalar arrayref hashref/ )
        {
            is( $cache->get( $key ), undef,
                "$storage_type post-clear $key fetch" );
        }
    }
}
