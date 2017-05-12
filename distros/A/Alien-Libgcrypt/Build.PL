use 5.006;
use strict;
use warnings;
use Alien::Base::ModuleBuild;

my $class = Alien::Base::ModuleBuild->subclass(class => 'Alien::Libgcrypt::Builder',
                                               code => <<'EOC');

use strict;
use warnings;
use Carp;
$ENV{FTP_PASSIVE}=1;

sub alien_check_installed_version {
  my $self = shift;
  my $version = $self->config_data('system_library_version');
  unless (defined $version) {
    # $self->alien_helper->{pkg_config} ||= 'Alien::Base::PkgConfig->pkg_config_command';
    $version = $self->SUPER::alien_check_installed_version(@_);
    chomp $version;
    $self->config_data('system_library_version', $version);
  }
  $version;
}

sub use_installed_version {
  my $self = shift;
  if (defined (my $type = $self->config_data('install_type'))) {
    return ($type eq 'system');
  }

  !$Alien::Base::ModuleBuild::Force and
    $self->alien_check_installed_version
}

sub system_libgcrypt_config_get {
  my ($self, @keys) = @_;
  my %result = $self->do_system(join(' ', 'libgcrypt-config', map "--$_", @keys));
  if ($result{success}) {
    my $out = $result{stdout};
    chomp $out;
    return $out
  }
  return;
}

sub alien_provides_cflags {
  my $self = shift;
  if ($self->use_installed_version) {
    return $self->system_libgcrypt_config_get('cflags');
  }
  return;
}

sub alien_provides_libs {
  my $self = shift;
  if ($self->use_installed_version) {
    return $self->system_libgcrypt_config_get('libs');
  }
  return;
}

sub requires {
  my $self = shift;
  my %r;
  unless ($self->use_installed_version) {
    $r{'Alien::Libgpg_error'} = '0';
  }
  \%r;
}

*build_requires = \&requires;

sub libgpg_error_config {
  my ($self, $method) = @_;
  unless ($self->use_installed_version) {
    require Alien::Libgpg_error;
    return Alien::Libgpg_error->$method;
  }
  return;
}

sub alien_build_commands {
  my $self = shift;
  if ($self->{action} and $self->{action} eq 'Build_PL') {
    return ["echo '*** to be filled later ***'", "exit 1"]
  }

  my $config_cmd = "%c --prefix=%s";
  require Alien::Libgpg_error;
  my $alge = Alien::Libgpg_error->new;
  if ($alge->config('install_type') ne 'system') {
    if (defined(my $alge_dist_dir = $alge->dist_dir)) {
      if ($^O eq 'MSWin32') {
        $alge_dist_dir =~ s{\\}{/}g;
        $alge_dist_dir =~ s{^([a-z]):/}{/$1/}i;
      }
      $config_cmd .= " --with-libgpg-error-prefix=$alge_dist_dir";
    }
  }

  return [ $config_cmd, 'make']
}

EOC

my $builder = $class
    ->new( module_name          => 'Alien::Libgcrypt',
           license              => 'perl',
           dist_author          => q{Salvador Fandiño <sfandino@yahoo.com>},
           dist_version_from    => 'lib/Alien/Libgcrypt.pm',
           add_to_cleanup       => [ 'Alien-Libgcrypt-*' ],
           configure_requires   => { 'Alien::Base' => '0.024',
                                     'Module::Build' => '0.36' },
           alien_name           => 'libgcrypt',
           alien_repository     => { protocol => 'ftp',
                                     host => 'ftp.gnupg.org',
                                     location => '/gcrypt/libgcrypt/',
                                     pattern => qr/^libgcrypt-(\d+\.\d+\.\d+)\.tar\.gz$/ },
           alien_msys           => 1,
           alien_stage_install  => 1,
           alien_version_check  => 'libgcrypt-config --version',
	   meta_merge           => { resources => { homepage   => 'https://github.com/salva/p5-Alien-Libgcrypt',
                                                    bugtracker => 'https://github.com/salva/p5-Alien-Libgcrypt/issues',
                                                    repository => 'https://github.com/salva/p5-Alien-Libgcrypt.git' } },
);

$builder->create_build_script();
