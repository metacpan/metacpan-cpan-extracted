use strict;
use warnings;
use Test::More tests => 1;
use File::Spec;
use Env::Sanctify;
use CPANPLUS::Configure;

{
  my $sanctify = Env::Sanctify->sanctify( env => { PERL5_CPANPLUS_BASE => File::Spec->rel2abs('.') },
                                          sanctify => [ 'PERL5_YACSMOKE_BASE' ] );
  my $self = CPANPLUS::Configure->new( load_configs => 1 );
  is($self->get_conf('base'),File::Spec->catdir($ENV{PERL5_CPANPLUS_BASE},'.cpanplus'),'PERL5_CPANPLUS_BASE');
}
