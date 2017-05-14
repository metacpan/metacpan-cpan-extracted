BEGIN {
    my @options = (
        '+ignore' => 'Data/Dumper',
        '+select' => 'DBIx::PreQL',
    );
    require Devel::Cover
        &&  Devel::Cover->import( @options )
        if  $ENV{COVER};
}

use strict;
use warnings;
use Data::Dumper;

use Test::More;

use_ok( 'DBIx::PreQL' );

#  Verify behavior of standard, simple tags:
#
#       *  &  |   #

{   ## TAG  *
    #  - always include
    #  - !! dies
    #  - ?? dies if absent
    #  - ?? works if present
    my %in = (
        plain => " *  plain text",
        nph   => " *  nph : ?nph?",
        dep   => " *  dep   !dep!",
    );

    my %out = (
        plain => "plain text",
        nph   => "nph : ?",
        dep   => "dep",
    );

    {   #  - always include
        #  - ?? works if present
        my( $query, @params ) = DBIx::PreQL->build_query(
                query => _fmt( \%in, qw/ plain nph / ),
                data  => { nph => 'NPH' },
            );

        my $expect_q = _fmt( \%out, qw/ plain nph / ),
        my @expect_p = ('NPH');

        is( $query, $expect_q, 'TAG * generated expected query' );
        is_deeply( \@params, \@expect_p, 'TAG * generated expected params' );
    }

    {   #  - !! dies
        my $e;
        eval {  DBIx::PreQL::_parse_query(
                query => _fmt( \%in, qw/ dep / ),
                data  => {},
            ); 1
        } or do { $e = $@ };
        ok( $e, 'TAG * dies with dependencies' );
    }

    {   #  - ?? dies if absent
        my $e;
        eval {  DBIx::PreQL::_parse_query(
                query => _fmt( \%in, qw/ nph / ),
                data  => {},
            ); 1
        } or do { $e = $@ };
        ok( $e, 'TAG * dies with missing placeholder' );
    }

}

{   ## TAG  #
    #  - never include
    #  - !! does nothing
    #  - ?? does nothing
    my %in = (
        plain => " #  plain text",
        nph   => " #  nph : ?nph?",
        dep   => " #  dep   !dep!",
    );

    {   #  - never include
        #  - !! does nothing
        #  - ?? does nothing
        my( $query, @params ) = DBIx::PreQL->build_query(
                query => _fmt( \%in, qw/ plain nph dep / ),
                data  => { nph => 'NPH' },
            );

        my $expect_q = '';
        my @expect_p = ();

        is( $query, $expect_q, 'TAG # generated expected query' );
        is_deeply( \@params, \@expect_p, 'TAG # generated expected params' );
    }

}


{   ## TAG  &
    #  - include when ALL ?? !! present
    #  - include when ALL !! present
    #  - include when ALL ?? present
    #  - skip  when missing ??
    #  - skip  when missing !!
    #  - die when NO ??  !! present
    my %in = (
        plain => " &  plain text",
        nph   => " &  nph : ?nph?",
        dep   => " &  dep   !dep!",
        both  => " &  nph : ?nph2? - dep   !dep2!",
    );

    my %out = (
        plain => "plain text",
        nph   => "nph : ?",
        dep   => "dep",
        both  => "nph : ? - dep",
    );

    {   #  - include when ALL ?? !! present
        #  - include when ALL !! present
        #  - include when ALL ?? present
        my( $query, @params ) = DBIx::PreQL->build_query(
                query => _fmt( \%in, qw/ nph dep both / ),
                data  => { nph => 'NPH', dep => 'dep', nph2 => 'NPH2', dep2 => 'dep' },
            );

        my $expect_q = _fmt( \%out, qw/ nph dep both / ),
        my @expect_p = ('NPH', 'NPH2');

        is( $query, $expect_q, 'TAG & generated expected query' );
        is_deeply( \@params, \@expect_p, 'TAG & generated expected params' );
    }

    {   #  - include when ALL !! present
        #  - include when ALL ?? present
        #  - skip  when missing ??
        my( $query, @params ) = DBIx::PreQL->build_query(
                query => _fmt( \%in, qw/ nph dep both / ),
                data  => { nph => 'NPH' },
            );

        my $expect_q = _fmt(\%out, qw/ nph / );
        my @expect_p = ('NPH');

        is( $query, $expect_q, 'TAG & generated expected query' );
        is_deeply( \@params, \@expect_p, 'TAG & generated expected params' );
    }

    {   #  - include when ALL !! present
        #  - skip  when missing !!
        my( $query, @params ) = DBIx::PreQL->build_query(
                query => _fmt( \%in, qw/ nph dep both / ),
                data  => { dep => 'dep' },
            );

        my $expect_q = _fmt(\%out, qw/ dep / );
        my @expect_p = ();

        is( $query, $expect_q, 'TAG & generated expected query' );
        is_deeply( \@params, \@expect_p, 'TAG & generated expected params' );
    }


    {   #  - die when NO ?? !! present
        my $e;
        eval {  DBIx::PreQL::_parse_query(
            query => _fmt( \%in, qw/ plain / ),
            data  => {},
            ); 1
        } or do { $e = $@ };
        ok( $e, 'TAG & dies with no placeholders or dependencies specified' );
    }

}

{   ## TAG  |
    #  - include when ALL ?? and ANY !! present
    #  - include when NO ?? !! present    TODO verify
    #  - die if ANY ?? missing
    #  - die when NO ??  !! present
    #  - die when NO !! present

    my %in = (
        plain => " |  plain text",
        nph   => " |  nph : ?nph?",
        dep   => " |  dep   !dep!",
        both  => " |  nph : ?nph2? - dep   !dep2!",
    );

    my %out = (
        plain => "plain text",
        nph   => "nph : ?",
        dep   => "dep",
        both  => "nph : ? - dep",
    );

    {   #  - include when ALL ?? and ANY !! present

        my( $query, @params ) = DBIx::PreQL->build_query(
                query => _fmt( \%in, qw/ dep both / ),
                data  => { nph => 'NPH', dep => 'dep', nph2 => 'NPH2', dep2 => 'dep' },
            );

        my $expect_q = _fmt( \%out, qw/ dep both / ),
        my @expect_p = ('NPH2');

        is( $query, $expect_q, 'TAG | generated expected query' );
        is_deeply( \@params, \@expect_p, 'TAG | generated expected params' );
    }

    {   #  - die when NO ?? !! present
        my $e;
        eval {  DBIx::PreQL::_parse_query(
                query => _fmt( \%in, qw/ nph / ),
                data  => { nph => 'NPH' },
            ); 1
        } or do { $e = $@ };
        ok( $e, 'TAG | dies with no dependencies specified' );
    }

    {   #  - die when NO ?? !! present
        my $e;
        eval {  DBIx::PreQL::_parse_query(
                query => _fmt( \%in, qw/ plain / ),
                data  => {},
            ); 1
        } or do { $e = $@ };
        ok( $e, 'TAG | dies with no placeholders or dependencies specified' );
    }

}

done_testing();

sub _fmt {
    my $data = shift;
    return join "\n", @{$data}{@_};
}

