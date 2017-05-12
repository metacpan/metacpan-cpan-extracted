# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use File::Basename qw( basename );
use Test::More;
use Test::Exception;

BEGIN {
    use_ok( 'Carp::Proxy',
            fatal         => {                         },
            fatal_return  => { disposition => 'return' },
            fatal_warn    => { disposition => 'warn'   },
            fatal_die     => { disposition => 'die'    },
          );
}

my $BASE = basename __FILE__;

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->disposition( $setting )
        if defined $setting;

    $cp->filled('Diagnostic message here');

    return;
}

sub cheater {
    my( $cp, $setting ) = @_;

    #-----
    # We want Carp::Proxy to gracefully handle the possibility that a
    # user bypassed the Moose accessor validation, say by directly poking
    # a value into the attribute slot.  To check for graceful handling we
    # have to cheat as well...
    #-----
    $cp->{disposition} = $setting;

    $cp->filled('Diagnostic message here');

    return;
}

sub main {

    verify_return();
    verify_warn();
    verify_die();
    verify_coderef();
    verify_bogosity();

    return;
}

sub verify_return {

    #-----
    # The 'return' disposition should return rather than throwing.  It
    # should also return the Carp::Proxy object.
    #-----
    my $obj;

    my $validate = sub {
        my( $title ) = @_;

        isa_ok
            $obj,
            'Carp::Proxy',
            'Disposition return returns a Carp::Proxy object for ' . $title;

        is_deeply
            $obj->sections->[0],
            [ 'filled_section', 'Diagnostic message here', undef ],
            'Disposition-none return matches diagnostic for ' . $title;
    };

    #-----
    # This verifies that the handler can change the native disposition
    # to 'return' and that it functions correctly.
    #-----
    lives_ok{ $obj = fatal 'handler', 'return' }
        'Disposition return returns to caller for overridden disposition';

    $validate->( 'overridden disposition' );

    #----- To ensure that we don't carry over from previous test
    $obj = undef;

    lives_ok{ $obj = fatal_return( 'handler' )}
        'Disposition-return returns to caller for constructed proxy';

    $validate->( 'constructed proxy' );

    return;
}

sub verify_warn {

    #-----
    # The disposition setting of 'warn' causes the proxy to pass the
    # Carp::Proxy object to Perl's warn().  We attempt to intercept this
    # by trapping $SIG{ __WARN__ } so that we can capture and examine the
    # object.
    #-----
    my $obj;
    local $SIG{__WARN__} = sub{ $obj = $_[0]; };

    foreach my $tuple ([ \&fatal,      'warn', 'overridden'  ],
                       [ \&fatal_warn, undef,  'constructed' ],
                      ) {

        my( $proxy, $setting, $title ) = @{ $tuple };

        $obj = undef;

        #-----
        # Our proxy should call warn() and then return, not throw.
        #-----
        lives_ok{ $proxy->( 'handler', $setting )}
            "Disposition-warn returns to caller for $title";

        #----- $obj should now hold a Carp::Proxy object

        isa_ok
            $obj,
            'Carp::Proxy',
            "Warn handler reaped a Carp::Proxy object from $title";

        is_deeply
            $obj->sections->[0],
            [ 'filled_section', 'Diagnostic message here', undef ],
            "Returned object from $title matches handler output";
    }
    return;
}

sub verify_die {

    foreach my $tuple ([ \&fatal,     undef, 'implicit'    ],
                       [ \&fatal,     'die', 'explicit'    ],
                       [ \&fatal_die, undef, 'constructed' ],
                      ) {

        my( $proxy, $override, $title ) = @{ $tuple };

        throws_ok{ $proxy->( 'handler', $override ) }
            qr{
                  \A
                  ~+                                          \s+
                  \QFatal << handler >>\E                     \s+
                  ~+                                          \s+

                  \Q  *** Description ***\E                   \s+
                  \Q    Diagnostic message here\E             \s+

                  \Q  *** Stacktrace ***\E                    \s+
                  \Q    fatal\E \w* \Q called from\E .+ $BASE \s+

                  .+?   #----- Ignore the implementation of throws_ok()

                  \Qverify_die called from\E .+ $BASE         \s+
                  \Qmain called from\E       .+ $BASE         \s+
                  \z
              }xs,
            "Disposition-die throws appropriately from $title.";
    };

    return;
}


sub verify_coderef {

    #----- The message our custom thrower will issue
    my $message = 'message here';
    my $rex     = qr{ \A message [ ] here }x;

    #----- Custom throwers can either throw or return...
    my $simple_die = sub{ die    $message };
    my $simple_ret = sub{ return $message };

    #----- Constructed proxies for both types of throwers
    Carp::Proxy->import( fatal_code_die => { disposition => $simple_die },
                         fatal_code_ret => { disposition => $simple_ret } );

    throws_ok{ fatal( 'handler', $simple_die )}
        $rex,
        'Disposition-coderef works for overridden die';

    throws_ok{ fatal_code_die( 'handler' )}
        $rex,
        'Disposition-coderef works for constructed die';

    foreach my $tuple ([ \&fatal,          $simple_ret, 'overridden'  ],
                       [ \&fatal_code_ret, undef,       'constructed' ],
                      ) {

        my( $proxy, $setting, $title ) = @{ $tuple };

        my $result;

        lives_ok{ $result = $proxy->( 'handler', $setting ) }
            "Disposition-coderef returns when $title returns";

        is
            $result,
            $message,
            "Disposition-coderef propagates return from $title";
    }

    return;
}

sub verify_bogosity {

    throws_ok{ fatal 'cheater', 'bogus_disposition' }
        qr{
              \QOops << unknown disposition >>\E
              .+?
              \Qdisposition: 'bogus_disposition'\E
          }xs,
        'Crudely forged string disposition is handled';

    throws_ok{ fatal 'cheater', undef }
        qr{
              \QOops << unknown disposition >>\E
              .+?
              \Qdisposition: '(undef)'\E
          }xs,
        'Crudely forged undef disposition is handled';

    return;
}

