% my $class = shift;
package <%= $class %>;

=head1 NAME

<%= $class %> - Application Class

=head1 SYNOPSIS

<%= $class %>

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use base 'Clustericious::App';
use <%= $class %>::Routes;

our $VERSION = '0.01';

sub startup
{
  my($self) = @_;
  $self->SUPER::startup(@_);
  
  # called when the web application starts
}

sub sanity_check
{
  my($self) = @_;
  
  return 0 unless $self->SUPER::sanity_check;
  
  # test $self->config for missing or badly formed
  # configuration items, and return 1 if it is okay
  # and 0 if it is bad.  print diagnostics to
  # make it clear what is wrong.
  
  return 1;
}

sub generate_config
{
  my($self) = @_;
  
  # TODO
}

1;
