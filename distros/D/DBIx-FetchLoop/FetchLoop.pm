##############################################
## Copyright (c) 2002-2004 - Brendan Fagan
##############################################
package DBIx::FetchLoop;

use strict;
use vars qw($VERSION @ISA);

use Carp;
use DBI;

$VERSION = '0.6';

##############################################
## public methods
##############################################
sub new {
	my ($class,$sth,$dbi_method) = @_;
	unless($sth) {
                my ($p,$f,$l) = caller();
                croak("DBIx::FetchLoop statement handle empty from $p, $f at line $l\n");
        }  
        unless($sth->execute()) {
                my ($p,$f,$l) = caller();
                croak("DBIx::FetchLoop failed execute from $p, $f at line $l\n");
        }  
	my $obj = bless {
		_sth 		=> $sth,
		_dbi_method	=> $dbi_method	|| 'fetchrow_hashref',
		_data		=> {},
		_aggregates	=> {},
		_agg_list	=> [],
		_concatenates	=> {},
		_cat_list	=> [],
		_flags		=> {},
		_count		=> 0
	}, $class;
	push(@ISA,"DBIx::FetchLoop::$obj->{_dbi_method}");
	return $obj;
}

sub fetch_current_data {
	my $obj = shift;	

	unless ($obj->{_flags}->{done} == 1) {

		my $current 	= $obj->{_data}->{current}	|| undef;
		my $next 	= $obj->{_data}->{next}		|| undef;
	
		undef $obj->{_data}->{previous};
		undef $obj->{_data}->{current};
		undef $obj->{_data}->{next};
	
		if ($current) {
			$obj->{_data}->{previous} = $current;
		} else {
			$obj->{_data}->{current} = $obj->_fetch || undef;	
			if ($obj->{_data}->{current}) {
				$obj->{_count}++; 
			} else { 
				$obj->{_flags}->{done} = 1; 
				$obj->{_sth}->finish();
				undef $obj->{_sth};
				return undef; 
			}
		}
	
		undef $current;
	
		if ($next) {
			$obj->{_data}->{current} = $next;
			$obj->{_count}++; 
		}
	
		undef $next;
	
		unless ($obj->{_data}->{next} = $obj->_fetch) {
			$obj->{_flags}->{done} = 1;
			$obj->{_sth}->finish();
			undef $obj->{_sth};
		}

		$obj->_process_aggregates;
		$obj->_process_concatenates;

		if ($obj->{_data}->{current}) {
			return $obj->{_data};
		}
	} return undef;
}

sub fetch_current_row {
	my $obj = shift;

	my $data = $obj->fetch_current_data;
	if ($data) {
		return $data->{current};
	} else {
		return undef;
	}
}

sub previous {
	my $obj = shift;

	CASE: {
		unless ($obj->{_data}) {
			return undef;
			last CASE;
		}

		unless ($obj->{_data}->{previous}) {
			return undef;
			last CASE;
		}
		
		return $obj->{_data}->{previous};
	}
}

sub current {
	my $obj = shift;

	CASE: {
		unless ($obj->{_data}) {
			return undef;
			last CASE;
		}

		unless ($obj->{_data}->{current}) {
			return undef;
			last CASE;
		}
		
		return $obj->{_data}->{current};
	}
}

sub next {
	my $obj = shift;

	CASE: {
		unless ($obj->{_data}) {
			return undef;
			last CASE;
		}

		unless ($obj->{_data}->{next}) {
			return undef;
			last CASE;
		}
		
		return $obj->{_data}->{next};
	}
}

sub is_first {
	my $obj = shift;
	if ($obj->{_count} == 1) { return 1; }
	else { return 0; }
}

sub is_last {
	my $obj = shift;
	if ($obj->{_flags}->{done} == 1) { return 1; }
	else { return 0; }
}

sub count {
	my $obj = shift;
	$obj->{_count};
}

sub set_aggregate {
	my ($obj,$aggregate,$field) = (@_);

	unless ($obj->{_flags}->{kinetic} == 1) {
		$obj->{_aggregates}->{$aggregate} = $field;
		my $array = $obj->{_agg_list};
		push(@$array,$aggregate);
	} else {
		warn('Error: set_aggregate must be called before fetch_current_data or fetch_current_row');
	}
}
sub set_concatenate {
	my ($obj,$concatenate,$field) = (@_);
	
	unless ($obj->{_flags}->{kinetic} == 1) {
		$obj->{_concatenates}->{$concatenate} = $field;
		my $array = $obj->{_cat_list};
		push(@$array,$concatenate);
	} else {
		warn('Error: set_concatenate must be called before fetch_current_data or fetch_current_row');
	}
}
 
sub reset_aggregate {
	my ($obj,$aggregate) = (@_);
	$obj->_reset_field($aggregate);	
}

sub reset_concatenate {
	my ($obj,$concatenate) = (@_);
	$obj->_reset_field($concatenate);
}

##############################################
## Module cleanup
##############################################
sub DESTROY {
	my $obj = shift;

	if (($obj->{_flags}->{kinetic} == 1) && ($obj->{_flags}->{done} != 1)) {
		if ($obj->{_sth}) {
			$obj->{_sth}->finish;
		}
	}
}

##############################################
## private methods: fetchrow_hashref
##############################################
package DBIx::FetchLoop::fetchrow_hashref;

sub _fetch {
	my $obj = shift;
	return $obj->{_sth}->fetchrow_hashref;
}

sub _process_aggregates {
	my $obj = shift;
	my $agg_list = $obj->{_agg_list};
	foreach my $aggregate (@$agg_list) {
		my $field = $obj->{_aggregates}->{$aggregate};
		$obj->{_data}->{current}->{$aggregate} =
			$obj->{_data}->{previous}->{$aggregate} + $obj->{_data}->{current}->{$field};
	}
}

sub _process_concatenates {
	my $obj = shift;
	my $cat_list = $obj->{_cat_list};
	foreach my $concatenate (@$cat_list) {
		my $field = $obj->{_concatenates}->{$concatenate};
		$obj->{_data}->{current}->{$concatenate} =
			$obj->{_data}->{previous}->{$concatenate} . $obj->{_data}->{current}->{$field};
	}
}
sub pre_loop {
	my ($obj,$field) = @_;
	if ($field) {
		if ($obj->{_data}->{previous}->{$field} ne $obj->{_data}->{current}->{$field}) {
			return 1;
		} else {
			return 0;
		}
	} else {
		warn('Error: $field required when calling pre_loop');
	}
}

sub pre_loop_substr {
	my ($obj,$field,$offset,$length) = @_;
	if ($field && $length) {
		if (uc(substr($obj->{_data}->{previous}->{$field},$offset,$length)) ne uc(substr($obj->{_data}->{current}->{$field},$offset,$length))) {
			return 1;
		} else {
			return 0;
		}
	} else {
		warn('Error: $field, $offset, $length required when calling pre_loop_substr');
	}
}

sub post_loop {
	my ($obj,$field) = (@_);
	if ($field) {
		if ($obj->{_data}->{current}->{$field} ne $obj->{_data}->{next}->{$field}) {
			return 1;
		} else {
			return 0;
		}
	} else {
		warn('Error: $field required when calling post_loop');
	}
}

sub post_loop_substr {
	my ($obj,$field,$offset,$length) = @_;
	if ($field && $length) {
		if (substr($obj->{_data}->{current}->{$field},$offset,$length) ne substr($obj->{_data}->{next}->{$field},$offset,$length)) {
			return 1;
		} else {
			return 0;
		}
	} else {
		warn('Error: $field, $offset, $length required when calling post_loop_substr');
	}
}

sub _reset_field {
	my ($obj,$field) = @_;
	$obj->{_data}->{current}->{$field} = undef;
}

##############################################
## private methods: fetchrow_arrayref
##############################################
package DBIx::FetchLoop::fetchrow_arrayref;

sub _fetch {
	my $obj = shift;
	return $obj->{_sth}->fetchrow_arrayref;
}

sub _process_aggregates {
	my $obj = shift;
	my $agg_list = $obj->{_agg_list};
	foreach my $aggregate (@$agg_list) {
		my $field = $obj->{_aggregates}->{$aggregate};
		$obj->{_data}->{current}->[$aggregate] =
			$obj->{_data}->{previous}->[$aggregate] + $obj->{_data}->{current}->[$field];
	}
}

sub _process_concatenates {
	my $obj = shift;
	my $cat_list = $obj->{_cat_list};
	foreach my $concatenate (@$cat_list) {
		my $field = $obj->{_concatenates}->{$concatenate};
		$obj->{_data}->{current}->[$concatenate] =
			$obj->{_data}->{previous}->[$concatenate] . $obj->{_data}->{current}->[$field];
	}
}

sub pre_loop {
	my ($obj,$field) = (@_);
	if ($field) {
		if ($obj->{_data}->{previous}->[$field] ne $obj->{_data}->{current}->[$field]) {
			return 1;
		} else {
			return 0;
		}
	} else {
		warn('Error: $field required when calling pre_loop');
	}
}

sub pre_loop_substr {
	my ($obj,$field,$offset,$length) = @_;
	if ($field && $length) {
		if (substr($obj->{_data}->{previous}->[$field],$offset,$length) ne substr($obj->{_data}->{current}->[$field],$offset,$length)) {
			return 1;
		} else {
			return 0;
		}
	} else {
		warn('Error: $field, $offset, $length required when calling pre_loop_substr');
	}
}

sub post_loop {
	my ($obj,$field) = (@_);
	if ($field) {
		if ($obj->{_data}->{current}->[$field] ne $obj->{_data}->[next]->{$field}) {
			return 1;
		} else {
			return 0;
		}
	} else {
		warn('Error: $field required when calling post_loop');
	}
}

sub post_loop_substr {
	my ($obj,$field,$offset,$length) = @_;
	if ($field && $length) {
		if (substr($obj->{_data}->{current}->[$field],$offset,$length) ne substr($obj->{_data}->{next}->[$field],$offset,$length)) {
			return 1;
		} else {
			return 0;
		}
	} else {
		warn('Error: $field, $offset, $length required when calling post_loop_substr');
	}
}

sub _reset_field {
	my ($obj,$field) = @_;
	$obj->{_data}->{current}->[$field] = undef;
}

1;
__END__
=pod

=head1 NAME

DBIx::FetchLoop - Fetch with change detection and aggregates

=head1 SYNOPSIS

  use DBIx::FetchLoop;

  $lph = DBIx::FetchLoop->new($sth, $dbi_method);

  $hash_ref = $lph->fetch_current_data;
  $rowset = $hash_ref->{previous};
  $rowset = $hash_ref->{current};
  $rowset = $hash_ref->{next};

  $rowset = $lph->fetch_current_row;

  $rowset = $lph->previous;
  $rowset = $lph->current;
  $rowset = $lph->next;

  $lph->set_aggregate($new_field, $field);
  $lph->reset_aggregate($new_field);

  $lph->set_concatenate($new_field, $field);
  $lph->reset_concatenate($new_field);

  $boolean = $lph->pre_loop($field);
  $boolean = $lph->post_loop($field); 

  $boolean = $lph->pre_loop_substr($field,$offset,$length);
  $boolean = $lph->post_loop_substr($field,$offset,$length);

  $boolean = $lph->is_first;
  $boolean = $lph->is_last;

  $count = $lph->count;

=head1 DESCRIPTION

DBIx::FetchLoop is a supplemental approach for data retrieval with DBI. Result rows are queued 
with hash references to previous, current and next rows.  Utility functions allow for simplified
comparison of a field between previous and current or current and next rows.  Additional
functions allow you automatically create new fields for aggregating or concatenating based on 
fields in the resulting dataset.

Note:
This module was created with ease of use and performance in mind.  This module is intended to 
eliminate the need for temporary variables for loop detection as well as aggregation and concatenation.
The reason that not all DBI methods for data retrieval are not implemented (such as selectall_arrayref) 
is that the module's design for performance would be defeated.  

In essence you can write cleaner looking, more efficient code minus a few hassles.

=head1 METHODS

=head2 Instantiating a DBIx::FetchLoop object:

DBIx::FetchLoop requires two arguements when creating an object: a dbi statement handle, and 
a scalar identifying the DBI data retrieval method to utilize.  Supported DBI methods are:
	fetchrow_arrayref
	fetchrow_hashref

The module automatically handles calling the $sth->execute and $sth->finish functions of DBI,
therefore you only need to create the statement handle and pass it along.

Instantiating an object would look like this:

  use DBI;
  use DBIx::FetchLoop;

  $dbh = DBI->connect($connect_string);
  $sth = $dbh->prepare($sql);
  $lph = DBIx::FetchLoop->new($sth,'fetchrow_hashref');

If $dbi_method is not supplied, the module will default to using fetchrow_hashref.

The loop must be operated by calling $lph->fetch_current_data or $lph->fetch_current_row.

When the loop is done operating, DBIx::FetchLoop will call $sth->finish on the statement handle.

=head2 Retrieving data with fetch_current_data:

  $d = $lph->fetch_current_data;

$d is a hashref with elements to previous, current and next datasets as available.

eg (fetchrow_hashref)

  $d->{previous}->{field} 
  $d->{current}->{field} 
  $d->{next}->{field} 

eg (fetchrow_arrayref) 

  $d->{previous}->[1] 
  $d->{current}->[1] 
  $d->{next}->[1] 


=head2 Retrieving data with fetch_current_row:

This was added as an implementation to make code a bit cleaner and simpler to use. 

  $rowset = $lph->fetch_current_row;

eg (fetchrow_hashref)

  $rowset->{field} 

eg (fetchrow_arrayref) 

  $rowset->[1] 

=head2 Accessor methods:

Regardless of calling $lph->fetch_current_row or $lph->fetch_current_data, you can use accessor methods to access the previous, next, and current rows.

$rowset = $lph->previous;
$rowset = $lph->current;
$rowset = $lph->next;

=head2 Conditional testing:

These functions exist to make the code necessary for detecting a new loop a little cleaner.

  $lph->pre_loop($field);  - compares $field between previous and current rows, returns true if different
  $lph->post_loop($field); - compares $field between current and next rows, returns true if different
 
  $lph->pre_loop_substr($field,$offset,$length);  - compares substring of $field between previous and current rows, returns true if different
  $lph->post_loop_substr($field,$offset,$length);- compares substring of $field between current and next rows, returns true if different
 
  $lph->is_first; - returns true if current record is first record
  $lph->is_last;  - returns true if current record is last record

=head2 Data Utilities: 

  $lph->set_aggregate($new_field, $field);
  $lph->set_concatenate($new_field, $field);

These functions allow you to create new fields in the resulting dataset that are aggregates or
concatenates of an original field in the data set. They must be called before the first time you
call $lph->fetch_current_data.

  $lph->reset_aggregate($new_field);
  $lph->reset_concatenate($new_field);

These functions reset the value of the specified field to undef in the current dataset.  They can be 
called anytime during the running of the program.

  $lph->count; - return the number of the current row returned (starts at 1)

=head1 EXAMPLES

=head2 Example 1 (fetchrow_hashref):

  use DBI;
  use DBIx::FetchLoop;

  $dbh = DBI->connect(...);
  $sth = $dbh->prepare('select company, department, bank_account, balance from account_table");
  $lph = DBIx::FetchLoop->new($sth,'fetchrow_hashref');

  $lph->set_aggregate('department_rollup','balance');
  $lph->set_aggregate('company_rollup','balance');

  while (my $d = $lph->fetch_current_row) {

    if ($lph->pre_loop('company')) {
      print "Company: " . $d->{company} . "\n";
    }

    if ($lph->pre_loop('department')) {
      print "Department: " . $d->{department} . "\n";
    }

    print "Account: " . $d->{bank_account} . " : " . $d->{balance} . "\n";

    if ($lph->post_loop('department')) {
      print "Department Balance: " . $d->{department_rollup} . "\n";
      $lph->reset_aggregate('department_rollup');
    }

    if ($lph->post_loop('company')) {
      print "Company Balance: " . $d->{company_rollup} . "\n\n";
      $lph->reset_aggregate('company_rollup');
    }
  }

  $dbh->disconnect;


=head2 Example 2 (fetchrow_arrayref):

  use DBI;
  use DBIx::FetchLoop;

  $dbh = DBI->connect(...);
  $sth = $dbh->prepare('select company, department, bank_account, balance from account_table");
  $lph = DBIx::FetchLoop->new($sth,'fetchrow_arrayref');

  $lph->set_aggregate(4,3);
  $lph->set_aggregate(5,3);

  while (my $d = $lph->fetch_current_data) {
	
    if ($lph->pre_loop(0)) {
      print "Company: " . $d->{current}->[0] . "\n";
    }

    if ($lph->pre_loop(1)) {
      print "Department: " . $d->{current}->[1] . "\n";
    }

    print "Account: " . $d->{current}->[2] . " : " . $d->{current}->[3] . "\n";

    if ($lph->post_loop(1)) {
      print "Department Balance: " . $d->{current}->[4] . "\n";
      $lph->reset_aggregate(4);
    }

    if ($lph->post_loop(0)) {
      print "Company Balance: " . $d->{current}->[5] . "\n\n";
      $lph->reset_aggregate(5);
    }
  }

  $dbh->disconnect;


=head2 Example 3 (concatenation, fetchrow_hashref and substring comparison)

  use DBI;
  use DBIx::FetchLoop;

  $dbh = DBI->connect(...);
  $sth = $dbh->prepare('select news_group, message_header, message_part from news");
  $lph = DBIx::FetchLoop->new($sth,'fetchrow_hashref');

  $lph->set_concatenate('whole_message','message_part');

  while (my $d = $lph->fetch_current_data) {

    if ($lph->is_first) {
      print "News Viewing App\n";
    }

    if ($lph->pre_loop('news_group')) {
      print "Group: " . $d->{current}->{news_group} . "\n";
    }

    if ($lph->pre_loop_substr('message_header',4,10)) { 
      print "Title: " . substr($d->{current}->{message_header},4,10) . "\n";
      print "Author: " . substr($d->{current}->{message_header},14,10) . "\n";
      print "Result #" . $lph->count . "\n";
    }

    if (i$lph->post_loop_substr('message_header',4,10)) { 
      print "Message: \n" . $d->{current}->{whole_message} . "\n\n";
      $lph->reset_concatenate('whole_message');
    }

    if ($lph->is_last) {
      print "All done\n";
    }

  }

  $dbh->disconnect;

=head1 CHANGES

Please see the CHANGES file in the module distribution.

=head1 TO-DO

 - Spend more time on the documentation.

 - More in-depth examples (with comments)

=head1 ACKNOWLEDGEMENTS

Thanks to Tim Bunce for a lesson in the finer points of module naming.  :)

=head1 AUTHOR 

Brendan Fagan <suburbanantihero (at) yahoo (dot) com>. Comments, bug reports, patches and flames are appreciated. 

=head1 COPYRIGHT

Copyright (c) 2002-2004 - Brendan Fagan

=cut
