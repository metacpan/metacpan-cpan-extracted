use strict;
use Test::More;
use CPAN::Dependency;


my @options = qw(clean_build_dir color debug prefer_bin verbose);
my @mods    = qw(WWW::Mechanize Maypole Template CPAN::Search::Lite);
my @skip_list = qw(LWP::UserAgent Net::SSLeay CGI Net-Pcap);

plan tests => 7 + 3*@options + 4;

# create an object
my $cpandep = eval { CPAN::Dependency->new };
is( $@, ''                                  , "object created"               );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

# check that CPANPLUS object is correctly created
ok( defined $cpandep->{backend}                   , "backend object is defined"          );
ok( $cpandep->{backend}->isa('CPANPLUS::Backend') , "backend object is of expected type" );
is( ref $cpandep->{backend}, 'CPANPLUS::Backend'  , "backend object is of expected ref"  );

# check binary options
for my $option (@options) {
    ok( ref $cpandep->can($option)          , "object->can($option)"         );
    $cpandep->$option(1);
    is( $cpandep->{options}{$option}, 1     , "  checking true value"        );
    $cpandep->$option(0);
    is( $cpandep->{options}{$option}, 0     , "  checking false value"       );
}

SKIP: {
    my $mirror_access = $cpandep->{backend}->configure_object->get_conf("hosts")->[0]{scheme};
    skip "CPANPLUS not configured to use a local mirror", 2
        unless $mirror_access eq "file";

    # check that process() works
    $cpandep->process(@mods[0,1]);
    is_deeply( $cpandep->{process}, [@mods[0,1]] , "calling process() with two args as list" );
    $cpandep->process([@mods[2,3]]);
    is_deeply( $cpandep->{process}, [@mods]      , "calling process() with two args as arrayref" );
}

# check that skip() works (note: skip() accepts module or distribution 
# names but only stores distribution names)
$cpandep->{skip} = {};
my %expected1 = ('libwww-perl' => 1, 'Net-SSLeay' => 1                                   );
my %expected2 = ( %expected1                             , 'CGI' => 1,    'Net-Pcap' => 1);
$cpandep->skip(@skip_list[0,1]);
is_deeply( $cpandep->{skip}, \%expected1 , "calling skip() with two args as list" );
$cpandep->skip([@skip_list[2,3]]);
is_deeply( $cpandep->{skip}, \%expected2 , "calling skip() with two args as arrayref" );
