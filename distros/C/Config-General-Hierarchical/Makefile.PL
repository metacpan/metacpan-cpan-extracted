use ExtUtils::MakeMaker;

my $exclude = $ENV{EXCLUDE_WEAKEN} ? 1 : 0;

open FD, '>Hierarchical/ExcludeWeaken.pm';
print FD <<EOF;
package Config::General::Hierarchical::ExcludeWeaken;

our \$exclude = $exclude;

1;
EOF
close FD;

WriteMakefile(
    NAME      => 'Config::General::Hierarchical',
    PREREQ_PM => {
        'Carp'                  => 0,
        'Class::Accessor::Fast' => 0,
        'Clone::PP'             => 1.02,
        'Config::General'       => 2.49,
        'Cwd'                   => 0,
        'Scalar::Util'          => 1.18,
        'Test::Differences'     => 0.47,
    },
    VERSION_FROM => 'lib/Config/General/Hierarchical.pm',
    clean        => {
        FILES =>
'*~ .*~ */*~ */.*~ nohup.out *.tdy t/*.tdy Hierarchical/*.tdy t/dir/*~ t/dump.conf t/import.conf t/dir cover_db'
    }
);

package MY;

# This make the clean target to not remove the Makefile.
# This because I use make clean so often and I want it not removes my
# Makefile. If you know any way this can hurt, don't esitate to
# remove this sub and please warn me about it.
sub clean {
    my $inherited = shift->SUPER::clean(@_);
    $inherited =~
s/- \$\(MV\) \$\(FIRST_MAKEFILE\) \$\(MAKEFILE_OLD\)/- \$(CP) \$(FIRST_MAKEFILE) \$(MAKEFILE_OLD)/;
    $inherited;
}
