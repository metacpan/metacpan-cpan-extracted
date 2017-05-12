=head1 NAME

DBIx::Class::Numeric - helper methods for numeric columns

=head1 SYNOPSIS

 package MyApp::Schema::SomeTable;

 use base 'DBIx::Class';

 __PACKAGE__->load_components(qw/Numeric Core/); # Load the Numeric component
												 # Don't forget to load it *before* Core!
 __PACKAGE__->add_columns(
     qw/primary_id some_string num_col1 num_col2 restricted bounded lower_bound upper_bound/
 );

 # Define 'simple' numeric cols, these will have some extra accessors & mutators
 #  created
 __PACKAGE__->numeric_columns(qw/num_col1 num_col2/);
 
 # Define min and max values for a column
 __PACKAGE__->numeric_columns(restricted => {min_value => 10, max_value => 30});
 
 # Define a column that's bound by the value of others
 __PACKAGE__->numeric_columns(bounded => {lower_bound_col => 'lower_bound', upper_bound_col => 'upper_bound'});

 # ... meanwhile, after reading a record from the DB

 $row->increase_num_col1(5); # Add 5 to num_col1

 $row->decrease_num_col2(9); # Subtract 9 from num_col2

 $row->adjust_num_col1(-5); # Subtract 5 from num_col1
                            # (can be positive or negative, as can increase/decrease...
                            #  adjust is just a clearer name...) 

 $row->increment_num_col1; # Increment num_col1

 $row->decrement_num_col2; # Decrement num_col2
 
 $row->restricted(40); # restricted col will be set to '30' since that's the max
 
 $row->lower_bound(5);
 $row->bounded(10);   # bounded will be set to '5', since its lower bound was set to 5

=head1 DESCRIPTION

A DBIx::Class component that adds some extra accessors / mutators to any numeric columns
you define. Additionally, columns can have max and min values defined, or be bound to the 
values of other columns in the table.

=head1 METHODS

=head2 numeric_columns(@cols)

Call this method as you would add_columns(), and pass it a list of columns that are numeric. Note,
you need to pass the column names to add_columns() *and* numeric_columns().

Any columns in this list will have extra accessors / mutators defined (see below).

If the item in the list after a column name is a hashref, the hashref will define the arguments for
that numeric column. (If the next item's not a hashref, it's assumed to be the next column - you can
mix and match columns with and without arguments in the same call to numeric_colums(). 

The valid keys in the argument hashref are:

=over 4

=item min_value / max_value

These two keys define the minimum and/or maximum value of the column. If you attempt to set the column
to a value outside this range, it will be set to that min or max value accordingly.

=item lower_bound_col / upper_bound_col

If either of these are set to the name of a column in the same table, the numeric column will be 
restricted in the same way as a min or max value, except the min/max value will be defined by the 
value of the column specified.

If the value of the lower or upper bound column changes, the bounded column won't be affected, until
its value is set. Eg. if your bounded column is currently 5, and you set it's lower_bound_col to
8 the bounded col won't change, even though it's below the minimum value. If you were to (eg) increment
the column, it would then be set to 8.

=back

=over

=item WARNING

Little (if any) validation is done on the list of cols passed to numeric_columns(). You could easily
pass it non-existant column names, etc. (This may be improved in a later release).

In particular, no check is made to see if you are using incompatible combinations of min/max_value
and lower/uppper_bound_col (e.g. both a min_value and a lower_bound_col). Doing this is unsupported,
and may be prevented in the future (even thought it might 'kind of' work at the moment). You're free
to use compatible combinations, though, eg. a min_value and an upper_bound_col.

=back  

=head2 increase_*, decrease_*, increment_*, decrement_*, adjust_*

These 5 methods are added to your schema class for each column you pass to numeric_cols(). E.g. if
you have a numeric column called 'foo', you will automagically get methods called increment_foo(), 
decrement_foo(), etc. They are fairly self-explanatory, with the possible exception of 'adjust_*'.
You can pass it either a positive or negative value to adjust the value of the column accordingly.  

=head1 AUTHOR

Sam Crawley (Mutant) - mutant dot nz at gmail dot com

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

package DBIx::Class::Numeric;

use strict;
use warnings;

our $VERSION = '0.004';

use base qw(DBIx::Class Class::Accessor::Grouped);

__PACKAGE__->mk_group_accessors('inherited', '_numeric_col_def');

use Sub::Name ();

sub numeric_columns {
	my $self = shift;
	my @cols = @_;
	
	my $count = 0;
	my %def;

	foreach my $col (@cols) {
		next if ref $col eq 'HASH';
		
		my $args = {};
		if (ref $cols[$count+1] eq 'HASH') {
			$args = $cols[$count+1];
		}
		$def{$col} = $args;
		
		my %methods = (
			adjust => sub {
				_adjust($col, @_);	
			},
			increase => sub {
	    		_increase($col, @_);
	    	},
	    	decrease => sub {
	    		_decrease($col, @_);
	    	},
	    	increment => sub {
	    		_increment($col, @_);
	    	},
	    	decrement => sub {
	    		_decrement($col, @_);
	    	} 
		);
   	
    	while (my ($method_name, $subref) = each %methods) {
    		no strict 'refs';
    		no warnings 'redefine';
    				
	    	my $name = join '::', $self, "${method_name}_$col";
      		*$name = Sub::Name::subname($name, $subref);
    	}		
	}
	continue {
		$count++;	
	}
	
	my $existing = $self->_numeric_col_def;
	%def = (%$existing, %def) if $existing;
		
	$self->_numeric_col_def(\%def);
}

sub _increase {
	my $col = shift;
	my $self = shift;
	my $increase = shift;

	$self->set_column($col, ($self->get_column($col) || 0) + ($increase || 0));	
}

sub _decrease {
	_increase($_[0], $_[1], -$_[2]);	
}

sub _increment {
	_increase($_[0], $_[1], 1);	
}

sub _decrement {
	_decrease($_[0], $_[1], 1);	
}

sub _adjust {
	_increase(@_);	
}

sub set_column {
    my $self = shift;
    my $column = shift;
    my $new_val = shift;
         
	$new_val = $self->_restrict_numeric($column, $new_val);

    return $self->next::method( $column, $new_val, @_ );
}

sub insert {
	my $self = shift;	
	
	if (my $def = $self->_numeric_col_def) {		
		foreach my $column (keys %$def) {
			next unless $def->{$column} && %{ $def->{$column} };
			
			my $val = $self->get_column($column);
			
			next unless defined $val;
			
			$self->set_column($column, $self->_restrict_numeric($column, $val));
		}
	}
	
	return $self->next::method( @_ );
}

sub _restrict_numeric {
	my $self = shift;
	my $column = shift;
	my $new_val = shift;
	
    my $def = $self->_numeric_col_def;

    if ($def) {
    	if (defined $def->{$column}{min_value} && $new_val < $def->{$column}{min_value}) {
    		$new_val = $def->{$column}{min_value};
    	}    	
    	if (defined $def->{$column}{max_value} && $new_val > $def->{$column}{max_value}) {
    		$new_val = $def->{$column}{max_value};
    	}
    	if (defined $def->{$column}{upper_bound_col}) {
    		my $max_val = $self->get_column($def->{$column}{upper_bound_col});
    		$new_val = $max_val if $new_val > $max_val;
    	}
    	if (defined $def->{$column}{lower_bound_col}) {
    		my $min_val = $self->get_column($def->{$column}{lower_bound_col});
    		$new_val = $min_val if $new_val < $min_val;
    	}
    }
    
    return $new_val;
}


1;