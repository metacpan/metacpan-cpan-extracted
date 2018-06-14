use v5.16;
use Module::Build;

BEGIN                                                                           # Check environment
 {if ($^O eq 'MSWin32')
   {print "OS Unsupported\n";
    exit 1;
   }
  unless(eval q{ use 5.016; 1})
   {print "Perl v5.16 or better required\n";
    exit 1;
   }
 }

my $b = Module::Build->new
 (module_name   => 'Data::Edit::Conversion',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Perform a restartable series of steps in parallel',
  license       => 'perl',
  requires      =>
   {'Carp'             =>0,
    'Data::Dump'       =>0,
    'File::Touch'      =>0,
    'Data::Table::Text'=>20180610,
    'Storable'         =>0,
    'Test2::API'       =>0,
    'Test::More'       =>0,
    'Time::HiRes'      =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
