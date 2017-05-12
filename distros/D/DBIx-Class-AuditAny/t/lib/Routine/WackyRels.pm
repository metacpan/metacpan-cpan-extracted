package # hide from PAUSE
     Routine::WackyRels;
use strict;
use warnings;

use Test::Routine;
with 'Routine::Base';

use Test::More; 
use namespace::autoclean;

has 'test_schema_class', is => 'ro', default => 'TestSchema::WackyRels';

test 'inserts' => { desc => 'Insert Test Data' } => sub {
  my $self = shift;
  my $schema = $self->Schema;
  
  $schema->txn_do(sub {
    
    $schema->resultset('Grade')->create({ letter => 'A' });
    
    ok(
      # Remove $ret to force VOID context (needed to test Storgae::insert_bulk codepath)
      do { my $ret = $schema->resultset('Size')->populate([
        [qw(name detail)],
        ['big',"Largest Size"],
        ['medium',"In-between"],
        ['small',"Starbucks calls it 'Tall'"]
      ]); 1; },
      "Populate Some Size rows"
    );
  });
  
  
  $schema->txn_do(sub {
    ok(
      # Remove $ret to force VOID context (needed to test Storgae::insert_bulk codepath)
      do { my $ret = $schema->resultset('Parent')->populate([
        [qw(color size info)],
        ['blue','big',"Big Blue Parent!"],
        ['blue','medium',"Medium Blue Parent!"]
      ]); 1; },
      "Populate Some Parent rows"
    );
  });
  
  $schema->txn_do(sub {
    ok(
      # Remove $ret to force VOID context (needed to test Storgae::insert_bulk codepath)
      do { my $ret = $schema->resultset('Child')->populate([
        [qw(color size info)],
        ['blue','big',"First child"],
        ['blue','big',"Second child"],
        ['blue','big',"Third child"],
        ['blue','medium',"alpha"],
        ['blue','medium',"bravo"]
      ]); 1; },
      "Populate Some Child rows"
    );
  });
  
  $schema->txn_do(sub {
    ok(
      # Remove $ret to force VOID context (needed to test Storgae::insert_bulk codepath)
      do { my $ret = $schema->resultset('Product')->populate([
        [qw(sku size info)],
        ['33-456BL','big',"White plastic bowl"],
        ['67GB','medium',"George Bush Tee-Shirt"],
        ['UU-900','big',"Cell Phone o-ring"],
        ['I3-W','big',"Widget for source-code incinerator"],
        ['IPU-5000','small',"Puppy incinerator"],
      ]); 1; },
      "Populate Some Product rows"
    );
  });
	
	$schema->txn_do(sub {
    ok(
      # Remove $ret to force VOID context (needed to test Storgae::insert_bulk codepath)
      do { my $ret = $schema->resultset('Thing')->populate([
        [qw(name size grade info)],
        ['Blarg','big','A',"foo"],
        ['Smlebber','medium','A',"doo-hickey"],
      ]); 1; },
      "Populate Some Thing rows"
    );
    
    ok(
      $schema->resultset('Thing')->create({
        name => 'Wiget',
        size => 'small',
        grade => { letter => 'B' },
        info => 'Moof bopper'
      }),
      "Create Thing with new Grade row"
    );
    
    ok(
      $schema->resultset('Grade')->create({
        letter => 'C',
        things => [
          { name => 'willy', size => 'small', info => '?!#' },
          { name => 'billy', size => 'medium', info => '?!#' },
          { name => 'milly', size => 'small', info => '?!#' },
        ]
      }),
      "Create Grade 'C' with Things"
    );
    
  });
  
};


test 'updates_cascades' => { desc => 'Updates causing db-side cascades' } => sub {
  my $self = shift;
  my $schema = $self->Schema;
  
  ok(
    my $Parent = $schema->resultset('Parent')->search_rs({ 
      size => 'big',
      color => 'blue'
    })->first,
    "Find 'big-blue' Parent row"
  );
  
  ok(
    $Parent->update({ color => 'red' }),
    "Change the PK of the 'big-blue' Parent row (should cascade)"
  );
  
  ok(
    my $Size = $schema->resultset('Size')->search_rs({ 
      name => 'big',
    })->first,
    "Find 'big' Size row"
  );
  
  ok(
    $Size->update({ name => 'venti' }),
    "Change the PK of the 'big' Size row (should cascade + double-cascade [3 tables])"
  );
  
};	

1;