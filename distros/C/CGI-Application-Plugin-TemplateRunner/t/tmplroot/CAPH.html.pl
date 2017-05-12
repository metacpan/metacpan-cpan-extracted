{
	world => 'world',
	
	hash => {
		one => 1,
		two => { two => 2},
		three => 3,
	},
	
	subroutine => sub{
		my $app = shift;
		$app->param('a_param');
	}
};
