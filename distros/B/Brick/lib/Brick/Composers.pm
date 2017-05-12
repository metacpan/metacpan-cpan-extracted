package Brick::Composers;
use base qw(Exporter);
use vars qw($VERSION);

$VERSION = '0.227';

use Brick::Bucket;

package Brick::Bucket;
use strict;

use Carp qw(carp);

=encoding utf8

=head1 NAME

Brick::Composers - This is the description

=head1 SYNOPSIS

	use Brick::Constraints::Bucket;

=head1 DESCRIPTION

This module defines composing functions in the
Brick::Constraints package. Each function takes a list of code
refs and returns a single code ref that wraps all of them. The single
code ref returns true or false (but defined), as with other
constraints.

If a composer cannot create the single code ref (for instance, due to
bad input) it returns C<undef> of the empty list, indicating a failure
in programming rather than a failure of the data to validate.

=cut

=over 4

=item __and( LIST OF CODEREFS )

=item __compose_satisfy_all( LIST OF CODEREFS )

This is AND with NO short-circuiting.

	( A && B && C )

This function creates a new constraint that returns true if all of its
constraints return true. All constraints are checked so there is no
short-circuiting. This allows you to get back all of the errors at
once.

=cut

sub __compose_satisfy_all
	{
	my $bucket = shift;
	$bucket->__compose_satisfy_N( scalar @_, @_ );
	}

BEGIN {
*__and = *__compose_satisfy_all;
}

=item __or( LIST OF CODEREFS )

=item __compose_satisfy_any( LIST OF CODEREFS )

This is OR but with NO short-circuiting.

	( A || B || C )

This function creates a new constraint that returns true if all of its
constraints return true. All constraints are checked so there is no
short-circuiting.

=cut

sub __compose_satisfy_any
	{
	my $bucket = shift;
	$bucket->__compose_satisfy_N_to_M( 1, scalar @_, @_ );
	}

BEGIN {
*__or = *__compose_satisfy_any;
}

=item __none( LIST OF CODEREFS )

=item __compose_satisfy_none( LIST OF CODEREFS )


	( NOT A && NOT B && NOT C )

	NOT ( A || B || C )

This function creates a new constraint that returns true if all of its
constraints return false. All constraints are checked so there is no
short-circuiting.

=cut

sub __compose_satisfy_none
	{
	my $bucket = shift;
	$bucket->__compose_satisfy_N_to_M( 0, 0, @_ );
	}

BEGIN {
*__none = *__compose_satisfy_none;
}

=item __compose_satisfy_N( SCALAR, LIST OF CODEREFS )

This function creates a new constraint that returns true if exactly N
of its constraints return true. All constraints are checked so there
is no short-circuiting.

=cut

sub __compose_satisfy_N
	{
	my( $bucket, $n, @subs ) = @_;

	$bucket->__compose_satisfy_N_to_M( $n, $n, @subs );
	}

=item __compose_satisfy_N_to_M( LIST OF CODEREFS )

This function creates a new constraint that returns true if between N
and M (inclusive) of its constraints return true. All constraints are
checked so there is no short-circuiting.

=cut

sub __compose_satisfy_N_to_M
	{
	my( $bucket, $n, $m, @subs ) = @_;

	if( grep { ref $_ ne ref sub {} } @subs )
		{
		croak "Got something else when expecting code ref!";
		return sub {};
		}

	my @caller = $bucket->__caller_chain_as_list();

	my @composers = grep { /^__compose/ } map { $_->{sub} } @caller;

	my $max = @subs;

	my $sub = $bucket->add_to_bucket( {
		name => $composers[-1], # forget the chain of composers
		code => sub {
			my $count = 0;
			my @dies = ();
			foreach my $sub ( @subs )
				{
				my $result = eval { $sub->( @_ ) };
				my $at = $@;
				$count++ unless $at;
				#print STDERR "\n!!!!Sub died!!!!\n" if ref $at;
				#print STDERR "\n", Data::Dumper->Dump( [$at], [qw(at)]) if ref $at;
				die if( ! ref $at and $at );
				push @dies, $at if ref $at;
				};

			my $range = $n == $m ? "exactly $n" : "between $n and $m";

			die {
				message => "Satisfied $count of $max sub-conditions, needed to satisfy $range",
				handler => $caller[0]{'sub'},
				errors  => \@dies,
				} unless $n <= $count and $count <= $m;

			return 1;
			},
		});

	$bucket->comprise( $sub, @subs );

	return $sub;
	}

=item __not( CODEREF )

=item __compose_not( CODEREF )

This composers negates the sense of the code ref. If the code ref returns
true, this composer makes it false, and vice versa.

=cut


sub __compose_not
	{
	my( $bucket, $not_sub ) = @_;

	my $sub = $bucket->add_to_bucket( {
		code => sub { if( $not_sub->( @_ ) ) { die {} } else { return 1 } },
		} );

	return $sub;
	}


=item __compose_until_pass

=item __compose_pass_or_skip

Go through the list of closures, trying each one until one suceeds. Once
something succeeds, it returns the name of the subroutine that passed.

If
a closure doesn't die, but doesn't return true, this doesn't fail but
just moves on. Return true for the first one that passes,
short-circuited the rest.

If none of the closures pass (and none of them die), return 0. This might
be the odd case of a several selectors (see L<Brick::Selector>), none of
which pass.

If one of the subs dies, this composer still dies. This can also die
for programming (not logic) errors.

=cut

sub __compose_pass_or_skip
	{
	my( $bucket, @subs ) = @_;

	if( grep { ref $_ ne ref sub {} } @subs )
		{
		croak "Got something else when expecting code ref!";
		return sub {};
		}

	my @caller = $bucket->__caller_chain_as_list();

	my $sub = $bucket->add_to_bucket( {
		code => sub {
			my $count = 0;
			my @dies = ();

			foreach my $sub ( @subs )
				{
				my $result = eval { $sub->( @_ ) };
				my $eval_error = $@;

				# all true values are success
				return "$sub" if $result;   # we know we passed


				# we're a selector: failed with no error
				return if ( ! defined $result and ! defined $eval_error );

				# die for everything else - validation error
				die if( ref $eval_error );
				};

			return 0;
			},
		});

	$bucket->comprise( $sub, @subs );

	return $sub;
	}

BEGIN {
*__compose_until_pass = *__compose_pass_or_skip;
}

=item __compose_until_fail

=item __compose_pass_or_stop

Keep going as long as the closures return true.

The closure that returns undef is a selector.

If a closure doesn't die and doesn't don't fail, just move on. Return true for
the first one that passes, short-circuited the rest. If none of the
closures pass, die with an error noting that nothing passed.

This can still die for programming (not logic) errors.


	$result		$@			what		action
	------------------------------------------------------------
		1		undef		passed		go on to next brick

		undef	undef		selector	stop, return undef, no die
							failed

		undef	string		program		stop, die with string
							error

		undef	ref			validator	stop, die with ref
							failed

=cut

sub __compose_pass_or_stop
	{
	my( $bucket, @subs ) = @_;

	if( grep { ref $_ ne ref sub {} } @subs )
		{
		croak "Got something else when expecting code ref!";
		return sub {};
		}

	my @caller = $bucket->__caller_chain_as_list();

	my $max = @subs;

	my $sub = $bucket->add_to_bucket( {
		code => sub {
			my $count = 0;
			my @dies = ();

			my $last_result;
			foreach my $sub ( @subs )
				{
				no warnings 'uninitialized';
				my $result = eval { $sub->( @_ ) };
				my $at = $@;
				#print STDERR "\tstop: Returned result: $result\n";
				#print STDERR "\tstop: Returned undef!\n" unless defined $result;
				#print STDERR "\tstop: Returned ref!\n" if ref $at;
				$last_result = $result;

				next if $result;

				die $at if ref $at;

				return unless( defined $result and ref $at );

				die if( ref $at and $at ); # die for program errors
				#print STDERR "\tStill going\n";
				};

			return $last_result;
			},
		});

	$bucket->comprise( $sub, @subs );

	return $sub;
	}

BEGIN {
*__compose_until_fail = *__compose_pass_or_stop;
}

=back

=head1 TO DO

TBA

=head1 SEE ALSO

TBA

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/brick

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2007-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
