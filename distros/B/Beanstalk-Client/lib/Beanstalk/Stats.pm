package Beanstalk::Stats;

use strict;
use warnings;

use Carp ();

our $AUTOLOAD;
our $VERSION = "1.07";

sub new {
  my $proto = shift;
  my $href = shift;
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

Beanstalk::Stats - Class to represent stats results from the beanstalk server

=head1 SYNOPSIS

  my $client = Beanstalk::Client->new;

  my $stats = $client->stats;

  print $stats->uptime,"\n"

=head1 DESCRIPTION

Simple class to allow method access to hash of stats returned by
C<stats>, C<stats_job> and C<stats_tube> commands

See L<Beanstalk::Client> for the methods available based on the command used

=head1 SEE ALSO

L<Beanstalk::Client>

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (C) 2008 by Graham Barr.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
