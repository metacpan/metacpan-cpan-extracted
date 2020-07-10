use Test::Most;

use constant PACKAGE => 'Bible::OBML::Gateway';

exit main();

sub main {
    BEGIN { use_ok(PACKAGE) }
    require_ok(PACKAGE);

    my $self = PACKAGE->new;
    isa_ok( $self, PACKAGE );

    can_ok( PACKAGE, $_ ) for ( qw(
        ua url translation obml data
        new translation get obml data html save load
    ) );

    done_testing();
    return 0;
};
