#!/usr/bin/perl
#
# OO wrapper in Perl for LocalhostListener.jar - PAYBOX.NET
# Copyright (C) 2000 Dirk Tostmann (tostmann@tosti.com)
#
# $rcs = ' $Id: Paybox.pm,v 1.2 2000/12/21 16:59:44 tostmann Exp $ ' ;	
#
################################################

=head1 NAME

Business::PayBox - OO wrapper for Paybox Java Localhost Listener (LHL)

=head1 SYNOPSIS

To create object:

    use Business::PayBox;

    $PB = Business::PayBox->new(MRID => '+490001234567');
    or
    $PB = Business::PayBox->new(MRID => '+490001234567', server => '192.168.1.1', port => 61);

To do a payment:

    $result = $PB->do_test_payment(AMNT => 100, CURR => 'DEM', ORNM=>'TEST123', CPID => '+491773729269');
    or 
    $result = $PB->dopayment(AMNT => 100, CURR => 'DEM', ORNM=>'TEST123', CPID => '+491773729269');


=head1 DESCRIPTION

This is an OO wrapper for the PAYBOX - Integrated Solution. You must install Localhostlistener LHL (which comes as Java-Jar) to use this
module. After you succeed with this you can process payments as described above.

=head1 CONSTRUCTOR

=cut

package Business::PayBox;

use strict;
use vars qw/$DEBUG $VERSION/;
use IO::Socket;
use POSIX qw/strftime/;

$DEBUG   = 1;
$VERSION = '1.0';

=head2 new($key => $value, ...)

Call to initialize object. Valid Parameters are:

 Mandatory:
   MRID   => Merchant ID

 Others:
   server => IP address or name of LHL server. (defaults to localhost)
   port   => Port of LHL server. (defaults to port 60)
 
   CMID   => Customer ID (defaults to 0)
   AUTT   => Transaction Type
   LANG   => Language (defaults to DE)
   PYMD   => Zahlungsziel (defaults to 1)
   LCMT   => Localtime stamp (defaults to localtime)

=cut

sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my %args  = @_;
  my $self  = {};
  foreach (keys %args) {
    $self->{$_} = $args{$_};
  }
  
  bless $self, $class; 

  $self->{DATA}->{1} = {
			MRID => $self->{MRID} || return,
			CMID => $self->{CMID} || 0,
			AUTT => $self->{AUTT} || 'T',
			LANG => $self->{LANG} || 'DE',
			PYMD => $self->{PYMD} || 1,
			LCMT => $self->{LCMT} || strftime "%Y-%m-%d %H:%M:%S.000000000", localtime,
		       };

  return unless $self->connect2listener;

  $self;
}

sub DESTROY {
  my $self = shift;

  $self->{sock}->close if $self->{sock};
}

sub connect2listener {
  my $self   = shift;
  my $server = shift || $self->{server} || '127.0.0.1';
  my $port   = shift || $self->{port} || 60;

  $DEBUG && print STDERR "connecting to $server:$port ...\n";

  my $sock   = IO::Socket::INET->new(
				     PeerAddr => $server,
				     PeerPort => $port,
				     Proto    => 'tcp'
				    );

  return unless $sock;

  $self->{sock} = $sock;

  $sock;
}

=head1 METHODS

=head2 dopayment($key => $value, ...)

Mandatory parameters are:

  AMNT => Amount (18.75 => 1875)
  CURR => Currency (ISO ie: DEM/EUR)
  ORNM => Order number/decr (max 40 char)
  CPID => PayBoxNumber (must match /^\+\d{12}$/)

This function will return undef on errors. In this case you can catch the error by accessing $PB->{ERROR} which will look like:

  $VAR1 = [
            45,
            'Undefinierter Fehler'
          ];

On success the return value will be a hash ref looking like:

  ...

=cut

sub dopayment {
  my $self   = shift;

  $self->{DATA}->{1}->{AUTT} = 'N',

  $self->do_test_payment(@_);
}

=head2 do_test_payment($key => $value, ...)

Acts the same as dopayment-call, only as a test call...

=cut

sub do_test_payment {
  my $self   = shift;

  delete $self->{ERROR};

  my %hash   = @_;

  foreach (qw/AMNT CURR ORNM CPID/) {
    $self->{DATA}->{1}->{$_} = $hash{$_} || return;
  }

  return unless $self->{DATA}->{1}->{CPID} =~ /^\+\d{12}$/;

  #
  # STEP 1
  #

  my $data = $self->build_STEP1;
  my $ans = $self->ask($data) || return;

  #
  # STEP 2
  #

  $self->parse_answer($ans) || return;
  unless ($self->{DATA}->{2}->{STAT} eq 'AS') {
    $self->{ERROR} = [$self->{DATA}->{2}->{ERRC},$self->{DATA}->{2}->{ERRM}];
  }

  #
  # STEP 3
  #

  $data = $self->build_STEP3;
  $self->{sock}->print("$data\n") || return;

  return $self->{ERROR} ? undef : $self->{DATA};
}

sub build_STEP1 {
  my $self   = shift;

  my @VARS = ();
  foreach (qw/MRID CMID CPID AMNT CURR LCMT ORNM AUTT LANG PYMD/) {
    push @VARS, $self->{DATA}->{1}->{$_};
  }

  sprintf ('MRID%s|CMID%04d|CPID%s|AMNT%d|CURR%3s|LCMT%s|ORNM%s|STEP1|AUTT%1s|LANG%2s|PYMD%d', @VARS);
}

sub build_STEP3 {
  my $self   = shift;

  $self->{DATA}->{3}->{TANM} = $self->{DATA}->{2}->{ORNM};

  my @VARS = ();
  foreach (qw/MRID CPID TANP ATCP PYMD ORNM TANM STAT/) {
    $self->{DATA}->{3}->{$_} = $self->{DATA}->{3}->{$_} || $self->{DATA}->{2}->{$_} || $self->{DATA}->{1}->{$_};
    push @VARS, $self->{DATA}->{3}->{$_};
  }

  sprintf ('MRID%s|CPID%s|TANP%s|ATCP%s|STEP3|PYMD%d|ORNM%s|TANM%s|STAT%s', @VARS);
}

sub parse_answer {
  my $self = shift;
  my $ans  = shift || return; 

  my @values = split(/\|/,$ans);
  
  foreach (@values) {
    if (m/^([A-Z]{4})(.+)$/) {
      $self->{DATA}->{2}->{$1} = $2;
    }
  }

  1;
}

sub ask {
  my $self = shift;
  my $data = shift;

  $self->{sock}->print("$data\n");

  $self->{sock}->getline;
}

=head1 EXAMPLE

  #!/usr/bin/perl

  use Business::PayBox;
  use Data::Dumper;

  $PB = Business::PayBox->new(MRID=>'+490001234567') || die "connecting to listener failed";

  $result = $PB->do_test_payment(AMNT=>100,CURR=>DEM,ORNM=>'TEST123',CPID=>'+491773729269');

  print Dumper($result ? $result : $PB->{ERROR});


=head1 SEE ALSO

http://www.paybox.net

=head1 AUTHOR

Dirk Tostmann (tostmann@tosti.com)

=head1 COPYRIGHT

Copyright (c) 2000 Dirk Tostmann. All rights reserved.
This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
