# -*- cperl -*-
use 5.010;
use warnings FATAL => qw( all );
use strict;

use English qw( -no_match_vars );
use Test::More;
use Test::Exception;
use Carp::Capture;

main();
done_testing;

#-----

sub main {
    my( @lines ) = @_;

    bad_ids();
    corrupt_callstack_cache();

    return;
}

sub bad_ids {

    my $cc = Carp::Capture->new;
    my $uncaptured = $cc->uncaptured;
    my $scalar;

    foreach my $meth (qw( stacktrace
                          retrieve_annotation )) {

        throws_ok{ $scalar = $cc->$meth() }
            qr{\QFatal << missing identifier >>\E}x,
            "$meth detects unprovided argument";

        throws_ok{ $scalar = $cc->$meth( undef ) }
            qr{\QFatal << missing identifier >>\E}x,
            "$meth detects undef argument";

        throws_ok{ $scalar = $cc->$meth( -1 ) }
            qr{
                  \QFatal << invalid identifier >>\E
                  .+?
                  The \s+ '\$id' \s+ argument, \s+ '-1', \s+ is
              }xs,
            "$meth detects negative identifier";

        throws_ok{ $scalar = $cc->$meth('abc') }
            qr{
                  \QFatal << invalid identifier >>\E
                  .+?
                  The \s+ '\$id' \s+ argument, \s+ 'abc', \s+ is
              }xs,
            "$meth detects non-numeric identifier";
    }

    throws_ok{ $scalar = $cc->stacktrace( 481367293 ) }
        qr{
              \QFatal << no such id >>\E
              .+?
              does \s+ not \s+ contain \s+ an \s+ identifier \s+ matching \s+
              '481367293'\. \s+ The \s+ database \s+ is \s+ empty\.
          }xs;

    $cc->capture;
    throws_ok{ $scalar = $cc->stacktrace( 481367293 ) }
        qr{
              \QFatal << no such id >>\E
              .+?
              does \s+ not \s+ contain \s+ an \s+ identifier \s+ matching \s+
              '481367293'\. \s+ The \s+ database \s+ has \s+ 1 \s+
              other \s+ entries
          }xs;

    return;
}

sub corrupt_callstack_cache {

    my $cc = Carp::Capture->new;

    #-----
    # Here we insert a fake key that is only 1 unsigned in length.
    # This should make the fetch routine throw.
    #-----
    $cc->callstacks->{ pack 'I', 0 } = 14;

    throws_ok{ scalar $cc->stacktrace( 14 )}
        qr{\Q<< incorrect entry size >>\E}x,
        'fetch by value detects a corrupt key length';

}
