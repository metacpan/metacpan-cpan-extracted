package Business::iDEAL::Mollie;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use XML::Simple;

our $VERSION = '0.01';

sub new {
   my ($class, $args) = @_;
   $args ||= {};
   $class->_croak("Options must be a hash reference")
      if ref($args) ne 'HASH';
   my $self = {};
   bless $self, $class;
   $self->_init($args) or return undef;

   return $self;
}

sub _init {
   my ($self, $args) = @_;

   my $ua = LWP::UserAgent->new(
      agent => __PACKAGE__." v. $VERSION",
   );
   my %options = (
        baseurl      => 'http://www.mollie.nl/xml/ideal',
        ua           => $ua,
        %{ $args },
      );
   $self->{"_$_"} = $options{$_} foreach (%options);
   return $self;
}

sub banklist {
   my $self = shift;
   
   my $res = $self->{'_ua'}->get($self->{'_baseurl'}.'?a=banklist');
   if ($res->is_success) {
      return _parse_output($res->decoded_content)->{'bank'};
   } else {
      $self->{'_error'} = $res->status_line;
   }
}

sub fetch {
   my ($self, $parms) = @_;
   $parms ||= {};
   $self->_croak("Parameters must be in a hash reference")
      if ref($parms) ne 'HASH';

   # Check for mandatory input
   foreach(qw/partnerid amount bank_id description reporturl returnurl/) {
      $self->_croak("Mandatory parameter $_ not found!") unless($parms->{$_});
   }

   # Make sure amount is in cents
   $parms->{'amount'} =~ s/[\.,]//g;

   # Put the action value in $parms
   $parms->{'a'} = 'fetch';
   my $res = $self->{'_ua'}->post($self->{'_baseurl'}, $parms);

   if ($res->is_success) {
      return _parse_output($res->decoded_content)->{'order'};
   } else {
      $self->{'_error'} = $res->status_line;
   }
}

sub check {
   my ($self, $parms) = @_;
   $parms ||= {};
   $self->_croak("Parameters must be in a hash reference")
      if ref($parms) ne 'HASH';

   # Check for mandatory input
   foreach(qw/partnerid transaction_id/) {
      $self->_croak("Mandatory parameter $_ not found!") unless($parms->{$_});
   }
  
   # Put the action value in $parms
   $parms->{'a'} = 'check';
   my $res = $self->{'_ua'}->post($self->{'_baseurl'}, $parms);

   if ($res->is_success) {
       return _parse_output($res->decoded_content)->{'order'};
   } else {
      $self->{'_error'} = $res->status_line;
   }
}

sub is_payed {
   my ($self, $parms) = @_;
   my $resp = $self->check($parms);
   return ($resp->{'payed'} eq 'true') ? 1 : 0;
}

sub error {
   my $self = shift;
   return $self->{'_error'};
}


sub _parse_output {
   my $input = shift;
   return unless($input);
   my $xso = new XML::Simple();
   return $xso->XMLin($input);
}

sub _croak {
   my ($self, @error) = @_;
   Carp::croak(@error);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::iDEAL::Mollie - Backend for iDEAL payments through mollie.nl

=head1 SYNOPSIS

  use strict;
  use Business::iDEAL::Mollie;

  my $mollie = new Business::iDEAL::Mollie;
  
  # First you will have to grab the bank list (the list might
  # change, so make sure you do this).

  my $banks = $mollie->banklist;

  # Then, you probably want to feed your user the URL of
  # the right bank.

  my $resp = $mollie->fetch({
               partnerid  => 'your partner id',
               amount     => '1250',
               bank_id    => $banks->[2]{'bank_id'},
               description=> 'Acme Labs: order# foo-bar-123'
               reporturl  => 'http://your.site.tld/mollie.cgi',
               returnurl  => 'http://your.site.tld/thanks.html'
             });
  if($resp) {
     # ... probably some Database activity here 
     # with $resp->{'transaction_id'} and some redirection
     # headers with $resp->{'URL'}
  } else {
     # Do something with $mollie->error, which contains the 
     # status_line of LWP::UserAgent
  }

Meanwhile, in a nearby piece of code (mollie.cgi in this example)

  # The easy way ...

  if($q->param('transaction_id')) {
     if($mollie->is_payed({
           partnerid      => 'your partner id',
           transaction_id => $q->param('transaction_id'),
        })) {
        # Do something with the verified transaction_id
     } else {
        # Not payed, or checked more than once...
     }
  }

  # The more complicated way

  if($q->param('transaction_id')) {
     my $resp = $mollie->check({
                  partnerid      => 'your partner id',
                  transaction_id => $q->param('transaction_id'),
                }); 
     if($resp->{'payed'} eq 'true') {
        # Do something with $resp->{'amount'}, $resp->{'currency'}, etc.
     } else {
        # Log, cry, do anything here with the failed check.
     }
  }

=head1 DESCRIPTION

C<Business::iDEAL::Mollie> provides a backend to process iDEAL payments
through mollie.nl.

=head2 METHODS

The following methods can be used

=head3 new

C<new> creates a new C<Business::iDEAL::Mollie> object. 

=head4 options

=over 5

=item baseurl

Defaults to L<http://www.mollie.nl/xml/ideal>, but could be set
to a different URL for testing (e.g. L<http://menno.b10m.net/perl/ideal>)

=item ua

Configure your own LWP UserAgent.

=back

=head3 banklist

First of all, you need to fetch a list of bank_ids and bank_names. This
list is subject to change, and mollie.nl recommends checking this list
for each transaction. Returns an arrayref of hashes with bank_id and bank_name.

=head3 fetch

After you've retrieved the banklist, your users may choose the preferred
bank. Now you can feed that 'bank_id', together with 'partnerid', 'amount',
'description', 'reporturl' and 'returnurl'.

This method returns the I<transaction_id> that you should store for later
reference, aswell as I<URL> of the bank's iDEAL page that the user
should be directed to.

=over 5

=item partnerid

See L<http://ww.mollie.nl/> for more information on how to get a partnerid.

=item amount

The amount in cents. So 10 euro should be written as 1000. This module
removes periods and columns by default, but don't count on this to go
perfect!

=item bank_id

The bank_id as retrieved by the B<"banklist"> method. Include leading zeros
where needed. The bank id should contain 4 digits.

=item description

A description of the payment in 29 characters or less (more chars
will be stripped by mollie.nl). This description will be used by
the actual banks, so make sure it's clear for your users.

=item reporturl

The URL of your script handling the query by mollie.nl when a transaction
is completed. This script should perform the B<"check"> method. 

=item returnurl

The URL of where to redirect your users to after the payment process is 
done.

=back

=head3 check

After the user went through the payment process, mollie.nl will fire off
a GET request on your I<"reporturl">. This GET request will include
the I<"transaction_id"> that you stored during B<"fetch"> method.

This method requires the I<"partnerid"> aswell as the I<"transaction_id">
you just received, and returns the status of the order.

=head3 is_payed

Simple wrapper around the B<"check"> method. Returns a true value when
the order is payed for, and a false value when this is not the case.

=head3 error

The error method will return any errors encountered (mainly, or solely
L<LWP::UserAgent> based). Note that all methods also return a B<message>
from mollie.nl, explaining the answers a little.

=head1 SEE ALSO

=over 5

=item * L<http://www.ideal.nl/>,

=item * L<http://mollie.nl/geavanceerd/ideal>

=item * L<http://menno.b10m.net/perl/>

=back

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Business-iDEAL-Mollie>.

=head1 AUTHOR

M. Blom, 
E<lt>blom@cpan.orgE<gt>,
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by M. Blom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
