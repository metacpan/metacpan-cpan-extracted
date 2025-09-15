# Copyright (C) 2002-2003 Rob Brown (bbb@cpan.org)
# Chicken-And-Egg rpm SPEC file generator.

use strict;

my $reqs = join ";"
    , qq([ -e /etc/SuSE-release -o -e /etc/UnitedLinux-release ] && SuSE=1)
    , qq(ver=`rpm -q rpm --qf %%{version}|awk -F . '{print \$1}'`)
    , qq([ \$ver -le 3 -o -n "\$SuSE" ] && echo rpm || echo rpm-build)
    ;

my @cmd = (
    $^X,
    "-Ilib",
    "./cpan2rpm",
    ((eval("use File::Temp"),$@) ? ("--tempdir","/tmp/cpan2rpm") : ()),
    "--force",
    "--spec-only",
    "--spec", "./cpan2rpm.spec",
    "--requires", "%($reqs)",
    "--no-prfx",
    "--buildarch=noarch",
    "--doc", "perl.req.patch",
    "--license", "Gnu Public License (GPL)",
    "."
    );

exec(@cmd) or die "exec failure: $!";
