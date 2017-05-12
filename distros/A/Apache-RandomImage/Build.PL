use strict;
use warnings;
use Module::Build;

# Adapted from http://search.cpan.org/src/PAULDOOM/Apache-AppSamurai-1.01/Build.PL
# Thx pauldoom!
#
# Decide right now if we are shooting for a mod_perl 1.x
# or mod_perl 2.x install.  Defaults to mod_perl 2.x.
# This is to have a proper set of requirements in place
# so CPAN and others will behave.
my @modperlreq = ();
if (eval{require mod_perl2;}) {
    push(@modperlreq, 'mod_perl2', 1.9922);
    print STDERR "mod_perl 2 detected: Setting requirements accordingly\n";
} elsif (eval{require mod_perl;}) {
    push(@modperlreq, 'mod_perl', 1.07);
    print STDERR "mod_perl 1 detected: Setting requirements accordingly\n";
} else {
    # Nothing found yet.  Let's go with MP2
    push(@modperlreq, 'mod_perl2', 1.9922);
    print STDERR "mod_perl not detected: Setting requirements for mod_perl 2.x\n";
}

my $builder = Module::Build->new(
    module_name         => 'Apache::RandomImage',
    license             => 'perl',
    dist_author         => 'Michael Kroell <pepl@cpan.org>',
    dist_version_from   => 'lib/Apache/RandomImage.pm',
    build_requires => {
        'Test::More'  => 0,
    },
    requires => {
        @modperlreq
    },
    add_to_cleanup      => [ 'Apache-RandomImage-*' ],
    create_makefile_pl  => 'traditional',
    create_readme       => 1,
    sign                => 1,
);

$builder->create_build_script();
