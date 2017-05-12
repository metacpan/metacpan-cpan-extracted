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
            fatal           => {                        },
            fatal_none      => { context => 'none'      },
            fatal_die       => { context => 'die'       },
            fatal_croak     => { context => 'croak'     },
            fatal_confess   => { context => 'confess'   },
            fatal_internals => { context => 'internals' },
            fatal_coderef   => { context => \&describe  },
          );
}

my $BASE = basename __FILE__;

main();

#-----
# The 'croak' context attempts to look back one extra frame in the
# callstack from where the proxy was called.  If the proxy was called from
# top-level code, in other words called from OUTSIDE any subroutine, then
# there is no previous frame.  Croak is supposed to fallback and behave
# like die when there is no previous frame.
#
# To test the fallback we have to call a proxy from top-level code -
# outside of main().
#-----
SKIP: {

    skip 'Forking with "open -|" is broken on windows', 1
        if $OSNAME =~ / MSWin /xi;

    my $pid = open my( $fd ), '-|';

    skip 'Cannot Fork', 1
        if not defined $pid;

    if (not $pid) { #----- Child

        close STDERR;
        open STDERR, '>&STDOUT';
        fatal_croak 'handler';
        exit 0;   # not reached
    }

    #----- Parent

    #----- Slurp the entire message.
    my $diagnostic = do{ local $INPUT_RECORD_SEPARATOR = undef; <$fd>; };

    close $fd;

    like
        $diagnostic,
        qr{
              \A
              ~+                                \r? \n
              \QFatal << handler >>\E           \r? \n
              ~+                                \r? \n

              \Q  *** Description ***\E         \r? \n
              \Q    Diagnostic message here\E   \r? \n
                                                \r? \n
              \Q  *** Exception ***\E           \r? \n
              \Q    fatal_croak called from \E
              line \s+ \d+ \s+ of .+? \Q$BASE\E      (?: \r? \n )+

              \z
          }xs,
        'Context croak gracefully handles top-level throwing';
}

done_testing();


#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->context( $setting )
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
    $cp->{context} = $setting;

    $cp->filled('Diagnostic message here');

    return;
}

sub throws_deeply { level1( @_ ) }
sub level1        { level2( @_ ) }
sub level2 {
    my( $proxy, @args ) = @_;

    $proxy->( 'handler', @args );
    return;
}

sub describe {
    my( $cp ) = @_;

    $cp->filled( 'custom stacktrace here', 'title here' );
    return;
};

sub main {

    my $banner_rex =
        qr{
              ~+                      \r? \n
              \QFatal << handler >>\E \r? \n
              ~+                      \r? \n
          }x;

    my $message_rex =
        qr{
              \Q  *** Description ***\E        \r? \n
              \Q    Diagnostic message here\E  (?: \r? \n )+
          }x;

    my $where =
        qr{
              \Q called from\E .+? \Q${BASE}\E \s+
          }xs;

    my $none_rex =
        qr{
              \A
              $banner_rex
              $message_rex
              \z
          }x;

    my $die_rex =
        qr{
              \A
              $banner_rex
              $message_rex

              \Q  *** Exception ***\E \s+
              fatal (?: _die )? $where
              \z
          }xs;

    my $croak_rex =
        qr{
              \A
              $banner_rex
              $message_rex

              \Q  *** Exception ***\E \s+
              level2 $where
              \z
          }xs;

    my $confess_rex =
        qr{
              \A
              $banner_rex
              $message_rex

              \Q  *** Stacktrace ***\E \s+
              fatal (?: _confess )? $where
              level2                $where
              level1                $where
              throws_deeply         $where

              .+?   # Ignore implementation of Test::Exception::throws_ok()

              main                  $where
              \z
          }xs;

    my $internals_rex =
        qr{
              \A
              $banner_rex
              $message_rex
              \Q  *** Stacktrace ***\E  \r? \n

              .+?    # Ignore any children of add_context()
              add_context
              .+?    # Ignore any parents of add_context()

              fatal (?: _internals )? $where
              level2                  $where
              level1                  $where
              throws_deeply           $where

              .+?    # Ignore implementation of Test::Exception::throws_ok()

              main                    $where
              \z
          }xs;

    my $coderef_rex =
        qr{
              \A
              $banner_rex
              $message_rex

              \Q  *** title here ***\E        \r? \n
              \Q    custom stacktrace here\E  (?: \r? \n )+
              \z
          }x;

    foreach my $tuple
        ([ \&fatal,          'none',       $none_rex,      'none-over'  ],
         [ \&fatal_none,      undef,       $none_rex,      'none-cons'  ],
         [ \&fatal,           'die',       $die_rex,       'die-over'   ],
         [ \&fatal_die,       undef,       $die_rex,       'die-cons'   ],
         [ \&fatal,           'croak',     $croak_rex,     'croak-over' ],
         [ \&fatal_croak,     undef,       $croak_rex,     'croak-cons' ],
         [ \&fatal,           'confess',   $confess_rex,   'conf-over'  ],
         [ \&fatal_confess,   undef,       $confess_rex,   'conf-cons'  ],
         [ \&fatal,           'internals', $internals_rex, 'int-over'   ],
         [ \&fatal_internals, undef,       $internals_rex, 'int-cons'   ],
         [ \&fatal,           \&describe,  $coderef_rex,   'code-over'  ],
         [ \&fatal_coderef,   undef,       $coderef_rex,   'code-cons'  ],
        ) {

        my( $proxy, $setting, $rex, $title ) = @{ $tuple };

        throws_ok{ throws_deeply( $proxy, $setting )}
            $rex,
            "Context $title";
    }

    throws_ok{ fatal 'cheater', 'bogus_context' }
        qr{
              \QOops << unknown context >>\E
              .+?
              \Qcontext: 'bogus_context'\E
          }xs,
        'Crudely forged string context is handled';

    throws_ok{ fatal 'cheater', undef }
        qr{
              \QOops << unknown context >>\E
              .+?
              \Qcontext: '(undef)'\E
          }xs,
        'Crudely forged undef context is handled';

    return;
}

