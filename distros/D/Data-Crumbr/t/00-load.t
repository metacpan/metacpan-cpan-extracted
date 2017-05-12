use Test::More tests => 5;

BEGIN {
   use_ok($_)
     for (
      qw<
      Data::Crumbr
      Data::Crumbr::Default
      Data::Crumbr::Default::JSON
      Data::Crumbr::Default::URI
      Data::Crumbr::Util
      >
     );
} ## end BEGIN

diag("Testing App::Crumbr $Data::Crumbr::VERSION");

done_testing();
