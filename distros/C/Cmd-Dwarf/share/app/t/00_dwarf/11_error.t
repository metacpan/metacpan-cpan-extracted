use Dwarf::Pragma;
use Dwarf::Error;
use Test::More 0.88;

my $message = 'invalid parameters';

subtest 'throw' => sub {
	my $error = Dwarf::Error->new;
	$error->throw($message);
	eval { $error->flush };
	is $@->message->data->[0], $message;
};

subtest 'autoflush' => sub {
	my $error = Dwarf::Error->new(autoflush => 1);
	eval { $error->throw($message) };
	is $@->message->data->[0], $message;
};

subtest 'stringify' => sub {
	my $error = Dwarf::Error->new(autoflush => 1);
	eval { $error->throw($message) };
	is "$@", $message;
};

done_testing();
