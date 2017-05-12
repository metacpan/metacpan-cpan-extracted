package AnyEvent::Beanstalk::Stats;
$AnyEvent::Beanstalk::Stats::VERSION = '1.170590';
use strict;
use warnings;

use Carp ();

our $AUTOLOAD;

sub new {
  my $proto = shift;
  my $href  = shift;
  bless $href, $proto;
}

sub DESTROY { }

sub AUTOLOAD {
  (my $method = $AUTOLOAD) =~ s/.*:://;
  (my $field  = $method)   =~ tr/_/-/;

  unless (ref($_[0]) and exists $_[0]->{$field}) {
    my $proto = ref($_[0]) || $_[0];
    Carp::croak(qq{Can't locate object method "$method" via package "$proto"});
  }
  no strict 'refs';
  *{$AUTOLOAD} = sub {
    my $self = shift;
    unless (ref($self) and exists $self->{$field}) {
      my $proto = ref($self) || $self;
      Carp::croak(qq{Can't locate object method "$method" via package "$proto"});
    }
    $self->{$field};
  };

  goto &$AUTOLOAD;
}

1;

__END__

=head1 NAME

AnyEvent::Beanstalk::Stats - Class to represent stats results from the beanstalk server

=head1 VERSION

version 1.170590

=head1 SYNOPSIS

  my $client = AnyEvent::Beanstalk->new;

  my $stats = $client->stats->recv;

  print $stats->uptime,"\n"

=head1 DESCRIPTION

Simple class to allow method access to hash of stats returned by
C<stats>, C<stats_job> and C<stats_tube> commands

See L<AnyEvent::Beanstalk> for the methods available based on the command used

=head1 SEE ALSO

L<AnyEvent::Beanstalk>

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2010 by Graham Barr.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
