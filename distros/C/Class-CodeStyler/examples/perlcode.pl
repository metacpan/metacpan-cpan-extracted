use lib './lib';
use Class::CodeStyler;

my $p2 = Class::CodeStyler::Program::Perl->new();
$p2->code("sub function_operator");
$p2->open_block();
	$p2->code("my \$self = shift;");
	$p2->code("my \$arg1 = shift;");
	$p2->code("my \$arg2 = shift;");
	$p2->code("return \$arg1->eq(\$arg2);");
$p2->close_block();

#my $new_func = MyFunctions::NewFunc->new();
my $new_func = Class::CodeStyler::Program::Perl->new();
$new_func->code("sub new");
$new_func->open_block();
	$new_func->code("use vars qw(\@ISA);");
	$new_func->code("my \$proto = shift;");
	$new_func->code("my \$class = ref(\$proto) || \$proto;");
	$new_func->code("my \$self = int(\@ISA) ? \$class->SUPER::new(\@_) : {};");
	$new_func->code("bless(\$self, \$class);");
	$new_func->code("return \$self;");
$new_func->close_block();

my $p = Class::CodeStyler::Program::Perl->new(program_name => 'testing.pl', tab_size=>4);
$p->open_block();
	$p->code("package MyBinFun;");
	$p->bookmark('subs');
	$p->indent_off();
	$p->comment("Some comment line...");
	$p->indent_on();
	$p->add($p2);

my $p3 = Class::CodeStyler::Program::Perl->new();
$p3->code("sub greater");
$p3->open_block();
	$p3->code("my \$self = shift;");
	$p3->code("my \$arg1 = shift;");
	$p3->code("my \$arg2 = shift;");
	$p3->code("return \$arg1 > \$arg2 ? 1 : 0;");
$p3->close_block();

$p->jump('subs');
$p->add($p3);
$p->return();
$p->divider();
$p->comment('Next function follows...');
$p->add($new_func);

my $p4 = Class::CodeStyler::Program::Perl->new();
$p4->code("sub function_operator_3");
$p4->open_block();
	$p4->code("my \$self = shift;");
	$p4->code("my \$arg1 = shift;");
	$p4->code("my \$arg2 = shift;");
	$p4->code("return \$arg1->eq(\$arg2);");
$p4->close_block();
$p->add($p4);
$p->close_block();
$p->code('my $pack = MyBinFun->new();');
$p->code("print '100 > 200 is ', \$pack->greater(100, 200) ? 'true' : 'false', \"\\n\";");
$p->code("print '300 > 200 is ', \$pack->greater(300, 200) ? 'true' : 'false', \"\\n\";");

$p->prepare();
$p->display();
$p->save();
$p->syntax_check();
$p->eval();
$p->exec();
