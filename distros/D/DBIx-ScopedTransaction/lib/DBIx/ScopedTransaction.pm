package DBIx::ScopedTransaction;

use strict;
use warnings;

use Carp qw();
use Data::Validate::Type qw();
use Try::Tiny qw();


=head1 NAME

DBIx::ScopedTransaction - Scope database transactions on DBI handles in code, to detect and prevent issues with unterminated transactions.


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';

our $DESTROY_LOGGER;


=head1 SYNOPSIS

	use DBIx::ScopedTransaction;
	use Try::Tiny;

	# Optional, define custom logger for errors detected when destroying a
	# transaction object. By default, this prints to STDERR.
	$DBIx::ScopedTransaction::DESTROY_LOGGER = sub
	{
		my ( $messages ) = @_;

		foreach my $message ( @$messages )
		{
			warn "DBIx::ScopedTransaction: $message";
		}
	};

	# Start a transaction on $dbh - this in turn calls $dbh->begin_work();
	my $transaction = DBIx::ScopedTransaction->new( $dbh );
	try
	{
		# Do some work on $dbh that may succeed or fail.
	}
	finally
	{
		my @errors = @_;
		if ( scalar( @errors ) == 0 )
		{
			$transaction->commit() || die 'Failed to commit transaction';
		}
		else
		{
			$transaction->rollback() || die 'Failed to roll back transaction.';
		}
	};


=head1 DESCRIPTION

Small class designed to be instantiated in a localized scope. Its purpose
is to start and then clean up a transaction on a DBI object, while detecting
cases where the transaction isn't terminated properly.

The synopsis has an example of working code, let's see here an example in
which DBIx::ScopedTransaction helps us to detect a logic error in how the
programmer handled terminating the transaction.

	sub test
	{
		my $transaction = DBIx::ScopedTransaction->new( $dbh );
		try
		{
			# Do some work on $dbh that may succeed or fail.
		}
		catch
		{
			$transaction->rollback();
		};
	}

	test();

As soon as the test() function has been run, $transaction goes out of scope and
gets destroyed by Perl. DBIx::ScopedTransaction subclasses destroy and detects
that the underlying transaction has neither been committed nor rolled back,
and forces a rollback for safety as well as prints details on what code should
be reviewed on STDERR.


=head1 METHODS

=head2 new()

Create a new transaction.

	my $transaction = DBIx::ScopedTransaction->new(
		$database_handle,
	);

=cut

sub new
{
	my ( $class, $database_handle ) = @_;

	# If we're in void context, DESTROY will be called immediately on the
	# object we return in new(), which is not desirable and indicates an
	# error in the calling code. To prevent unhelpful reports of
	# "transaction not completed properly", we instead catch it here before
	# we even instantiate the object.
	Carp::croak(
		'You need to assign the output of DBIx::ScopedTransaction to a ' .
		'variable, otherwise it would get destroyed immediately.'
	) if !defined( wantarray() );

	Carp::croak('You need to pass a database handle to create a new transaction object')
		if !Data::Validate::Type::is_instance( $database_handle, class => 'DBI::db' );

	Carp::croak('A transaction is already in progress on this database handle')
		if !$database_handle->begin_work();

	my ( undef, $filename, $line ) = caller();

	return bless(
		{
			database_handle => $database_handle,
			active          => 1,
			filename        => $filename,
			line            => $line,
		},
		$class
	);
}


=head2 get_database_handle()

Return the database handle the current transaction is operating on.

	my $database_handle = $transaction->get_database_handle();

=cut

sub get_database_handle
{
	my ( $self ) = @_;

	return $self->{'database_handle'};
}


=head2 is_active()

Return whether the current transaction object is active.

	# Get the active status of the transaction.
	my $is_active = $transaction->is_active();

	# Set the active status of the transaction.
	$transaction->is_active( $is_active );

The transaction object goes inactive after a successful commit or rollback.

=cut

sub is_active
{
	my ( $self, $value ) = @_;

	if ( defined( $value ) )
	{
		$self->{'active'} = $value;
	}

	return $self->{'active'};
}


=head2 commit()

Commit the current transaction.

	my $commit_successful = $transaction->commit();

=cut

sub commit
{
	my ( $self ) = @_;

	if ( ! $self->is_active() )
	{
		Carp::carp('Logic error: inactive transaction object committed again');
		return 0;
	}

	my $database_handle = $self->get_database_handle();
	if ( $database_handle->commit() )
	{
		$self->is_active( 0 );
		return 1;
	}
	else
	{
		my $error = $database_handle->errstr();
		$error = '(no error associate with the database handle)'
			if !defined( $error );
		Carp::cluck( "Failed to commit transaction: $error" );
		return 0;
	}
}


=head2 rollback()

Roll back the current transaction.

	my $rollback_successful = $transaction->rollback();

=cut

sub rollback
{
	my ( $self ) = @_;

	if ( ! $self->is_active() )
	{
		Carp::carp('Logic error: inactive transaction object committed again');
		return 0;
	}

	my $database_handle = $self->get_database_handle();
	if ( $database_handle->rollback() )
	{
		$self->is_active( 0 );
		return 1;
	}
	else
	{
		my $error = $database_handle->errstr();
		$error = '(no error associate with the database handle)'
			if !defined( $error );
		Carp::cluck( "Failed to rollback transaction: $error" );
		return 0;
	}
}


=head1 HIDDEN FUNCTIONS

=head2 _default_destroy_logger()

Log to STDERR warnings and errors that occur when a DBIx::ScopedTransaction
object is destroyed.

	_default_destroy_logger( $messages );

To override this default logger you can override
C<$DBIx::ScopedTransaction::DESTROY_LOGGER>. For example:

	$DBIx::ScopedTransaction::DESTROY_LOGGER = sub
	{
		my ( $messages ) = @_;

		foreach $message ( @$messages )
		{
			warn "DBIx::ScopedTransaction: $message";
		}
	};

=cut

sub _default_destroy_logger
{
	my ( $messages ) = @_;

	print STDERR "\n";
	print STDERR "/!\\ ***** DBIx::ScopedTransaction::DESTROY *****\n";
	foreach my $message ( @$messages )
	{
		print STDERR "/!\\ $message\n";
	}
	print STDERR "\n";

	return;
}


=head2 DESTROY()

Clean up function to detect unterminated transactions and try to roll them
back safely before destroying the DBIx::ScopedTransaction object.

=cut

sub DESTROY
{
	my ( $self ) = @_;

	# If the transaction is still active but we're trying to destroy the object,
	# we have a problem. It most likely indicates that the transaction object is
	# going out of scope without the transaction having been properly completed.
	if ( $self->is_active() )
	{
		my $messages = [];

		# Try to resolve the situation as cleanly as possible, inside an eval
		# block to catch any issue.
		Try::Tiny::try
		{
			push(
				@$messages,
				"Transaction object created at $self->{'filename'}:$self->{'line'} is "
				. "going out of scope, but the transaction has not been committed or "
				. "rolled back; check logic."
			);

			my $database_handle = $self->get_database_handle();
			if ( defined( $database_handle ) )
			{
				if ( $database_handle->rollback() )
				{
					push( @$messages, 'Forced rolling back the transaction to prevent issues.' );
				}
				else
				{
					push( @$messages, 'Could not roll back transaction to resolve the issue.' );
				}
			}
			else
			{
				push( @$messages, 'Failed to roll back transaction, the database handle has already vanished.' );
			}
		}
		Try::Tiny::catch
		{
			push( @$messages, 'Error: ' . $_ );
		};

		# Find where to log the errors to.
		my $destroy_logger;
		if ( defined( $DESTROY_LOGGER ) )
		{
			# There's a custom logger defined, make sure it is a valid code block
			# before using it.
			if ( Data::Validate::Type::is_coderef( $DESTROY_LOGGER ) )
			{
				$destroy_logger = $DESTROY_LOGGER;
			}
			else
			{
				# Fall back to the default logger.
				$destroy_logger = \&_default_destroy_logger;
				push(
					@$messages,
					'$DBIx::ScopedTransaction::_default_destroy_logger is not a valid code block, could not send log message to it.',
				);
			}
		}
		else
		{
			# No logger defined, use the default.
			$destroy_logger = \&_default_destroy_logger;
		}

		$destroy_logger->( $messages );
	}

	return $self->can('SUPER::DESTROY') ? $self->SUPER::DESTROY() : 1;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/DBIx-ScopedTransaction/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc DBIx::ScopedTransaction


You can also look for information at:

=over 4

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/DBIx-ScopedTransaction/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx::ScopedTransaction>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx::ScopedTransaction>

=item * MetaCPAN

L<https://metacpan.org/release/DBIx-ScopedTransaction>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 ACKNOWLEDGEMENTS

I originally developed this project for ThinkGeek
(L<http://www.thinkgeek.com/>). Thanks for allowing me to open-source it!


=head1 COPYRIGHT & LICENSE

Copyright 2012-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
