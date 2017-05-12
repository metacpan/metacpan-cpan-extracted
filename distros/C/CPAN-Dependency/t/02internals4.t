use strict;
use Test::More;
use CPAN::Dependency;


my $mirror_access = CPANPLUS::Configure->new->get_conf("hosts")->[0]{scheme};
plan skip_all => "CPANPLUS not configured to use a local mirror"
    unless $mirror_access eq "file";

my @mods = qw(WWW::Mechanize Maypole Template CPAN::Search::Lite);

plan tests => 5;

my $cpandep = eval { CPAN::Dependency->new(process => [ @mods ]) };
is( $@, ''                                  , "object created (passing a list of modules to process())" );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );
is_deeply( $cpandep->{process}, [@mods]    , "checking process() with two args as arrayref" );
