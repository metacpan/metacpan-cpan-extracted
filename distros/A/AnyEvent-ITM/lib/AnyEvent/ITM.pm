package AnyEvent::ITM;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Debug ITM/SWD stream deserializer for AnyEvent
$AnyEvent::ITM::VERSION = '0.002';
use strict;
use warnings;
use bytes;

use AnyEvent::Handle;
use Carp qw( croak );
use ITM;

AnyEvent::Handle::register_read_type(itm => sub {
  my ( $self, $cb ) = @_;
  sub {
    if (defined $_[0]{rbuf}) {
      my $first = substr($_[0]{rbuf},0,1);
      my $len = length($_[0]{rbuf});
      my $f = ord($first);
      my $header = itm_header($first);
      if ($header) {
        my $size = $header->{size} ? $header->{size} : 0;
        my $payload = substr($_[0]{rbuf},1,$size);
        if (defined $payload && length($payload) == $size) {
          my $itm = itm_parse($header,$size ? ($payload) : ());
          $_[0]{rbuf} = substr($_[0]{rbuf},$size + 1);
          $cb->( $_[0], $itm );
          return 1;          
        }
        return 0;
      } else {
        croak sprintf("unknown packet type");
      }
    }
    return 0;
  };
});

1;

__END__

=pod

=head1 NAME

AnyEvent::ITM - Debug ITM/SWD stream deserializer for AnyEvent

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUPPORT

IRC

  Join #hardware on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-anyevent-itm
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-anyevent-itm/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
