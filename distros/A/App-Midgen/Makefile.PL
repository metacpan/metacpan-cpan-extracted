use inc::Module::Install::DSL 1.08;

all_from lib/App/Midgen.pm
requires_from lib/App/Midgen.pm

perl_version 5.008001

requires Carp                 1.3301
requires Cwd                  3.47
requires Class::XSAccessor    1.19 if can_xs
requires Data::Printer        0.35
requires File::Slurp::Tiny    0.003
requires File::Spec           3.47
requires Getopt::Long         2.42
requires JSON::Tiny           0.49
requires List::MoreUtils      0.33
requires MetaCPAN::Client     1.003
requires Module::CoreList     3.1
requires Moo                  1.004005
requires PPI                  1.215
requires PPI::XS              0.902 if can_xs
requires Perl::MinimumVersion 1.37
requires Perl::PrereqScanner  1.019
requires Pod::Usage           1.63
requires Term::ANSIColor      4.03
requires Tie::Static          0.04
requires Time::Stamp          1.3
requires Try::Tiny            0.22
requires Type::Tiny           0.042
requires constant             1.27
# requires lib                  0.63
requires version              0.9908

test_requires Test::CheckDeps 0.01
test_requires Test::More      1.001003
test_requires Test::Requires  0.07

recommends ExtUtils::MakeMaker   6.68
recommends File::Spec::Functions 3.47
recommends List::Util            1.38
recommends Test::Pod             1.48
recommends Test::Pod::Coverage   1.08
recommends Test::Script          1.07

install_script midgen

homepage    https://github.com/kevindawson/App-Midgen
bugtracker  https://github.com/kevindawson/App-Midgen/issues
repository  git://github.com/kevindawson/App-Midgen.git

no_index directory  qw{ inc t xt }

