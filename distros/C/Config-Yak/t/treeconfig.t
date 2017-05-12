use Test::More qw( no_plan );
use Config::Yak;

BEGIN { use_ok( 'Config::Yak', '0.11' ); }

my $ConfigObject = Config::Yak::->new(
    {
        'locations' => [qw(t/conf/test001.conf)],
        'debug'     => 1,
        'verbose'   => 0,
    }
);
isa_ok $ConfigObject, 'Config::Yak';

my $config_ref = $ConfigObject->config();

my $ref = {
    'config' => {
        'yak' => {
            'example'   => 'Str',
            'sites' => {
                'site1' => {
                    'days' => 'Num',
                    'type' => 'Str',
                },
            },
        },
    },
};

# Compare reference structure to actual config
sub check_ref {
    my $ref    = shift;
    my $config = shift;
    my $stack  = shift;
    foreach my $key ( keys %{$ref} ) {
        push( @{$stack}, $key );
        if ( ref( $ref->{$key} ) eq 'HASH' ) {
            &check_ref( $ref->{$key}, $config->{$key}, $stack );
        }
        else {
            my $ref_val = $ref->{$key};
            if ( $ref_val eq 'ARRAY' ) {
                ok( ref( $config->{$key} ) eq 'ARRAY', 'Expected Array at ' . join( '-', @{$stack} ) . ' not ' . ref( $config->{$key} ));
            }
            elsif ( $ref_val eq 'HASH' ) {
                ok( ref( $config->{$key} ) eq 'HASH', 'Expected Hash at ' . join( '-', @{$stack}). ' - Got: '.$config->{$key} );
            }
            elsif ( $ref_val eq 'Str' ) {
                ok( $config->{$key} =~ m/\w+/, 'Expected String at ' . join( '-', @{$stack}). ' - Got: '.$config->{$key} );
            }
            elsif ( $ref_val eq 'Num' ) {
                ok( $config->{$key} =~ m/[+-]?[\d.,]+/, 'Expected Number at ' . join( '-', @{$stack}). ' - Got: '.$config->{$key} );
            }
            else {
                ok( $config->{$key} eq $ref_val, 'String eq at ' . join( '-', @{$stack}) . ' Got: ' . $config->{$key} . '. Expected: ' . $ref_val );
            }
        }
        pop( @{$stack} );
    }
}

&check_ref( $ref, $config_ref, [] );

# set value in config
$ConfigObject->set( 'Config::Yak::DoMeSo', '123' );
# set value in reference
$ref->{'config'}->{'yak'}->{'domeso'} = '123';
# compare config an reference
&check_ref( $ref, $config_ref, [] );
# get value set before
is( $ConfigObject->get('Config::Yak::DoMeSo'), '123', 'Get value set before' );

# Test set on hash_ref w/o force
$ConfigObject->set( 'Config::Yak::Sites', 'Hello', 0 );
isnt( $ConfigObject->get('Config::Yak::Sites'), 'Hello', 'Should not be able to replace hashref w/ scalar w/o force.' );

# Test set on hash_ref w/ force
$ConfigObject->set( 'Config::Yak::Sites', 'Hallo', 1 );
is( $ConfigObject->get('Config::Yak::Sites'), 'Hallo', 'Should be able to replace hashref w/ scalar w/ force.' );

# Try to read an non-existing key
isnt( $ConfigObject->get('Config::Yak::Some::Made::Up::Key'), '123', 'Should not be able to read an non-existing key.' );

# Make sure test002.conf was not read
isnt( $ConfigObject->get('Should::Not::Exist'), '1', 'Should not be able to read an non-existing key.' );

# Try to read an non-exisiting key w/ default
# case #1: default != undef
is( $ConfigObject->get( 'Config::Yak::Another::Made::Up::Key', { Default => 'HelloWorld' } ), 'HelloWorld', 'Default is returned for non-existing key' );

# case #2: default == undef
is( $ConfigObject->get( 'Config::Yak::Another::Made::Up::Key', ), undef, 'undef is returned for non-existing key' );

# case #3: default == 0
is( $ConfigObject->get( 'Config::Yak::Another::Made::Up::Key', { Default => 0 } ), 0, 'Default is returned for non-existing key' );

$ConfigObject->reset_config();
ok( !keys %{ $ConfigObject->config() }, 'Test that config is empty after reset' );

$ConfigObject = undef;

