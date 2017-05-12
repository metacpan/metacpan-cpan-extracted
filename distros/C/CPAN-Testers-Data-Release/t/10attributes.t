#!/usr/bin/perl -w
use strict;

use CPAN::Testers::Data::Release;
use Test::More tests => 13;

my $config = 't/_DBDIR/10attributes.ini';

SKIP: {
    skip "Test::Database required for DB testing", 13 unless(-f $config);

    my $obj;
    eval { $obj = CPAN::Testers::Data::Release->new(config => $config) };
    diag($@) if($@);
    isa_ok($obj,'CPAN::Testers::Data::Release');

    SKIP: {
        skip "Problem creating object", 12 unless($obj);

        # Class::Accessor::Fast method tests

        # predefined attributes
        foreach my $k ( qw/
            idfile
            logclean
        / ){
          my $label = "[$k]";
          SKIP: {
            ok( $obj->can($k), "$label can" ) or skip "'$k' attribute missing", 3;
            isnt( $obj->$k(), undef, "$label has default" );
            is( $obj->$k(123), 123, "$label set" ); # chained, so returns object, not value.
            is( $obj->$k, 123, "$label get" );
          };
        }

        # undefined attributes
        foreach my $k ( qw/
            logfile
        / ){
          my $label = "[$k]";
          SKIP: {
            ok( $obj->can($k), "$label can" ) or skip "'$k' attribute missing", 3;
            is( $obj->$k(), undef, "$label has no default" );
            is( $obj->$k(123), 123, "$label set" ); # chained, so returns object, not value.
            is( $obj->$k, 123, "$label get" );
          };
        }
    }
}
