package Clustericious::Admin;

use strict;
use warnings;
use App::clad;
use Carp ();

# ABSTRACT: Parallel SSH client
our $VERSION = '1.11'; # VERSION



sub banners
{
  (undef) = @_;
  Carp::carp "Class method call of Clustericious::Admin->banners is deprecated";
  ();
}


sub clusters
{
  my $self = shift;
  
  ref $self
  ? $self->SUPER::new($_)
  : do {
    Carp::carp "Class method call of Clustericious::Admin->clusters is deprecated";
    sort keys %{ App::clad->new('--server')->cluster_list };
  };
}


sub aliases
{
  (undef) = @_;
  Carp::carp "Class method call of Clustericious::Admin->aliases is deprecated";
  sort keys %{ App::clad->new('--server')->alias };
}


sub run
{
  my $self = shift;
  
  ref $self
  ? $self->SUPER::new(@_)
  : do {
    Carp::carp "Class method call of Clustericious::Admin->run is deprecated";
    my($opts, $cluster, @cmd) = @_;
    App::clad->new(
      ($opts->{n} ? ('-n') : ()),
      ($opts->{l} ? ('-l' => $opts->{l}) : ()),
      ($opts->{a} ? ('-a') : ()),
      $cluster, @cmd,
    )->run;
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Admin - Parallel SSH client

=head1 VERSION

version 1.11

=head1 SYNOPSIS

 % perldoc clad

=head1 DESCRIPTION

This module used to contain the machinery to implement the L<clad> command.
This was moved into L<App::clad> when it was rewritten.  This module is
provided for compatibility.  In the future it may provide a Perl level API
for L<clad>.  It currently provides a deprecated interface which will be
removed from a future version, but not before B<January 31, 2015>.

=head1 FUNCTIONS

=head2 banners

B<DEPRECATED>

 my @banners = Clustericious::Admin->banners;

Returns the banners from the configuration file as a list.

=head2 clusters

B<DEPRECATED>

 my @clusters = Clustericious::Admin->clusters;

Returns the list of clusters from the configuration file.

=head2 aliases

B<DEPRECATED>

 my @aliases = Clustericious::Admin->aliases;

Returns the alias names from the configuration file as a list.

=head2 run

B<DEPRECATED>

 Clustericious::Admin->new(\%options, $cluster, $command);

Run the given command on all the hosts in the given cluster.  Returns 0.  Options
is a hash reference which may include any of the following keys.

=over 4

=item n

 { n => 1 }

Dry run

=item l

 { l => $user }

Set the username that you want to connect with.

=item a

 { a => 1 }

Turn off color.

=back

=head1 CAVEATS

L<Clustericious::Admin> and L<clad> require an L<AnyEvent> event loop that allows
entering the event loop by calling C<recv> on a condition variable.  This is not
supported by all L<AnyEvent> event loops and is discouraged by the L<AnyEvent>
documentation for CPAN modules, though most of the important event loops, such as
L<EV> and the pure perl implementation that comes with L<AnyEvent> DO support
this behavior.

=head1 SEE ALSO

=over 4

=item L<clad>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
