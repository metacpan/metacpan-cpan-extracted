use ExtUtils::MakeMaker;

my @opt=( NAME      	  => "DB::SPEEDYB",
          VERSION_FROM	  => "SPEEDYB.pm",
          TYPEMAPS        => ['perlobject.map','typemap'],
          INC             => '-Ic',
          clean           => { FILES => 'DB-SPEEDYB-*' },
        );

WriteMakefile(@opt);
