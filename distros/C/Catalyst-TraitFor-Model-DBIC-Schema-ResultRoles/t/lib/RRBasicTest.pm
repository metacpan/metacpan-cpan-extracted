package RRBasicTest;

use Moose;
with 'Catalyst::TraitFor::Model::DBIC::Schema::ResultRoles';


#after new => \&BUILD;
sub schema {
	return RRBasicTest::Schema->new();

}

sub schema_class {
	return "RRBasicTest::Schema";
}

sub BUILD {
	return 1;
}

{
	package RRBasicTest::Schema::Result::Dummy;
	use Moose;


	sub result_class{
		my $self = shift;
		return $self;
	}
	no Moose;

}

{
	package RRBasicTest::Schema;

	use Moose;

	sub sources {
		return qw/Dummy/;

	}
	has source_registrations =>( 
			is => "ro",
			isa => 'HashRef',
			required => 1,
			default =>sub { return {'Dummy' => RRBasicTest::Schema::Result::Dummy->new()};},
			);


	no Moose;

}

1;
