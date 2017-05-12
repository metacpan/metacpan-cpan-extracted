package Business::OnlinePayment::WesternACH;

use strict;
use Carp;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS;
use XML::Simple;
use MIME::Base64;
use Date::Format 'time2str';
use Date::Parse  'str2time';
use vars qw($VERSION @ISA $me $DEBUG);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.08';
$me = 'Business::OnlinePayment::WesternACH';

$DEBUG = 0;

my $defaults = {
  command      => 'payment',
  check_ver    => 'yes',
  sec_code     => 'PPD',
  tender_type  => 'check',
  check_number => 9999,
  schedule     => 'live',
};

my $required = { map { $_ => 1 } ( qw(
  login
  password
  command
  amount
  tender_type
  _full_name
  routing_code
  check_number
  _check_type 
))};



# Structure of the XML request document
# Right sides of the hash entries are Business::OnlinePayment 
# field names.  Those that start with _ are local method names.

my $auth = {
Authentication => {
  username => 'login',
  password => 'password',
}
};

my $request = {
TransactionRequest => {
  %$auth,
  Request => {
    command => 'command',
    Payment => {
      type   => '_payment_type',
      amount => 'amount',
      # effective date: not supported
      Tender => {
        type   => 'tender_type',
        amount => 'amount',
        InvoiceNumber => { value => 'invoice_number' },
        AccountHolder => { value => '_full_name'      },
        Address       => { value => 'address'       },
        ClientID      => { value => 'customer_id'    },
        UserDefinedID => { value => 'email' },
        CheckDetails => {
          routing      => 'routing_code',
          account      => 'account_number',
          check        => 'check_number',
          type         => '_check_type',
          verification => 'check_ver',
        },
        Authorization => { schedule => 'schedule' },
        SECCode => { value => 'sec_code' },
      },
    },
  }
}
};

my $returns_request = {
TransactionRequest => {
  %$auth,
  Request => {
    command => 'command',
    DateRange => {
      start => '_start',
      end   => '_end',
    },
  },
}
};

sub set_defaults {
  my $self = shift;
  $self->server('www.webcheckexpress.com');
  $self->port(443);
  $self->path('/requester.php');
  return;
}

sub submit {
  my $self = shift;
  $Business::OnlinePayment::HTTPS::DEBUG = $DEBUG;
  $DB::single = $DEBUG; # If you're debugging this, you probably want to stop here.
  my $xml_request;

  if ($self->{_content}->{command} eq 'get_returns') {
    # Setting get_returns overrides anything else.
    $xml_request = XMLout($self->build($returns_request), KeepRoot => 1);
  }
  else {
    # Error-check and prepare as a normal transaction.

      eval {
      # Return-with-error situations
      croak "Unsupported transaction type: '" . $self->transaction_type . "'"
        if(not $self->transaction_type =~ /^e?check$/i);

      croak "Unsupported action: '" . $self->{_content}->{action} . "'"
        if(!defined($self->_payment_type));

      croak 'Test transactions not supported'
        if($self->test_transaction());
    };

    if($@) {
      $self->is_success(0);
      $self->error_message($@);
      return;
    }
    
    $xml_request = XMLout($self->build($request), KeepRoot => 1);
  }
  my ($xml_reply, $response, %reply_headers) = $self->https_post({ 'Content-Type' => 'text/xml' }, $xml_request);
  
  if(not $response =~ /^200/) {
    croak "HTTPS error: '$response'";
  }

  $self->server_response($xml_reply);
  my $reply = XMLin($xml_reply, KeepRoot => 1)->{TransactionResponse};

  if(exists($reply->{Response})) {
    $self->is_success( ( $reply->{Response}->{status} eq 'successful') ? 1 : 0);
    $self->error_message($reply->{Response}->{ErrorMessage});
    if(exists($reply->{Response}->{TransactionID})) {
      # get_returns puts its results here
      my $tid = $reply->{Response}->{TransactionID};
      if($self->{_content}->{command} eq 'get_returns') {
        if(ref($tid) eq 'ARRAY') {
          $self->{_content}->{returns} =  [ map { $_->{value} } @$tid ];
        }
        else {
          $self->{_content}->{returns} = [ $tid->{value} ];
        }
      }
      else { # It's not get_returns
        $self->authorization($tid->{value});
      }
    }
  }
  elsif(exists($reply->{FatalException})) {
    $self->is_success(0);
    $self->error_message($reply->{FatalException});
  }


  return;
}

sub get_returns {
  my $self = shift;
  my $content = $self->{_content};
  if(exists($content->{'command'})) {
    croak 'get_returns: command is already set on this transaction';
  }
  if ( exists($content->{'returns_method'}) &&
      $content->{'returns_method'} eq 'requester') {
    # Obsolete, deprecated method supported for now as a fallback option.
    $content->{'command'} = 'get_returns';
    $self->submit;
    if($self->is_success) {
      if(exists($content->{'returns'})) {
        return @{$content->{'returns'}};
      }
      else {
        return ();
      }
    }
    # you need to check error_message() for details.
    return ();
  }
  else {
    $Business::OnlinePayment::HTTPS::DEBUG = $DEBUG;
    $DB::single = $DEBUG;
    if (defined($content->{'login'}) and defined($content->{'password'})) {
      # transret.php doesn't respect date ranges.  It returns anything from the 
      # same month as the date argument.  Therefore we generate one request for 
      # each month in the date range, and then filter them by date later.
      my $path = ('transret.php?style=csv&sort=id&date=');
      my $starttime = str2time($self->_start);
      my $endtime = str2time($self->_end) - 1;
      my @months = map { s/^(....)(..)$/$1-$2-01/; $_ } (
          time2str('%Y%m', $starttime)..time2str('%Y%m', $endtime)
          );
      my $headers = { 
         Authorization => 'Basic ' . MIME::Base64::encode($content->{'login'} . ':' . $content->{'password'}) 
          };
      my @tids;
      foreach my $m (@months) {
        $self->path($path . $m);
        # B:OP:HTTPS::https_get doesn't use $DEBUG.
        my ($page, $reply, %headers) = 
            $self->https_get(
              { headers => $headers },
              {},
            );
        if ($reply =~ /^200/) {
          $self->is_success(1);
        }
        else {
          $self->error_message($reply);
          carp $reply if $DEBUG;
          carp $page if $DEBUG >= 3;
          $self->is_success(0);
          return;
        }
        my $index_date_ret = 2; # Usual position of 'Date Returned'
        foreach my $trans (split("\cJ", $page)) {
          my @fields = split(',', $trans);
          # fields:
          # id, Date Returned, Type, Amount, Name, Customer ID Number,
          # Email Address, Invoice Number, Status Code, SEC

          # we only care about id and date.
          next if scalar(@fields) < 10;
          if($fields[0] eq 'id') {
            # Use this header row to find the 'Date Returned' field.
            ($index_date_ret) = grep { lc($fields[$_]) eq 'date returned' } ( 0..scalar(@fields)-1 );
            $index_date_ret ||= 2;
          }
          next if not($fields[0] =~ /^\d+$/);
          my $rettime = str2time($fields[$index_date_ret]);
          next if (!$rettime or $rettime < $starttime or $rettime > $endtime);
          carp $trans if $DEBUG > 1;
          push @tids, $fields[0];
        }
      }
      return @tids;
    }
    else {
      croak 'login and password required';
    }
  } 
}

sub build {
  my $self = shift;
    my $content = { $self->content };
    my $skel = shift;
    my $data;
    if (ref($skel) ne 'HASH') { croak 'Failed to build non-hash' };
    foreach my $k (keys(%$skel)) {
      my $val = $skel->{$k};
      # Rules for building from the skeleton:
      # 1. If the value is a hashref, build it recursively.
      if(ref($val) eq 'HASH') {
        $data->{$k} = $self->build($val);
      }
      # 2. If the value starts with an underscore, it's treated as a method name.
      elsif($val =~ /^_/ and $self->can($val)) {
        $data->{$k} = $self->can($val)->($self);
      }
      # 3. If the value is undefined, keep it undefined.
      elsif(!defined($val)) {
        $data->{$k} = undef;
      }
      # 4. If the value is the name of a key in $self->content, look up that value.
    elsif(exists($content->{$val})) {
      $data->{$k} = $content->{$val};
    }
    # 5. If the value is a key in $defaults, use that value.
    elsif(exists($defaults->{$val})) {
      $data->{$k} = $defaults->{$val};
    }
    # 6. If the value is not required, use an empty string.
    elsif(! $required->{$val}) {
      $data->{$k} = '';
    }
    # 7. Fail.
    else {
      croak "Missing request field: '$val'";
    }
  }
  return $data;
}

sub XML {
  # For testing build().
  my $self = shift;
  return XMLout($self->build($request), KeepRoot => 1);
}

sub _payment_type {
  my $self = shift;
  my $action = $self->{_content}->{action};
  if(!defined($action) or $action =~ /^normal authorization$/i) {
    return 'debit';
  }
  elsif($action =~ /^credit$/i) {
    return 'credit';
  }
  else {
    return;
  }
}

sub _check_type {
  my $self = shift;
  my $type = $self->{_content}->{account_type};
  return 'checking' if($type =~ /checking/i);
  return 'savings'  if($type =~ /savings/i);
  croak "Invalid account_type: '$type'";
}

sub _full_name {
  my $self = shift;
  return join(' ',$self->{_content}->{first_name},$self->{_content}->{last_name});
}

sub _start {
  my $self = shift;
  if($self->{_content}->{start}) {
    my $start = time2str('%Y-%m-%d', str2time($self->{_content}->{start}));
    croak "Invalid start date: '".$self->{_content}->{start} if !$start;
    return $start;
  }
  else {
    return time2str('%Y-%m-%d', time - 86400);
  }
}

sub _end {
  my $self = shift;
  my $end = $self->{_content}->{end};
  if($end) {
    $end = time2str('%Y-%m-%d', str2time($end));
    croak "Invalid end date: '".$self->{_content}->{end} if !$end;
    return $end;
  }
  else {
    return time2str('%Y-%m-%d', time);
  }
}

1;
__END__

=head1 NAME

Business::OnlinePayment::WesternACH - Western ACH backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # Electronic check authorization.  We only support 
  # 'Normal Authorization' and 'Credit'.
  ####

  my $tx = new Business::OnlinePayment("WesternACH");
  $tx->content(
      type           => 'ECHECK',
      login          => 'testdrive',
      password       => 'testpass',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      first_name     => 'Jason',
      last_name      => 'Kohles',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      account_type   => 'personal checking',
      account_number => '1000468551234',
      routing_code   => '707010024',
      check_number   => '1001', # optional
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Check processed successfully: ".$tx->authorization."\n";
  } else {
      print "Check was rejected: ".$tx->error_message."\n";
  }

  my $tx = new Business::OnlinePayment("WesternACH");
  $tx->content(
      login     => 'testdrive',
      password  => 'testpass',
      start     => '2009-06-25', # optional; defaults to yesterday
      end       => '2009-06-26', # optional; defaults to today
      );
  $tx->get_returns;
  

=head1 SUPPORTED TRANSACTION TYPES

=head2 ECHECK

Content required: type, login, password|transaction_key, action, amount, first_name, last_name, account_number, routing_code, account_type.

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.  

=head2 result_code

Currently returns nothing; these transactions don't seem to have result codes.

=head2 error_message

Returns the response reason text.  This can come from several locations in the response document or from certain local errors.

=head2 server_response

Returns the complete response from the server.

=head1 Handling of content(%content) data:

=head2 action

The following actions are valid:

  normal authorization
  credit

=head1 AUTHOR

Mark Wells <mark@freeside.biz> with advice from Ivan Kohler <ivan-westernach@freeside.biz>.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

