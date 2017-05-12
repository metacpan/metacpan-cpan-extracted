# vim: ts=2 sw=2 expandtab
package Data::Transform::Identity;
use strict;

use Data::Transform;

use vars qw($VERSION @ISA);
$VERSION = '0.01';
@ISA = qw(Data::Transform);


sub new {
  my $type = shift;

  my $self = bless [ [] ], $type;

  return $self;
}

sub clone {
  my $self = shift;

  my $clone = bless [ [] ], ref $self;

  return $clone;
}

sub _handle_get_data {
  my ($self, $data) = @_;

  return $data;
}

sub _handle_put_data {
  my ($self, $chunk) = @_;

  return $chunk;
}


1;

__END__

=head1 NAME

Data::Transform::Identity - a no-op filter that passes data through unchanged

=head1 SYNOPSIS

  #!perl

  use Term::ReadKey;
  use POE qw(Wheel::ReadWrite Filter::Stream);

  POE::Session->create(
    inline_states => {
      _start => sub {
        ReadMode "ultra-raw";
        $_[HEAP]{io} = POE::Wheel::ReadWrite->new(
          InputHandle => \*STDIN,
          OutputHandle => \*STDOUT,
          InputEvent => "got_some_data",
          Filter => POE::Filter::Stream->new(),
        );
      },
      got_some_data => sub {
        $_[HEAP]{io}->put("<$_[ARG0]>");
        delete $_[HEAP]{io} if $_[ARG0] eq "\cC";
      },
      _stop => sub {
        ReadMode "restore";
        print "\n";
      },
    }
  );

  POE::Kernel->run();
  exit;

=head1 DESCRIPTION

Data::Transform::Identity passes data through unchanged. It
follows Data::Transform's API and implements no new functionality.

In the L</SYNOPSIS>, POE::Filter::Stream is used to collect keystrokes
without any interpretation and display output without any
embellishments.

=head1 SEE ALSO

L<Data::Transform>

=head1 AUTHORS & COPYRIGHTS

See L<Data::Transform>

=cut

