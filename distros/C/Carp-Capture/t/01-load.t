# -*- cperl -*-
use 5.010;
use strict;
use warnings FATAL => 'all';
use English qw( -no_match_vars );

use Test::More;
use Test::Exception;

main();
done_testing();

sub main {

    if (not use_ok( 'Carp::Capture' )) {

        print "Bail out!\n";
        return;
    }

    banner();
    public_methods_exist();

    return;
}

sub banner {

    diag(<<"EOF");


 Module      Carp::Capture $Carp::Capture::VERSION
 Perl        $]
 Executable  $EXECUTABLE_NAME

EOF
}

sub public_methods_exist {

    my $cc;

    lives_ok{ $cc = Carp::Capture->new; }
        'new() is callable';

    isa_ok $cc, 'Carp::Capture';

    can_ok $cc, (qw(
                       capture
                       disable
                       enable
                       retrieve_annotation
                       revert
                       stacktrace
                       uncaptured
                  ));

    return;
}

