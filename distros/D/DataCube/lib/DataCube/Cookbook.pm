package DataCube::Cookbook;


use strict;
use warnings;

1;

__END__;


=head1 NAME

Cookbook - Tips and Tricks for Business Intelligence with DataCube

=head1 DESCRIPTION

This document contains a collection of practical techniques for accomplishing large scale Business Intelligence tasks with DataCube. These techniques are what I am using at the moment. Feel free to use them, hack them, turn them inside out and do it again.

I hope they will save you time.


=head2 Emulating SQL functions

=head3 Problem

    You want to emulate SQL's 
    
            count(column_name)
            
            count(distinct column_name))
    
    aggregation functions.

=head3 Solution

    Use the count measure provided by DataCube::Schema
    
    Example: Suppose you have a database that stores sales data.
             In particular, suppose that the salesperson, country and product
             associated with each sale is recorded.  Set up a Schema like so:
    
            
        my $schema = DataCube::Schema->new;
        
        $schema->add_dimension('country');
        $schema->add_dimension('salesperson');
        
        $schema->add_measure('count');
        $schema->add_measure('count','products');

=head3 Discussion

    Any cube made from this schema will track the number of sales made
    by each salesperson in each country, along with the corresponding number
    of different products.
    
    The SQL equivalent of the cube's base_table would be as follows:
    
        select
              country
            , salesperson
            , count(*)
            , count(distinct products)
        from
            sales
        group by
            country, salesperson


=head2 use less 'ram';

=head3 Problem

    You want to use less memory associated with rollup


=head3 Solution

    Use lazy_rollup.
    
        while( my $next_cube = $cube->lazy_rollup ) {
            
            $next_cube->commit( 'data_warehouse/archive' );
            
        }

=head3 Discussion

    the rollup method uses:
        
            O( m )  space complexity
        O( log(m) ) time  complexity
    
    whereas the lazy_rollup method uses:
    
             O( 1 ) space complexity
             O( m ) time  complexity
    
    where m is the number of rollup tables (aka reports) to be generated.
    
    These are estimates.  The real best / worst / average case runtime complexity
    depends on your data.  Please use these estimates conservatively as heuristics
    until I prove the actual bounds. 




=head2 use more 'cpus';

=head3 Problem

    You want to use process threads to launch parallel cube workers
    
    In particular, you want to commit a cube in parallel with feeding it more data.    

=head3 Solution

    Use Perl fork and the reset method 
        
        for( @files ) {
            
            $cube->load_data_infile( $_ );
            
            fork_me( $cube );
            
            $cube->reset;
            
        }
        
        sub fork_me {
        
            my($cube) = @_;
            
            return if my $pid = fork;
            
            $cube->rollup;
            $cube->commit( $commit_target )
            
            exit;
        
        }

=head3 Discussion

    No discussion.  This just works.
    
    Just be sure you dont try to start a new commit if the last one is still working.
    
    (That is, develop a locking system)


=head2 Commit some tables, report others

=head3 Problem

    You want to commit some of your tables to disk for long term storage,
    but simply report the others.
    
    Example:
    
        my $schema = DataCube::Schema->new;
        
        $schema->add_dimension('country');
        $schema->add_dimension('salesperson');
        
        $schema->add_hierarchy('year','month','day');
        
        $schema->add_measure('count', 'product');
        
        $cube->load_data_infile('sales.tsv');
        
    Now imagine you wanted to commit the monthly numbers
    while only reporting the daily numbers 


=head3 Solution

    Use lazy_rollup and dispatch events as you see fit:
    
        while( my $next_cube = $cube->lazy_rollup ) {
            
            dispatch: {
                
                $next_cube->report( 'data_warehouse/reports' )
                    and last dispatch
                    if exists $next_cube->schema->field_names->{day};
                
                $next_cube->commit( 'data_warehouse/archive' )
                    and last dispatch;
            
            }
        
        }

=head3 Discussion

    This solution will commit the monthly numbers, but only report the daily numbers.
    
    More complex dispatch mechanisms (including multiple dispatch) are certainly possible. 


=head2 ACID Compliant Transactions

=head3 Problem

    You want to achieve ACID compliance.
    In particular, you want to start by ensuring Atomicity during the commit process.
    
    For those not familiar with Atomicity, this means you want to
    make sure a commit process happens entirely or not at all.
    
    If your machine loses power in the middle of the commit process,
    your data committed to date will not be corrupted. 

=head3 Solution

    ACID compliant commits can be achieved like so:
    
        $cube->load_data_infile('sales.tsv');
        
        require DataCube::FileUtils;
        require DataCube::FileUtils::CubeMerger;
        
        my @errors;
        
        my $commit_target      = 'data_warehouse/cubes/my_cube';
        my $transaction_target = 'data_warehouse/cubes/my_cube.temp';
        
        mkdir($transaction_target)
            or die "cant make dir:\n$transaction_target\n$!\n";
        
        my $utils  = DataCube::FileUtils->new;
        my $merger = DataCube::FileUtils::CubeMerger->new;
            
        txn_begin:
        {
            eval {    
                while(my $next_cube = $cube->lazy_rollup) {
                   $next_cube->commit($transaction_target);
                }   
                $merger->merge(
                    source => $commit_target,
                    target => $transaction_target,
                );
            };
            push @errors, $@ if $@;
            
            system("sync");
            
            unless($? == 0){
                push @errors, "sync returned a bad status: $?\n";
            }
            
        }
        
        txn_rollback:
        {
            last txn_rollback unless @errors;   
            eval {
                $utils->unlink_recursive($transaction_target);
            };
            my $error = $@ ? "there were rollback errors:\n$@\n" : '';
            die "txn_rollback complete\ncause of rollback:\n@errors\n$error\n";   
        }
        
        txn_finish:
        {
            my $pending = "$commit_target.pending";
            
            eval {
                
                rename($commit_target, $pending)            or die "final-stage-1: $!\n";
                rename($transaction_target, $commit_target) or die "final-stage-2: $!\n";
                
                $utils->unlink_recursive($pending)          or die "final-stage-3: $!\n";
                
                # or you can keep the $pending directory as an incremental 'checkpoint' 
            
            };
            
            push @errors, $@ if $@;
            die join("\n",@errors) if @errors;
        }
        
        # dying at final-stage-2 is the only place that
        # requires manual intervention to fix a broken commit target.
        
        return 1;


=head3 Discussion

    This approach will take slightly longer than simply calling
    
        $cube->commit( $commit_target );
    
    However, your data will always be in a consistent state.
    
    Notice that for the code in the solution to work, you must have the 'sync'
    utility in your system and it must return 0 on succes. 

=head1 AUTHOR

David Williams, E<lt>david@namimedia.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by David Williams

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
