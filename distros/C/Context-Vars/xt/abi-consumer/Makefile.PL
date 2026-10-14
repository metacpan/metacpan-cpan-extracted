use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;

# A consumer of Context::Vars's C ABI, as a third party would write one: it
# finds the header through ExtUtils::Depends and nothing else. Built and run
# by xt/abi-consumer.t; it is not installed and not shipped as a module.
#
# Any include directory that holds hamt_abi.h is dropped, so that the build
# proves the claim the header makes: a consumer needs this one header and
# nothing from HAMT.
my $pkg = ExtUtils::Depends->new('Context::Vars::ABI::Consumer', 'Context::Vars');
my %v   = $pkg->get_makefile_vars;
$v{INC} = join ' ', grep {
    my ($d) = /^-I(.+)$/;
    !(defined $d && -f "$d/hamt_abi.h");
} split ' ', ($v{INC} // '');
print "INC: $v{INC}\n";

WriteMakefile(
    NAME         => 'Context::Vars::ABI::Consumer',
    VERSION_FROM => 'lib/Context/Vars/ABI/Consumer.pm',
    XS           => { 'Consumer.xs' => 'Consumer.c' },
    OBJECT       => 'Consumer$(OBJ_EXT)',
    %v,
);
