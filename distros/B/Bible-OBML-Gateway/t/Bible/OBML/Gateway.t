use Test2::V0;
use Bible::OBML::Gateway;

my $self = Bible::OBML::Gateway->new;
isa_ok( $self, 'Bible::OBML::Gateway' );

can_ok( $self, $_ ) for ( qw(
    ua url translation obml data
    new translation get obml data html save load
) );

done_testing;
