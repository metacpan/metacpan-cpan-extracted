package Business::CCProcessor;

use warnings;
use strict;
use CGI::FormBuilder;
use Carp;

use vars qw($VERSION);
$VERSION = '0.09';

# Module implementation here

1; # Magic true value required at end of module

sub new {
  my $self = shift;
  my $cc = {};
  bless $cc, $self;
  return $cc;
}

sub button_factory {
  my $self = shift;
  my $data = shift;
  my $method = $data->{'processor_settings'}->{'processor'};

  my $fields = $self->$method(\%{$data});
  my $form = CGI::FormBuilder->new(
                               method   => 'POST',
                               action   => $fields->{'action'},
#                              target   => '_new',
                               name     => "ProceedToCCProcessor",
                             keepextras => 1,
                               sticky   => 1,
#                                    js => 0,
                                 submit => [ $fields->{'button_label'}->{'value'} ],
                             stylesheet => '/path/to/style.css',
                               );

  foreach my $key (keys %{$fields}){
    if( $key eq 'action' ){ next; }
    if( $key eq 'button_label' ){ next; }
    $form->field(
       name => $fields->{$key}->{'name'},
      value => $fields->{$key}->{'value'},
       type => $fields->{$key}->{'type'} 
    );
  }
  my $html = $form->render();
  return $html;
}

sub verisign {
  my $self = shift;
  my $data = shift;

  my $fields = {};
  $fields->{'action'} = "https://payments.verisign.com/payflowlink";
  $fields->{'MFCIsapiCommand'} = { 'name' => 'MFCIsapiCommand', 'type' => 'hidden', 'value' => 'Orders' };
  $fields->{'LOGIN'} = { 'name' => 'LOGIN', 'type' => 'hidden', 'value' => $data->{'processor_settings'}->{'login'} };
  $fields->{'TYPE'} = { 'name' => 'TYPE', 'type' => 'hidden', 'value' => 'S' };
  $fields->{'DESCRIPTION'} = { 'name' => 'DESCRIPTION', 'type' => 'hidden', 'value' => $data->{'processor_settings'}->{'description'} };
  $fields->{'PARTNER'} = { 'name' => 'PARTNER', 'type' => 'hidden', 'value' => 'VeriSign' };
  $fields->{'NAME'} = { 'name' => 'NAME', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'name'} };
  $fields->{'Street'} = { 'name' => 'NAME', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'addr1'} };
  $fields->{'COMMENT1'} = { 'name' => 'COMMENT1', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'comments1'} };
  $fields->{'COMMENT2'} = { 'name' => 'COMMENT2', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'comments2'} };
  $fields->{'AMOUNT'} = { 'name' => 'AMOUNT', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'amount'} };
  $fields->{'button_label'} = { 'name' => '_submit', 'type' => 'submit', 'value' => $data->{'processor_settings'}->{'button_label'} };
  # print STDERR $fields->{'button_label'}->{'value'};
  # print STDERR $data->{'processor_settings'}->{'button_label'};

  return $fields;
}

sub paypal {
  my $self = shift;
  my $data = shift;

  my $fields = {};
  $fields->{'action'} = "https://www.paypal.com/cgi-bin/webscr";
  $fields->{'cmd'} = { 'type' => 'hidden', 'name' => 'cmd', 'value' => '_ext-enter' };
  $fields->{'redirect_cmd'} = { 'type' => 'hidden', 'name' => 'redirect_cmd', 'value' => '_xclick' };
  $fields->{'business'} = { 'type' => 'hidden', 'name' => 'business', 'value' => $data->{'processor_settings'}->{'business'} };
  $fields->{'item_name'} = { 'type' => 'hidden', 'name' => 'item_name', 'value' => $data->{'processor_settings'}->{'item_name'} };
  $fields->{'page_style'} = { 'type' => 'hidden', 'name' => 'page_style', 'value' => 'vcol1' };
  $fields->{'return'} = { 'type' => 'hidden', 'name' => 'return', 'value' => $data->{'processor_settings'}->{'return_url'} };
  $fields->{'cancel_return'} = { 'type' => 'hidden', 'name' => 'cancel_return', 'value' => $data->{'processor_settings'}->{'cancel_return_url'} };
  $fields->{'no_note'} = { 'type' => 'hidden', 'name' => 'no_note', 'value' => '1' };
  $fields->{'currency_code'} = { 'type' => 'hidden', 'name' => 'currency_code', 'value' => $data->{'processor_settings'}->{'currency_code'} };
  $fields->{'on0'} = { 'type' => 'hidden', 'name' => 'on0', 'value' => 'Your Employer' };
  $fields->{'tax'} = { 'type' => 'hidden', 'name' => 'tax', 'value' => '0' };
  $fields->{'amount'} = { 'type' => 'hidden', 'name' => 'amount', 'value' => $data->{'credit_card_owner'}->{'amount'} };
  $fields->{'on1'} = { 'type' => 'hidden', 'name' => 'on1', 'value' => 'Your Occupation' };
  $fields->{'on2'} = { 'type' => 'hidden', 'name' => 'on2', 'value' => 'Email' };
  $fields->{'no_shipping'} = { 'type' => 'hidden', 'name' => 'no_shipping', 'value' => '1' };
  $fields->{'country_code'} = { 'type' => 'hidden', 'name' => 'country_code', 'value' => '' };
  $fields->{'process'} = { 'type' => 'hidden', 'name' => 'process', 'value' => '1' };
  $fields->{'first_name'} = { 'type' => 'hidden', 'name' => 'first_name', 'value' => $data->{'credit_card_owner'}->{'fname'} };
  $fields->{'last_name'} = { 'type' => 'hidden', 'name' => 'last_name', 'value' => $data->{'credit_card_owner'}->{'lname'} };
  $fields->{'email'} = { 'type' => 'hidden', 'name' => 'email', 'value' => $data->{'credit_card_owner'}->{'email'} };
  $fields->{'os1'} = { 'type' => 'hidden', 'name' => 'os1', 'value' => $data->{'credit_card_owner'}->{'occupation'} };
  $fields->{'os0'} = { 'type' => 'hidden', 'name' => 'os0', 'value' => $data->{'credit_card_owner'}->{'employer'} };
  $fields->{'address1'} = { 'type' => 'hidden', 'name' => 'address1', 'value' => $data->{'credit_card_owner'}->{'addr1'} };
  $fields->{'address2'} = { 'type' => 'hidden', 'name' => 'address2', 'value' => $data->{'credit_card_owner'}->{'addr2'} };
  $fields->{'city'} = { 'type' => 'hidden', 'name' => 'city', 'value' => $data->{'credit_card_owner'}->{'city'} };
  $fields->{'state'} = { 'type' => 'hidden', 'name' => 'state', 'value' => $data->{'credit_card_owner'}->{'state'} };
  $fields->{'zip'} = { 'type' => 'hidden', 'name' => 'zip', 'value' => $data->{'credit_card_owner'}->{'postal_code'} };
  $fields->{'phn'} = { 'type' => 'hidden', 'name' => 'phn', 'value' => $data->{'credit_card_owner'}->{'phone'} };
  $fields->{'amount'} = { 'type' => 'hidden', 'name' => 'amount', 'value' => $data->{'credit_card_owner'}->{'amount'} };
  $fields->{'notes'} = { 'type' => 'hidden', 'name' => 'notes', 'value' => $data->{'credit_card_owner'}->{'notes'} };
  $fields->{''} = { 'type' => 'hidden', 'name' => 'Continue', 'value' => 'Continue . . . ' };
  $fields->{'button_label'} = { 'name' => '_submit', 'type' => 'submit', 'value' => $data->{'processor_settings'}->{'button_label'} };
 
  return $fields;
}

sub dia {
  my $self = shift;
  my $data = shift;

  my $fields = {};
  $fields->{'action'} = "https://secure.democracyinaction.com/dia/shop/processDonate.jsp";
  # "https://secure.democracyinaction.com/dia/organizations/Greens/shop/custom.jsp?donate_page_KEY=1239";
  $fields->{'donate_page_KEY'} = { type => 'hidden', name =>
'donate_page_KEY', value => $data->{'preocessor_settings'}->{'donate_page_KEY'} };
  $fields->{'amount'} = { 'name' => 'amount', 'type' => 'hidden', 'value' => 'checked' };
  $fields->{'amountOther'} = { 'name' => 'amountOther', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'amount'} };
  # print STDERR $data->{'credit_card_owner'}->{'amount'}, '\n';
  # print STDERR sprintf('$%.2f',$data->{'credit_card_owner'}->{'amount'});
  # print STDERR '\n';
  $fields->{'VARCHAR2'} = { 'name' => 'VARCHAR2', 'type' => 'hidden', 'value' => sprintf('$%.2f',$data->{'credit_card_owner'}->{'amount'}) };
  $fields->{'First_Name'} = { 'name' => 'First_Name', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'fname'} };
  $fields->{'Last_Name'} = { 'name' => 'Last_Name', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'lname'} };
  $fields->{'Email'} = { 'name' => 'Email', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'email'} };
  $fields->{'Phone'} = { 'name' => 'Phone', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'phone'} };
  $fields->{'Street'} = { 'name' => 'Street', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'addr1'} };
  $fields->{'Street_2'} = { 'name' => 'Street_2', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'addr2'} };
  $fields->{'City'} = { 'name' => 'City', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'city'} };
  $fields->{'State'} = { 'name' => 'State', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'state'} };
  $fields->{'Zip'} = { 'name' => 'Zip', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'postal_code'} };
  $fields->{'VARCHAR0'} = { 'name' => 'VARCHAR0', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'employer'} };
  $fields->{'Occupation'} = { 'name' => 'Occupation', 'type' => 'hidden', 'value' => $data->{'credit_card_owner'}->{'occupation'} };
  $fields->{'required'} = { type => 'hidden', name => 'required', value => '0,Phone,Occupation,0,VARCHAR0,VARCHAR2,First_Name,Last_Name,Street,City,State,Zip,' };
  $fields->{'updateRowValues'} = { type => 'hidden', name => 'updateRowValues', 'value' => 'true' };
  $fields->{'button_label'} = { 'name' => '_submit', 'type' => 'submit', 'value' => $data->{'processor_settings'}->{'button_label'} };

  return $fields;
}

__END__

=head1 NAME

Business::CCProcessor - Pass transaction off to secure processor


=head1 VERSION

This document describes Business::CCProcessor version 0.05


=head1 SYNOPSIS

    use Business::CCProcessor;
    use CGI::FormBuilder; # this is optional

    my $cc = Business::CCProcessor->new();

    my %data = (
      'processor_settings' => \%processor_settings,
      'credit_card_owner' => \%credit_card_owner,
      );

    See below for details about how those two hash references
    ought to be structured.

    You may then create a button to include in a web page, like this: 

    my $html_button = $cc->button_factory(\%data);

    or use any one of the following three methods to get a
    hash of fields, you can use if you want some additional
    control over how the button is rendered.

    my $fields = $cc->verisign(\%data);
    my $fields = $cc->dia(\%data);
    my $fields = $cc->paypal(\%data);

    The data in the $fields hashref can then be used to
    construct a web form submission button which will take
    a browser to the credit card forms for these providers.
    You might consider using CGI::FormBuilder, CGI, CGI::Simple
    or even hand rolled html fed to print statements, to then
    render the form with that data.

=head1 DESCRIPTION

At present this module and its methods are trivially simple
in what they do, offering as its one service, the ability to
hide how to munge your web form's data into a post call to a
supported credit card processor.

Business::CCProcessor will permit a script to collect
non-financial data locally and then using an http POST call,
hand that data off to a secure credit card processor which
then collects the credit card parameters, and processes
the transaction between the credit card owners account and
the script owners account. This is a poor man's variant on
Business::OnlinePayment for clients who cannot afford the video
camera watched locked cages around their dedicated server,
to collect credit card payments from their buyers or donors,
in a real-time interaction with the credit card owner.

This module is for you if you need to accept online credit card
payments for your organization or services but are not prepared
to invest in an ssl certificate, a dedicated IP address, a
dedicated server and the monitored restricted access to your
server which the privacy of your customers or donors requires.

Initially this module offers five public methods: a constructor,
a button_factory and methods for munging data for three (so
far) credit card processors, but additional methods to handle
additional credit card processors who permit this sort of
interaction should be straight forward to add.

Each of the credit card processor methods takes a reference to
a hash of values which you will have to create before calling
the method.  This data is generally of the form:

    my %data = (
      'processor_settings' => \%processor_settings,
      'credit_card_owner' => \%credit_card_owner,
      );

The second part of the hash is fairly consistent across the methods,
with some methods offering additional options for passing data than
others, but generally, this hash looks like this:

    %credit_card_owner = (
              'fname' => '',
              'lname' => '',
              'addr1' => '',
              'addr2' => '',
               'city' => '',
              'state' => '',
        'postal_code' => '',
           'comments' => '',
          'comments1' => '',
              'phone' => '',
              'email' => '',
           'employer' => '',
         'occupation' => '',
             'amount' => '',
              'notes' => '',
       'button_label' => '',
        );

The %processor_settings hash's structure is dependent on which
credit card processor method you are using.

As this module develops, I anticipate also providing for a
mode, to permit this module to be switched from 'commercial',
to 'non-profit', to 'electoral_campaign' mode, to account
for variances in how what data is collected for each of these
types of users.

=head2 my $cc = Business::CCProcessor->new();

This method creates an object permitting access to the other
methods provided by this module.

The three public methods listed below each take a reference
to a hash of data collected, cleaned and validated from a
preceeding web form interaction and returns a hash of fields
which can be used to construct a submission button which will
POST that data to a web accessible credit card processor.

=head2 my $html_button = $cc->button_factory(\%data);

By including the name of your credit card processor in the
%data hash, as $data->{'processor_settings'}->{'processor'},
you can use the ->button_factory() method to access the magic
of CGI::FormBuilder, and have returned to you a snippet of
html code defining a Proceed_to_CC_Processor form button, ready
for inclusion in a web page.  The button will have encoded as
hidden values, the data given to the method in its invocation,
and that data should be handed off to the credit card processor,
at least that data the processor is designed to handle.

If you need any more control than that over the final form of
your web form, you can use these following methods, which are
invoked by the ->button_factory() method when doing its work.

=head2 my %fields = $cc->verisign(\%data);

This method returns the fields necessary to process a payment
with Verisign.

The %data hash must include the following:

    %processor_settings = (
             'processor' => 'verisign',
                'action' => '' # <-- url of web form posted to
                 'login' => '' # <-- account id
           'description' => '' # <-- description of transaction
          'button_label' => '' # <-- what to call the button
        );

=head2 my %fields = $cc->dia(\%data);

This method returns the fields necessary to process a payment
with Democracy In Action.

The %data hash must include the following:

    %processor_settings = (
             'processor' => 'dia',
                'action' => '' # <-- url of web form posted to
          'button_label' => '' #<-- what to call the button
        );

=head2 my %fields = $cc->paypal(\%data);

This method returns the fields necessary to process a payment
with Paypal.

The %data hash must include the following:

    %processor_settings = (
             'processor' => 'paypal',
                'action' => '' # <-- url of web form posted to
              'business' => '' # <-- email address registered with paypal
             'item_name' => '' # <-- description of transaction 
            'return_url' => '' # <-- url on your site to return to
     'cancel_return_url' => '' # <-- url on your site to error out to
         'currency_code' => '' # <-- EUR, USD, CAD etc.
          'button_label' => '' #<-- what to call the button
        );

=head1 INTERFACE

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Business::CCProcessor requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None at the moment, though a future version will reguire
CGI::FormBuilder for some additional methods.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

Apparently, some credit card processors require that their
clients register the domain and path of the scripts which
may refer a user and browser to them.  Paypal did not reject
connections coming from my own development sandbox.  But both
DiA and VeriSign seem to refuse to do business with the machine
under my desk, when I used keys for accounts who's forms are
hosted at real url's.  

If the Verisgn account is setup to screen posts to its forms by
referring url, it is possible to configure a new url by logging in to
the VeriSign account, and following the following links: 

	Account Information -> 
	   PayflowLink Info ->
	      Accepted URLs 	(look at bottom of configuration page)

No bugs have been reported, but I'm sure this is riddled
with them.

By no means should this module be mistaken for any sort of
informed distillation of the wisdom available in the API's
for the services these methods interface with.  This is more
an attempt to hide some of the ugly details from myself for
some code I found myself rewriting on a regular basis.

At this early stage of development, I am simply working to
write an interface which can be substituted into multiple
copies of similiar code I am hosting in various scripts,
which I'd like to refactor and simplify.  If it serves your
needs, great.  If not, perhaps over time, this can evolve into
a more generally useful tool to serve a broader audience.

At this point, this is a "works-for-me" kind of project and
your input, questions, bug reports, patches and tests to create
a more robust, stable and useful tool are certainly welcome.

I welcome bug reports and feature requests at both:
L<http://www.campaignfoundations.com/project/issues>
as well as through the cpan hosted channels at:
C<bug-business-ccprocessor@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.

=head1 SEE ALSO 

Business::OnlinePayment allows a script to accept credit card
data from an end user or other source and process a transaction
of funds between the account represented by the credit card
data and the account owned by the merchant which deploys
the script. Its a fine tool for a client who can afford the
security it requires to appropriately handle credit card data.


=head1 AUTHOR

Hugh Esco  C<< <hesco@campaignfoundations.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Hugh Esco C<< <hesco@campaignfoundations.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the terms of the Gnu Public License. See L<gpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
