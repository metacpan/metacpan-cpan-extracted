package CGI::Wiki::Simple::Plugin::Static;
use CGI::Wiki::Simple::Plugin();

use vars qw($VERSION);
$VERSION = 0.09;

my %static_content;

=head1 NAME

CGI::Wiki::Simple::Plugin::Static - Supply static text as node content

=head1 DESCRIPTION

This node supplies static text for a node. This text can't be changed. You could
use a simple HTML file instead. No provisions are made against users wanting to
edit the page. They can't save the data though.

=head1 SYNOPSIS

=for example begin

  use CGI::Wiki::Simple;
  use CGI::Wiki::Simple::Plugin::Static( Welcome  => "There is an <a href='entrance'>entrance</a>. Speak <a href='Friend'>Friend</a> and <a href='Enter'>Enter</a>.",
                                         Enter    => "The <a href='entrance'>entrance</a> stays closed.",
                                         entrance => "It's a big and strong door.",
                                         Friend   => "You enter the deep dungeons of <a href='Moria'>Moria</a>.",
                                         );
  # nothing else is needed

=for example end

=cut

sub import {
    my ($module,%args) = @_;
    for my $node (keys %args) {
      $static_content{$node} = $args{$node};
      CGI::Wiki::Simple::Plugin::register_nodes(module => $module, name => $node);
    };
};

sub retrieve_node {
  my (%args) = @_;

  return ($static_content{$args{name}},"0","");
};

1;