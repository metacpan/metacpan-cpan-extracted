package Business::OnlinePayment::USAePay;

use strict;
use Carp;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS;
use Digest::MD5 qw(md5_hex);
use URI::Escape;
use vars qw($VERSION @ISA $DEBUG);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.03';

$DEBUG = 0;

sub _info {
  {
    'info_compat'           => '0.01',
    'gateway_name'          => 'USAePay',
    'gateway_url'           => 'http://www.usaepay.com',
    'module_version'        => $VERSION,
    'supported_types'       => [ 'CC', 'ECHECK' ],
    'supported_actions'     => {
                                  CC => [
                                    'Normal Authorization',
                                    'Authorization Only',
                                    'Post Authorization',
                                    'Credit',
                                    'Void',
                                    ],
                                  ECHECK => [
                                    'Normal Authorization',
                                    'Credit',
                                    ],
    },
  };
}

my $default_path = '/gate.php';
my $default_cert_path = '/secure/gate.php';

sub set_defaults {
    my $self = shift;
    $self->server('www.usaepay.com');
    $self->port('443');
    $self->path($default_path);
    $self->build_subs(qw(avs_code cvv2_response));

}

sub map_fields {
  my($self) = shift;

  my %content = $self->content();

  my %types = ('visa'             => 'CC',
               'mastercard'       => 'CC',
               'american express' => 'CC',
               'discover'         => 'CC',
               'check'            => 'ECHECK',
              );
  $content{'type'} = $types{lc($content{'type'})} || $content{'type'};
  $self->transaction_type($content{'type'});

  my %actions;
  my %cc_actions = ('normal authorization' => 'sale',
                    'authorization only'   => 'authonly',
                    'post authorization'   => 'postauth',
                    'credit'               => 'credit',
                    'void'                 => 'void',
                   );
  my %ec_actions = ('normal authorization' => 'check',
                    'credit'               => 'checkcredit',
                   );
  if ($content{'type'} eq 'CC') {
    (%actions) = (%cc_actions);
  }elsif ($content{'type'} eq 'ECHECK') {
    (%actions) = (%ec_actions);
  }
  $content{'action'} = $actions{lc($content{'action'})} || $content{'action'};
                 
  $content{'expiration'} =~ s/\D//g if exists $content{'expiration'};

  $content{'md5hash'} =
      md5_hex( join(':', map { defined($content{$_}) ? $content{$_} : '' }
                             qw(action password amount invoice_number md5key)))
    if defined $content{'password'};

  $self->content(%content);
}

sub submit {
    my($self) = @_;

    $self->map_fields();

    $self->remap_fields(
      login            => 'UMkey',
      md5key           => 'UMmd5key',
      md5hash          => 'UMmd5hash',
      card_number      => 'UMcard',
      expiration       => 'UMexpir',
      amount           => 'UMamount',
      invoice_number   => 'UMinvoice',
      description      => 'UMdescription',
      customer_id      => 'UMcustid',
      cvv2             => 'UMcvv2',
      email            => 'UMcustemail',
      name             => 'UMname',
      address          => 'UMstreet',
      zip              => 'UMzip',
      customer_ip      => 'UMip',
      order_number     => 'UMrefNum',
      authorization    => 'UMauthCode',
      routing_code     => 'UMrouting',
      account_number   => 'UMaccount',
      customer_ssn     => 'UMssn',
      action           => 'UMcommand',
    );
    my %content = $self->content;
    if ( $DEBUG ) {
      warn "content:$_ => $content{$_}\n" foreach keys %content;
    }

    my @required_fields = qw(type action login);

    my $action = $self->{_content}->{action};
    if ($self->transaction_type() eq 'CC' ) {
      if ($action eq 'void' or $action eq 'capture') {
        push @required_fields, qw/order_number/;
      }
      else {
        # sale, authonly, credit, postauth
        push @required_fields, qw/card_number expiration amount address zip/;
        if ($action eq 'postauth') {
          push @required_fields, qw/authorization/;
        }
      }
    } 
    elsif ($self->transaction_type() eq 'ECHECK' ) {
      push @required_fields, qw/routing_code account_number amount name customer_ssn/;
    } else {
      croak("USAePay can't handle transaction type: ".
            $self->transaction_type());
    }

    $self->required_fields(@required_fields);

    my %post_data = $self->get_fields( map "$_", qw(
      UMcommand UMkey UMmd5hash UMmd5key UMauthCode UMrefNum UMcard UMexpir
      UMrouting UMaccount UMamount Umtax UMnontaxable UMtip UMshipping
      UMdiscount UMsubtotal UMcustid UMinvoice UMorderid UMponum UMdescription
      UMcvv2 UMcustemail UMcustreceipt UMname UMStreet UMzip UMssn UMdlnum
      UMdlstate UMclerk UMterminal UMtable UMip UMsoftware UMredir
      UMredirApproved UMredirDeclined UMechofields UMtestmode
    ) );

    # test_transaction(0): normal mode
    #                  1 : test mode (validates formatting only)
    #                  2 : use sandbox server
    #                  3 : test mode on sandbox server
    my $test = $self->test_transaction || 0;
    $self->server('sandbox.usaepay.com') if ( $test & 2 );
    $post_data{'UMtestmode'} = ($test & 1) ? 1 : 0;

    $post_data{'UMsoftware'} = __PACKAGE__. " $VERSION";
    if ( $DEBUG ) {
      warn "post_data:$_ => $post_data{$_}\n" foreach keys %post_data;
    }

    my($page,$server_response) = $self->https_post(%post_data);
    if ( $DEBUG ) {
      warn "response page: $page\n";
    }

    my $response;
    if ($server_response =~ /200/){
      $response = {map { split '=', $_, 2 } split '&', $page};
    }else{
      $response->{UMstatus} = 'Error';
      $response->{UMerror} = $server_response;
    }

    $response->{$_} =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg
      foreach keys %$response;

    if ( $DEBUG ) {
      warn "response:$_ => $response->{$_}\n" foreach keys %$response;
    }

    if ( $response->{UMstatus} =~ /^Approved/ ) {
      $self->is_success(1);
      $self->authorization($response->{UMauthCode});
    } else {
      $self->is_success(0);
    }
    $self->order_number($response->{UMrefNum});
    $self->avs_code($response->{UMavsResultCode});
    $self->cvv2_response($response->{UMcvv2ResultCode});
    $self->result_code($response->{UMresult});
    $self->error_message($response->{UMerror});
    $self->server_response($response);
}

1;
__END__

=head1 NAME

Business::OnlinePayment::USAePay - USA ePay backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("USAePay");
  $tx->content(
      login          => 'igztOatyqbpd1wsxijl4xnxjodldwdxR', #USAePay source key
      password       => 'abcdef', #USAePay PIN
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      name           => 'Tofu Beast',
      card_number    => '46464646464646',
      expiration     => '11/08',
      address        => '1234 Bean Curd Lane, San Francisco',
      zip            => '94102',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 COMPATIBILITY

This module was developed against USAePay's CGI Gateway API v2.9.5 and
also tested against v2.17.1 without problems.  See
http://wiki.usaepay.com/developer/transactionapi for details.

=head1 AUTHOR

Original author: Jeff Finucane <jeff@cmh.net>

Current maintainer: Ivan Kohler <ivan-usaepay@freeside.biz>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2012 Freeside Internet Services, Inc. (http://freeside.biz/)

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ADVERTISEMENT

Need a complete, open-source back-office and customer self-service solution?
The Freeside software includes support for credit card and electronic check
processing with USAePay and over 50 other gateways, invoicing, integrated
trouble ticketing, and customer signup and self-service web interfaces.

http://freeside.biz/freeside/

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut
