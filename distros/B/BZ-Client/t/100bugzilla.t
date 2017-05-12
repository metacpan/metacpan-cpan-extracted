#!/usr/bin/env perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab
BEGIN {
    unless ($ENV{TEST_AUTHOR}) {
        print qq{1..0 # SKIP these tests only run with TEST_AUTHOR set\n};
        exit
    }
}

use strict;
use warnings 'all';

use lib 't/lib';

use BZ::Client::Test;
use BZ::Client::Bugzilla;
use Test::More;

# these next three lines need more thought
use Test::RequiresInternet ( 'landfill.bugzilla.org' => 443 );

plan tests => 61; #89;

my @bugzillas = do 't/servers.cfg';

my $tester;

my %quirks = (
    '5.0' => { 'extensions' => 0, parameters => 1, last_audit_time => 1 },
    '4.4' => { 'extensions' => 1, parameters => 1, last_audit_time => 1 },
    '4.2' => { 'extensions' => 0, parameters => 0, last_audit_time => 0 },
);

sub TestCall {
    my ( $method ) = @_;
    my $client = $tester->client();
    my $values;
    SKIP: {
        skip( "BZ::Client::Bugzilla cannot do method: $method ?", 1 )
            unless ok( BZ::Client::Bugzilla->can($method),
                       "BZ::Client::Bugzilla implements method: $method" );

        eval {
            $values = BZ::Client::Bugzilla->$method($client);
            $client->logout();
        };

        if ($@) {
            my $err = $@;
            my $msg;
            if ( ref $err eq 'BZ::Client::Exception' ) {
                $msg = 'Error: '
                  . ( defined( $err->http_code() )   ? $err->http_code()   : 'undef' ) . ', '
                  . ( defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code() : 'undef' ) . ', '
                  . ( defined( $err->message() )     ? $err->message()     : 'undef' );
            }
            else {
                $msg = "Error $err";
            }
            ok( 0, 'No errors: ' . $method );
            diag($msg);
            return
        }
        else {
            ok( 1, 'No errors: ' . $method )
        }
        return $values
    }
}

for my $server (@bugzillas) {

    diag sprintf 'Trying server: %s', $server->{testUrl} || '???';

    $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

  SKIP: {
        skip( 'No Bugzilla server configured, skipping', 11 )
          if $tester->isSkippingIntegrationTests();

        {
            my $version = TestCall( 'version' );
            ok( ( $version and not ref $version ),
                'Got a something from ->version() but not a ref' );
            $version ||= 'NOT IN HASH!';
            like(
                $version,
                qr/^\d+\.\d+(\.\d+)?(\-\d+)?\+?$/,
                'Resembles a version number'
            );
            diag("Server says version; $version");

            like( $version, qr/^$server->{version}/,
                'Server version matches server.cfg' );
        }

        {
            my $tz = TestCall( 'timezone' );
            ok( ( $tz and not ref $tz ),
                'Got something from ->timezone() but not a ref' );
            $tz ||= '????';
            like( $tz, qr/^[-+]\d\d\d\d$/, 'Resembles a Time offset' );
            ok( $tz eq '+0000', 'Should always be +0000' );
        }
        {
            my $values = TestCall( 'time' );
            ok(
                ( ref $values eq 'HASH' ),
                'Got something from "time" call'
            );

            like( $values->{'tz_name'}, qr!^(\w+/\w+|UTC)$!,
                'Resembles a Timezone name' );
            ok(
                $values->{'tz_name'} eq 'UTC',
                'Timezone name should always be UTC'
            );

            like( $values->{'tz_short_name'},
                qr!^(\w+/\w+|UTC)$!, 'Resembles a Timezone short name' );
            ok(
                $values->{'tz_short_name'} eq 'UTC',
                'Timezone short name should always be UTC'
            );

            ok( ref $values->{'web_time'} eq 'DateTime',
                'web_time should be DateTime' );
            ok(
                ref $values->{'web_time_utc'} eq 'DateTime',
                'web_time_utc should be DateTime'
            );
            ok( ref $values->{'db_time'} eq 'DateTime',
                'db_time should be DateTime' );

        }

      SKIP: {
            skip( 'I wont look at parameters for this server', 3 )
              unless ($server->{version}
                  and $quirks{ $server->{version} }->{parameters});
            my $values = TestCall( 'parameters' );
            ok(
                ( ref $values eq 'HASH' ),
                'Got a hashref from ->parameters()'
            );
            ok( scalar keys %$values, 'Got something inside Parameters' );
        }

      SKIP: {
            skip( 'I wont look at last_audit_time for this server', 2 )
              unless ($server->{version}
                  and $quirks{ $server->{version} }->{last_audit_time});
            my $values = TestCall( 'last_audit_time' );
            ok(
                ( ref $values eq 'DateTime' ),
                'Got DateTime from Last Audit Time'
            );
        }

      SKIP: {
            skip( 'I wont look at extensions for this server', 3 )
              unless ($server->{version}
                  and $quirks{ $server->{version} }->{extensions});
            my $values = TestCall( 'extensions' );
            ok(
                ( ref $values eq 'HASH' ),
                'Got a hashref from Extensions'
            );
            ok( scalar keys %$values, 'Got something inside Extensions' );
        }

    }

}
