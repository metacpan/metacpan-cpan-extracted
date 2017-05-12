package Brick::Numbers;
use strict;

use base qw(Exporter);
use vars qw($VERSION);

$VERSION = '0.227';

package Brick::Bucket;
use strict;


=encoding utf8

=head1 NAME

Brick - This is the description

=head1 SYNOPSIS

	use Brick;

=head1 DESCRIPTION

=cut

=over 4

=item number_within_range( HASHREF )

Hash fields:

	minimum   - the lower bound
	maximum   - the higher bound
	inclusive - true includes bounds, false excludes bounds

=cut

sub number_within_range
	{
	my( $bucket, $setup ) = @_;

	my @missing = sort grep { ! defined $setup->{$_} } qw( minimum maximum );

  	if( @missing )
    	{
    	no warnings 'uninitialized';
    	croak( sprintf "number_within_range missing %s%s attibute%s",
    		$missing[0],
    		$missing[1] ? " and $missing[1]" : '',
    		$missing[1] ? 's' : ''
    		);
		}

	my $format_sub = $bucket->_is_decimal_integer( $setup );

	my $range_sub =	$setup->{inclusive} ?
			$bucket->_inclusive_within_numeric_range( $setup )
				:
			$bucket->_exclusive_within_numeric_range( $setup );

	my $composed_sub = $bucket->__compose_satisfy_all( $format_sub, $range_sub );

	$bucket->__make_constraint( $composed_sub, $setup );
	}

sub _is_only_decimal_digits
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	my $sub = $bucket->_matches_regex( {
		description  => "The $setup->{field} value only has decimal digits",
		field        => $setup->{field},
		name         => $setup->{name} || $caller[0]{'sub'},
		regex        => qr/
			\A
			\d+  # digits only
			\z
			/x,
		} );

	my $composed = $bucket->__compose_satisfy_all( $sub );

	$bucket->add_to_bucket( {
		name => $caller[0]{'sub'},
		code => $composed,
		} );
	}

sub _is_decimal_integer
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	no warnings 'uninitialized';
	my $sub = $bucket->_matches_regex( {
		description  => "The $setup->{field} is an integer in base 10",
		field        => $setup->{field},
		name         => $setup->{name} || $caller[0]{'sub'},
		regex        => qr/
			\A
			(?:[+-])?  # optional leading sign
			\d+
			\z
			/x,
		} );

	my $composed = $bucket->__compose_satisfy_all( $sub );

	$bucket->add_to_bucket( {
		name => $caller[0]{'sub'},
		code => $composed,
		} );
	}

sub _inclusive_within_numeric_range
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket( {
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "Find number within the range [$setup->{minimum}, $setup->{maximum}] inclusively",
		fields      => [ $setup->{field} ],
		code        => $bucket->__compose_satisfy_all(
			$bucket->_numeric_equal_or_greater_than( $setup ),
			$bucket->_numeric_equal_or_less_than( $setup ),
			),
		} );
	}

sub _exclusive_within_numeric_range
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket( {
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "Find number within the range [$setup->{minimum}, $setup->{maximum}] exclusively",
		fields      => [ $setup->{field} ],
		code        => $bucket->__compose_satisfy_all(
			$bucket->_numeric_strictly_greater_than( $setup ),
			$bucket->_numeric_strictly_less_than( $setup ),
			),
		} );

	}

sub _numeric_equal_or_greater_than
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket({
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "The number is equal to or greater than $setup->{minimum}",
		fields      => [ $setup->{field} ],
		code        => sub {
			die {
				message => "The number in $setup->{field} was $_[0]->{ $setup->{field} }, but should have been greater than or equal to $setup->{minimum}",
				failed_field   => $setup->{field},
				handler => $caller[0]{'sub'},
				} unless $_[0]->{ $setup->{field} } >=  $setup->{minimum}
			},
		} );
	}

sub _numeric_strictly_greater_than
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket({
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "The number is greater than $setup->{minimum}",
		fields      => [ $setup->{field} ],
		code        => sub {
			die {
				message => "The number in $setup->{field} was $_[0]->{ $setup->{field} }, but should have been strictly greater than $setup->{minimum}",
				failed_field   => $setup->{field},
				handler => $caller[0]{'sub'},
				} unless $_[0]->{ $setup->{field} } >  $setup->{minimum};
			},
		} );
	}

sub _numeric_equal_or_less_than
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket({
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "The number is equal to or less than $setup->{maximum}",
		fields      => [ $setup->{field} ],
		code        => sub {
			die {
				message      => "The number in $setup->{field} was $_[0]->{ $setup->{field} }, but should have been less than or equal to $setup->{maximum}",
				failed_field => $setup->{field},
				handler      => $caller[0]{'sub'},
				} unless $_[0]->{ $setup->{field} } <=  $setup->{maximum};
			},
		} );
	}

sub _numeric_strictly_less_than
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket({
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "The number is less than $setup->{maximum}",
		fields      => [ $setup->{field} ],
		code        => sub {
			die {
				message      => "The number in $setup->{field} was $_[0]->{ $setup->{field} }, but should have been strictly less than $setup->{maximum}",
				failed_field => $setup->{field},
				handler      => $caller[0]{'sub'},
				} unless $_[0]->{ $setup->{field} } <  $setup->{maximum};
			},
		} );
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
