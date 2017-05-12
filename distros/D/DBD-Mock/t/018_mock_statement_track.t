use strict;

use Test::More tests => 68;

BEGIN {
    use_ok('DBD::Mock');
}

{ # check the available methods

    can_ok("DBD::Mock::StatementTrack", 'new');
    my $st_track = DBD::Mock::StatementTrack->new();
    isa_ok($st_track, 'DBD::Mock::StatementTrack');
        
    can_ok($st_track, 'num_fields');
    can_ok($st_track, 'num_params');
    can_ok($st_track, 'bound_param');
    can_ok($st_track, 'bound_param_trailing');
    can_ok($st_track, 'is_active');
    can_ok($st_track, 'is_finished');
    can_ok($st_track, 'mark_executed');
    can_ok($st_track, 'next_record');
    can_ok($st_track, 'is_depleted');
    can_ok($st_track, 'to_string');
    can_ok($st_track, 'is_executed');
    can_ok($st_track, 'statement');
    can_ok($st_track, 'current_record_num');
    can_ok($st_track, 'return_data');
    can_ok($st_track, 'fields');
    can_ok($st_track, 'bound_params');
}

{ # check the default state

    my $st_track = DBD::Mock::StatementTrack->new();
    isa_ok($st_track, 'DBD::Mock::StatementTrack');

    is($st_track->num_fields(), 0, '... we have no fields in the default');
    is_deeply($st_track->fields(), [], '... we have no fields in the default');
    
    is($st_track->num_params(), 0, '... we have no bound params in the default');
    is_deeply($st_track->bound_params(), [], '... we have no bound params in the default');
    
    is_deeply($st_track->return_data(), [], '... we have no return data in the default');
    
    is($st_track->current_record_num(), 0, '... our current record num is 0 in the default');
    
    is($st_track->statement(), '', '... our statement is a blank string in the default');
    is($st_track->is_executed(), 'no', '... our statement is not executed in the default');
    
    ok($st_track->is_depleted(), '... the default state is depleted');
    ok(!defined($st_track->next_record()), '... the default state has no next record since it is depleted');
    
    is($st_track->is_finished(), 'no', '... our statement is not finished in the default');
    
    is($st_track->is_active(), 0, '... the default state is not active');
}
    
{ # check a pre-defined state

    my %params = (
        return_data        => [ [1, 1, 1], [2, 2, 2], [3, 3, 3] ],
        fields             => [ 'foo', 'bar', 'baz' ],
        bound_params       => [ 'baz' ],
        statement          => 'SELECT foo FROM bar WHERE baz = ?'
        );

    my $st_track = DBD::Mock::StatementTrack->new(%params);
    isa_ok($st_track, 'DBD::Mock::StatementTrack');

    is($st_track->num_fields(), 3, '... we have the expected num of fields');
    is_deeply($st_track->fields(), $params{fields}, '... we have the expected fields');
    
    is($st_track->num_params(), 1, '... we have the expected num of bound params');
    is_deeply($st_track->bound_params(), $params{bound_params}, '... we have the expected bound params');
    
    is_deeply($st_track->return_data(), $params{return_data}, '... we have the expected return data');
    
    is($st_track->current_record_num(), 0, '... our current record num is 0 in the default');
    
    is($st_track->statement(), $params{statement}, '... our statement as expected ');
    is($st_track->is_executed(), 'no', '... our statement is not executed');
    
    ok(!$st_track->is_depleted(), '... the state is not depleted');
    
    is($st_track->is_finished(), 'no', '... our statement is not finished');
    
    is($st_track->is_active(), 0, '... the default state is active');
    
# now lets alter that state 
# and make sure changes reflect
    
    is_deeply(
            $st_track->bound_param(2, 'foo'), 
            [ 'baz', 'foo' ], 
            '... we have the expected bound params');   

    $st_track->bound_param_trailing('bar', 'foobar');
    is_deeply(
            $st_track->bound_params(), 
            [ 'baz', 'foo', 'bar', 'foobar' ], 
            '... we have the expected bound params');    
            
    is($st_track->num_params(), 4, '... we have the expected num of bound params');    
    
    {
        my $old_SQL = $st_track->statement();
    
        my $SQL = 'INSERT INTO foo (foo, bar, baz) VALUE(1, 2, 3)';
        $st_track->statement($SQL);
        
        is($st_track->statement(), $SQL, '... our statement as expected ');  
        is($st_track->is_active(), 0, '... with an INSERT we are not considered active');  
        
        $st_track->statement($old_SQL);  
        
        is($st_track->statement(), $old_SQL, '... restore our statement');                          
    }
    
    $st_track->mark_executed();
    is($st_track->is_executed(), 'yes', '... our statement is now executed');    
    is($st_track->current_record_num(), 0, '... our current record num is 0'); 
    
    is($st_track->is_active(), 1, '... we are active now that we are executed'); 

    for (1 .. 3) {
        ok(!$st_track->is_depleted(), '... the state is not depleted');     
        is_deeply(
            $st_track->next_record(),
            [ $_, $_, $_ ],
            '... got the next record as expected');
        is($st_track->current_record_num(), $_, '... our current record num is now ' . $_);    
    }   
    
    ok(!defined($st_track->next_record()), '... no more records'); 
    ok($st_track->is_depleted(), '... we are now depleted'); 
    
    is($st_track->is_active(), 0, '... we are no longer active now that we are depleted');   
    
    is($st_track->is_finished(), 'no', '... passing in nothing just returns the value');
    
    $st_track->is_finished('yes');
    is($st_track->is_finished(), 'yes', '... our statement is now finished');                                
                                                                                                                                                                
    $st_track->is_finished('nothing');
    is($st_track->is_finished(), 'no', '... our statement is no longer finished');                                

}    
