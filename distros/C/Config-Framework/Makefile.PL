use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

##GET INFO FROM USER
print "Where is your Virtual Root? (/prod usually)\n";
$data{v_root} = <stdin>;
print "Which directory under your Virtual Root holds your configuration Data?\n";
$data{config_loc} = <stdin>;
print "Do you have Sybase client libraries installed under your Virtual Root? [yes/no]\n";
$switch = <stdin>;
if ($switch =~/yes/i){
    print "Where under Virtual Root?\n";
    $data{SYBASE} = <stdin>;
}
print "Do you have Oracle client libraries installed under your Virtual Root? [yes/no]\n";
$switch = <stdin>;
if ($switch =~/yes/i){
    print "Where under Virtual Root?\n";
    $data{ORACLE_HOME} = <stdin>;
}
print "Which library location under your virtual root should be set in LD_LIBRARY_PATH?\n";
$data{LD_LIBRARY_PATH} = <stdin>;
print "Where is sendmail?\n";
$data{sendmail} = <stdin>;
print "Who should I email if one of the programs using Config::Framework dies unexpectedly?\n";
$data{admin} = <stdin>;
$data{admin} =~s/\@/\\\@/;
print "Which encryption module should I use for passwds.xml?\n";
$data{Crypt} = <stdin>;
print "What will be the passphrase for passwds.xml?\n";
$data{Key}   = <stdin>;
foreach (keys %data){ chomp($data{$_}); }
$data{SYBASE} = "$data{v_root}/$data{SYBASE}";
$data{ORACLE_HOME} = "$data{v_root}/$data{ORACLE_HOME}";
$data{LD_LIBRARY_PATH} = "$data{v_root}/$data{LD_LIBRARY_PATH}";
##WRITE TO config.cache
print "saving config data in config.cache\n";
open (conf, ">./config.cache") || die ("can't write config data: $!\n");
foreach (keys %data){ print conf "{$_}\t$data{$_}\n"; }
close (conf);

WriteMakefile(
    'NAME'			=> 'Config::Framework',
    'VERSION_FROM'	=> 'Framework.pm',
    'ABSTRACT_FROM'	=> 'Framework.pod',
    'AUTHOR'		=> 'Andrew N. Hicox  <andrew@hicox.com>',
    'PREREQ_PM'		=> {
        Crypt::CBC				=> 2.02,
        Data::DumpXML::Parser	=> 1.01,
        File::Copy				=> 2.03
    },
    'PM_FILTER'		=> "\$(PERL) ./insert_config_data"
);
