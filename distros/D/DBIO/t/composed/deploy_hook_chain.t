# ABSTRACT: a storage layer does not define dbio_deploy_class; the driver storage owns it (ADR 0066 section 4)
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Storage::Composed;

{
  package T::DHC::Base;
  sub new { bless {}, shift }
  sub dbio_deploy_class { 'T::DHC::DriverDeploy' }
}

{ package T::DHC::LayerOk;    use mro 'c3'; sub other { 1 } }
{ package T::DHC::LayerA;     use mro 'c3'; sub dbio_deploy_class { 'T::DHC::DeployA' } }
{ package T::DHC::LayerB;     use mro 'c3'; sub dbio_deploy_class { 'T::DHC::DeployB' } }
{ package T::DHC::LayerChain; use mro 'c3'; sub dbio_deploy_class { my $s = shift; $s->next::method(@_) } }
{ package T::DHC::LayerUndef; use mro 'c3'; sub dbio_deploy_class { undef } }

sub composed { DBIO::Storage::Composed->compose('T::DHC::Base', [@_]) }

# the driver storage's own answer reaches the composed storage
is composed('T::DHC::LayerOk')->new->dbio_deploy_class, 'T::DHC::DriverDeploy',
  'a layer without the hook leaves the driver storage the owner';

# a layer that defines it is refused, loudly, naming layer and rule
for my $layer (qw(T::DHC::LayerA T::DHC::LayerChain T::DHC::LayerUndef)) {
  throws_ok { composed($layer) } 'DBIO::Exception', "$layer: composing is refused";
  like $@, qr/\Q$layer\E/, "$layer: the message names the layer";
  like $@, qr/must not define dbio_deploy_class/, "$layer: the message states the rule";
  like $@, qr/ADR 0066/, "$layer: the message points to ADR 0066";
}

# two layers that both define it: the rule is reported, not a generic collision
throws_ok { composed('T::DHC::LayerA', 'T::DHC::LayerB') } 'DBIO::Exception',
  'two layers defining it are refused';
like $@, qr/T::DHC::LayerA.*T::DHC::LayerB/s, 'both layers are named';
like $@, qr/must not define dbio_deploy_class/, 'by the rule';
unlike $@, qr/method collision/, 'not as a generic method collision';

# no layer is chained: nothing is installed into a composed package
{
  my $ok = composed('T::DHC::LayerOk');
  no strict 'refs';
  ok !defined *{"${ok}::dbio_deploy_class"}{CODE}, 'no method is synthesised into the composed package';
}

# other doubles still collide as before
{
  { package T::DHC::ClashX; sub boom { 1 } }
  { package T::DHC::ClashY; sub boom { 2 } }
  throws_ok { composed('T::DHC::ClashX', 'T::DHC::ClashY') } qr/method collision: boom\b/,
    'other collisions still throw';
}

done_testing;
