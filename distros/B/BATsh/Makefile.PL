use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use ExtUtils::MakeMaker;

my %args = (
    'NAME'      => q{BATsh},
    'VERSION'   => q{0.11},
    'ABSTRACT'  => q{Bilingual Shell for cmd.exe and bash in one script},
    'PREREQ_PM' => {
        'Carp' => '0',
        'Fcntl' => '1.03',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'File::Spec' => '0',
        'FindBin' => '1.42',
    },
    'AUTHOR'    => q{ina <ina.cpan@gmail.com>},
);

# Install bin/*.pl as executables (EUMM creates .bat wrappers on Win32).
# A dist without a bin/ directory is unaffected.
if (-d 'bin') {
    local *BINDIR;
    if (opendir(BINDIR, 'bin')) {
        $args{EXE_FILES} =
            [map { "bin/$_" } sort grep { /\.pl\z/ && -f "bin/$_" } readdir(BINDIR)];
        closedir(BINDIR);
    }
}

# LICENSE was introduced in ExtUtils::MakeMaker 6.31 (2006).
# Passing it to older versions produces an "is not a known parameter" warning
# without failing, but we suppress the noise by checking the version.
if ($ExtUtils::MakeMaker::VERSION >= 6.31) {
    $args{LICENSE} = q{perl};
}

# CONFIGURE_REQUIRES was introduced in ExtUtils::MakeMaker 6.52.  Older
# versions ignore an unknown parameter with a warning, so it is passed
# only when it is understood; the generated META files carry the same
# information for every toolchain.
if ($ExtUtils::MakeMaker::VERSION >= 6.52) {
    $args{CONFIGURE_REQUIRES} = {
        'ExtUtils::MakeMaker' => '5.4302',
    };
}

# MIN_PERL_VERSION (6.48) and META_MERGE (6.46) arrived together in the
# same EUMM release cycle; guard them under the higher threshold (6.48)
# so both are always either present or absent.
if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $args{MIN_PERL_VERSION} = q{5.00503};
    $args{META_MERGE} = {
        'meta-spec' => { version => 2 },
        'resources' => {
            'license'    => [ 'http://dev.perl.org/licenses/' ],
        },
        'provides' => {
            'BATsh' => {
                'file'    => 'lib/BATsh.pm',
                'version' => '0.11',
            },
            'BATsh::CMD' => {
                'file'    => 'lib/BATsh/CMD.pm',
                'version' => '0.11',
            },
            'BATsh::Env' => {
                'file'    => 'lib/BATsh/Env.pm',
                'version' => '0.11',
            },
            'BATsh::MB' => {
                'file'    => 'lib/BATsh/MB.pm',
                'version' => '0.11',
            },
            'BATsh::SH' => {
                'file'    => 'lib/BATsh/SH.pm',
                'version' => '0.11',
            }
        },
    };
}

WriteMakefile(%args);

__END__
