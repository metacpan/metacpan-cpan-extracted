use warnings;
use strict;
use ExtUtils::MakeMaker;
use File::Which;

if ( $^O eq 'solaris' ) {
    die "OS unsupported\n";
}

if ( $^O eq 'MSWin32' ) {
    require Win32;
    my $product_info = Win32::GetOSDisplayName();
    my ( $osvername, $major, $minor, $id ) = Win32::GetOSVersion();
    print "Running on $product_info - major=$major, minor=$minor, id=$id\n";

    unless ( $major >= 6 ) {
        warn
"Too old Microsoft Windows to be supported, major version must be equal or higher 6.\n";
        die "OS unsupported\n";
    }

    # double quoting is required on Windows if there are spaces in the path
    my $tar_path = which('bsdtar.exe');
    $tar_path = which('tar') unless ( defined($tar_path) );

    unless ( defined($tar_path) ) {
        warn "No tar program available, cannot work without it.\n";
        die "OS unsupported\n";
    }
    else {
        $tar_path = qq{$tar_path} if ( $tar_path =~ /\s/ );
        my $version_info = `$tar_path --version`;
        print "Using $tar_path $version_info\n";

        if ( $version_info =~ /GNU/ ) {
            warn
"Sorry, GNU tar is not supported on Microsoft Windows. Install a BSD tar or check your PATH configuration\n";
            die "OS unsupported\n";
        }
    }
}

my ( $module_path, $module_version );

{
    require ExtUtils::MY;
    my $version_reader = MM->new();
    $module_path    = 'lib/Archive/Tar/Wrapper.pm';
    $module_version = $version_reader->parse_version("./$module_path");
}

my %WriteMakefileArgs = (
    'NAME'             => 'Archive::Tar::Wrapper',
    'VERSION'          => $module_version,
    'MIN_PERL_VERSION' => 5.008001,
    'PREREQ_PM'        => {
        'File::Temp'    => 0,
        'Cwd'           => 0,
        'Log::Log4perl' => 0,
        'IPC::Run'      => 0,
        'File::Which'   => 0
    },
);

if ( $ExtUtils::MakeMaker::VERSION >= 6.46 ) {
    $WriteMakefileArgs{META_MERGE} = {
        provides => {
            'Archive::Tar::Wrapper' => {
                file    => $module_path,
                version => $module_version
            }
        }
    };
}

if ($ExtUtils::MakeMaker::VERSION >= 6.57_02) {
    $WriteMakefileArgs{META_MERGE}->{NO_MYMETA} = 1;
}

if ( $ExtUtils::MakeMaker::VERSION >= 6.50 ) {
    $WriteMakefileArgs{META_MERGE}->{'meta-spec'} = { version => 2 };
    $WriteMakefileArgs{META_MERGE}->{'resources'} = {
        'bugtracker' => {
            'web' =>
              'https://github.com/glasswalk3r/archive-tar-wrapper-perl/issues',
        },
        'repository' => {
            'type' => 'git',
            'url' =>
              'https://github.com/glasswalk3r/archive-tar-wrapper-perl.git',
            'web' => 'https://github.com/glasswalk3r/archive-tar-wrapper-perl',
        }
    };
}

# Test::More::is_deeply is required for testing
if ( $ExtUtils::MakeMaker::VERSION >= 6.64 ) {
    $WriteMakefileArgs{TEST_REQUIRES}->{'Test::Simple'} = 1.302073;
    $WriteMakefileArgs{TEST_REQUIRES}->{'Dumbbench'}    = 0.111;
}
else {
    $WriteMakefileArgs{PREREQ_PM}->{'Test::Simple'} = 1.302073;
    $WriteMakefileArgs{PREREQ_PM}->{'Dumbbench'}    = 0.111;
}

if ( $ExtUtils::MakeMaker::VERSION >= 6.52 ) {
    $WriteMakefileArgs{CONFIGURE_REQUIRES} = {
        'ExtUtils::MakeMaker' => 0,
        'File::Which'         => 0,
    };
}

if ( $] >= 5.005 ) {
    $WriteMakefileArgs{ABSTRACT_FROM} = 'lib/Archive/Tar/Wrapper.pm';
    $WriteMakefileArgs{AUTHOR}        = [
        'Mike Schilli <cpan@perlmeister.com>',
        'Alceu Rodrigues de Freitas Junior <arfreitas@cpan.org>'
    ];
}

$WriteMakefileArgs{LICENSE} = 'gpl_3'
  if ( $ExtUtils::MakeMaker::VERSION >= 6.3002 );
WriteMakefile(%WriteMakefileArgs);
