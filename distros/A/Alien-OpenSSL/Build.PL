use strict;
use warnings;
use IPC::Cmd qw/can_run/;

use Alien::Base::ModuleBuild '0.025';

my $addcc = "";
$addcc = "CC=cc " if ( (!can_run('gcc')) && can_run('cc') );

my ($addsh, $class);

if ($^O eq 'MSWin32') {
  print "Enabling Windows hacks...\n";
  $addsh = "sh ";
  $class = Alien::Base::ModuleBuild->subclass( class => 'Alien::OpenSSL::Builder',
                                               code => <<'EOC' );

use Carp;
use File::Spec;
use Env qw(@PATH);

# Look for MinGW
for my $INC (grep !ref, @INC) {
  my $dir = File::Spec->rel2abs(File::Spec->catdir($INC, qw(auto MinGw bin)));
  push @PATH, $dir if -d $dir;
}

sub alien_extract_archive {
  my ($self, $archive) = @_;

  print "Extracting archive '$archive'...\n";
  print "tar may report some errors now, they are harmless and can be ignored!\n";
  $self->alien_do_system(['tar', '-xzf', $archive]);
  my (undef, undef, $dir) = File::Spec->splitpath($archive);
  $dir =~ s/\.tar\.gz$//;
  -d $dir or croak "Archive extraction failed";
  print "Done\n";
  return $dir
}
EOC

}
else {
  $addsh = "";
  $class = 'Alien::Base::ModuleBuild';
}

my $builder = $class->new (
	sign => 1,
	module_name => 'Alien::OpenSSL',
	license => 'perl',
	configure_requires => {
		'Alien::Base' => '0.025',
		'Module::Build' => '0.38',
		'Test::More' => 0,
	},
	requires => {
		'perl' => '5.8.1',
		'Alien::Base' => '0.025',
	},
	dist_author => 'Johanna Amann <johanna@icir.org>',
	alien_name => 'openssl',
	alien_repository => {
		protocol => 'ftp',
		host => 'ftp.openssl.org',
		location => '/source/',
		pattern  => qr/^openssl-([\d\.]+\w?).tar\.gz$/,
	},
	alien_msys => 1,
	alien_stage_install => 0,
	alien_build_commands => [
		$addcc.$addsh.'%pconfig shared --prefix=%s',
		$addcc.'make',
	],
	alien_test_commands => [
		$addcc.'make test',
	],
	alien_install_commands => [
		'make install_sw',
	],
	meta_merge => {
		resources => {
			homepage => 'https://github.com/0xxon/alien-openssl',
			bugtracker => 'https://github.com/0xxon/alien-openssl/issues',
			repository  => 'git://github.com/0xxon/alien-openssl.git',
		},
	},
);


$builder->create_build_script;
