package Brick::Result;
use strict;

use vars qw($VERSION);

use Carp qw(carp croak);

$VERSION = '0.227';

=encoding utf8

=head1 NAME

Brick::Result - the result of applying a profile

=head1 SYNOPSIS

	use Brick;

	my $result = $brick->apply( $Profile, $Input );

	$result->explain;

=head1 DESCRIPTION

This class provides methods to turn the data structure returned
by apply() into a useable form for particular situations.


=head2 Class methods

=over 4

=item result_item_class

Loads and returns the class name to use for the elements of the Results
data structure.

=cut

sub result_item_class { require Brick::Result::Item; 'Brick::Result::Item' };

=back

=head2 Instance methods

=over

=item explain

Create a string the shows the result in an outline form.

=cut


# for the $pair thing in explain
use constant LEVEL   => 0;
use constant MESSAGE => 1;


sub explain
	{
	my( $result_set ) = @_;

	my $str   = '';

	foreach my $element ( @$result_set )
		{
		my $level = 0;

		$str .= "$$element[0]: " . do {
			if( $element->passed )                  { "passed " }
			elsif( $element->is_validation_error )  { "failed " }
			elsif( $element->is_code_error )        { "code error in " }
			};

		$str .= $element->get_method() . "\n";

		if( $element->passed )
			{
			$str .= "\n";
			next;
			}

		# this descends into the error tree (without using recursion
		my @uses = ( [ $level, $element->get_messages ] );

		while( my $pair = shift @uses )
			{
			# is it a single error or a composition?
			if( ! ref $pair->[ MESSAGE ] )
				{
				$str .= $pair->[ MESSAGE ] . "foo";
				}
			elsif( ! ref $pair->[ MESSAGE ] eq ref {} )
				{
				next;
				}
			elsif( exists $pair->[ MESSAGE ]->{errors} )
				{
				# something else to process, but put it back into @uses
				unshift @uses, map {
					[ $pair->[ LEVEL ] + 1, $_ ]
					} @{ $pair->[ MESSAGE ]->{errors} };
				}
			else
				{
				# this could come back as an array ref instead of a string
				no warnings 'uninitialized';
				$str .=  "\t" . #x $pair->[ LEVEL ] .
					join( ": ", @{ $pair->[ MESSAGE ]
						}{qw(failed_field handler message)} ) . "\n";
				}

			}

		$str.= "\n";
		}

	$str;
	}

=item flatten

Collapse the result structure to an array of flat hashes.

=cut

sub flatten
	{
	my( $result_set ) = @_;

	my $str   = '';

	my @flatten;

	foreach my $element ( @$result_set ) # one element per profile element
		{
		bless $element, $result_set->result_item_class;
		next if $element->passed;
		my $constraint = $element->get_method;

		my @uses = ( $element->get_messages );

		while( my $hash = shift @uses )
			{
			if( ! ref $hash eq ref {} )
				{
				carp "Non-hash reference in messages result key! Skipping";
				next;
				}

			# is it a single error or a composition?
			unless( ref $hash  )
				{
				next;
				}
			elsif( exists $hash->{errors} )
				{
				unshift @uses, @{ $hash->{errors} };
				}
			else
				{
				push @flatten, { %$hash, constraint => $constraint };
				}

			}

		}

	\@flatten;
	}

=item flatten_by_field

Similar to flatten, but keyed by the field that failed the constraint.

=cut

sub flatten_by_field
	{
	my( $result_set ) = @_;

	my $str   = '';

	my %flatten;
	my %Seen;

	foreach my $element ( @$result_set ) # one element per profile element
		{
		next if $element->passed;
		my $constraint = $element->get_method;

		my @uses = ( $element->get_messages );

		while( my $hash = shift @uses )
			{
			# is it a single error or a composition?
			unless( ref $hash  )
				{
				next;
				}
			elsif( exists $hash->{errors} )
				{
				unshift @uses, @{ $hash->{errors} };
				}
			else
				{
				my $field = $hash->{failed_field};
				next if $hash->{handler} and $Seen{$field}{$hash->{handler}}++;
				$flatten{ $field } = [] unless exists $flatten{ $field };
				push @{ $flatten{ $field } },
					{ %$hash, constraint => $constraint };
				$Seen{$field}{$hash->{handler}}++;
				}

			}

		}

	\%flatten;
	}

=item flatten_by

Similar to flatten, but keyed by the hash key named in the argument list.

=cut

sub flatten_by
	{
	my( $result_set, $key ) = @_;

	my $str   = '';

	my %flatten;
	my %Seen;

	foreach my $element ( @$result_set ) # one element per profile element
		{
		next if $element->passed;
		my $constraint = $element->get_method;

		my @uses = ( $element->get_messages );

		while( my $hash = shift @uses )
			{
			# is it a single error or a composition?
			unless( ref $hash  )
				{
				next;
				}
			elsif( exists $hash->{errors} )
				{
				unshift @uses, @{ $hash->{errors} };
				}
			else
				{
				my $field = $hash->{$key};
				next if $hash->{handler} and $Seen{$field}{$hash->{handler}}++;
				$flatten{ $field } = [] unless exists $flatten{ $field };
				push @{ $flatten{ $field } },
					{ %$hash, constraint => $constraint };
				$Seen{$field}{$hash->{handler}}++;
				}

			}

		}

	\%flatten;
	}

=item dump

What should this do?

=cut

sub dump { croak "Not yet implemented" }

=back

=head1 TO DO

TBA

=head1 SEE ALSO

L<Brick::Tutorial>, L<Brick::UserGuide>

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
