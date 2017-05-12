package App::Office::Contacts::Donations::Util::Validator;

use Moose;

extends 'App::Office::Contacts::Util::Validator';

use namespace::autoclean;

our $VERSION = '1.10';

# --------------------------------------------------

sub donations
{
	my($self) = @_;

	$self -> log(debug => 'Entered donations');

	my($verifier) = Data::Verifier -> new
	(
		filters => [qw(trim)],
		profile =>
		{
			amount_input =>
			{
				required => 1,
				type     => 'Num',
			},
			currency_id_1 =>
			{
				required => 1,
				type     => 'Int',
			},
			donation_motive_id =>
			{
				required => 1,
				type     => 'Int',
			},
			donation_project_id =>
			{
				required => 1,
				type     => 'Int',
			},
			motive_text =>
			{
				required => 0,
				type     => 'Str',
			},
			project_text =>
			{
				required => 0,
				type     => 'Str',
			},
			sid =>
			{
				required => 1,
				type     => 'Str',
			},
			target_id =>
			{
				required => 1,
				type     => 'Int',
			},
		},
	);
	my($result) = $verifier -> verify({$self -> query -> Vars});

	return $result;

} # End of donations.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

=pod

From http://search.cpan.org/~flora/Moose-0.93/lib/Moose/Manual/Types.pod

  Any
  Item
      Bool
      Maybe[`a]
      Undef
      Defined
          Value
              Str
                Num
                    Int
                ClassName
                RoleName
          Ref
              ScalarRef
              ArrayRef[`a]
              HashRef[`a]
              CodeRef
              RegexpRef
              GlobRef
                FileHandle
              Object

=cut
