use strict;
use Module::Build;
use lib 't/lib';  # distributed here until changes are incorporated into the real version
use Apache::test qw(have_httpd);

my %params = Apache::test->get_test_params();

my $class = 'Module::Build';

if (have_httpd()) {
  Apache::test->write_httpd_conf
      (%params,
       include => do {local $/; open FH, 't/config.incl'; <FH>});
  
  $class = $class->subclass
    (
     code => sprintf(<<'     EOF', $params{port}),
       sub ACTION_test {
	 my $self = shift;
	 
	 $self->depends_on('build');
	 
	 # Could be File::Spec-ified, but this is mostly a Unix module
	 $self->add_to_cleanup(qw(t/httpd t/httpd.conf t/error_log));
	 $self->do_system('t/httpd', '-f', $self->base_dir . "/t/httpd.conf");
	 
	 $ENV{PORT} = %s;  # Used by the test scripts
	   eval { $self->SUPER::ACTION_test };
	 warn $@ if $@;
	 
	 $self->do_system("kill `cat t/httpd.pid`");
       }
     EOF
    );
}

my $b = $class->new
  (
   module_name => 'Apache::Filter',
   license => 'perl',
   requires => { mod_perl => '1.24_01' },
  );

$b->create_build_script;
