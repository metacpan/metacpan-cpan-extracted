use inc::Module::Install;

name 'App-Unix-RPasswd';
all_from 'lib/App/Unix/RPasswd.pm';
license 'gpl';
no_index 'directory'            => 'lib/App/Unix/RPasswd';
perl_version '5.010000';
test_requires 'Test::More'      => '0.42';
requires 'Crypt::PasswdMD5'      => 0;
requires 'Expect'                => 0;
requires 'List::MoreUtils'       => 0;
requires 'Moo'                  => 0;
requires 'Parallel::ForkManager' => 0;
requires 'Term::ReadKey'	 => 0;
install_script 'rpasswd';
write_mymeta_yaml;
write_mymeta_json;
WriteAll;
