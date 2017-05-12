use strict;
use Benchmark::Harness;
package Benchmark::Harness::ValuesHighRes;
use base qw(Benchmark::Harness::Values);
use Benchmark::Harness::Constants;
use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

package Benchmark::Harness::Handler::ValuesHighRes;
use base qw(Benchmark::Harness::Handler::Values);
use Benchmark::Harness::Constants;
use Time::HiRes;
=pod

=head1 Benchmark::Harness::ValuesHighRes

=head2 SYNOPSIS

High resolution timing combined with Benchmark::Harness::Values.

=head2 Impact


This produces a slightly larger XML report than the Values harness, since HighRes times consume more digits than low-res ones.
This report will be about 20% larger than that of Trace.

=over 8

=item1 MSWin32

Approximately 0.8 millisecond per trace (mostly from *::Trace.pm).

=item1 Linux

=back

=cut

### ###########################################################################
sub reportTraceInfo {
  my $self = shift;

#  return Benchmark::Harness::Handler::Values::reportTraceInfo($self,
  return Benchmark::Harness::Handler::reportTraceInfo($self,
              {
                't' => ( Time::HiRes::time() - $self->[HNDLR_HARNESS]->{_startTime} )
              }
              ,@_
          );
}

### ###########################################################################
#sub reportValueInfo {
#  my $self = shift;
#  return Benchmark::Harness::Handler::Values::reportValueInfo($self,
#              ,@_
#          );
#}

### ###########################################################################
# USAGE: Benchmark::HarnessVlauesHighRes::OnSubEntry('class::method', 
sub OnSubEntry {
  my $self = shift;

  my $i=1;
  for ( @_ ) {
    $self->NamedObjects($i, $_);
    last if ( $i++ == 20 );
  }
  if ( scalar(@_) > 20 ) {
    ##$self->print("<G n='".scalar(@_)."'/>");
  };
  $self->reportTraceInfo();#(shift, caller(1));
  return @_; # return the input arguments unchanged.
}

### ###########################################################################
# USAGE: Benchmark::Trace::MethodReturn('class::method', [, 'class::method' ] )
sub OnSubExit {
  my $self = shift;

  if (wantarray) {
    my $i=1;
    for ( @_ ) {
      $self->NamedObjects($i, $_) if defined $_;
      last if ( $i++ == 20 );
    }
    if ( scalar(@_) > 20 ) {
      ##$self->print("<G n='".scalar(@_)."'/>");
    };
  } else {
    scalar $self->NamedObjects('0', $_[0]) if defined $_[0];
  }
  $self->reportTraceInfo();#(shift, caller(1));
  return @_;
}


### ###########################################################################

=head1 AUTHOR

Glenn Wood, <glennwood@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2004 Glenn Wood. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;