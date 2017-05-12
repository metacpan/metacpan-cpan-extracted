use Test::More qw( no_plan );
use Data::Tree;

BEGIN { use_ok( 'Data::Tree', ); }

my $TreeObject = Data::Tree::->new();
isa_ok $TreeObject, 'Data::Tree';

my $ref = {
    'hxs' => {
        'cpp' => {
            'dry'   => 'Num',
            'sites' => {
                'site1' => {
                    'count' => 'Num',
                    'type'         => 'Str',
                }
            }
        },
        'xzf'   => { 'basedir'  => 'Str', },
        'merge' => { 'angel' => 'Str', },
        'skip'  => { 'olympus'     => 'Num', },
    },
    'tbb' => {
        'tdb' => {
            'dba' => {
                'username' => 'Str',
                'password' => 'Str',
            },
            'hosts' => { 'foo' => { 'hosts' => { 'bar' => { 'ip' => '1.2.3.4', } }, }, }
        },
        'basketcase' => {
            'key' => 'Str',
            'check'       => { 'exec' => 'Str', },
            'cnc'         => { 'gid' => 'Num', },
            'post'   => 'ARRAY',
        },
    },
    'overlord' => {
        'panel'    => 'Str',
        'switch' => 'Str',
        'role' => 'Str',
        'rain' => 'Str',
    },
    'vvf' => { 'config' => 'HASH', }
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
                ok( ref( $config->{$key} ) eq 'ARRAY', 'Expected Array at ' . join( '-', @{$stack} ) . ' not ' . ref( $config->{$key} ) );
            }
            elsif ( $ref_val eq 'HASH' ) {
                ok( ref( $config->{$key} ) eq 'HASH', 'Hash at ' . join( '-', @{$stack} ) );
            }
            elsif ( $ref_val eq 'Str' ) {
                ok( $config->{$key} =~ m/\w*/, 'String at ' . join( '-', @{$stack} ) );
            }
            elsif ( $ref_val eq 'Num' ) {
                ok( $config->{$key} =~ m/[+-]?[\d.,]+/, 'Number at ' . join( '-', @{$stack} ) );
            }
            else {
                ok( $config->{$key} eq $ref_val, 'String eq at ' . join( '-', @{$stack} ) );
            }
        }
        pop( @{$stack} );
    }
}

__END__
