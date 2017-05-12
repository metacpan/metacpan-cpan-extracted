#! perl
use Test::More no_plan;

my @core_slots = qw(CGI activate app_enter app_leave control_enter
	       control_leave dispatch display engine error param
	       render render_enter render_leave respond respond_enter
	       respond_leave template);

require_ok 'CGI::Prototype';
isa_ok my $m = CGI::Prototype->reflect, 'Class::Prototyped::Mirror';
isa_ok $m->object, 'CGI::Prototype';
can_ok $m->object, @core_slots;

eval { $m->object->CGI };
like $@, qr/initialize_CGI not called/, 'CGI slot properly annoyed';

## now make sure the same thing is true for a derived app:

{
  package My::App;
  @ISA = qw(CGI::Prototype);
}

isa_ok $m = My::App->reflect, 'Class::Prototyped::Mirror';
isa_ok $m->object, 'My::App';
can_ok $m->object, @core_slots;

eval { $m->object->CGI };
like $@, qr/initialize_CGI not called/, 'CGI slot properly annoyed';

{
  open my $stdout, ">&STDOUT" or die;
  open STDOUT, '>test.out' or die;
  END { unlink 'test.out' }
  My::App->activate;
  open STDOUT, ">&=".fileno($stdout) or die;
}

open IN, 'test.out' or die;
like join("", <IN>), qr/\cM?\cJ\cM?\cJThis page intentionally left blank\.$/,
  'proper output from null app';

is_deeply [My::App->param], [],
  'verify no params';

