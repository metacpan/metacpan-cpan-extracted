package Bot::Cobalt::Plugin::Silly::OutputLOLCAT;
$Bot::Cobalt::Plugin::Silly::OutputLOLCAT::VERSION = '0.031002';
use strictures 2;

use POE::Filter::Stackable;
use POE::Filter::Line;
use POE::Filter::LOLCAT;

use Bot::Cobalt::Common;

sub FILTER () { 0 }

sub new { bless [undef], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;
  
  $core->plugin_register( $self, 'USER',
    'message'
  );
  
  $core->log->info("Loaded");
  
  PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;
  
  $core->log->info("Unloaded");
  
  PLUGIN_EAT_NONE
}

sub Outgoing_message {
  my ($self, $core) = splice @_, 0, 2;

  my $filter = $self->[FILTER] //= POE::Filter::Stackable->new(
    Filters => [
      POE::Filter::Line->new(),
      POE::Filter::LOLCAT->new(),
    ],
  );

  $filter->get_one_start([${$_[2]}."\n"]);

  my $lol = $filter->get_one;

  my $cat = shift @$lol;
  chomp($cat);

  ${$_[2]} = $cat;

  PLUGIN_EAT_NONE
}

1;
__END__
=pod

=head1 NAME

Bot::Cobalt::Plugin::Silly::OutputLOLCAT - LOLCAT output filter

=head1 SYNOPSIS

  !plugin load OutputLOLCAT Bot::Cobalt::Plugin::Silly::OutputLOLCAT

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

Turns all of your bot's message output into lolcats.

A simple bridge to L<POE::Filter::LOLCAT> (which in turn uses 
L<Acme::LOLCAT>).

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
