
package AnyEvent::HTTP::LWP::UserAgent::Determined;

use strict;
use warnings;

# ABSTRACT: a virtual browser that retries errors with AnyEvent
our $VERSION = 'v0.05.1.06'; # VERSION
use      AnyEvent::HTTP::LWP::UserAgent 0.08 ();
use      LWP::UserAgent::Determined ();
our (@ISA) = ('AnyEvent::HTTP::LWP::UserAgent', 'LWP::UserAgent::Determined');


#==========================================================================
# extracted from LWP::UserAgent::Determined with little modification

sub simple_request_async {
  my($self, @args) = @_;
  my(@timing_tries) = ( $self->timing() =~ m<(\d+(?:\.\d+)*)>g );
  my $determination = $self->codes_to_determinate();

  my $cv = AE::cv;
  my $before_c = $self->before_determined_callback;
  my $after_c  = $self->after_determined_callback;
  push @timing_tries, undef;

  my $loop;
  $loop = sub {
    my $pause_if_unsuccessful = shift @timing_tries;

    $before_c and $before_c->(
      $self, \@timing_tries, $pause_if_unsuccessful, $determination, \@args);
    $self->SUPER::simple_request_async(@args)->cb(sub {
      my $resp = shift->recv;
      $after_c and $after_c->(
        $self, \@timing_tries, $pause_if_unsuccessful, $determination, \@args, $resp);

      my $code = $resp->code;
      unless( $determination->{$code} ) { # normal case: all is well (or 404, etc)
        $cv->send($resp); return;
      }
      if(defined $pause_if_unsuccessful) { # it's undef only on the last

        sleep $pause_if_unsuccessful if $pause_if_unsuccessful;
        $loop->();
      } else {
        $cv->send($resp);
      }
    });
  };
  $loop->(); # First invoke

  return $cv;
}

#--------------------------------------------------------------------------
# extracted from LWP::UserAgent::Determined

sub new {
  my $self = shift->SUPER::new(@_);
  $self->_determined_init();
  return $self;
}

#==========================================================================

1;

__END__

=pod

=head1 NAME

AnyEvent::HTTP::LWP::UserAgent::Determined - a virtual browser that retries errors with AnyEvent

=head1 VERSION

version v0.05.1.06

=head1 SYNOPSIS

  use strict;
  use AnyEvent::HTTP::LWP::UserAgent::Determined;
  my $browser = LWP::UserAgent::Determined->new;
  my $response = $browser->get($url, headers... );
  $browser->get_async($url, headers... )->cb(sub {
    my $response = shift->recv;
  });

=head1 DESCRIPTION

L<LWP::UserAgent::Determined> works just like L<LWP::UserAgent> (and is based on it, by
being a subclass of it), except that when you use it to get a web page
but run into a possibly-temporary error (like a DNS lookup timeout),
it'll wait a few seconds and retry a few times.

It also adds some methods for controlling exactly what errors are
considered retry-worthy and how many times to wait and for how many
seconds, but normally you needn't bother about these, as the default
settings are relatively sane.

This class not only works like L<LWP::UserAgent::Determined> but also L<AnyEvent::HTTP::LWP::UserAgent>
 (and is based on them, by being a subclass of them),

=head1 METHODS

This module inherits all of L<LWP::UserAgent::Determined>'s methods and 
L<AnyEvent::HTTP::LWP::UserAgent>'s methods.

=head1 IMPLEMENTATION

This class works by overriding L<AnyEvent::HTTP::LWP::UserAgent>'s C<simple_request> method
with its own around-method that just loops.  See the source of this
module; it's straightforward with caution of asynchronous nature.

=head1 SEE ALSO

L<LWP>, L<LWP::UserAgent>, L<LWP::UserAgent::Determined>, L<AnyEvent::HTTP>, L<AnyEvent::HTTP::LWP::UserAgent>

=head1 COPYRIGHT AND DISCLAIMER

Original copyright for LWP::UserAgent::Determined:

Copyright 2004, Sean M. Burke, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Yasutaka ATARASHI C<yakex@cpan.org>

Original authors of LWP::UserAgent::Determined are as follows:

Originally created by Sean M. Burke, C<sburke@cpan.org>

Currently maintained by Jesse Vincent C<jesse@fsck.com>

=cut
