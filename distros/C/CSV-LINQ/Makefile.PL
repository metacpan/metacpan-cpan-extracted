use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } } use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use ExtUtils::MakeMaker;

my %args = (
    'NAME'      => q{CSV::LINQ},
    'VERSION'   => q{1.00},
    'ABSTRACT'  => q{LINQ-style query interface for CSV files},
    'PREREQ_PM' => {
        'perl' => '5.005_03',
        'strict' => '1.01',
        'vars' => '0',
        'warnings' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

# LICENSE was introduced in ExtUtils::MakeMaker 6.31 (2006).
# Passing it to older versions produces an "is not a known parameter" warning
# without failing, but we suppress the noise by checking the version.
if ($ExtUtils::MakeMaker::VERSION >= 6.31) {
    $args{LICENSE} = q{perl};
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
            'bugtracker' => {
                'web' => 'https://github.com/ina-cpan/CSV-LINQ/issues',
            },
            'repository' => {
                'url'  => 'https://github.com/ina-cpan/CSV-LINQ',
                'web'  => 'https://github.com/ina-cpan/CSV-LINQ',
                'type' => 'git',
            },
        },
        'provides' => {
            'CSV::LINQ' => {
                'file'    => 'lib/CSV/LINQ.pm',
                'version' => '1.00',
            },
            'CSV::LINQ::Ordered' => {
                'file'    => 'lib/CSV/LINQ.pm',
                'version' => '1.00',
            }
        },
    };
}

WriteMakefile(%args);

__END__
