use warnings;
use English '-no_match_vars';
use Module::Build 0.280802;
use Config;
	
die "OS unsupported" if ('MSWin32' ne $OSNAME);

my $class = Module::Build->subclass(

	class => 'ModuleBuildAlienWiX',
	code => q{
		use Config;
	
		sub ACTION_code {
            my $self = shift;
            my $install_dotnet = $self->notes('install_dotnet');
            my $install_wix = $self->notes('install_wix');
            my $WIX_URL = 'http://wix.sourceforge.net/releases/3.0.5419.0/Wix3.msi';
			if ($Config{archname} =~ /MSWin32-x64/) {
				$WIX_URL = 'http://wix.sourceforge.net/releases/3.0.5419.0/Wix3_x64.msi';
			}
            my $NET20_URL = 'http://download.microsoft.com/download/0/8/c/08c19fa4-4c4f-4ffb-9d6c-150906578c9e/NetFx20SP1_x86.exe';
			require Win32;
            my $NET20_FILE = Win32::GetShortPathName($ENV{TEMP}) . '\NetFx20SP1_x86.exe';
            my $ok;
            
            if ($install_dotnet) {
                print "Downloading and installing Microsoft .NET Framework 2.0 SP1.\n";

				# Need to get the file manually - it's not an MSI.
				require LWP::UserAgent;
				my $ua = LWP::UserAgent->new;
				$ua->agent('Alien-WiX/1.305419 ');
				my $r = $ua->mirror( $NET20_URL, $NET20_FILE );
				if ( $r->is_error ) {
					print "Error getting $NET20_URL: " . $r->as_string . "\n";
					unlink $NET20_FILE if -f $NET20_FILE;
					die q{Couldn't install .NET Framework 2.0 SP1, stopped};
				} elsif ( 24_758_792 != -s $NET20_FILE ) {
					print "Error getting $NET20_URL: File downloaded not correct size.\n";
					unlink $NET20_FILE if -f $NET20_FILE;
					die q{Couldn't install .NET Framework 2.0 SP1, stopped};				
				} else {
					$self->notes('install_dotnet' => 0);
				}
					
				# Now run it in passive mode.  It's only polite to show some UI.
				$ok = $self->do_system("$NET20_FILE /passive");
				unless ($ok) {
					unlink $NET20_FILE;
					die q{Couldn't install .NET Framework 2.0 SP1, stopped};
				} else {
					$self->notes('install_dotnet' => 0);
					unlink $NET20_FILE;
				}
            }

            if ($install_wix) {
                print "Downloading and installing Windows Installer XML 3.0.5419.0.\n";
                $ok = $self->do_system("msiexec /i $WIX_URL /qb!");
                unless ($ok) {
                    die q{Couldn't install WiX, stopped};
                } else {
                    $self->notes('install_wix' => 0);
                }
            }
            
            $self->SUPER::ACTION_code();
        }

		
		sub ACTION_authortest {
			my ($self) = @_;

			$self->depends_on('build');
			$self->depends_on('manifest');
			$self->depends_on('distmeta');

			$self->test_files( qw< t xt/author > );
			$self->depends_on('test');

			return;
		}


		sub ACTION_releasetest {
			my ($self) = @_;

			$self->depends_on('build');
			$self->depends_on('manifest');
			$self->depends_on('distmeta');

			$self->test_files( qw< t xt/author xt/release > );
			$self->depends_on('test');

			return;
		}


		sub ACTION_manifest {
			my ($self, @arguments) = @_;

			if (-e 'MANIFEST') {
				unlink 'MANIFEST' or die "Can't unlink MANIFEST: $!";
			}

			return $self->SUPER::ACTION_manifest(@arguments);
		}

    }
);


my $builder = $class->new(
    module_name         => 'Alien::WiX::Version30',
    license             => 'perl',
    dist_author         => 'Curtis Jewell <csjewell@cpan.org>',
    dist_version_from   => 'lib/Alien/WiX.pm',
    configure_requires  => {
        'Win32API::Registry'
                        => '0.30',
        'Module::Build'
                        => '0.280802',
    },
    build_requires  => {
        'Module::Build'
                        => '0.280802',
        'LWP::UserAgent'
                        => '5.819',
        'Test::More'    => '0.88',
    },
    requires            => {
        'perl'          => '5.008',
        'Readonly'      => '1.03',
        'version'       => '0.76',
        'Win32API::Registry'
		                => '0.30',
		'Win32::TieRegistry'
		                => '0.26',
    },
	recommends          => {
		'Readonly::XS'  => '1.05',
	},
	create_makefile_pl  => 'small',
	meta_merge => {
		resources => {
			homepage => 'http://csjewell.comyr.com/',
			bugtracker =>
'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-WiX-Version30',
			repository =>
			  'http://svn.ali.as/cpan/trunk/Alien-WiX/'
		},
	},
    add_to_cleanup      => [ 'Alien-WiX-Version30-*' ],
);

eval { require Win32API::Registry; }
    or die q{I can't check whether WiX is installed without Win32API::Registry};
Win32API::Registry->import(0.30);
Win32API::Registry->import(':ALL');

$builder->notes('install_dotnet' => 0);
$builder->notes('install_wix' => 0);

my ($default, $answer, $installed, $key, $type, $data, $int_data, $version);
my $WIX30_REGISTRY_KEY = 'SOFTWARE\\Microsoft\\Windows Installer XML\\3.0';
my $NET20_REGISTRY_KEY = 'SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v2.0.50727';
my $WIX_VERSION = 5419;

$key = 1;
$installed = 0;
if (RegOpenKeyEx( regConstant('HKEY_LOCAL_MACHINE'), $NET20_REGISTRY_KEY, 0, regConstant('KEY_READ'), $key ))
{
	if (RegQueryValueEx( $key, 'Install', [], $type, $data, [] )) {
        $int_data = unpack 'L', $data;
    
		if ($int_data > 0) {
            print ".NET Framework 2.0 installed.\n\n";
			$installed = 1;
		}
	} 
    
    RegCloseKey( $key );
}

$answer = 0;

unless ($installed) {
	$answer = $builder->y_n('Install .NET Framework 2.0 SP1?', 'y');

	if ($answer) {
        $builder->notes('install_dotnet' => 1);
	} else {
		die q{Didn't install .NET Framework 2.0 SP1, stopped};
	}
}
	
$installed = 0;
$default = 'y';
$answer = 0;

# 0x200 = KEY_WOW64_32KEY.
if (RegOpenKeyEx( regConstant('HKEY_LOCAL_MACHINE'), $WIX30_REGISTRY_KEY, 0, regConstant('KEY_READ') | 0x200, $key ))
{
	if (RegQueryValueEx( $key, 'ProductVersion', [], $type, $data, [] )) {
		if ($data =~ m/3.0.(\d+).0/) {
			$version = $1;
            print "Version of WiX installed: $data ($version)\n\n";
			if ($version >= $WIX_VERSION) {
				$installed = 1;
			} else {
				$default = 'n';
			}
		}
	}

    RegCloseKey( $key );
}

unless ($installed) {
	$answer = $builder->y_n('Install Windows Installer XML version 3.0.5419?', $default);

	if ($answer) {
        $builder->notes('install_wix' => 1);
	} else {
		die q{Didn't install WiX, stopped} if ($default eq 'y');
	}
}

$builder->create_build_script();

