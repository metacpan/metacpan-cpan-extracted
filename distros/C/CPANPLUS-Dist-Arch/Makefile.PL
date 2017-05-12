use ExtUtils::MakeMaker;

my @reqs = qw{CPANPLUS Digest::MD5 File::Copy File::stat IPC::Cmd DynaLoader
    Pod::Select Module::CoreList File::Spec::Functions Carp};

# cpan2aur
push @reqs, qw{Term::ANSIColor Archive::Tar Text::Wrap IO::Zlib version POSIX
    Cwd};

# cpan2aur and setupdistarch
push @reqs, qw{Getopt::Long Pod::Usage};

@reqs = map { ($_ => 0) } @reqs;
push @reqs, qw/File::Path 2.06_05/;

my $meta =
    { 'resources' =>
        { 'repository' =>
            'https://github.com/jnbek/perl-cpanplus-dist-arch' }};

my @scripts = qw{script/cpan2aur script/setupdistarch};

WriteMakefile(
    'NAME' => 'CPANPLUS::Dist::Arch',
    'ABSTRACT' => 'CPANPLUS backend for building ArchLinux pacman packages',
    'AUTHOR' => 'John D Jones III <jnbek@cpan.org>',
    'VERSION' => '1.32',
    'PREREQ_PM' => { @reqs },
    'META_ADD' => $meta,
    'EXE_FILES' => \@scripts,
);
