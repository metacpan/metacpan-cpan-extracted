package DBIx::Class::OptimisticLocking;
BEGIN {
  $DBIx::Class::OptimisticLocking::VERSION = '0.02';
}

# ABSTRACT: Optimistic locking support for DBIx::Class

use strict;
use warnings;

use DBIx::Class 0.08195;
use base 'DBIx::Class';
use Carp qw(croak);
use List::Util qw(first);


__PACKAGE__->mk_classdata( optimistic_locking_strategy => 'dirty' );
__PACKAGE__->mk_classdata('optimistic_locking_ignore_columns');
__PACKAGE__->mk_classdata( optimistic_locking_version_column => 'version' );

my %valid_strategies = map { $_ => undef } qw(dirty all none version);

sub optimistic_locking_strategy {
	my @args = @_;
	my $class = shift(@args);
	my ($strategy) = $args[0];
	croak "invalid optimistic_locking_strategy $strategy" unless exists $valid_strategies{$strategy};
	return $class->_opt_locking_strategy_accessor(@args);
}


sub update {
	my $self = shift;
	my $upd = shift;

	# we have to do this ahead of time to make sure our WHERE
	# clause is computed correctly
	$self->set_inflated_columns($upd) if($upd);

	# short-circuit if we're not changed
	return $self if !$self->is_changed;

    if ( $self->optimistic_locking_strategy eq 'version' ) {
		# increment the version number but only if there are dirty
		# columns that are not being ignored by the optimistic
		# locking

		my %dirty_columns = $self->get_dirty_columns;

		delete(@dirty_columns{ @{ $self->optimistic_locking_ignore_columns || [] } });

		if(%dirty_columns){
			my $v_col = $self->optimistic_locking_version_column;

			my $current_version = $self->{_column_data_in_storage}{$v_col};
			$current_version = $self->get_column($v_col) || 0 if ! defined $current_version;

			# increment the version
			$self->set_column( $v_col, $current_version + 1);
		}
    }

	my $return = $self->next::method();

	return $return;
}


sub _track_storage_value {
	my ( $self, $col ) = @_;

	return 1 if $self->next::method($col);

	my $mode = $self->optimistic_locking_strategy;
	my $ignore_columns = $self->optimistic_locking_ignore_columns || [];

	if ( $mode eq 'dirty' || $mode eq 'all' ) {
		return !first { $col eq $_ } @$ignore_columns;    # implicit return from do block
	} elsif ( $mode eq 'version' ) {
		return $col eq $self->optimistic_locking_version_column;    # implicit return from do block
	}

	return 0;
}


sub _storage_ident_condition {
	my $self = shift;
	my $ident_condition = $self->next::method(@_);

	# YUCK YUCK YUCK
	my(undef,undef,undef,$caller) = caller(1);
	return $ident_condition if $caller eq 'DBIx::Class::Row::get_from_storage';

	my $mode = $self->optimistic_locking_strategy;

	my $ignore_columns = $self->optimistic_locking_ignore_columns || [];
		
	if ( $mode eq 'dirty' ) {
        my %orig = %{$self->{_column_data_in_storage} || {}};
		delete @orig{@$ignore_columns};
        $ident_condition = {%orig, %$ident_condition };
	} elsif ( $mode eq 'version' ) {
		my $v_col = $self->optimistic_locking_version_column;
		$ident_condition->{ $v_col } = defined $self->{_column_data_in_storage}{$v_col} ? $self->{_column_data_in_storage}{$v_col} : $self->get_column($v_col);
	} elsif ( $mode eq 'all' ) {
        my %orig = ($self->get_columns, %{$self->{_column_data_in_storage} || {}});
		delete @orig{@$ignore_columns};
		$ident_condition = { %orig, %$ident_condition };
	}

	return $ident_condition;
}


1; # End of DBIx::Class::OptimisticLocking

__END__
=pod

=head1 NAME

DBIx::Class::OptimisticLocking - Optimistic locking support for DBIx::Class

=head1 VERSION

version 0.02

=head1 SYNOPSIS

This module allows the user to utilize optimistic locking when updating
a row.

Example usage:

	package DB::Main::Orders;

	use base qw/DBIx::Class/;

	__PACKAGE__->load_components(qw/OptimisticLocking Core/);

	__PACKAGE__->optimistic_locking_strategy('dirty'); # this is the default behavior

=head1 PURPOSE

Optimistic locking is an alternative to using exclusive locks when
you have the possibility of concurrent, conflicting updates in your
database.  The basic principle is you allow any and all clients to issue
updates and rather than preemptively synchronizing all data modifications
(which is what happens with exclusive locks) you are "optimistic" that
updates won't interfere with one another and the updates will only fail
when they do in fact interfere with one another.

Consider the following scenario (in timeline order, not in the same
block of code):

	my $order = $schema->resultset('Orders')->find(1);

	# some other different, concurrent process loads the same object
	my $other_order = $schema->resultset('Orders')->find(1);

	$order->status('fraud review');
	$other_order->status('processed');

	$order->update; # this succeeds
	$other_order->update; # this fails when using optimistic locking

Without locking (optimistic or exclusive ), the example order
would have two sequential updates issued with the second essentially
erasing the results of the first.  With optimistic locking, the second
update (on C<$other_order>) would fail.

This optimistic locking is typically done by adding additional
restrictions to the C<WHERE> clause of the C<UPDATE> statement.  These
additional restrictions ensure the data is still in the expected state
before applying the update.  This DBIx::Class::OptimisticLocking component
provides a few different strategies for providing this functionality.

=head1 CONFIGURATION

=head2 optimistic_locking_strategy

This configuration controls the main functionality of this component.
The current recognized optimistic locking modes supported are:

=over 4

=item * dirty

When issuing an update, the C<WHERE> clause of the update will include
all of the original values of the columns that are being updated.
Any columns that are not being updated will be ignored.

=item * version

When issuing an update, the C<WHERE> clause of the update will include
a check of the C<version> column (or otherwise configured column using
L<optimistic_locking_version_column>).  The C<version> column will
also be incremented on each update as well.  The exception is if all
of the updated columns are in the L<optimistic_locking_ignore_columns>
configuration.

=item * all

When issuing an update, the C<WHERE> clause of the update will include
a check on each column in the object regardless of whether they were
updated or not.

=item * none (or any other value)

This turns off the functionality of this component.  But why would you
load it if you don't need it? :-)

=back

=head2 optimistic_locking_ignore_columns

Occassionally you may elect to ignore certain columns that are not
significant enough to detect colisions and cause the update to fail.
For instance, if you have a timestamp column, you may want to add that
to this list so that it is ignored when generating the C<UPDATE> where
clause for the update.

=head2 optimistic_locking_version_column

If you are using 'version' as your L<optimistic_locking_strategy>,
you can optionally specify a different name for the column used for
version tracking.  If an alternate name is not passed, the component
will look for a column named C<version> in your model.

=head1 EXTENDED METHODS

=head2 update

See L<DBIx::Class::Row::update> for basic usage.

Before issuing the actual update, this component injects additional
criteria that will be used in the C<WHERE> clause in the C<UPDATE>. The
criteria that is used depends on the L<CONFIGURATION> defined in the
model class.

=head2 _track_storage_value

This is a method internal to L<DBIx::Class::Row> that basically serves
as a predicate method that indicates whether or not the orginal value
of the row (as loaded from storage) should be recorded when it is updated.

Typically, only primary key values are persisted but for
L<DBIx::Class::OptimisticLocking>, this list is augmented to include other
columns based on the optimistic locking strategy that is configured for
this L<DBIx::Class::ResultSource>.  For instance, if the chosen strategy
is 'C<dirty>' (the default), every column's original value will be tracked
in order to generate the appropriate C<WHERE> clause in any subsequent
C<UPDATE> operations.

=head2 _storage_ident_condition

This is an internal method to L<DBIx::Class::PK> that generates the C<WHERE>
clause for update and delete operations.

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-optimisticlocking at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-OptimisticLocking>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::OptimisticLocking

=head1 ACKNOWLEDGEMENTS

Credit goes to the Java ORM package L<Hibernate|http://hibernate.org>
for inspiring me to write this for L<DBIx::Class>.

=head1 AUTHOR

  Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Brian Phillips.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

