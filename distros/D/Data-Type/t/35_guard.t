use Test;
BEGIN { plan tests => 5; $| = 0 }

use Data::Type qw(:all);
use Data::Type::Guard;
use IO::Extended qw(:all);

Class::Maker::class 'Human',
{
	public =>
	{
		int => [qw(age)],

		string =>
		[
			qw(email countrycode postalcode firstname lastname sex eye_color),

			qw(hair_color occupation city region street fax)
		],

		time => [qw(birth dead)],

		array => [qw(nicknames friends)],

		hash => [qw(contacts telefon)],

		whatsit => { tricky => 'An::Object' },
	},
};
	
	my $g = Data::Type::Guard->new( 
	
		tests =>
		{
			email		=> STD::EMAIL, 
			firstname	=> STD::WORD,
			lastname	=> STD::WORD,
			sex		=> STD::GENDER,
			countrycode 	=> STD::NUM,
			age		=> STD::NUM,
			contacts	=> sub { my %args = @_; exists $args{lucy} },				
		}
	);

	my $h = Human->new( email => 'j@d.de', firstname => 'john', lastname => 'doe', sex => 'male', countrycode => '123123', age => 12 );
	
	$h->contacts( { lucy => '110', john => '123' } );

ok( $g->inspect( $h ) );

	push @{ $g->allow }, 'Animal';
	
ok( $g->inspect( $h ), 0 );

	push @{ $g->allow }, 'Human';

ok( $g->inspect( $h ), 0 );

	@{ $g->allow } = ();

ok( $g->inspect( $h ), 1 );

	$h->firstname = undef;

	use Data::Dumper;
	
	print Data::Dumper->Dump( [ $h ] );
	
ok( $g->inspect( $h ), 0 );

