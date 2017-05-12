package Brick::Strings;
use strict;

use base qw(Exporter);
use vars qw($VERSION);

$VERSION = '0.227';

package Brick::Bucket;
use strict;

=encoding utf8

=head1 NAME

Brick::General - constraints for domain-nonspecific stuff

=head1 SYNOPSIS

	use Brick;

=head1 DESCRIPTION

=over 4

=item $bucket->value_length_is_exactly( HASHREF )

	exact_length

=cut

sub _value_length_is_exactly
	{
	my( $bucket, $setup ) = @_;

	$setup->{minimum_length} = $setup->{exact_length};
	$setup->{maximum_length} = $setup->{exact_length};

	$bucket->_value_length_is_between( $setup );
	}

=item $bucket->value_length_is_greater_than( HASHREF )

	minimum_length

=cut

sub _value_length_is_equal_to_greater_than
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();


	$bucket->add_to_bucket( {
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "Length must be $setup->{minimum_length} or more characters",
		code        => sub {
			die {
				message      => "[$_[0]->{ $setup->{field} }] isn't $setup->{minimum_length} or more characters",
				handler      => $caller[0]{'sub'},
				failed_field => $setup->{field},
				failed_value => $_[0]->{ $setup->{field} },
				} unless $setup->{minimum_length} <= length( $_[0]->{ $setup->{field} } )
			},
		} );
	}

=item $bucket->value_length_is_less_than( HASHREF )

	maximum_length

=cut

sub _value_length_is_equal_to_less_than
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	$bucket->add_to_bucket( {
		name        => $setup->{name} || $caller[0]{'sub'},
		description => "Length must be $setup->{maximum_length} or fewer characters",
		code        => sub {
			die {
				message      => "[$_[0]->{ $setup->{field} }] isn't $setup->{maximum_length} or fewer characters",
				handler      => $caller[0]{'sub'},
				failed_field => $setup->{field},
				failed_value => $_[0]->{ $setup->{field} },
				} unless length( $_[0]->{ $setup->{field} } ) <= $setup->{maximum_length}
			},
		} );
	}

=item $bucket->value_length_is_between( HASHREF )

	minimum_length
	maximum_length

=cut

sub _value_length_is_between
	{
	my( $bucket, $setup ) = @_;

	local $setup->{name} = '';

	my $min = $bucket->_value_length_is_equal_to_greater_than( $setup );

	my $max = $bucket->_value_length_is_equal_to_less_than( $setup );

	my $composed = $bucket->__compose_satisfy_all( $min, $max );
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
