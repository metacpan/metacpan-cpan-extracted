use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Query;
our $VERSION = '0.98';
use base qw(Apache::Wyrd::Interfaces::Setter Apache::Wyrd);
use Apache::Wyrd::Services::SAK qw(token_parse);

=pod

=head1 NAME

Apache::Wyrd::Query - SQL-handle (DBI) object for Wyrds

=head1 SYNOPSIS

	<Apache::Wyrd::Query>
	  update table set row='value' where row='old_value';
	  delete from table where row='obsolete value'
	</Apache::Wyrd::Query>
	
	<Apache::Wyrd::Query query="delete from table where row=23" />

	<Apache::Wyrd::Query>
	  update table set row=$:row_value where row='old_value'
	  <Apache::Wyrd::Var name="row_value">value</Apache::Wyrd::Var>
	</Apache::Wyrd::Query>

=head1 DESCRIPTION

Provides a DBI-style statement handle to the Wyrd that encloses it.  The
parent must implement the C<register_query> method to make use of it.  The
Query Wyrd passes a reference of itself to the C<register_query> method.

=head2 HTML ATTRIBUTES

=over

=item cols

What columns the statement will return.  Automatically defined under
MySQL.  Dev Note: Derived classes for other DBAs should subclass the
C<_set_cols> method for DBDs other than MySQL if the automatic
maintenance of this attribute is to be accomplished and required.

=item query

What statement to execute.  If not defined, will default to the enclosed
text.  Multiple queries can be given, separated by a semicolon.  If
output is expected (via the C<sh> method), only the final query in a
series will be used.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (scalar) C<activate> (void)

Activate the Database Query, prepping the Query object to begin
producing data.  Should be called before any calls to C<sh>.

=cut

sub activate {
	my ($self) = @_;
	return undef if ($self->{'_activated'});
	my $query = $self->_get_query;
	$self->_raise_exception('No query was provided') unless ($query);
	$self->_info("preparing query: $query");
	my @queries = split (';', $query);
	foreach my $subquery (@queries) {
		next unless($subquery =~ /\S+/);
		$self->_info("executing $subquery");
		$self->{'sh'} = $self->dbl->dbh->prepare($subquery);
		$self->{'sh'}->execute;
		$self->_check_bad_statement;
	}
	$self->_set_cols unless ($self->{'cols'});
	$self->{'_activated'} = 1;
	return;
}

=pod

=item arrayref C<cols> (void)

Return the column names, as an arrayref.

=cut

sub cols {
	my ($self) = @_;
	$self->_raise_exception('cols requested before activate') unless ($self->{'_activated'});
	return ($self->{'cols'} || []);
}


=pod

=item (void) C<set_var> (Apache::Wyrd::Var)

Use the Var object to change the value-placemarkers of the query.  Items
with a setter-style placemarker which matches the name of the object
will be replaced with the object's value.  This is for right-hand values
only, as the value will be C<quote>d by DBI.

=cut

sub set_var {
	my ($self, $var) = @_;
	$self->{'_variables'}->{$var->name} = $var->value;
}

=pod

=item (void) C<sh> (Apache::Wyrd::Var)

The DBI statement handle.

=cut

sub sh {
	my ($self) = @_;
	$self->_raise_exception('sh requested before activate') unless ($self->{'_activated'});
	return $self->{'sh'};
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Reserves the C<_setup>, C<_format_output>, and C<_generate_output>
methods.

=cut

sub _setup {
	my ($self) = @_;
	$self->{'_variables'} = {};
	$self->{'sh'} = undef;
	$self->_raise_exception('A query object must have a valid connection to a DBI Handle object')
		unless ($self->dbl->dbh->ping);
}

sub _format_output {
	my ($self) = @_;
	$self->{'_temp_data'} = $self->{'_data'};
	$self->{'_data'} = undef;
}

sub _generate_output {
	my ($self) = @_;
	if ($self->{'_parent'}->can('register_query')) {
		$self->activate;
		$self->{'_parent'}->register_query($self);
	} else {
		$self->_warn("Query '" . $self->{'query'} . "' called, but not used.  Parent should register_query.");
	}
	return;
};


=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub _check_bad_statement {
	my ($self) = @_;
	$self->_raise_exception($self->{'sh'}->errstr) if ($self->{'sh'}->err);
}

sub _get_query {
	my ($self) = @_;
	my $query = $self->{'query'};
	$query ||= $self->{'_temp_data'};
	$query = $self->_perform_substitutions($query) if ($query =~ /\$:/);
	return $query;
}

sub _perform_substitutions {
	my ($self, $query) = @_;
	foreach my $var ($query =~ m/\$:(\w+)/g) {
		#note that the variable will be created and set to NULL, so _raise_exception
		#isn't needed
		$self->_warn("Failed to find $var in provided variables.  Using undef value.") unless $self->{'_variables'}->{$var};
		$self->{'_variables'}->{$var} = $self->dbl->dbh->quote($self->{'_variables'}->{$var});
	}
	return $self->_set($self->{'_variables'}, $query);
}

sub _set_cols {
	my ($self) = @_;
	my $cols = $self->{'cols'};
	unless (ref($cols) eq 'ARRAY') {
		if ($cols) {#assume user-defined attribute
			$cols = [token_parse($cols)];
		} else {#assume undefined attribute
			$cols = $self->{'sh'}->{NAME_lc};
		}
	}
	$self->_warn('Cols is undefined.') unless ($cols);
	$self->{'cols'} = $cols;
}

1;
