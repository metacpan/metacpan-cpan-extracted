package Collectd::Plugins::Common;

use 5.006;
use strict;
use warnings;

use vars qw/@ISA @EXPORT_OK/;
use Exporter;
push @ISA, qw/Exporter/;

@EXPORT_OK = qw/recurse_config/;

=head1 NAME

Collectd::Plugins::Common - Common functions to be used by plugins

=cut

our $VERSION = '0.1001';

=head1 SYNOPSIS

 package Collectd::Plugins::Mine;
 use Collectd qw/:all/;
 use Collectd::Plugins::Common qw/recurse_config/;

=head1 FUNCTIONS

None are exported by default.

=head2 recurse_config

Args: $config

Traverses config hash as returned by the L<collectd-perl> plugin recursively.
This will return a nested data structure, similarly to L<Config::General>.

=cut

sub recurse_config {
  my $config = shift;
  my $key = $config -> {key};
  my %inter;
  my @children = @{$config -> {children}};
  if (@children) {
    for my $child (@children) {
      my @next = recurse_config ($child);
      $key =~ s/__/./; # collectd liboconfig won't allow dots in key names
      if (defined $inter{$key}->{$next[0]} && ref $inter{$key}->{$next[0]}) {
        $inter{$key}->{$next[0]} = [$inter{$key}->{$next[0]},$next[1]];
      } else {
        $inter{$key}->{$next[0]} = $next[1];
      }
    }
    return %inter;
  } else {
    my $key = $config -> {key};
    $key =~ s/__/./; # collectd liboconfig won't allow dots in key names
    if (@{$config -> {values}} > 1) {
      return ($key, $config -> {values});
    } else {
      return ($key, $config -> {values} -> [0]);
    }
  }
}

=head1 AUTHOR

Fabien Wernli, C<< <wernli at in2p3.fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-collectd-plugins-ge at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Collectd-Plugins-Common>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Collectd::Plugins::Common


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Collectd-Plugins-Common>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Collectd-Plugins-Common>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Collectd-Plugins-Common>

=item * Search CPAN

L<http://search.cpan.org/dist/Collectd-Plugins-Common/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Fabien Wernli.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Collectd::Plugins::Common
