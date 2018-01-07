use Test::Most;
use Test::Moose;

use constant PACKAGE => 'Bible::OBML::Gateway';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $self = PACKAGE->new;
    isa_ok( $self, PACKAGE );

    does_ok( $self, 'Throwable' );
    has_attribute_ok( $self, $_, qq{attribute "$_" exists} ) for ( qw( ua url translation obml data ) );
    can_ok( PACKAGE, $_ ) for ( qw( new translation get obml data html save load ) );

    done_testing();
    return 0;
};
