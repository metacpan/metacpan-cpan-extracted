package Babble::Filter;

use Babble::PluginChain;
use Filter::Util::Call;
use strictures 2;

sub import {
  my ($class, @plugins) = @_;
  my $pc = Babble::PluginChain->new;
  $pc->add_plugin($_) for @plugins;
  filter_add(sub {
    filter_del();
    1 while filter_read();
    $_ = $pc->transform_document($_);
    return 1;
  });
  if ($0 eq '-e') {
    eval 'sub main::babble { $_ = $pc->transform_document($_) }'
  }
}

1;
