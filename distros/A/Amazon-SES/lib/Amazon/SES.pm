use Moops;

# ABSTRACT: Interfaces with AWS's SES service.

class Amazon::SES  {
    use strict;
    use warnings;
    use Carp ('croak');
    use MIME::Base64;
    use Time::Piece;
    use HTTP::Headers;
    use LWP::UserAgent;
    use AWS::Signature4;
    use Amazon::SES::Response;
    use VM::EC2::Security::CredentialCache;
    use HTTP::Request::Common;
    use Kavorka qw( multi method );



    has 'ua' => (is => 'ro', default => sub { return LWP::UserAgent->new() } );
    has 'use_iam_role' => ( is => 'ro', default => 0 );
    has 'access_key'   => ( is => 'ro' );
    has 'secret_key'   => ( is => 'ro' );
    has 'region'       => ( is => 'ro', default => 'us-east-1' );
    has 'response'       => ( is => 'rw' );
    

    method call(Str $action, HashRef $args? = {}) {
        $args->{AWSAccessKeyId} = $self->access_key;
        $args->{Action}         = $action;
        
        my $request = POST("https://email." . $self->region . ".amazonaws.com", $args);
        
        if ($self->{use_iam_role}) {
            my $creds = VM::EC2::Security::CredentialCache->get();
            defined($creds) || die("Unable to retrieve IAM role credentials");
            $self->{access_key} = $creds->accessKeyId;
            $self->{secret_key} = $creds->secretAccessKey;
            $request->header('x-amz-security-token' => $creds->sessionToken);
        }
        
        
        # Add the signature.
        my $signer = AWS::Signature4->new(-access_key => $self->access_key,
                                          -secret_key => $self->secret_key);
        $signer->sign($request);
        
        my $response = $self->ua->request($request);
        return Amazon::SES::Response->new(response => $response, 
                                          action => $action );
    }

    multi method send(MIME::Entity $message) {
        $self->send_mime($message);
    }

    multi method send(Str :$from,
                      Str :$body?,
                      Str :$body_html?,
                      Str :$to,
                      Str :$subject?,
                      Str :$charset = "UTF-8",
                      Str :$return_path?,
                  ) {
        $to = [$to] unless ref($to);
        defined($body) || defined($body_html) || die("No body specified");
        my %call_args = (
            'Message.Subject.Data'    => $subject,
            'Message.Subject.Charset' => $charset,
            'Source'                  => $from
        );
        
        if (defined($body)) {
            $call_args{'Message.Body.Text.Data'} = $body;
            $call_args{'Message.Body.Text.Charset'} = $charset;
        }
        
        
        if (defined($body_html)) {
            $call_args{'Message.Body.Html.Data'} = $body_html;
            $call_args{'Message.Body.Html.Charset'} = $charset;
        }

        if (defined($return_path)) {
            $call_args{'ReturnPath'} = $return_path;
        }
        my $i = 1;
        map { 
            $call_args{'Destination.ToAddresses.member.' . $i++} = $_;
        } @$to;
        
        $self->call( 'SendEmail', \%call_args );
    }
    
    
    method verify_email(Str $email) {
        return $self->call( 'VerifyEmailIdentity', { EmailAddress => $email } );
    }
    
    method delete_domain(Str $identity) {
        return $self->call( 'DeleteIdentity', { Identity => $identity } );
    }

    method delete_email(Str $identity) {
        return $self->call( 'DeleteIdentity', { Identity => $identity } );
    }

    method delete_identity(Str $identity) {
        return $self->call( 'DeleteIdentity', { Identity => $identity } );
    }
    
    
    method list_emails(Int :$limit?,
                       Int :$offset?) {
        my %call_args = ( IdentityType => 'EmailAddress' );
        
        defined($limit) && ($call_args{MaxItems} = $limit);
        defined($offset) && ($call_args{NextToken} = $offset);
        my $r = $self->call( 'ListIdentities', \%call_args );
    }
    
    
    method list_domains(Int :$limit?,
                        Int :$offset?) {
        my %call_args = ( IdentityType => 'Domain' );
        
        defined($limit) && ($call_args{MaxItems} = $limit);
        defined($offset) && ($call_args{NextToken} = $offset);
        my $r = $self->call( 'ListIdentities', \%call_args );
    }
    
    method get_quota() {
        return $self->call('GetSendQuota');
    }
    
    method get_statistics() {
        return $self->call('GetSendStatistics');
    }
    
    method send_mime(Str|MIME::Entity $message) {
        my $src = $message;
        if (ref($message) && $message->isa("MIME::Entity") ) {
            $src = $message->stringify;
        } 
        
        return $self->call( 'SendRawEmail',
                            { 'RawMessage.Data' => MIME::Base64::encode_base64($src) } );
    }
    
    method get_dkim_attributes(Str @identities) {
        my %call_args  = ();
        my $i =1 ;
        map { 
            $call_args{'Identities.member.' . $i++} = $_;
        } @identities;
        return $self->call( 'GetIdentityDkimAttributes', \%call_args );
    }
    
}

1;

__END__

=head1 NAME

Amazon::SES - Perl extension that implements Amazon Simple Email Service (SES) client

=head1 SYNOPSIS

    use Amazon::SES;

    my $ses = Amazon::SES->new(access_key => '....', secret_key => '...');
    # or
    my $ses = Amazon::SES->new(use_iam_role => 1);

    my $r = $ses->send(
        From    => '[your SES identity]',
        To      => '[recipient]',
        Subject => 'Hello World from SES',
        Body    => "Hello World"
    );

    unless ( $r->is_success ) {
        die "Could not deliver the message: " . $r->error_message;
    }

    printf("Sent successfully. MessageID: %s\n", $r->message_id);

    ######### sending attachments
    my $msg = MIME::Entity->build();
    my $r = $ses->send( $msg );

=head1 DESCRIPTION

Implements Amazon Web Services' Simple Email Service (SES). Sess L<http://docs.aws.amazon.com/ses/latest/DeveloperGuide/Welcome.html> for details and to sign-up for the service.  Forked from Net::AWS::SES, changed to use Moops and updated to support AWS signatures V4 and IAM Roles.

=head1 GETTING STARTED

After you sign-up for AWS SES service you need to create an C<IAM> credentials and create an C<access_key> and a C<secret_key>, which you will be needing to interface with the SES. Do not forget to grant permission to your C<IAM> to use SES. Read L<http://docs.aws.amazon.com/ses/latest/DeveloperGuide/using-credentials.html> for details.

=head1 METHODS

I attempted to make the method names as Perlish as possible, as opposed to direct copy/paste from the API reference. This way I felt you didn't have to be familiar with the full API reference in order to use the basic features of the service.

If you are avid AWS developer there is a C<call()> method, which gives you access to all the documented Query actions of the AWS SES. In fact, that's what all the methods use to hide the complexity of the request/response. There are few examples of the C<call()> method in later sections.

All the methods (including C<call()>) returns an instance of L<Response|Amazon::SES::Response>. You should check if the the call is success by testing for C<is_success> attribute of the response. If you want to gain full access to the raw parsed conents of the response I<(which originally is in XML, but we parse it into Perl hashref for you)>, C<result> attribute is all you will be needing. For the details see L<Response manual|Amazon::SES::Response>. Since C<result()> is the most important attribute of the resonse I will be giving you a sample result data in JSON notation for your reference.

=head2 new(access_key => $key, secret_key => $s_key)

=head2 new(access_key => $key, secret_key => $s_key, region => $region)

=head2 new(use_iam_role => 1)

Returns a Amazon::SES instance. C<access_key> and C<secret_key> arguments are optional if not specifying to C<use_iam_role>. C<region> is optional, and can be overriden in respective api calls. Must be a valid SES region: C<us-east-1>, C<us-west-2> or C<eu-west-1>. Default is C<us-east-1>. Must be your verified identity. 

=head2 send( $msg )

=head2 send(%options)

Sends an email address and returns L<Response|Amazon::SES::Response> instance.

If the only argument is passed, it must be an instance of MIME::Entity. Example:

    $msg = MIME::Entity->build(
        from    => '[your address]',
        to      => '[your recipient]',
        subject => 'MIME msg from AWS SES',
        data    => "<h1>Hello world from AWS SES</h1>",
        type    => 'text/html'
    );

    $msg->attach(
        Path     => File::Spec->catfile( 't', 'image.gif' ),
        Type     => 'image/gif',
        Encoding => 'base64'
    );

    $ses = Amazon::SES->new(....);
    $r = $ses->send($msg);

    unless ( $r->is_success ) {
        die $r->error_message;
    }

If you don't have MIME::Entity instance handy you may use the following arguments to have AWS SES build the message for you (bold entries are required): C<From>, B<To>, B<Subject>, B<Body>, C<Body_html>, C<ReturnPath>. To send e-mail to multiple emails just pass an arrayref to C<To>.

If C<From> is missing it defaults to your default e-mail given to C<new()>. Remember: this must be a verified e-mail. Example:

    $r = $ses->send(
        from    => '[your email address]',
        to      => '[destination email address]',
        subject => 'Hello World'
        body    => 'Hello World'
    );
    unless ( $r->is_success ) {
        die $r->error_message;
    }

You may provide an alternate html content by passing C<body_html> header.

C<charset> of the e-mail is set to 'UTF-8'. As of this writing I didn't make any way to affect this.

Success calls also return a C<message_id>, which can be accessed using a shortcut C<$r->message_id> syntax. See L<Response class|Amazon::SES::Response>.

Sample successful response looks like this in JSON:

    {
        "MessageId": "00000141344ce1a8-0664c3c5-e9a0-4b47-aa2e-12b0bdf6070e-000000"
    }

Sample error response looks like as:

    {
        "Error": {
            "Code":     "MessageRejected",
            "Type":     "Sender",
            "Message":  "Email address is not verified."
        },
        "xmlns":    "http://ses.amazonaws.com/doc/2010-12-01/",
        "RequestId":"0d04b41a-20dd-11e3-b01b-51d07c103915"
    }


=head2 verify_email($email)

Verifies a given C<$email> with AWS SES. This results a verification e-mail be sent from AWS to the e-mail with a verification link, which must be clicked before this e-mail address appears in C<From> header. Returns a L<Response|Amazon::SES::Response> instance.

Sample successful response:

    {}      # right, it's empty.

=head2 list_emails()

Retrieves list e-mail addresses. Returns L<Response|Amazon::SES::Response> instance.

Sample response:

    {
        "Identities": ["example@example.com", "sample@example.com"]
    }

=head2 list_domains()

Retrieves list of domains. Returns L<Response|Amazon::SES::Response> instance.

    {
        "Identities": ["example1.com", "example2.com"]
    }

=head2 delete_email($email)

=head2 delete_domain($domain)

Deletes a given email or domain name from the SES. Once the identity is deleted you cannot use it in your C<From> headers. Returns L<Response|Amazon::SES::Response> instance.

Sample response:

    { }     # empty


=head2 get_quota()

Gets your quota. Returns L<Response|Amazon::SES::Response> instance.

Sample response:

    {
        "Max24HourSend":    "10000.0",
        "MaxSendRate":      "5.0",
        "SentLast24Hours":  "15.0"
    }


=head2 get_statistics()

Gets your usage statistics. Returns L<Response|Amazon::SES::Response> instance.

Sample response:

    "SendDataPoints" : {
      "member" : [
         {
            "Rejects" : "0",
            "Timestamp" : "2013-09-14T13:07:00Z",
            "Complaints" : "0",
            "DeliveryAttempts" : "1",
            "Bounces" : "0"
         },
         {
            "Rejects" : "0",
            "Timestamp" : "2013-09-17T09:37:00Z",
            "Complaints" : "0",
            "DeliveryAttempts" : "2",
            "Bounces" : "0"
         },
         {
            "Rejects" : "0",
            "Timestamp" : "2013-09-17T10:07:00Z",
            "Complaints" : "0",
            "DeliveryAttempts" : "4",
            "Bounces" : "0"
         },
         # ..................
      ]
   }

=head2 get_dkim_attributes($email)

=head2 get_dkim_attributes($domain)

    {
        "DkimAttributes":[{
            "entry":{
                "value": {
                    "DkimEnabled":"true",
                    "DkimTokens":["iz26kxoyadfasfsafdsafg42jjh33gpcm","adtzf6s4edagadsfasdfsafsafr7rhvcf2c","yybjqlduafasfsafdsfc3a33dzqyyfr"],
                    "DkimVerificationStatus":"Success"
                },
                "key":"example@example.com"
            }
        }]
    }

=head1 ADVANCED API CALLS

Methods documented in this library are shortcuts for C<call()> method, which is a direct interface to AWS SES. So if there is an API call that you need which does not have a shortcut here, use the C<call()> method instead. For example, instead of using C<send($message)> as above, you could've done:

    my $response = $self->call( 'SendRawEmail', {
        'RawMessage.Data' => encode_base64( $msg->stringify )
    } );

Those of you who are familiar with SES API will notice that you didn't have to pass any C<Timestamp>, C<AccessKey>, or sign your message with your C<SecretKey>. This library does it for you. You just have to pass the data that is documented in the SES API reference.

=head1 TODO

=over 4

=item *

Ideally all API calls must returns their own respective responce instances, as opposed to a common L<Amazon::SES::Response|Amazon::SES::Response>.

=item *

All documented API queries must have respective methods in the library.

=back

=head1 SEE ALSO

L<Net::AWS::SES> which this module was based on.

L<JSON>, L<MIME::Base64>, L<Digest::HMAC_SHA1>, L<LWP::UserAgent>, L<Amazon::SES::Response>, L<XML::Simple>

=head1 AUTHOR

Rusty Conover rusty@luckydinosaur.com

Sherzod B. Ruzmetov E<lt>sherzodr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Lucky Dinosaur, LLC. http://www.luckydinosaur.com

Portions Copyright (C) 2013 by L<Talibro LLC|https://www.talibro.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
