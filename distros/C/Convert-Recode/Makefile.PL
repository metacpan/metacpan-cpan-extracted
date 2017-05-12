use ExtUtils::MakeMaker;

$recode_version = `recode --version`;

die "You need to have GNU recode v3.5 or better installed before you can use Convert::Recode\n"
    unless $recode_version && $recode_version =~ /^.*\brecode\s+(\d+\.\d+)/ && $1 > 3.5;

WriteMakefile(
    NAME	 => 'Convert::Recode',
    VERSION_FROM => 'Recode.pm',
    PREREQ_PM    => { 'File::Spec' => 0, },
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
