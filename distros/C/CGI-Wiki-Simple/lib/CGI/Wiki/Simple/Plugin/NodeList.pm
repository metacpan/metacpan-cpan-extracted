package CGI::Wiki::Simple::Plugin::NodeList;
use CGI::Wiki::Simple::Plugin();
use HTML::Entities;

use vars qw($VERSION);
$VERSION = 0.09;

=head1 NAME

CGI::Wiki::Simple::Plugin::NodeList - Node that lists all existing nodes on a wiki

=head1 DESCRIPTION

This node lists all nodes in your wiki. Think of it as the master index to your wiki.

=head1 SYNOPSIS

=for example begin

  use CGI::Wiki::Simple;
  use CGI::Wiki::Simple::Plugin::NodeList( name => 'AllNodes' );
  # nothing else is needed

  use CGI::Wiki::Simple::Plugin::NodeList( name => 'AllCategories', re => qr/^Category:(.*)$/ );

=for example end

=cut

use vars qw(%re);

sub import {
    my ($module,%args) = @_;
    my $node = $args{name};
    $re{$node} = $args{re} || '^(.*)$';
    CGI::Wiki::Simple::Plugin::register_nodes(module => $module, name => $node);
};

sub retrieve_node {
  my (%args) = @_;

  my $node = $args{name};
  my $re = $re{$node};
  my %nodes = map { /$re/ ? ($_ => $1) : () } ($args{wiki}->list_all_nodes, keys %CGI::Wiki::Simple::magic_node);

  return (
       "<ul>" .
       join ("\n", map { "<li>" . $args{wiki}->inside_link( node => $_, title => $nodes{$_} ) . "</li>" }
                   sort { uc($nodes{$a}) cmp uc($nodes{$b}) }
                   keys %nodes)
     . "</ul>",0,"");
};

1;
