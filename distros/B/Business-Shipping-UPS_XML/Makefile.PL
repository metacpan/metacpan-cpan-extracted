use ExtUtils::MakeMaker;

my $config_file = "t/log/config.cfg";

if ( ! -f $config_file ) {

   my $userid         = prompt("Enter your UPS user id: ");
   my $userid_pass    = prompt("Enter your UPS password: ");
   my $access_key     = prompt("Enter your UPS access key: ");

   open( CFG, "> $config_file");

   print CFG "$userid\n";
   print CFG "$userid_pass\n";
   print CFG "$access_key\n";

   close(CFG);
}

WriteMakefile(
  NAME => 'Business::Shipping::UPS_XML',
  VERSION_FROM => 'lib/Business/Shipping/UPS_XML.pm',
  PREREQ_PM => {
                'Test::More'	=> 0,
                'Net::SSLeay'	=> 0,
               },
);

 