use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',
	SUFFIX   => 'gz',
};

if ($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME           => 'App::Actions',
	ABSTRACT_FROM  => 'lib/App/Actions.pm',
	VERSION_FROM   => 'lib/App/Actions.pm',
	AUTHOR         => 'Nigel Horne (njh@nigelhorne.com)',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE' => 'gpl_2')
		: ()),
	EXE_FILES      => [ 'bin/action-run', 'bin/action-run-smoke' ],
    PREREQ_PM      => {
        'Carp'             => 0,
        'Config'           => 0,
        'Cwd'              => 0,
        'Exporter'         => 0,
        'File::Basename'   => 0,
        'File::Path'       => 0,
        'File::Spec'       => 0,
        'File::Temp'       => 0,
        'Getopt::Long'     => 0,
        'IO::Handle'       => 0,
        'IPC::System::Simple' => 0,
        'JSON::PP'         => 0,
        'Log::Abstraction' => 0.41,
        'Object::Configure' => 0.24,
        'Params::Get'      => 0.17,
        'Params::Validate::Strict' => 0.33,
        'Pod::Usage'       => 0,
        'Readonly'         => 0,
        'Return::Set'      => 0,
        'overload'         => 0,
        'POSIX'            => 0,
        'Scalar::Util'     => 0,
        'Sub::Identify'    => 0,
        'Sub::Private'     => 0.07,
        'Sub::Protected'   => 0.03,
        'Text::ParseWords' => 0,
        'Time::HiRes'      => 0,
        'YAML::PP'         => 0,
        'YAML::PP::Common' => 0,
        'autodie'          => 0,
        'utf8'             => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.64,
    }, TEST_REQUIRES  => {
        'Capture::Tiny'    => 0,
        'File::Copy'       => 0,
        'File::Find'       => 0,
        'File::Temp'       => 0,
        'FindBin'          => 0,
        'JSON::PP'         => 0,
        'Errno'            => 0,
        'Test::Exception'  => 0,
        'Test::Memory::Cycle' => 1.06,
        'Test::Mockingbird' => 0.14,
        'Test::Most'       => 0,
        'Test::Returns'    => 0.05,
    },
    MIN_PERL_VERSION => '5.014',
    dist             => $dist,
    clean            => { FILES => 'App-Actions-*' },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://metacpan.org/pod/App::Actions',
            repository => {
                type       => 'git',
                url        => 'https://github.com/nigelhorne/App-Actions.git',
                web        => 'https://github.com/nigelhorne/App-Actions',
            },
            bugtracker => {
                web    => 'https://rt.cpan.org/Public/Dist/Display.html?Name=App-Actions',
                mailto => 'bug-App-Actions@rt.cpan.org',
            },
        },
    },
);

# Run the pre-commit hook's checks from the command line.  The staged target
# reads the index with git checkout-index, so it checks what would be committed
# without creating a commit; the worktree target checks the checkout as it is,
# unstaged edits included.  An ordinary clone needs no hook setup for either
# target to work.
sub MY::postamble {
	return <<'MAKE';
.PHONY: check-staged check-worktree
check-staged:
	$(PERLRUN) .githooks/pre-commit --staged
check-worktree:
	$(PERLRUN) .githooks/pre-commit --worktree
MAKE
}
