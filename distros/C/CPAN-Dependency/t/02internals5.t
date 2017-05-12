use strict;
use Test::More;
use CPAN::Dependency;


my @mods = qw(WWW::Mechanize Maypole Template CPAN::Search::Lite);
my @skip_list = qw(LWP::UserAgent Net::SSLeay CGI Net-Pcap);

plan tests => 4;

my $cpandep = eval { CPAN::Dependency->new(skip => [ @skip_list ]) };
is( $@, ''                                  , "object created (passing a list of modules to process())" );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );
