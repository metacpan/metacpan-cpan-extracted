package Data::RunningTotal::Item;

use 5.005;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.03';


sub new {
    my $that = shift;
    my $class = ref($that) || $that;
    my ($rt, $numDims, $weight) = @_;

    my %state = (weight  => $weight || 1,
                 numDims => $numDims,
                 rt      => $rt
                );

    return bless(\%state);

}


sub moveTo {
  my ($self, $time, %opts) = @_;

  croak("Expected an array ref for parameter 'coords'") if (ref($opts{coords}) ne "ARRAY");
  if (scalar(@{$opts{coords}}) != $self->{rt}->{numDims}) {
    croak("Expected $self->{numDims} coordinates, but ".scalar(@{$opts{coords}})." given");
  }

  if (defined($self->{lastTime}) &&
      $time < $self->{lastTime}) {
    carp("Item can't be moved to time in the past.  Previous time moved: $self->{lastTime}.  Current movement time: $time");
    return;
  }

  if (defined($self->{lastCoords})) {
    $self->{rt}->dec($time, weight => $self->{weight}, coords => $self->{lastCoords});
  }

  @{$self->{lastCoords}} = @{$opts{coords}};

  $self->{rt}->inc($time, weight => $self->{weight}, coords => $self->{lastCoords});

}

__END__

=head1 AUTHOR

Edward Funnekotter, E<lt>efunneko+cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Edward Funnekotter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 NAME

Data::RunningTotal::Item - Internal module for L<Data::RunningTotal>.


=cut


