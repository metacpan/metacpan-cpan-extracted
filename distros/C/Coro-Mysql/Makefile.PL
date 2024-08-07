use ExtUtils::MakeMaker;

print <<EOF;

**
** This module *MUST* be dynamically linked against exactly the same
** libmysqlclient as your DBD::mysql module (also dynamically).
** Otherwise it will die quickly when used.
** If desperate, you could also try linking against the DBD::mysql
** shared object itself.
**
** To adjust include and library path, edit the Makefile.PL, near the end.
**
** The default is to look for mariadb_config, followed by mysql_config.
**

EOF

my $cfg = (system "mariadb_config --cflags >/dev/null 2>&1")
   ? "mysql_config"
   : "mariadb_config";

print "Using '$cfg' to get compile settings.\n\n";

sub cfg {
   my $param = join " ", @_;

   my $val = qx<$cfg $param>;
   $val =~ y/[\r\n]/  /;

   print "$cfg $param: $val\n";

   $val
}

my %wm = (
    dist	=> {
	            PREOP	=> 'pod2text Mysql.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    PREREQ_PM    => {
       Scalar::Util     => 0.00,
       Coro             => 5.1,
       Guard            => 1.0,
       DBI              => 0, # not actually a hard dependency
       DBD::mysql       => 0, # not actually a hard dependency
    },
    NAME => "Coro::Mysql",
    VERSION_FROM => "Mysql.pm",

    INC => (cfg "--include"),
    LIBS => [cfg "--libs_r"],
);

if (eval "require EV::MakeMaker; require Coro::MakeMaker; 1") {
   %wm = Coro::MakeMaker::coro_args (EV::MakeMaker::ev_args (%wm));
   $wm{DEFINE} .= " -DHAVE_EV=1";
} else {
   print <<EOF;

**
** Especially fast with EV!
**
** This module is especially fast when used together with EV as
** the event loop - but you don't have EV installed. Too bad,
** but I work with any event loop, including EV, using my
** generic code, so no sweat. If you plan to use EV, better
** install it before this module.
**

EOF
}

WriteMakefile %wm;

