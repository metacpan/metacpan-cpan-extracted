use 5.006;
use strict;
use warnings;
use Alien::Base::ModuleBuild;

my $class = Alien::Base::ModuleBuild->subclass( class => 'Alien::Libpgp_error::Builder',
                                                code => <<'EOC');

use strict;
use warnings;

$ENV{FTP_PASSIVE} = 1;

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

sub system_libgpg_error_config_get {
  my ($self, @keys) = @_;
  my %result = $self->do_system(join(' ', 'gpg-error-config', map "--$_", @keys));
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
    return $self->system_libgpg_error_config_get('cflags');
  }
  return;
}

sub alien_provides_libs {
  my $self = shift;
  if ($self->use_installed_version) {
    return $self->system_libgpg_error_config_get('libs');
  }
  return;
}

EOC

my $builder = Alien::Base::ModuleBuild
    ->new( module_name          => 'Alien::Libgpg_error',
           license              => 'perl',
           dist_author          => q{Salvador Fandiño <sfandino@yahoo.com>},
           dist_version_from    => 'lib/Alien/Libgpg_error.pm',
           configure_requires   => { 'Alien::Base' => '0.024',
                                     'Module::Build' => '0.36' },
           build_requires       => { 'Test::More' => 0 },
           add_to_cleanup       => [ 'Alien-Libgpg_error-*' ],
           alien_name           => 'libgpg-error',
           alien_repository     => { protocol => 'ftp',
                                     host => 'ftp.gnupg.org',
                                     location => '/gcrypt/libgpg-error/',
                                     pattern => qr/^libgpg-error-(\d+\.\d+)\.tar\.gz$/ },
           alien_msys           => 1,
           alien_stage_install  => 0,
           alien_build_commands => [ '%c --prefix=%s --disable-doc --disable-languages',
                                     '%x ../../helpers/fix-makefile.pl',
                                     'make' ],

           alien_version_check  => 'gpg-error-config --version',
         );

$builder->create_build_script();
