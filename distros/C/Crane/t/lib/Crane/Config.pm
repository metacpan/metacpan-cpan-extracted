# -*- coding: utf-8 -*-


package t::lib::Crane::Config;


use Crane::Base qw( Exporter );
use Crane::Config qw( merge_config read_config write_config );

use Test::More;


our @EXPORT = qw(
    &test_merge
    &test_read_write
);


Readonly::Scalar(my $FILENAME => 'test.conf');

my %ORIGINAL = (
    'a' => 1,
    
    'b' => [
        1,
        2,
    ],
    
    'c' => {
        'foo' => 'bar',
    },
);


sub test_merge {
    
    plan('tests' => 4);
    
    my $value_of_a = $ORIGINAL{'a'};
    my $new_value_for_b = 'Now it is scalar';
    my $valud_for_d = 42;
    
    my $config = merge_config(\%ORIGINAL, {
        'b' => $new_value_for_b,
        'd' => $valud_for_d,
    });
    
    is($config->{'a'}, $value_of_a, 'Value unchanged');
    
    is($config->{'b'}, $new_value_for_b, 'Value changed');
    
    ok(exists $config->{'d'}, 'Exists');
    is($config->{'d'}, $valud_for_d, 'Is equal');
    
    return done_testing();
    
}


sub test_read_write {
    
    plan('tests' => 2);
    
    SKIP: {
        try {
            write_config(\%ORIGINAL, $FILENAME);
        } catch {
            skip('write config failed', 2);
        };
        
        pass('Created');
        
        my $config = read_config($FILENAME);
        
        is_deeply($config, \%ORIGINAL, 'Restored');
    }
    
    if ( -e $FILENAME ) {
        unlink $FILENAME;
    }
    
    return done_testing();
    
}


1;
