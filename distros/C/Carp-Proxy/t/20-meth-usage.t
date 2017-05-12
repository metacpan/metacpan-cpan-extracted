# -*- cperl -*-
use warnings;
use strict;
use 5.010;

use English '-no_match_vars';
use Test::More;
use Test::Exception;

use Carp::Proxy;

main();
aux();
done_testing();

#----------------------------------------------------------------------

sub handler {
    my( $cp ) = @_;

    $cp->usage;
    return;
}

sub main {

    unadorned();
    underscore();
    carpproxy();
    intermediary();
    return;
}

sub aux {

    missing();
    return;
}

sub usage_unadorned {
    my( $cp ) = @_;

    $cp->fixed('hello from unadorned');
    return;
}

sub unadorned {

    #-----
    # We expect the usage() call in handler() to search for
    #
    #    usage_unadorned()
    #    _usage_unadorned()
    #    _cp_usage_unadorned()
    #
    # Only usage_unadorned() is defined so we should see a message from it.
    #-----
    throws_ok{ fatal 'handler' }
        qr{
              \Qhello from unadorned\E
          }x,
        'Find usage function with empty-string prefix';

    return;
}

sub _usage_underscore {
    my( $cp ) = @_;

    $cp->fixed('hello from underscore');
    return;
}

sub underscore {

    throws_ok{ fatal 'handler' }
        qr{
              \Qhello from underscore\E
          }x,
        'Find usage function with underscore prefix';

    return;
}

sub _cp_usage_carpproxy {
    my( $cp ) = @_;

    $cp->fixed('hello from carpproxy');
    return;
}

sub carpproxy {

    throws_ok{ fatal 'handler' }
        qr{
              \Qhello from carpproxy\E
          }x,
        'Find usage function with _cp_ prefix';

    return;
}

sub usage_main {
    my( $cp ) = @_;

    $cp->fixed('hello from main');
    return;
}

sub intermediary {

    #-----
    # main() calls us.  We call fatal().  We expect the full handler-prefix
    # template search for usage_intermediary() to fail so usage() should
    # fall back to the next invoker in the callstack and search for
    # templated variations on usage_main()
    #-----
    throws_ok{ fatal 'handler' }
        qr{
              \Qhello from main\E
          }x,
        'Find usage function via parental naming';

    return;
}

sub missing {

    throws_ok{ fatal 'handler' }
        qr{\Q<< no usage documentation >>\E}x,
        'Detect absence of a viable usage handler';
}


__END__

=pod

=head1 NAME

A terse summary of our purpose.

=head1 SYNOPSIS

Examples and usage text go here.

=head1 DESCRIPTION

A brief description of what the module does.

=cut

