use Test::More;

use strict;
use warnings;

use CGI::Application::Plugin::Throttle;

my $mock_cgi = bless {}, 'MyCGI';
my $throttle = throttle($mock_cgi);



subtest "Original and Basic behaviour" => sub {
    
    is_deeply( $throttle->_get_throttle_rule( [] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "slow_down"
        },
        "Default rules"
    );
    
    is_deeply( $throttle->_get_throttle_rule( [ foo => 1 ] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "slow_down"
        },
        "There are no filters etc."
    );
    
};



subtest "List without default" => sub {
    
    local $throttle->{throttle_spec_callback} = sub {
        { foo => 1 } =>
        {
            exceeded => 'foo one',
        },
        
        { foo => 1, bar => 2 } =>
        {
            exceeded => 'foo one / bar two',
        },
        
        { foo => 2, bar => 2 } =>
        {
            exceeded => 'foo two / bar two',
        },
        
        { bar => 2 } =>
        {
            exceeded => 'bar two',
        }
    };

    is_deeply( $throttle->_get_throttle_rule( [] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "slow_down"
        },
        "Default rules"
    );
    
    is_deeply( $throttle->_get_throttle_rule( [ foo => 1 ] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "foo one"
        },
        "Match 'foo one'"
    );
    
    is_deeply( $throttle->_get_throttle_rule( [ foo => 1, bar => 2 ] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "foo one"
        },
        "Match 'foo one', the first match"
    );
    
    is_deeply( $throttle->_get_throttle_rule( [ foo => 2, bar => 2 ] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "foo two / bar two"
        },
        "Match 'foo two / bar two'"
    );
    
    is_deeply( $throttle->_get_throttle_rule( [ bar => 2 ] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "bar two"
        },
        "Match 'bar two', 'foo' does not exist"
    );
    
    is_deeply( $throttle->_get_throttle_rule( [ foo => 3 ] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "slow_down"
        },
        "Default rules again"
    );
    
};



subtest "List with default" => sub {
    
    local $throttle->{throttle_spec_callback} = sub {
        { foo => 1 } =>
        {
            exceeded => 'foo one',
        },
        
        {
            exceeded => 'fall through',
        }
    };

    is_deeply( $throttle->_get_throttle_rule( [] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "fall through"
        },
        "Falls through, none of the specified filters match"
    );
    
    is_deeply( $throttle->_get_throttle_rule( [ foo => 1 ] ) => {
            limit     => 100,
            period    => 60,
            exceeded  => "foo one"
        },
        "Match 'foo one'"
    );
    
};

done_testing();


package MyCGI;

1;
