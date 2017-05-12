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
use utf8;

use lib 't/lib';

use BZ::Client::Test;
use BZ::Client::User;
use Clone 'clone';
use Test::More;
use Text::Password::Pronounceable;
my $pp = Text::Password::Pronounceable->new(10,14);

use Data::Dumper;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;

# these next three lines need more thought
use Test::RequiresInternet ( 'landfill.bugzilla.org' => 443 );
my @bugzillas = do 't/servers.cfg';

plan tests => ( scalar @bugzillas * 21 + 16 );

my $tester;

sub quoteme {
    my @args = @_;
    for my $foo (@args) {
        $foo =~ s{\n}{\\n}g;
        $foo =~ s{\r}{\\r}g;
    }
    @args;
}

my %quirks;
$quirks{'5.0'}->{'offer_account_by_email'} = [
        # test insufficient arguments
        {
            params => { },
            error => {
                    xmlrpc => 50,
                    message => 'The function requires a email argument, and that argument was not set.',
            },
            response => undef,
        },
        # test error 500
        {
            params => { email => 'djzort@cpan.org' },
            error => {
                    xmlrpc => 500,
                    message => 'There is already an account with the login name djzort@cpan.org.'
            },
            response => undef,
        },
        # test error 500 with lazy syntax
        {
            params => 'djzort@cpan.org',
            error => {
                    xmlrpc => 500,
                    message => 'There is already an account with the login name djzort@cpan.org.'
            },
            response => undef,
        },
        # test error 501
        {
            params => { email => 'djzortATcpan.org' },
            error => {
                    xmlrpc => 501,
                    message => q|The e-mail address you entered (djzortATcpan.org) didn't pass our syntax checking for a legal email address. A legal address must contain exactly one '@', and at least one '.' after the @. It also must not contain any illegal characters.|,
            },
            response => undef,
        },
        {
            params => { email => sprintf('bz-client-testing-%s@cpan.org',$pp->generate) },
            response => 1,

        },
]; # 'offer_account_by_email' = [

# for now, all 4.4 tests are the same as 5.0
$quirks{'4.4'}->{'offer_account_by_email'} = $quirks{'5.0'}->{'offer_account_by_email'};

$quirks{'5.0'}->{get} = [
    # test insufficient arguments
    {
        params => { },
        error => {
            xmlrpc => 50,
            message => 'The function User.get requires that you set one of the following parameters: ids, names, match',
        },
        response => undef,
    },
    # search by name
    {
        params => { names => [ 'djzort@cpan.org' ] },
        response => [{
            'can_login' => '1',
            'email' => 'djzort@cpan.org',
            'groups' => [
              {
                'description' => 'Can confirm a bug.',
                'id' => '7',
                'name' => 'canconfirm'
              },
              {
                'description' => 'Can edit all aspects of any bug.',
                'id' => '6',
                'name' => 'editbugs'
              },
            ],
            'id' => '64995',
            'name' => 'djzort@cpan.org',
            'real_name' => 'Cpan Testing',
            'saved_reports' => [],
            'saved_searches' => []
          }],
    },
    # search by ids
    {
        params => { ids => [ 64995 ] },
        response => [{
            'can_login' => '1',
            'email' => 'djzort@cpan.org',
            'groups' => [
              {
                'description' => 'Can confirm a bug.',
                'id' => '7',
                'name' => 'canconfirm'
              },
              {
                'description' => 'Can edit all aspects of any bug.',
                'id' => '6',
                'name' => 'editbugs'
              },
            ],
            'id' => '64995',
            'name' => 'djzort@cpan.org',
            'real_name' => 'Cpan Testing',
            'saved_reports' => [],
            'saved_searches' => []
          }],
    },
    # check for no result search. error #51
    {
        params => { names => 'oremipsumdolorsitametconsecteturadipiscingelitnvariusodioeumagnaultriciesquisefficiturloremvenenatisaecenasauctor@cpan.org' },
        error => {
            xmlrpc => 51,
            message => q|There is no user named 'oremipsumdolorsitametconsecteturadipiscingelitnvariusodioeumagnaultriciesquisefficiturloremvenenatisaecenasauctor@cpan.org'. Either you mis-typed the name or that user has not yet registered for a Bugzilla account.|,
        },
        response => undef,

    },
    # check no result
    {
        params => { ids => 0e0, },
        response => [], # intentionally empty
    },
    # check error 52
    {
        params => { ids => 'asdf' },
        error => {
            xmlrpc => 52,
            message => q|Invalid parameter passed to Bugzilla::User::new_from_list: It must be numeric.|,
        },
        response => undef,
    },
    # check error 304 - TODO find a case that manifests this error number
    #{
    #    params => { ids => 1, },
    #    response => [], # intentionally empty
    #},
    # check error 505
    {
        logged_out => 1,
        params => { ids => [ 64995 ] },
        error => {
            message => 'Logged-out users cannot use the "ids" argument to this function to access any user information.',
            xmlrpc => 505,
        },
        response => undef,
    },
    # check error 804
    {
        params => { names => [ 'djzort@cpan.org' ], groups => 'asdf' },
        error => {
            xmlrpc => 804,
            message => q|The group you specified, asdf, is not valid here.|,
        },
        response => undef,
    },
];

$quirks{'4.4'}->{get} = [
    {
      params => { names => [ 'djzort@cpan.org' ] },
      response => [{
        'id' => '46062',
        'name' => 'djzort@cpan.org',
        'real_name' => 'Cpan Testing'
      }],
    },
    # check for no result search
    {
        params => { names => 'oremipsumdolorsitametconsecteturadipiscingelitnvariusodioeumagnaultriciesquisefficiturloremvenenatisaecenasauctor@cpan.org' },
        error => {
            xmlrpc => 51,
            message => q|There is no user named 'oremipsumdolorsitametconsecteturadipiscingelitnvariusodioeumagnaultriciesquisefficiturloremvenenatisaecenasauctor@cpan.org'. Either you mis-typed the name or that user has not yet registered for a Bugzilla account.|,
        },
        response => undef,

    },
];

sub TestOffer {
    my $list = shift;
    my $client = $tester->client();

    my $cnt = 0;
    my $return = 1;

    for my $data (@$list) {

        $cnt++;
        my $ok;

        eval {
            $ok = BZ::Client::User->offer_account_by_email($client, $data->{params});
        };

        my $error = $data->{error};

        if ($@) {
            my $err = $@;
            my $msg;
            if ( ref $err eq 'BZ::Client::Exception' ) {

                if ($error) {

                    if ($error->{message}) {
                        is( $err->message(), $error->{message},
                            sprintf( q|Error message correct. Test # %d|, $cnt ))
                            or $return = 0;
                    }
                    else {
                        ok( 0, 'No Error message to check? Test ' . $cnt )
                            or $return = 0;
                    }

                    if ($error->{xmlrpc}) {
                        is( $err->xmlrpc_code(), $error->{xmlrpc},
                            sprintf( q|Error xmlrpc_code correct. Test # %d|, $cnt ))
                            or $return = 0;
                    }

                    if ($error->{http}) {
                        is( $err->httprpc_code(), $error->{http},
                            sprintf( q|Error http_code correct. Test # %d|, $cnt ))
                            or $return = 0;
                    }

                }

                $msg =
                    'Error: '
                  . ( defined( $err->http_code() )   ? $err->http_code() : 'undef' )   . ', '
                  . ( defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code() : 'undef' ) . ', '
                  . ( defined( $err->message() )     ? $err->message() : 'undef' );

            }
            else {

                $msg = "Error: $err\n";

                if ($error) {

                    if ($error->{message}) {
                        is( $err, $error->{message}, 'Error message correct. Test # ' . $cnt )
                            or $return = 0;
                    }
                    else {
                        ok( 0, 'No Error message to check? Test #' . $cnt )
                            or $return = 0;
                    }

                    ok( 0, 'Error before xmlrpc code was provided' ) if $error->{xmlrpc};
                    ok( 0, 'Error before http code was provided' ) if $error->{http};

                }

            }

            unless ($error) {
                diag($msg);
                ok( 0, 'No errors: offer_account_by_email. Test # ' . $cnt );
                diag Dumper $@;
                $return = 0;
            }
        }
        else { # if ($@)
            if ($error) {
                ok( 0, 'Expected an error when running: offer_account_by_email, test # ' . $cnt );
                ok( 0, 'Expected xmlrpc error code: ' . $error->{xmlrpc} ) if $error->{xmlrpc};
                ok( 0, 'Expected http error code :' . $error->{http} ) if $error->{http};

                $return = 0;
            }
            else {
                ok( 1, 'No errors: offer_account_by_email, test # ' .$cnt );
            }
        } # if ($@)

        is_deeply( $ok, $data->{response}, 'offer_account_by_email response check' )
            if exists $data->{response};


    } # for my $data (@$list)

    return $return

} # sub TestOffer

sub TestGet {
    my $list = shift;

    my $cnt = 0;
    my $return = 1;

    for my $data (@$list) {

        my $client = $tester->client();
        if ($data->{logged_out}) {
            $client = clone $client;
            $client->logout;
            $client->api_key('') if $client->api_key();
        }

        $cnt++;
        my $ok;

        eval {
            $ok = BZ::Client::User->get($client, $data->{params});
        };

        my $error = $data->{error};

        if ($@) {
            my $err = $@;
            my $msg;
            if ( ref $err eq 'BZ::Client::Exception' ) {

                if ($error) {

                    if ($error->{message}) {
                        is( $err->message(), $error->{message},
                            sprintf( q|Error message correct. Test # %d|, $cnt ))
                            or $return = 0;
                    }
                    else {
                        ok( 0, 'No Error message to check? Test ' . $cnt )
                            or $return = 0;
                    }

                    if ($error->{xmlrpc}) {
                        is( $err->xmlrpc_code(), $error->{xmlrpc},
                            sprintf( q|Error xmlrpc_code correct. Test # %d|, $cnt ))
                            or $return = 0;
                    }

                    if ($error->{http}) {
                        is( $err->httprpc_code(), $error->{http},
                            sprintf( q|Error http_code correct. Test # %d|, $cnt ))
                            or $return = 0;
                    }

                }

                $msg =
                    'Error: '
                  . ( defined( $err->http_code() )   ? $err->http_code() : 'undef' )   . ', '
                  . ( defined( $err->xmlrpc_code() ) ? $err->xmlrpc_code() : 'undef' ) . ', '
                  . ( defined( $err->message() )     ? $err->message() : 'undef' );

            }
            else {

                $msg = "Error: $err\n";

                if ($error) {

                    if ($error->{message}) {
                        is( $err, $error->{message}, 'Error message correct. Test # ' . $cnt )
                            or $return = 0;
                    }
                    else {
                        ok( 0, 'No Error message to check? Test #' . $cnt )
                            or $return = 0;
                    }

                    ok( 0, 'Error before xmlrpc code was provided' ) if $error->{xmlrpc};
                    ok( 0, 'Error before http code was provided' ) if $error->{http};

                }

            }

            unless ($error) {
                diag($msg);
                ok( 0, 'No errors: offer_account_by_email. Test # ' . $cnt );
                diag Dumper $@;
                $return = 0;
            }
        }
        else { # if ($@)
            if ($error) {
                ok( 0, 'Expected an error when running: offer_account_by_email, test # ' . $cnt );
                ok( 0, 'Expected xmlrpc error code: ' . $error->{xmlrpc} ) if $error->{xmlrpc};
                ok( 0, 'Expected http error code :' . $error->{http} ) if $error->{http};

                $return = 0;
            }
            else {
                ok( 1, 'No errors: offer_account_by_email, test # ' .$cnt );
            }
        } # if ($@)

        if (exists $data->{response}) {
            is_deeply( $ok, $data->{response}, 'offer_account_by_email response check' )
                or diag sprintf( '$got %s $expected %s',
                                Dumper($ok),
                                defined $data->{response} ? $data->{response}
                                                          : 'undef');
        }


    } # for my $data (@$list)

    return $return

} # sub TestGet

## OK Lets get to work.

for my $server (@bugzillas) {

    diag sprintf 'Trying server: %s', $server->{testUrl} || '???';

    $tester = BZ::Client::Test->new( %$server, logDirectory => '/tmp/bz' );

  SKIP: {
        skip( 'No Bugzilla server configured, skipping', 2 )
          if $tester->isSkippingIntegrationTests();
        diag sprintf 'Server %s is version %s', $server->{testUrl}, $server->{version};

          ok( TestOffer( $quirks{$server->{version}}{offer_account_by_email} ), 'Test Offering Accounts via Email');
          ok( TestGet( $quirks{$server->{version}}{get} ), 'Test Get of User Account Info');

          # TODO create() and update() tests, which we cant really do on landfill.bugzilla.org

    }

}
