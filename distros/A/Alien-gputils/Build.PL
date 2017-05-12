use strict;
use warnings;
use Env qw(@PATH);
use Alien::Base::ModuleBuild;

$Alien::Base::ModuleBuild::Verbose = 1;

my %nonwin32 = ();
if ($^O =~ /mswin32/i) {
    foreach (qw{PROGRAMFILES ProgramFiles PROGRAMFILES(X86)
                ProgramFiles(X86) ProgamFileW6432 PROGRAMFILESW6432}) {
        next unless exists $ENV{$_};
        my $dir = ($ENV{$_} =~ /\s+/) ? Win32::GetShortPathName($ENV{$_}) : $ENV{$_};
        push @PATH, File::Spec->catdir($dir, 'gputils', 'bin') if $dir;
    }
} else {
    %nonwin32 = ('Alien::bison' => 0);
}

my $class = Alien::Base::ModuleBuild->subclass(
    class => 'Alien::gputils::ModuleBuild',
    code => q {
        use File::Spec;
        use Env qw(@PATH);
        use File::Which qw(which);
        use Capture::Tiny qw(capture_merged);
        
        if ($^O =~ /mswin32/i) {
            foreach (qw{PROGRAMFILES ProgramFiles PROGRAMFILES(X86)
                    ProgramFiles(X86) ProgamFileW6432 PROGRAMFILESW6432}) {
                next unless exists $ENV{$_};
                my $dir = ($ENV{$_} =~ /\s+/) ? Win32::GetShortPathName($ENV{$_}) : $ENV{$_};
                push @PATH, File::Spec->catdir($dir, 'gputils', 'bin') if $dir;
            }
        }
        sub gpasm_check {
            my $self = shift;
            my $path = which('gpasm');
            unless (defined $path) {
                if ($^O =~ /mswin32/i) {
                    warn q{You need to install the gputils from their Windows
                        specific installer from the website http://sourceforge.net/projects/gputils/files/};
                    die 'No support for OS';
                }
            }
            return $path;
        }
        sub alien_check_installed_version {
            my $self = shift;
            my $path = $self->gpasm_check();
            if (defined $path) {
                my $output = capture_merged {
                    `gpasm -v`;
                };
                print STDERR "Got gpasm version: $output" if $output;
                if ($output =~ /gpasm-(\d+)\.(\d+)\.(\d+)/) {
                    unless ($1 > 0 and $2 > 2) {
                        $ENV{ALIEN_FORCE} = 1;
                        $Alien::Base::ModuleBuild::Force = 1;
                        return;
                    }
                    my $ver = sprintf "%d.%d.%d", $1, $2, $3;
                    print STDERR "Found gputils VERSION: $ver\n";
                    # find the path where it is found
                    my @dirs = File::Spec->splitpath($path);
                    pop @dirs if @dirs;
                    $path = File::Spec->catdir(@dirs) if @dirs;
                    print STDERR "Found gputils installed in $path\n" if defined $path;
                    return unless $1 > 0;
                    return unless $2 > 2;
                    $self->config_data(gputils_system_path => $path) if defined $path;
                    return $ver;
                }
            }
            $ENV{ALIEN_FORCE} = 1;
            $Alien::Base::ModuleBuild::Force = 1;
            return;
        }
    }
);
my $build = $class->new(
    module_name => 'Alien::gputils',
    license => 'apache',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for gputils from http://gputils.sourceforge.net',
    create_readme => 0,
    configure_requires => {
        'Module::Build' => 0,
        'Alien::Base' => '0.006',
        'Alien::Base::ModuleBuild' => '0.006',
        'Capture::Tiny' => 0,
        %nonwin32,
    },
    build_requires => {
        'Alien::Base::ModuleBuild' => '0.006',
        'Test::More' => 0,
        'Module::Build' => 0,
        'Capture::Tiny' => 0,
        %nonwin32,
    },
    requires => {
        'File::Spec' => 0,
        'File::Which' => 0,
        'Alien::Base' => '0.006',
    },
    alien_name => 'gputils',
    alien_repository => {
        protocol => 'http',
        host => 'downloads.sourceforge.net',
        location => '/project/gputils/gputils/1.4.0/',
        exact_filename => 'gputils-1.4.0-1.tar.gz',
        exact_version => '1.4.0',
        c_compiler_required => 1,
    },
    alien_build_commands => [
        '%c --disable-html-doc --without-mplabx-path --prefix=%s',
        'make',
        'make check'
    ],
    alien_install_commands => [
        'make install'
    ],
    alien_bin_requires => { %nonwin32 },
    meta_merge => {
        resources => {
            repository => "https://github.com/selectiveintellect/p5-alien-gputils",
            bugtracker => "https://github.com/selectiveintellect/p5-alien-gputils/issues",
        },
    },
);

$build->create_build_script;
$build->dispatch('distmeta');
$build->dispatch('manifest');
$build->dispatch('build');

__END__
#### COPYRIGHT: Vikas N Kumar. Selective Intellect LLC. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 18th Nov 2014
#### LICENSE: Refer LICENSE file.
