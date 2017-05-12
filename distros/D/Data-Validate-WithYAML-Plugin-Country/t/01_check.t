#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::Country' );
}

my $module = 'Data::Validate::WithYAML::Plugin::Country';

my @countries = qw(DE JP FR);
my @blacklist = qw(DEU FRA JPN ZU TE);


for my $country ( @countries ){
    ok( $module->check($country), "test: $country" );
}

for my $country ( @countries ){
    ok( $module->check($country, {format => 'alpha-2'}), "test: $country" );
}

for my $check ( @blacklist ){
    my $retval = $module->check( $check );
    ok( !$retval, "test: $check" );
}

for my $check ( @blacklist ){
    my $retval = $module->check( $check, {format => 'alpha-2'} );
    ok( !$retval, "test: $check" );
}

done_testing();
