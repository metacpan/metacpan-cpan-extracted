package # hide from PAUSE
	CafeInsertion;

use strict;
use warnings;
use parent 'DBIx::Class::Schema';
use aliased 'DBIx::Class::ResultSource::MultipleTableInheritance' => 'MTIView';

for my $p (__PACKAGE__) {
  $p->load_namespaces;
  $_->attach_additional_sources
    for grep $_->isa(MTIView), map $p->source($_), $p->sources;
}

sub sqlt_deploy_hook {
  my $self = shift;
  $self->{sqlt} = shift;
}

1;
