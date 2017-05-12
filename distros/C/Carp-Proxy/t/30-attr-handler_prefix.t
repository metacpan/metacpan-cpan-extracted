# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

BEGIN {
    use_ok( 'Carp::Proxy',

            fatal    => { disposition    => 'return' },

            fatal_hp => { disposition    => 'return',
                          handler_prefix => 'pre_' },

            fatal_he => { disposition    => 'return',
                          handler_prefix => '' },

            fatal_hu => { disposition    => 'return',
                          handler_prefix => undef },
          );
}

main();
done_testing();

#----------------------------------------------------------------------

sub hana     { $_[0]->exit_code( 2 ) }
sub _hanb    { $_[0]->exit_code( 3 ) }
sub _cp_hanc { $_[0]->exit_code( 4 ) }
sub pre_hand { $_[0]->exit_code( 5 ) }

sub _cp_hane { $_[0]->exit_code( 6 ) }
sub _hane    { $_[0]->exit_code( 7 ) }

sub _hanf    { $_[0]->exit_code( 8 ) }
sub hanf     { $_[0]->exit_code( 9 ) }

sub main {

    verify_prefix_search_and_precedence();
    verify_prefix_finds_only();
    verify_override();
    verify_embarrassed();
}

sub verify_prefix_search_and_precedence {

    foreach my $tuple
        ([ \&fatal,    'hana', 2, 'Fallback finds unadorned'             ],
         [ \&fatal,    'hanb', 3, 'Fallback finds underscore'            ],
         [ \&fatal,    'hanc', 4, 'Fallback finds _cp_'                  ],
         [ \&fatal_hp, 'hand', 5, 'Explicit finds explicit'              ],
         [ \&fatal,    'hane', 6, 'Fallback gives underscore precedence' ],
         [ \&fatal,    'hanf', 8, 'Fallback gives _cp_ precedence'       ],
        ) {

        my( $proxy, $handler, $exit_code, $title ) = @{ $tuple };

        my $cp;
        lives_ok{ $cp = $proxy->( $handler ) }
            "$handler handler returns to caller";

        if ( isa_ok
                 $cp,
                 'Carp::Proxy',
                 "$handler returns Carp::Proxy" ) {

            is
                $cp->exit_code,
                $exit_code,
                $title;
        }
    }
}

sub verify_prefix_finds_only {

    foreach my $handler (qw( hana hanb hanc )) {

        throws_ok{ fatal_hp $handler }
            qr{ << [ ] embarrassed [ ] developers [ ] >> }x,
            "Explicit prefix reject $handler";
    }
}

sub verify_override {

    my $conf = fatal '*configuration*';

    foreach my $tuple ([ '_', 'hane', 7 ],
                       [ '',  'hanf', 9 ],
                      ) {

        my( $prefix, $handler, $exit_code ) = @{ $tuple };

        $conf->{handler_prefix} = $prefix;

        my $cp;
        lives_ok{ $cp = fatal $handler }
            "$handler handler returns to caller";

        if ( isa_ok
                 $cp,
                 'Carp::Proxy',
                 "$handler returns Carp::Proxy" ) {

            is
                $cp->exit_code,
                $exit_code,
                "Prefix override with '$prefix'";
        }
    }
    return;
}

sub verify_embarrassed {

    throws_ok{ fatal_hp 'handler' }
        qr{
              \QOops << embarrassed developers >>\E
              .+?
              \Qhandler_prefix: pre_\E
          }xs,
        'A defined value for handler_prefix shows up in diagnostic';

    throws_ok{ fatal_he 'handler' }
        qr{
              \QOops << embarrassed developers >>\E
              .+?
              \Qhandler_prefix: ''\E
          }xs,
        'An empty value for handler_prefix shows up in diagnostic';

    throws_ok{ fatal_hu 'handler' }
        qr{
              \QOops << embarrassed developers >>\E
              .+?
              \Qhandler_prefix: (undef)\E
          }xs,
        'An undef value for handler_prefix shows up in diagnostic';

    return;
}


