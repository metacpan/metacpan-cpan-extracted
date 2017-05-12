use strict;
use warnings;
package Catalyst::Plugin::ActionPaths;
$Catalyst::Plugin::ActionPaths::VERSION = '0.01';
use Encode 'decode_utf8';
use Moose::Role;

#ABSTRACT: get Catalyst actions with example paths included!


sub get_action_paths
{
  my $c = shift;
  die 'get_action_paths() requires a Catalyst context as an argument'
    unless $c && $c->isa('Catalyst');

  my @actions = ();

  for my $dt (@{$c->dispatcher->dispatch_types})
  {
    if (ref $dt eq 'Catalyst::DispatchType::Path')
    {
      # taken from Catalyst::DispatchType::Path
      foreach my $path ( sort keys %{ $dt->_paths } ) {
        foreach my $action ( @{ $dt->_paths->{$path} } ) {
          my $args  = $action->number_of_args;
          my $parts = defined($args) ? '/*' x $args : '/...';

          my $display_path = "/$path/$parts";
          $display_path =~ s{/{1,}}{/}g;
          $display_path =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg; # deconvert urlencoded for pretty view·
          $display_path = decode_utf8 $display_path;  # URI does encoding
          $action->{path} = $display_path;
          push @actions, $action;
        }
      }
    }
    elsif (ref $dt eq 'Catalyst::DispatchType::Chained')
    {
      # taken from Catalyst::DispatchType::Chained
      ENDPOINT: foreach my $endpoint (
                    sort { $a->reverse cmp $b->reverse }
                             @{ $dt->_endpoints }
                    ) {
          my $args = $endpoint->list_extra_info->{Args};
          my @parts = (defined($endpoint->attributes->{Args}[0]) ? (("*") x $args) : '...');
          my @parents = ();
          my $parent = "DUMMY";
          my $extra  = $dt->_list_extra_http_methods($endpoint);
          my $consumes = $dt->_list_extra_consumes($endpoint);
          my $scheme = $dt->_list_extra_scheme($endpoint);
          my $curr = $endpoint;
          my $action = $endpoint;
          while ($curr) {
              if (my $cap = $curr->list_extra_info->{CaptureArgs}) {
                  unshift(@parts, (("*") x $cap));
              }
              if (my $pp = $curr->attributes->{PathPart}) {
                  unshift(@parts, $pp->[0])
                      if (defined $pp->[0] && length $pp->[0]);
              }
              $parent = $curr->attributes->{Chained}->[0];
              $curr = $dt->_actions->{$parent};
              unshift(@parents, $curr) if $curr;
          }
          if ($parent ne '/') {
              next ENDPOINT;
          }
          my @rows;
          foreach my $p (@parents) {
              my $name = "/${p}";

              if (defined(my $extra = $dt->_list_extra_http_methods($p))) {
                  $name = "${extra} ${name}";
              }
              if (defined(my $cap = $p->list_extra_info->{CaptureArgs})) {
                  if($p->has_captures_constraints) {
                    my $tc = join ',', @{$p->captures_constraints};
                    $name .= " ($tc)";
                  } else {
                    $name .= " ($cap)";
                  }
              }
              if (defined(my $ct = $p->list_extra_info->{Consumes})) {
                  $name .= ' :'.$ct;
              }
              if (defined(my $s = $p->list_extra_info->{Scheme})) {
                  $scheme = uc $s;
              }

              unless ($p eq $parents[0]) {
                  $name = "-> ${name}";
              }
              push(@rows, [ '', $name ]);
          }

          if($endpoint->has_args_constraints) {
            my $tc = join ',', @{$endpoint->args_constraints};
            $endpoint .= " ($tc)";
          } else {
            $endpoint .= defined($endpoint->attributes->{Args}[0]) ? " ($args)" : " (...)";
          }
          push(@rows, [ '', (@rows ? "=> " : '').($extra ? "$extra " : ''). ($scheme ? "$scheme: ":'')."/${endpoint}". ($consumes ? " :$consumes":"" ) ]);
          my @display_parts = map { $_ =~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg; decode_utf8 $_ } @parts;
          $rows[0][0] = join('/', '', @display_parts) || '/';
          $action->{path} = $rows[0][0];
          push @actions, $action;
      }
    }
  }
  return \@actions;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::ActionPaths - get Catalyst actions with example paths included!

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This is an early-release plugin for Catalyst. It adds the method C<get_action_paths> to the Catalyst context object.

This plugin makes it easier to retrieve every loaded action path and chained path in your Catalyst application, usually for testing purposes.

To use the plugin, just install it and append the plugin name in your application class e.g. F<lib/MyApp.pm>

  use Catalyst 'ActionPaths';

=head1 METHODS

=head2 get_action_paths

Returns an arrayref of C<Catalyst::Actions> objects, with a path attribute added. The path is an example path for the action, e.g.:

  my $actions = $c->get_action_paths;

  print $actions->[0]{path}; # /some/*/path/*

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Farrell.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
