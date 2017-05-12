use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Config::DB',
    PREREQ_PM    => { 'DBI' => 1.616 },
    VERSION_FROM => 'lib/Config/DB.pm',
    clean        => { FILES => '*~ .*~ */*~ */.*~ nohup.out cfg* notable*' }
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
