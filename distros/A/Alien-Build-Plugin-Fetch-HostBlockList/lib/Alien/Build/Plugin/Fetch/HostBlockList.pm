package Alien::Build::Plugin::Fetch::HostBlockList;

use strict;
use warnings;
use 5.008004;
use Alien::Build::Plugin;
use URI;

# ABSTRACT: Reject any Alien::Build fetch requests going to hosts in the block list
our $VERSION = '0.01'; # VERSION


has '+block_hosts' => sub { [
  defined $ENV{ALIEN_BUILD_HOST_BLOCK}
  ? split /,/, $ENV{ALIEN_BUILD_HOST_BLOCK}
  : ()
] };

sub init
{
  my($self, $meta) = @_;

  my %blocked = map { $_ => 1 } @{ $self->block_hosts };

  $meta->around_hook( fetch => sub {

    my $orig = shift;
    my $build = shift;
    my $url = $_[0] || $build->meta_prop->{start_url};

    if($url =~ /:/)
    {
      my $url = URI->new($url);
      if($url->scheme ne 'file')
      {
        my $host = eval { $url->host };
        die "unable to determine host from $url: $@" if $@;
        die "The host $host is in the block list" if $blocked{$host};
      }
    }

    $orig->($build, @_);
  });
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Fetch::HostBlockList - Reject any Alien::Build fetch requests going to hosts in the block list

=head1 VERSION

version 0.01

=head1 SYNOPSIS

Using with environment variables only:

 export ALIEN_BUILD_PRELOAD=Fetch::HostBlockList
 export ALIEN_BUILD_HOST_BLOCK=badsite1.com,badsite2.org

Using from C<~/.alienbuild/rc.pl>:

 preload sub {
   my($meta) = @_;
   $meta->apply_plugin('Fetch::HostBlockList', block_hosts => [qw( badsite1.com badsite2.org )])
 };

=head1 DESCRIPTION

This is an L<Alien::Build> plugin that will, when enabled, reject any fetch requests
made by an L<Alien::Build> based L<Alien> that are fetching from a remote host that
is on the block list.

L<Alien>s that bundle packages are not affected, as this plugin does not check
C<file> URLs.

If now block list is specified (either via the property or environment variable,
see below), then not hosts will be blocked.

=head1 PROPERTIES

=head2 block_hosts

 plugin 'Fetch::HostBlockList', block_list => \@hosts;

The list of domains that will be blocked.  Should be provided as an array reference.
If not provided, then C<ALIEN_BUILD_HOST_BLOCK> will be used (see below).

=head1 ENVIRONMENT

=over 4

=item C<ALIEN_BUILD_HOST_BLOCK>

Comma separated list of hosts to block.  If not specified when the
plugin is applied then this list will be used.

=back

=head1 SEE ALSO

=over 4

=item L<Alien::Build::Plugin::Fetch::HostBlockList>

=item L<Alien::Build>

=item L<alienfile>

=item L<Alien::Build::rc>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
