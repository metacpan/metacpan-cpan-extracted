#!/usr/bin/perl -w

package Data::Fallback::Client;

use strict;
use Carp qw(confess);
use IO::Socket;
use Time::HiRes qw(gettimeofday);

use Data::Fallback;
use vars qw(@ISA);
@ISA = qw(Data::Fallback);

sub new {
  my $type  = shift;
  my $class = ref($type) || $type || __PACKAGE__;
  my @PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  my @DEFAULT_ARGS = (
    reverse_lookup => '',
    host           => 'localhost',
    port           => '20203',
  );
  my %ARGS = (@DEFAULT_ARGS, @PASSED_ARGS);
  return $class->SUPER::new(\%ARGS);
}

sub get {
  my $self = shift;
  $self->{get_this} = shift;
  die "need a \$self->{get_this} on the get" unless($self->{get_this});
  my $start = gettimeofday;
  $self->get_socket;
  print "<elapsed>" . (gettimeofday - $start) . "</elapsed>\n";
  $self->make_block;
  $self->post_block;
  $self->get_response;
  return $self->parse_response;
}

sub get_socket {
  my $self = shift;
  unless($self->{socket}) {
    $self->{socket} = new IO::Socket::INET (
      Proto    => "tcp",
      PeerAddr => $self->{host},
      PeerPort => $self->{port},
    );
  }
}

sub make_block {
  my $self = shift;
  $self->{block} = "GET $self->{get_this}\n";
  $self->append_cookies;
  $self->{block} .= "\n";
}

sub append_cookies {
  my $self = shift;
  return unless($self->{cookies} && scalar keys %{$self->{cookies}});
  foreach(keys %{$self->{cookies}}) {
    $self->{block} .= "Cookie: $_=$self->{cookies}{$_}\n";
  }
}

sub post_block {
  my $self = shift;
  $self->{block} =~ s/([^\r\n]?)\n/$1\r\n/g;
  my $socket = $self->{socket};
  print $socket $self->{block};
}

sub get_response {
  my $self = shift;
  $self->{response} = {};
  $self->{response}{body} = "";

  my $socket = $self->{socket};
  $self->{response}{header} = "";
  for(1 .. 3) {
    $self->{response}{header} .= <$socket>;
  }

  while(<$socket>) {
    s/\r//;
    $self->{response}{body} .= $_;
  }
}

sub parse_response {
  my $self = shift;
  my ($type) = $self->{response}{body} =~ m@^<type>(\w+)</type>@;
  my $return;
  if($type eq 'scalar') {
    ($return) = $self->{response}{body} =~ m@<scalar>(.+?)</scalar>@s;
  } elsif($type eq 'array') {
    $return = [];
    while($self->{response}{body} =~ m@<array>(.+?)</array>@sg) {
      push @{$return}, $1;
    }
  }
  return $return;
}

=head1 NAME

Data::Fallback::Client - a client for Data::Fallback

=head1 DESCRIPTION

Data::Fallback::Client is a simple client to interact with an active Data::Fallback::Daemon.

=head1 EXAMPLE

#!/usr/bin/perl -w

use strict;
use Data::Fallback::Client;

my $self = Data::Fallback::Client->new({

  # point to the Data::Fallback::Daemon that is running
  host           => 'localhost',
  port           => '20203',

});

my $value = $self->get("/list_name/primary_key/column");

=head1 A SIMPLE WARNING

I plan on eventually supporting XML, but I am not sure when.  My protocol is not written in stone, so please be agile when updating
to new versions.

=head1 THANKS

Thanks to Paul Seamons for Net::Server and for helping me set up this simple client.

=head1 AUTHOR

Copyright 2001-2002, Earl J. Cahill.  All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Address bug reports and comments to: cpan@spack.net.

When sending bug reports, please provide the version of Data::Fallback, the version of Perl, and the name and version of the operating
system you are using.

=cut

1;
