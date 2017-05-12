# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

use Carp::Proxy
    fatal      => {                       },
    fatal_main => { disposition => \&disp };

package abc;
Carp::Proxy->import( fatal_abc => { disposition  => \&main::disp,
                                    handler_pkgs => ['main'],
                                  });

package main;

main();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp, $setting ) = @_;

    $cp->{fq_proxy_name} = $setting
        if @_ > 1;

    return;
}

sub disp { return $_[0]->fq_proxy_name }

sub main {

    my $capture;

    lives_ok{ $capture = fatal_main 'handler' }
        'fatal_main returns to caller';

    is
        $capture,
        'main::fatal_main',
        'fq_proxy_name meets expectations from main';

    $capture = undef;
    lives_ok{ $capture = abc::fatal_abc( 'handler' )}
        'fatal_abc returns to caller';

    is
        $capture,
        'abc::fatal_abc',
        'fq_proxy_name meets expectations from abc';

    throws_ok{ fatal 'handler', 'bogus_proxy_name' }
        qr{
              \QOops << no proxy frame >>\E
          }x,
        'Crudely forged fq_proxy_name cannot thwart _find_proxy_frame';

    return;
}
