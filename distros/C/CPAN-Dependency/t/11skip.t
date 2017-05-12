use strict;
use Test::More;


plan skip_all => "Test::Deep required for this test" unless eval "use Test::Deep; 1";

my @bundles = qw(
    Bundle::CPANPLUS  Bundle::Math  Bundle::Net::LDAP
);
my @core = qw(
    Carp  Class::Struct  Fcntl  File::Basename  File::Copy  File::Find
    Getopt::Std  IPC::Open3  Math::Trig  Net::hostent  POSIX  Socket
    Sys::Hostname  Sys::Syslog  Term::ReadLine  Text::ParseWords
    Thread  Tie::Array  Tie::Handle  Tie::Hash  Tie::Scalar
);
my %dists = (
    'Bundle::CPANPLUS' => 'Bundle-CPANPLUS', 
    'Bundle::Math' => 'Bundle-Math', 
    'Bundle::Net::LDAP' => 'Bundle-Net-LDAP', 
);
map { $dists{$_} = 'perl' } @core;

my $nb_process_tests = @core + @bundles;

plan tests => 4 + $nb_process_tests;

eval "use File::Temp qw(:POSIX)";
eval "use YAML qw(LoadFile)";
eval "use CPAN::Dependency";

# create an object
my $cpandep = undef;
eval { $cpandep = new CPAN::Dependency };
is( $@, ''                                  , "object created"               );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

SKIP: {
    my $mirror_access = $cpandep->{backend}->configure_object->get_conf("hosts")->[0]{scheme};
    skip "CPANPLUS not configured to use a local mirror", $nb_process_tests
        unless $mirror_access eq "file";

    # check that bundles are correctly skipped
    $cpandep->process(@bundles);
    $cpandep->run;
    for my $dist (@dists{@bundles}) {
        ok( not exists $cpandep->{prereqs}{$dist} );
    }
    
    # check that core modules are correctly skipped
    $cpandep->process(@core);
    $cpandep->run;
    for my $mod (@core) {
        ok( not exists $cpandep->{prereqs}{$dists{$mod}} );
    }
}
