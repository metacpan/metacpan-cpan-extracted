#!/usr/bin/perl
#

use strict;
use warnings;

use lib qw#../lib#;
use Switch;

use Business::PayPal::SDK;

our %ARG_OPS = (
  '-h'    => "Print help message and exit",
  '-help'       => "Print help message and exit",
  '--amount' => "Amount or OrderTotal",
  '--cmd' => "command",
  '--transid' => "TransactionID",
  '--memo' => "Memo",
  '--refundtype' => "RefundType",
  '--payerid' => "PayerID",
  '--returnurl' => "ReturnURL",
  '--cancelurl' => "CancelURL",
  '--token' => "token",
);

###
# Functions
##
#
#

sub nl {
  return "\n" unless ($ENV{HTTP_USER_AGENT});
  return "<br>";
}

sub help_poor_soul {
  my $help = shift;
  $help ||= '';
  $help .= nl;
  for my $key (keys(%ARG_OPS)) {
    $help = $help . "$key $ARG_OPS{$key}" . nl;
  }
  print << "EOH";

$help
EOH
  exit 1;
}

sub get_args {
  my %return;
  while (my $arg = shift @ARGV) {
    my @arg_ops;
    for my $k (keys(%ARG_OPS)) {
      push @arg_ops, "^$k\$";
    }
    my $key_ops = join ("|",@arg_ops);
    unless ($arg =~ m/($key_ops)/ ) {
      help_poor_soul("Bad arg '$arg'");
    }
    for my $key (keys(%ARG_OPS)) {
      if ($key eq $arg) {
        if ($arg =~ m/^-[a-zA-Z]+/) {
          $key =~ s/^-//;
          $return{$key} = 1;
        } elsif ($arg =~ m/^-{2}\w+/) {
          $key =~ s/^-{2}//;
          $return{$key} = shift @ARGV;
        } else {
          help_poor_soul();
        }
      }
    }
  }
  return \%return;
}

sub get_cmd_args {
  my $args = shift;

  my $cmd = $args->{cmd};
  die 'You must pass a command.' unless $cmd;

  my $req = {};
  switch ($cmd) {
    case "DoDirectPayment" {
      $req = {
        FirstName => 'Big',
        LastName => 'Spender',
        MiddleName => 'Cash',
        Street1 => '2211 N. First St.',
        CityName => 'San Jose',
        StateOrProvince => 'CA',
        PostalCode => '95131',
        Country => 'US',
#        CreditCardNumber => '4138848780259668',
        CreditCardNumber => '4138848780259668',
        ExpMonth => 1,
        ExpYear => 2006,
        CVV2 => '000',
        CardType => 'Visa',
        OrderTotal => $args->{amount} || '39.85',
        IPAddress => '216.234.213.44',
      };
    }
    
    case "RefundTransaction" {
      my $rt = $args->{refundtype} || 'Full';
      $req = {
        TransactionID => $args->{transid},
        RefundType => $rt,
        Amount => ($rt eq 'Full') ? undef : $args->{amount},
        Memo => $args->{memo},
      };
    }
    
    case "DoExpressCheckoutPayment" {
      $req = {
        token => $args->{token},
        PayerID => $args->{payerid},
        OrderTotal => $args->{amount},
      };
    }

    case "SetExpressCheckout" {
      $req = {
        ReturnURL => $args->{returnurl},
        CancelURL => $args->{cancelurl},
        OrderTotal => $args->{amount},
      };
    }
    
    case "GetExpressCheckoutDetails" {
      $req = {
        token => $args->{token},
      };
    }
  }

  return $req;
}
MAIN: {
  my $args = get_args();
  my $cmd = $args->{cmd};

  $Business::PayPal::SDK::PPCONINFO = 1;
  my $pp = new Business::PayPal::SDK({java_sdk_dir => "$ENV{HOME}/paypal_java_sdk"});
  $pp->shared_jvm(1);

  my $ret = $pp->$cmd(get_cmd_args($args));

  use Data::Dumper;
  print Dumper($ret);
  print "\n";
  print $pp->error if $pp->error;
  print "\n";
}
