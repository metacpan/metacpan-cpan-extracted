package Business::NoChex;

require 5.005_62;
use strict;
use warnings;
use vars qw/%ENV/;
use LWP::UserAgent; 
use CGI qw/:cgi/;

use Class::MethodMaker;

our $VERSION = '0.02';

our $REFERAL_URL = 'https://www.nochex.com/nochex.dll/apc/apc';

use Class::MethodMaker
  new_with_init => 'new',
  new_hash_init => 'hash_init',
  grouped_fields => [ post_fields =>[ qw/to_email from_email transaction_date transaction_id security_key order_id amount/ ] ],
  get_set => [ qw/ recipient query cgi/],
  boolean => [ qw/ authorised declined no_response is_valid /];

sub init {
  my ($self,$args) = @_;

  if(ref($args) eq 'HASH'){
    $self->hash_init($args);
  }

  $self->cgi(new CGI);
  $self->parse;
  $self->verify;
  $self->set_is_valid if (($self->recipient eq $self->to_email) && $self->authorised);
}
 
sub parse{
  my($self)=shift;

  foreach my $field ($self->post_fields){
    $self->$field($self->cgi->param($field));
  }
}

sub verify{
  my($self)=shift;

  my($ua) = new LWP::UserAgent; 
  my($req) = new HTTP::Request 'POST',$REFERAL_URL; 
  $req->content_type('application/x-www-form-urlencoded');
  $req->content($self->cgi->query_string);  
  my($res) = $ua->request($req);

  if ($res->content eq 'AUTHORISED'){ $self->set_authorised; return 1 }
  elsif ($res->content eq 'DECLINED'){ $self->set_declined; return 0 }
  else { $self->set_no_response; return 0; }
}


1;
__END__

=head1 NAME

Business::NoChex - Perl extension for the validation of NoChex payments 

=head1 SYNOPSIS

  use Business::NoChex;
  my($payment)= new Business::NoChex({ recipient => 'a@bc.com'});

  if($payment->is_valid){
    spendItAll($payment->amount);
  }else{
    ringAlarmBells();
  }
 
=head1 DESCRIPTION

A simple module to allow verification of the NoChex APC notification messages.

=head2 EXPORT

None by default.

=head1 AUTHOR

Robin Szemeti

Redpoint Consulting Limited

=head1 SEE ALSO

perl(1).

=cut
