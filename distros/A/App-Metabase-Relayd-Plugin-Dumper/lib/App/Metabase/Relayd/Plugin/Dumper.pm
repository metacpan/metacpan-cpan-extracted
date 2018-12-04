package App::Metabase::Relayd::Plugin::Dumper;
$App::Metabase::Relayd::Plugin::Dumper::VERSION = '0.04';
# ABSTRACT: Dumper plugin for metabase-relayd

use strict;
use warnings;
use POE;

sub init {
  my $package = shift;
  my $config  = shift;
  return unless $config and ref $config eq 'Config::Tiny';
  return unless $config->{Dumper};
  return unless $config->{Dumper}->{enable};
  my $heap = $config->{Dumper};
  POE::Session->create(
     package_states => [
        __PACKAGE__, [qw(_start mbrd_received)],
     ],
     heap => $heap,
  );
}

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $kernel->refcount_increment( $_[SESSION]->ID(), __PACKAGE__ );
  return;
}

sub mbrd_received {
  my ($kernel,$heap,$data,$ip) = @_[KERNEL,HEAP,ARG0,ARG1];
  use Time::Piece;
  my $stamp = '[ ';
  {
    my $t = localtime;
    $stamp .= join ' ', $ip, $t->strftime("%Y-%m-%dT%H:%M:%S");
  }
  $stamp .= ' ]';
  my $t = localtime; my $ts = $t->strftime("%Y-%m-%dT%H%M%S");
  my $msg = join(' ', uc($data->{grade}), ( map { $data->{$_} } qw(distfile archname osversion) ), "perl-" . $data->{perl_version}, $stamp );
  open my $file, '>', $ts or die "$!\n";
  print {$file} "$msg\n$data->{textreport}\n";
  close $file;
  return;
}


qq[Smokey Dumps];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Metabase::Relayd::Plugin::Dumper - Dumper plugin for metabase-relayd

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  # example metabase-relayd configuration file

  [Dumper]

  enable = 1

=head1 DESCRIPTION

App::Metabase::Relayd::Plugin::Dumper is a plugin for L<App::Metabase::Relayd> and
L<metabase-relayd> that dumps the reports are received by the daemon to file.

Configuration is handled by a section in the L<metabase-relayd> configuration file.

=for Pod::Coverage   init
  mbrd_received

=head1 CONFIGURATION

This plugin uses an C<[Dumper]> section within the L<metabase-relayd> configuration file.

The only mandatory required parameter is C<enable>. Set this to a C<true> value to enable
the plugin.

=head1 SEE ALSO

L<metabase-relayd>

L<App::Metabase::Relayd::Plugin>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
