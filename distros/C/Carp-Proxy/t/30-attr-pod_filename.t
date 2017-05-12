# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;
use File::Basename qw( basename );
use File::Spec::Functions qw( catfile );

my $base = catfile 't', basename __FILE__;

my $replacement;
BEGIN {

    $replacement = 't/files/file1.pod';
}

use Carp::Proxy
    fatal     => {                              },
    fatal_pod => { pod_filename => $replacement };

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->pod_filename( $setting )
        if defined $setting;

    $cp->filled('Diagnostic message here.');

    $cp->synopsis;

    return;
}

sub main {

    my $local =
        qr{
              \Q  *** Synopsis ***\E  \r? \n
              \Q    Usage:\E          \r? \n
              \s+ Run \s+ 'make \s+ test', \s+ possibly \s+
              setting \s+ the \s+ TEST_FILES \s+ variable [.] \s+
          }x;

    my $remote =
        qr{
              \Q  *** Synopsis ***\E  \r? \n
              \s+ Usage: \s+ Body \s+ of \s+ the \s+ SYNOPSIS \s+
              section \s+ goes \s+ here. \s+
          }x;

    foreach my $tuple
        ([ \&fatal,     undef,        $local,  'default'     ],
         [ \&fatal,     $replacement, $remote, 'override'    ],
         [ \&fatal_pod, undef,        $remote, 'constructed' ],
         [ \&fatal_pod, $base,        $local,  'cons-over'   ],
        ) {

        my( $proxy, $setting, $rex, $title ) = @{ $tuple };

        throws_ok{ $proxy->( 'handler', $setting ) }
            qr{
                  \A

                  ~+                                \r? \n
                  \QFatal << handler >>\E           \r? \n
                  ~+                                \r? \n

                  \Q  *** Description ***\E         \r? \n
                  \Q    Diagnostic message here.\E  (?: \r? \n )+

                  $rex

                  \Q  *** Stacktrace ***\E          \r? \n
              }x,
              "POD synopsis matches for $title";
    }

    return;
}

__END__

=pod

=head1 NAME attr-pod_filename

This test checks to see if setting the pod_filename attribute causes
the synopsis() method to render pod from the named file.

=head1 SYNOPSIS

Run 'make test', possibly setting the TEST_FILES variable.

=head1 DESCRIPTION

Nothing here.

=cut
