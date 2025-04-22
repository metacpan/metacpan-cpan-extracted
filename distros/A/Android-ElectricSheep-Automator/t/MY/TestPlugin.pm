package MY::TestPlugin;

use lib ($FindBin::Bin, 'blib/lib');

use parent 'Android::ElectricSheep::Automator::Plugins::Base';

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

sub new {
	my ($class, $params) = @_;
	my $self = $class->SUPER::new({
		%$params,
		'child-class' => $class,
	});
	return $self;
}

sub test_call {
	my ($self, $params) = @_;

	return 0; # success
}
1;
