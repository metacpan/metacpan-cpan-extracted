use inc::Module::Install::DSL 0.91;

all_from       lib/CPANDB/Generator.pm
requires_from  lib/CPANDB/Generator.pm
requires_from  lib/CPANDB/Generator/GetIndex.pm
requires       Probe::Perl               0.01
requires       Time::Elapsed             0.26
requires       ORDB::CPANUploads         0.04
requires       ORDB::CPANTesters         0.09
requires       ORDB::CPANMeta::Generator 0.10
requires       Parse::CPAN::Ratings      0.33
test_requires  Test::More                0.42
test_requires  URI::file                 4.20
test_requires  File::Remove              1.42
install_script script/cpandb-generate
