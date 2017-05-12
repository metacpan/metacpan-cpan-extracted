use App::Test;

my $t = App::Test->new;
my $c = $t->context;
my $m = $t->context->model('Hash');

my $id = 12345678;
my $expected = 'ceb77dbcdd0e428a4f51a3d9976c18b5e442cf6e40d45322136ba0f8b41a1eed';

subtest "create" => sub {
	is $m->create($id), $expected, 'work create method';
};

done_testing;
