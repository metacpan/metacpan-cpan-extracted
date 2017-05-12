package Brick::Regexes;
use strict;

use base qw(Exporter);
use vars qw($VERSION);

$VERSION = '0.227';

package Brick::Bucket;
use strict;

use Carp qw(croak);

=encoding utf8

=head1 NAME

Brick - This is the description

=head1 SYNOPSIS

	use Brick::Constraints;

=head1 DESCRIPTION

See C<Brick::Constraints> for the general discussion of constraint
creation.

=head2 Utilities

=over 4

=item _matches_regex( HASHREF )

Create a code ref to apply a regular expression to the named field.

	field - the field to apply the regular expression to
	regex - a reference to a regular expression object ( qr// )

=cut

sub _matches_regex
	{
	my( $bucket, $setup ) = @_;

	my @caller = $bucket->__caller_chain_as_list();

	unless( eval { $setup->{regex}->isa( ref qr// ) } )
		{
    	croak( "Argument to $caller[0]{'sub'} must be a regular expression object" );
		}

	$bucket->add_to_bucket ( {
		name        => $setup->{name} || $caller[0]{'sub'},
		description => ( $setup->{description} || "Match a regular expression" ),
		fields      => [ $setup->{field} ],
		code        => sub {
			die {
				message      => "[$_[0]->{ $setup->{field} }] did not match the pattern",
				failed_field => $setup->{field},
				failed_value => $_[0]->{ $setup->{field} },
				handler      => $caller[0]{'sub'},
				} unless $_[0]->{ $setup->{field} } =~ m/$setup->{regex}/;
			},
		} );

	}

=back

=head1 TO DO

Regex::Common support

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
