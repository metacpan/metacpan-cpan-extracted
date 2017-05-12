package Business::OnlinePayment::Jety;

use strict;
use Carp 'croak';
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS;
use vars qw($VERSION @ISA $me $DEBUG);

use Date::Format;
use Tie::IxHash;

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.09';
$me = 'Business::OnlinePayment::Jety';

$DEBUG = 0;

my %trans_type = (
  'normal authorization' => 'echeck',
  'void'                 => 'ereturn',
  'credit'               => 'ereturn',
  );

my %map = (
# 'function' will always be prepended
'normal authorization' => [ # note array-ness
  'username'      => 'login',
  'password'      => 'password',
  'firstname'     => 'first_name',
  'lastname'      => 'last_name',
  'address1'      => 'address',
  'address2'      => 'address2',
  'city'          => 'city',
  'state'         => 'state',
  'zip'           => 'zip',
  'email'         => 'email',
  'phone'         => 'phone',
  'programdesc'   => 'description',
  'ref'           => sub { my %c = @_; 
                           $c{'authorization'} || 
                           substr( time2str('%Y%m%d%H%M%S',time). int(rand(10000)), -15 ) 
                           },
  'bankname'      => 'bank_name',
  'bankcity'      => 'bank_city',
  'bankstate'     => 'bank_state',
  'accountaba'    => 'routing_code',
  'accountdda'    => 'account_number',
  'amount'        => sub { my %c = @_; sprintf("%.02f",$c{'amount'}) },
],
'void' => [
  'username'      => 'login',
  'password'      => 'password',
  'ref'           => 'authorization',
  'accountdda'    => 'account_number',
  'amount'        => sub { my %c = @_; sprintf("%.02f",$c{'amount'}) },
],
);
$map{'credit'} = $map{'void'};

my %defaults = ( # using the B:OP names
  'phone'         => '111-111-1111',
  'bank_name'     => 'unknown',
  'bank_city'     => 'unknown',
  'bank_state'    => 'XX',
  );

my %required = (
'normal authorization' => [ qw(
  type
  action
  login
  password
  first_name
  last_name
  address
  city
  state
  zip
  email
  account_number
  routing_code
  amount
  description
) ],
'void' => [ qw(
  type
  action
  login
  password
  authorization 
  account_number
  amount
) ],
);
$required{'credit'} = $required{'void'};

sub _info {
  {
    info_compat             => '0.01',
    gateway_name            => 'Jety',
    gateway_url             => 'http://www.jetypay.com',
    module_version          => $VERSION,
    supported_types         => [ 'ECHECK' ],
    supported_actions       => [ 'Normal Authorization', 'Void', 'Credit' ],
    ECHECK_void_requires_account => 1,
  }
}

sub set_defaults {
  my $self = shift;
  $self->server('api.cardservicesportal.com');
  $self->port(443);
  $self->path('/servlet/drafts.echeck');
  return;
}

sub submit {
  my $self = shift;
  $Business::OnlinePayment::HTTPS::DEBUG = $DEBUG;
  $DB::single = $DEBUG; 

  # strip existent but empty fields so that required_fields works right
  foreach(keys(%{$self->{_content}})) {
    delete $self->{_content}->{$_} 
      if (!defined($self->{_content}->{$_} ) or
           $self->{_content}->{$_} eq '');
  }

  my %content = $self->content();
  my $action = lc($content{'action'});

  croak "Jety only supports ECHECK payments.\n"
    if( lc($content{'type'}) ne 'echeck' );
  croak "Unsupported transaction type: '$action'\n"
    if( !exists($trans_type{$action}) );

  $self->required_fields(@{ $required{$action} });

  my @fields = @{ $map{$action} } ;
  tie my %request, 'Tie::IxHash', ( 'function' => $trans_type{$action} );
  while(@fields) {
    my ($key, $value) = (shift (@fields), shift (@fields));
    if( ref($value) eq 'CODE' ) {
      $request{$key} = $value->(%content);
    }
    elsif (defined($content{$value}) and $content{$value} ne '') {
      $request{$key} = $content{$value};
    }
    elsif (exists($defaults{$value})) {
      $request{$key} = $defaults{$value};
    } # else do nothing
  }

  $DB::single = $DEBUG;
  if($self->test_transaction()) {
    print "https://".$self->server.$self->path."\n";
    print "$_\t".$request{$_}."\n" foreach keys(%request);
    $self->error_message('test mode not supported');
    $self->is_success(0);
    return;
  }
  my ($reply, $response, %reply_headers) = $self->https_post(\%request);
  
  if(not $response =~ /^200/) {
    croak "HTTPS error: '$response'";
  }

  # string looks like this:
  # P1=1234&P2=General Status&P3=Specific Status
  # P3 is not always there, though.
  if($reply =~ /^P1=(\d+)&P2=([\w ]*)(&P3=(\S+))?/) {
    if($1 == 0) {
      $self->is_success(1);
      $self->authorization($4);
    }
    else {
      $self->is_success(0);
      $self->error_message($2.($4 ? "($4)" : ''));
    }
  }
  else {
    croak "Malformed server response: '$reply'";
  }

  return;
}

sub get_returns {
# Required parameters:
# ftp_user, ftp_pass, ftp_host, ftp_path
# Optional:
# start, end
  eval('use Date::Parse q!str2time!; use Net::FTP; use File::Temp q!tempdir!');
  die $@ if $@;

  my $self = shift;
# $self->required_fields, for processor options
  my @missing;
  my ($user, $pass, $host, $path) = map {
    if($self->can($_) and $self->$_) {
      $self->$_ ;
    } else {
      push @missing, $_; '';
    } 
  } qw(ftp_user ftp_pass ftp_host);
  die "missing gateway option(s): ".join(', ',@missing)."\n" if @missing;
  my $ftp_path = $self->ftp_path if $self->can('ftp_path');

  my $start = $self->{_content}->{start};
  $start &&= str2time($start);
  $start ||= time - 86400;
  $start = time2str('%Y%m%d',$start);

  my $end = $self->{_content}->{end};
  $end &&= str2time($end);
  $end ||= time;
  $end = time2str('%Y%m%d',$end);
  
  my $ftp = Net::FTP->new($host) 
    or die "FTP connection to '$host' failed.\n";
  $ftp->login($user, $pass) or die "FTP login failed: ".$ftp->message."\n";
  $ftp->cwd($path) or die "can't chdir to $path\n" if $path;
 
  my $tmp = tempdir(CLEANUP => 1);
  my @files;
  foreach my $filename ($ftp->ls) {
    if($filename =~ /^\w+_RET(\d{8}).csv$/ 
      and $1 >= $start 
      and $1 <= $end ) {
      $ftp->get($filename, "$tmp/$1") or die "Failed to download $filename: ".$ftp->message."\n";
      push @files, $1;
    }
  }
  $ftp->close;

  my @tids;
  foreach my $filename (@files) {
    open IN, '<', "$tmp/$filename";
    my @fields = split ',',<IN>; #fetch header row
    my ($i) = grep { $fields[$_] eq 'AccountToID' } 0..(scalar @fields - 1);
    $i ||= 1;
    while(<IN>) {
      my @fields = split ',', $_;
      push @tids, $fields[$i];
    }
    close IN;
  }
  return @tids;
}

1;
__END__

=head1 NAME

Business::OnlinePayment::Jety - Jety Payments ACH backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # Electronic check authorization.
  ####

  my $tx = new Business::OnlinePayment("Jety");
  $tx->content(
      type           => 'ECHECK',
      login          => 'testdrive',
      password       => 'testpass',
      action         => 'Normal Authorization',
      description    => '111-111-1111 www.example.com',
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

=head1 SUPPORTED TRANSACTION TYPES

=head2 ECHECK

Content required: type, login, password, action, amount, first_name, last_name, account_number, routing_code, description.

description should be set in the form "111-111-1111 www.example.com"

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.  

=head2 result_code

Returns the four-digit result code.

=head2 error_message

Returns a useful error message.

=head1 Handling of content(%content) data:

=head2 action

The following actions are valid:

  Normal Authorization
  Void
  Credit

=head1 AUTHOR

Mark Wells <mark@freeside.biz>

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=head1 ADVERTISEMENT

Need a complete, open-source back-office and customer self-service solution?
The Freeside software includes support for credit card and electronic check
processing, integrated trouble ticketing, and customer signup and self-service
web interfaces.

http://freeside.biz/freeside/

=cut

