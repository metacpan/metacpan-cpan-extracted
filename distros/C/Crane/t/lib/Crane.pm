# -*- coding: utf-8 -*-


package t::lib::Crane;


use vars qw( $BASE $OPTIONS $CONFIG );

use Crane (
    'base' => $BASE = [ qw( Exporter ) ],
    
    'namespace' => 'My',
    
    'options' => $OPTIONS = [
        [ 'my=s', 'My option.', { 'default' => 'value' } ],
    ],
    
    'config' => $CONFIG = {
        'my' => {
            'a' => 1,
            'b' => 2,
        },
    },
);

use Crane::Config;
use Crane::Options;

use Test::More;


our @EXPORT = qw(
    &test_base
    &test_options
    &test_config
    &test_namespace
    &test_daemon
);


sub test_base {
    
    plan('tests' => scalar @{ $BASE });
    
    foreach my $class ( @{ $BASE } ) {
        isa_ok(__PACKAGE__, $class);
    }
    
    return done_testing();
    
}


sub test_options {
    
    plan('tests' => 2);
    
    ok(exists options->{'my'}, 'Exists');
    is(options->{'my'}, 'value', 'Is equal');
    
    return done_testing();
    
}


sub test_config {
    
    plan('tests' => 2);
    
    ok(exists config->{'my'}, 'Exists');
    is_deeply(config->{'my'}, $CONFIG->{'my'}, 'Is equal');
    
    return done_testing();
    
}


sub test_namespace {
    
    plan('tests' => 5);
    
    use_ok('My');
    use_ok('My::Base');
    use_ok('My::Config');
    use_ok('My::Logger');
    use_ok('My::Options');
    
    return done_testing();
    
}


sub test_daemon {
    
    plan('tests' => 1);
    
    pass('TODO');
    
    return done_testing();
    
}


1;
