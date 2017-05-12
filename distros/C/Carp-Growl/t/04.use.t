use Test::More tests => 17;
use lib 't/testlib';    # Load fake 'Growl::Any'

use Carp::Growl;

is_deeply(
    $Growl::Any::SUB_NEW_ARGS,
    +{ appname => 'Carp::Growl', events => [qw/warn die/] },
    'correct args for Growl::Any->new'
);
my %notify_title = (
    warn  => [ 'warn', "WARNING" ],
    die   => [ 'die',  'FATAL' ],
    carp  => [ 'warn', "WARNING" ],
    croak => [ 'die',  'FATAL' ],
);
for my $func ( keys %notify_title ) {
    my $warn_message = $func . '()';
    my $warn_message_complete
        = $warn_message . ' at ' . __FILE__ . ' line ' . ( __LINE__ + 1 );
    eval { &{$func}($warn_message) };
    my @expected = ( @{ $notify_title{$func} }, undef, undef );
    diag $warn_message;
    for my $i ( 0, 1, 3 ) {
        is( $Growl::Any::SUB_NOTIFY_ARGS->[$i], $expected[$i] );
    }
    like(
        $Growl::Any::SUB_NOTIFY_ARGS->[2],
        qr/^\Q$warn_message_complete\E\.?$/
    );
    @$Growl::Any::SUB_NOTIFY_ARGS = ();    #reset
}
