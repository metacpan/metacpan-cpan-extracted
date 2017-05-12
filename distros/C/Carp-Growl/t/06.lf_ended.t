use Test::More tests => 21;
use lib 't/testlib';    # Load fake 'Growl::Any'

use Carp::Growl;
my $CAPTURED_WARN;
local $SIG{__WARN__} = local $SIG{__DIE__} = sub { $CAPTURED_WARN = shift; };

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
    my $warn_message          = 'LF-ended ' . $func . '()';
    my $warn_message_complete = $warn_message;
    $warn_message_complete
        .= $/ . ' at ' . __FILE__ . ' line ' . ( __LINE__ + 2 )
        if ( $func eq 'carp' || $func eq 'croak' );
    eval { &{$func}( $warn_message . $/ ) };
    my $line = __LINE__ - 1;
    my @expected = ( @{ $notify_title{$func} }, undef, undef );
    diag $warn_message . ' of GROWL';
    for my $i ( 0, 1, 3 ) {
        is( $Growl::Any::SUB_NOTIFY_ARGS->[$i], $expected[$i] );
    }
    like(
        $Growl::Any::SUB_NOTIFY_ARGS->[2],
        qr/^\Q$warn_message_complete\E\.?$/
    );
    my $expected_re = "\Q$warn_message_complete\E\\.?";
    my $file        = __FILE__;
    $expected_re
        .= "\x0D?\x0A\t"
        . "\Qeval {...} called at $file\E"
        . ' line '
        . $line
        if ( $func eq 'carp' || $func eq 'croak' );
    $expected_re .= "\x0D?\x0A";
    like( $CAPTURED_WARN, qr/$expected_re/, $warn_message . ' of ' . $func );
#    my $got      = [ split '', $CAPTURED_WARN ];
#    my $expected = [ split '', $warn_message_complete ];
#    is_deeply( $got, $expected, $warn_message . ' of ' . $func );
    @$Growl::Any::SUB_NOTIFY_ARGS = ();       #reset
    $CAPTURED_WARN                = undef;    #reset
}
