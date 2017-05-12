use strict;
use warnings;
use Module::Build;

#################################################
# hint for CPAN testers
#
die "OS unsupported\n" unless $^O =~ m/linux/i;

my $default_install_base = '/usr/local/capo';

################
# it's a webapp, we need special install procedures
#
my $my_capo_class = Module::Build->subclass(
    class => 'Module::Build::Capo',
    code  => <<'EO_SUBCLASS' );

    use ExtUtils::Install qw();

    sub ACTION_dist {
      my ($self) = @_;


      # be sure we make RELEASE_TESTING=1 on Build dist
      { 
	  local $ENV{RELEASE_TESTING} = 1;
	  $self->dispatch('test');
      }

      $self->SUPER::ACTION_dist;
    }

    sub ACTION_install {
        my $self = shift;

        my $target = $self->destdir || $self->install_base || '/tmp';

        my %my_install_map =
          map { $_ => "$target/$_" } @{ $self->notes('dirs') };

	# 'read' key needed by newer versions of ExtUtils::install  
	# set it with dummy value to silence warnings
        $my_install_map{read} = '';

        ExtUtils::Install::install( \%my_install_map, $self->verbose, 0);
    }

    sub ACTION_fakeinstall {
        my $self = shift;

        my $target = $self->destdir || $self->install_base || '/tmp';

        my %my_install_map =
          map { $_ => "$target/$_" } @{ $self->notes('dirs') };

	# 'read' key needed by newer versions of ExtUtils::install  
	# set it with dummy value to silence warnings
        $my_install_map{read} = '';

        ExtUtils::Install::install( \%my_install_map, !$self->quiet, 1);
    }

    sub ACTION_uulmfiles {
        my $self = shift;

        my $src = $self->current_action;

        my $target =
          $self->dist_name . '-' . $src . '-' . $self->dist_version;

        $self->make_tarball( $src, $target );
    }

EO_SUBCLASS

my $builder = $my_capo_class->new(
    module_name       => 'Captive::Portal',
    license           => 'perl',
    dist_author       => q{Karl Gaissmaier <gaissmai (at) cpan.org>},
    dist_version_from => 'lib/Captive/Portal.pm',
    create_readme     => 1,
    dynamic_config    => 1,
    install_base      => $default_install_base,

    script_files => [
        qw(
          bin/capo-ctl.pl
          cgi-bin/capo.fcgi
          bin/mock-server.pl
          bin/test-server.pl
          )
    ],

    requires => {
        'parent'      => 0,
        'Role::Basic' => 0,
        'Template'    => 0,
        'JSON'        => 0,
        'CGI::Fast'   => 0,
        'CGI::Cookie' => 0,

        'Authen::Simple' => 0,
        'Scalar::Util'   => 0,
        'Time::HiRes'    => 0,
        'Try::Tiny'      => 0,
        'Spawn::Safe'    => 0,

        'Log::Log4perl'         => 0,
        'Log::Dispatch::Syslog' => 0,

    },

    recommends => {
        'Authen::Simple::RADIUS' => 0,

        'Test::WWW::Mechanize::CGI'    => 0,
        'HTTP::Server::Simple::CGI'    => 0,
        'HTTP::Server::Simple::Static' => 0,
    },

    configure_requires => { 'Module::Build' => 0, },

    add_to_cleanup => [ 'README', 'Captive-Portal-*', 't/sessions' ],
);

# what web-app dirs must be installed
$builder->notes( dirs => [qw(lib bin cgi-bin etc static templates)] );
$builder->create_build_script();

# -----------------------------------------------------------------------

$builder->notes( test_radius_modules => 1 )
  if $builder->prompt( 'Shall we test availabilty of RADIUS modules?', 'no' )
  =~ m/^y(es)?$/i;

$builder->log_info( <<EOWARN );

Please read the INSTALL file!
EOWARN

