package CGI::Wiki::Simple::Plugin::RecentChanges;
use CGI::Wiki::Simple::Plugin();
use HTML::Entities;

use vars qw($VERSION);
$VERSION = 0.11;

=head1 NAME

CGI::Wiki::Simple::Plugin::RecentChanges - Node that lists the recent changes

=head1 DESCRIPTION

This node lists the nodes that were changed in your wiki. This only works for nodes that
are stored within a CGI::Wiki::Store::Database, at least until I implement more of
the store properties for the plugins as well.

=head1 SYNOPSIS

=for example begin

  use CGI::Wiki::Simple;
  use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'LastWeekChanges', days => 7 );
  # also
  use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'Recent20Changes', last_n_changes => 20 );
  # also
  use CGI::Wiki::Simple::Plugin::RecentChanges( name => 'RecentFileChanges', days => 14, re => qr/^File:(.*)$/ );
  # This will display all changed nodes that match ^File:

=for example end

=cut

use vars qw(%args);

sub import {
    my ($module,%node_args) = @_;
    my $node = delete $node_args{name};
    $args{$node} = { %node_args };
    $args{$node}->{re} ||= '^(.*)$';
    CGI::Wiki::Simple::Plugin::register_nodes(module => $module, name => $node);
};

sub retrieve_node {
  my (%node_args) = @_;

  my $node = $node_args{name};
  my %params = %{$args{$node}};

  my $re = delete $params{re} || '^(.*)$';
  my %nodes = map {
                    $_->{name} =~ /$re/ ?
                      ($_->{name} => [ $1, $_->{last_modified} ])
                    : ()
                  } $node_args{wiki}->list_recent_changes( %params );

  return (
       "<table class='RecentChanges'>" .
       join ("\n", map { "<tr><td>" .
                         $node_args{wiki}->inside_link( node => $_, title => $nodes{$_}->[0] ) .
                         "</td><td>".$nodes{$_}->[1]."</td></tr>" }
                   sort { $nodes{$b}->[1] cmp $nodes{$a}->[1] }
                   keys %nodes)
     . "</table>",0,"");
};

1;