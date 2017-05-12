use Dwarf::Pragma;
use Dwarf::Message;
use Test::More 0.88;

my $value = 'message';

subtest 'name' => sub {
	my $message = Dwarf::Message->new(name => $value);
	is $message->name, $value;
};

subtest 'data' => sub {
	my $message = Dwarf::Message->new(data => [ $value ]);
	is $message->data->[0], $value;
};

subtest 'stringify' => sub {
	my $message = Dwarf::Message->new(data => [ $value ]);
	is "$message", $value;
};

done_testing();
