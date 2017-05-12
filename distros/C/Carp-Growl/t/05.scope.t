package DUMMY;
use lib 't/testlib';    # Load fake 'Growl::Any'

use Carp::Growl;

package main;
use Test::More tests => 8;

my @funcs = qw/warn die carp croak/;

diag "call Carp::Growl'ed &DUMMY::<func> from main";
for my $func (@funcs) {
    my $warn_message = 'call &DUMMY::' . $func . '()';
    my $warn_message_complete
        = $warn_message . ' at ' . __FILE__ . ' line ' . ( __LINE__ + 1 );
    eval { &{ 'DUMMY::' . $func }($warn_message) };
    like(
        $Growl::Any::SUB_NOTIFY_ARGS->[2],
        qr/^\Q$warn_message_complete\E\.?$/
    );
    @$Growl::Any::SUB_NOTIFY_ARGS = ();    #reset
}
diag "call <funcs> normally from main";
for my $func (@funcs) {
    my $warn_message = 'call &main::' . $func . '()';
    eval { &{$func}($warn_message) };
    is_deeply( $Growl::Any::SUB_NOTIFY_ARGS, [] );
    @$Growl::Any::SUB_NOTIFY_ARGS = ();    #reset
}
