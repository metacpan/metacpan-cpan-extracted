use Module::Build 0.11;

my $m = Module::Build->new
  (
   module_name => 'Crypt::SKey',
   recommends => {
		  Digest::MD5 => 2.16,
		  Digest::MD4 => 1.0,
		  Term::ReadKey => 2.14,
		  Digest::SHA1 => 2.11,
		 },
   license => 'perl',
   create_readme => 1,
   sign => 1,
  );
$m->create_build_script;
