use Module::Build 0.21;

use lib 't/lib';
use Apache::test;

# Don't buffer, so automated tools like Module::Release see the output right away
$| = 1;

my %params = Apache::test->get_test_params();
Apache::test->write_httpd_conf
    (%params,
     include => <<EOF);

  PerlModule Apache::Compress
  <FilesMatch "\.html$">
   SetHandler perl-script
   PerlHandler Apache::Compress
  </FilesMatch>

EOF

my $build = Module::Build->subclass(code => do {local $/; <DATA>})->new
  (
   module_name => 'Apache::Compress',
   dist_version_from => 'Compress.pm',
   pm_files => { 'Compress.pm' => 'lib/Apache/Compress.pm' },
   license => 'perl',
   requires => {
		'Apache' => '1.00',
		'Compress::Zlib' => '1.08',
	       },
   build_requires => {
		      'Module::Build' => '0.21',
		      'File::Spec' => 0,
		      'Test' => 0,
		     },
   add_to_cleanup => [qw(t/httpd t/httpd.conf t/error_log)],
  );
$build->notes(apache_params => \%params);
$build->create_build_script;

__DATA__

use strict;
use Apache::test;
use File::Spec;

sub ACTION_test {
  my $self = shift;
  
  my $conf_file = File::Spec->catfile($self->cwd, 't', 'httpd.conf');
  $self->do_system(File::Spec->catfile('t', 'httpd'), '-f', $conf_file)
    or die "Couldn't start httpd\n";
  
  local $ENV{PORT} = $self->notes('apache_params')->{port};
  $self->SUPER::ACTION_test;
  
  my $pidfile = File::Spec->catfile('t', 'httpd.pid');
  my $pid = do {open my($fh), $pidfile; local $/; <$fh>};
  warn "Stopping httpd, process ID = $pid\n";
  kill "TERM", $pid;
}
