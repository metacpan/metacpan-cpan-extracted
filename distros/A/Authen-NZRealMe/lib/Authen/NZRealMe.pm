package Authen::NZRealMe;
$Authen::NZRealMe::VERSION = '1.18';
use warnings;
use strict;


=head1 NAME

Authen::NZRealMe - Integrate with RealMe login and identity services (formerly "igovt logon")

=head1 DESCRIPTION

Provides an API for integrating your application with the New Zealand RealMe
login service and the RealMe assertion service (for verified identity and
address details) using SAML 2.0 messaging.

Note: This distribution was renamed from Authen::NZigovt following the
rebranding of the service from "igovt" to "RealMe".  When migrating systems to
use the new module, it will be necessary to rename some of the config files to
the new names listed under L</CONFIGURATION> below.

The distribution also includes a command-line tool called C<nzrealme> which can
be used for:

=over 4

=item *

generating certificate/key pairs for signing and SSL encryption

=item *

creating/editing the Service Provider metadata file

=item *

creating a bundle (zip file) containing metadata and certs for upload to the
IdP

=item *

generating AuthnRequest URLs

=item *

decoding/dumping AuthnRequest URLs

=item *

resolving SAMLart artifact responses and validating the response

=back

Run C<< nzrealme --help >> for more information about using the command-line
tool.

=cut


my %class_map = (
    service_provider        => 'Authen::NZRealMe::ServiceProvider',
    identity_provider       => 'Authen::NZRealMe::IdentityProvider',
    token_generator         => 'Authen::NZRealMe::TokenGenerator',
    xml_signer              => 'Authen::NZRealMe::XMLSig',
    sp_builder              => 'Authen::NZRealMe::ServiceProvider::Builder',
    sp_cert_factory         => 'Authen::NZRealMe::ServiceProvider::CertFactory',
    resolution_request      => 'Authen::NZRealMe::ResolutionRequest',
    icms_resolution_request => 'Authen::NZRealMe::ICMSResolutionRequest',
    resolution_response     => 'Authen::NZRealMe::ResolutionResponse',
    authen_request          => 'Authen::NZRealMe::AuthenRequest',
    logon_strength          => 'Authen::NZRealMe::LogonStrength',
);


sub service_provider {
    my $class = shift;

    return $class->class_for('service_provider')->new(@_);
}


sub _sp_from_opt {
    my $class      = shift;
    my $opt        = shift;

    my $service_type = $opt->{type} || "login";
    my %sp_options = (
        conf_dir  => _conf_dir($opt),
        type      => $service_type,
    );
    $sp_options{disable_ssl_verify} = $opt->{disable_ssl_verify} if $opt->{disable_ssl_verify};
    return $class->service_provider(%sp_options);
}


sub class_for {
    my($class, $key) = @_;
    my $module = $class_map{$key} or die "No class defined for '$key'";
    $module =~ s{::}{/}g;
    require $module . '.pm';
    return $class_map{$key};
}


sub register_class {
    my($class, $key, $package) = @_;
    $class_map{$key} = $package;
}


sub run_command {
    my $class   = shift;
    my $opt     = shift;
    my $command = shift or die "no command specified\n";

    my $method = '_dispatch_' . $command;
    $method =~ s{[^a-z0-9]+}{_}g;
    die "unrecognised command: '$command'\n" unless $class->can($method);

    $class->$method($opt, @_);
}


sub _dispatch_make_certs {
    my($class, $opt) = @_;

    my %args;
    foreach my $key (qw(env org org_unit domain subject_suffix self_signed)) {
        $args{$key} = $opt->{$key} if defined $opt->{$key};
    }
    $class->class_for('service_provider')->generate_certs(
        _conf_dir($opt), %args
    );
}


sub _dispatch_make_meta {
    my($class, $opt) = @_;

    $class->class_for('service_provider')->build_meta(
        conf_dir => _conf_dir($opt)
    );
}


sub _dispatch_make_bundle {
    my($class, $opt) = @_;

    my $file = $class->class_for('service_provider')->make_bundle(
        conf_dir => _conf_dir($opt),
    );
    print "Created metadata bundle for IDP at: $file\n";
}


sub _dispatch_make_req {
    my($class, $opt) = @_;

    my $sp  = $class->_sp_from_opt($opt);
    my @req_options;
    if($sp->type eq 'login') {
        my $allow_create = $opt->{allow_create} ? 1 : 0;
        push @req_options, allow_create => $allow_create;
    }
    my $req = $sp->new_request( @req_options );

    print "Request ID: ", $req->request_id, "\n" if -t 1;
    print $req->as_url, "\n";
}


sub _dispatch_dump_req {
    my $class = shift;
    my $opt   = shift;

    $class->class_for('authen_request')->dump_request(@_);
}


sub _dispatch_resolve {
    my $class      = shift;
    my $opt        = shift;
    my $artifact   = shift or die "Must provide artifact or URL\n";
    my $request_id = shift or die "Must provide ID from original request\n";

    my $sp   = $class->_sp_from_opt($opt);
    my %args = (
        artifact   => $artifact,
        request_id => $request_id,
    );
    $args{resolve_flt}    = 1 if $opt->{resolve_flt};
    $args{logon_strength} = shift if @_;
    $args{strength_match} = shift if @_;
    $args{_to_file_}      = $opt->{to_file}   if $opt->{to_file};
    $args{_from_file_}    = $opt->{from_file} if $opt->{from_file};
    my $response = eval {
        $sp->resolve_artifact(%args);
    };
    if($@) {
        print "Failed to resolve artifact:\n$@";
        exit 1;
    }
    print $response->as_string();
}


sub _dispatch_version {
    print $Authen::NZRealMe::VERSION, "\n";
}


sub _conf_dir {
    my($opt) = @_;

    if($opt->{conf_dir}) {
        $opt->{conf_dir} =~ s{/\z}{};
        return $opt->{conf_dir} if -d $opt->{conf_dir};
        die "Directory does not exist: $opt->{conf_dir}";
    }
    my $cmnd = (caller(1))[3];
    $cmnd =~ s/^.*::_dispatch_//;
    $cmnd =~ s/_/-/g;
    die "$cmnd command needs --conf-dir option\n";
}

1;


__END__


=head1 GETTING STARTED

You cannot simply drop some config files in a directory and start
authenticating users.  Your agency will need to establish a Service Provider
role with the logon service and complete the required integration steps.  Your
first step should be to make contact with the DIA/RealMe team and arrange a
meeting.


=head1 CODE INTEGRATION

To integrate the RealMe login service with your application, you will need to:

=over 4

=item 1

complete a number of configuration steps (see L</CONFIGURATION> below)

=item 2

link this module into your application to initiate the logon (by redirecting
the user to the RealMe login service) and to 'consume' the login information
when the user is redirected back to your site

=back

To understand how this module must be linked into your application, it helps to
understand the SAML protocol interaction that is followed for each user logon:

  Agency Web Site                                 RealMe login server

                     .-------------------------.
                     | 1. user visits agency   |
               .-----|    web site and clicks  |
               |     |   'RealMe login' button |
               v     '-------------------------'
  .-------------------------.
  | 2. SAML AuthnRequest    |
  |    passed back to user  |-------------------------.
  |    via 302 redirect     |                         v
  '-------------------------'           .--------------------------.
   API call                             | 3. Logon service prompts |
                                   .----|    for username/password |
                                   v    '--------------------------'
                      .------------------------.
                      | 4. user enters         |
                      |    username/password   |------.
                      '------------------------'      v
                                        .--------------------------.
                                        | 5. SAML 'artifact'       |
              .-------------------------|    returned via redirect |
              v                         '--------------------------'
 .-------------------------.
 | 6. SAML ArtifactResolve |
 |    sent direct to IdP   |--------------------------.
 '-------------------------'                          v
  API call                              .--------------------------.
                                        | 7. SAML ArtifactResponse |
              .-------------------------|    sent back to SP       |
              v                         '--------------------------'
 .-------------------------.
 | 8. FLT to identify user |
 |    extracted from resp. |
 '-------------------------'
  API call returns

The RealMe login server is a SAML Identity Provider or 'IdP'.  However the only
attribute the login service provides is the 'Federated Logon Tag' - a unique
identifier associating the user's login account with the agency web site.

The RealMe assertion server is also a SAML IdP and can be accessed using the
same process described above.  The response returned from the assertion server
will include details of the user's verified identity and/or address (the user
must first consent to sharing the requested details).

The agency web site is a SAML Service Provider or 'SP'.  The Authen::NZRealMe
module implements the SAML SP role on behalf of the agency web app.

To integrate this module with your application, you need to make two calls to
its API: the first to generate the authentication request (step 2 above) and
the second to resolve the returned artifact and return the Federated Logon Tag
(FLT) which identifies the user (steps 6 thru 8).

It is your responsibility to create a persistent association in your
application data store between your user record and the RealMe FLT for that
user.

=head2 Authentication Request

You will add the RealMe login button image to your application templates.  The
button does not link directly to the RealMe login server, but instead links to
your application which in turn uses the Authen::NZRealMe module to generate a
SAML AuthnRequest message encoded in a URL and returns it as a 302 redirect.

The request includes a unique 'Request ID' which you must save in the user
session for use when resolving the artifact response later.  The example below
uses generic framework method calls to save the Request ID and return the
redirect URL, you will need to replace these with specific calls for the
framework you are using:

  use Authen::NZRealMe;

  my $sp  = Authen::NZRealMe->service_provider(
      type      => 'login',
      conf_dir  => $path_to_config_directory
  );
  my $req = $sp->new_request(
      allow_create => 0,         # set to 1 for initial registration
      # other options here
  );

  $framework->set_state(login_request_id => $req->request_id);

  return $framework->redirect($req->as_url);  # Use HTTP status 302

Your code does not need to explicitly reference the RealMe login service domain
or URL - these details are handled automatically by the configuration.

If you wish to use the assertion service rather than the login service, simply
change the C<type> parameter when creating the service_provider object:

  my $sp  = Authen::NZRealMe->service_provider(
      type      => 'assertion',
      conf_dir  => $path_to_config_directory
  );

=head2 Artifact Resolution

Once the user has provided a valid username and password to the logon service,
they will be redirected back to your application and an 'artifact' will be
passed in a URL parameter called 'SAMLart'.  You set up which URL you want the
logon service to redirect back to when you generate your service provider
metadata (see L</CONFIGURATION>).  This URL is known as the Assertion Consumer
Service or 'ACS'.

A single method call is used to:

=over 4

=item *

generate a SAML ArtifactResolve message

=item *

pass it to the IdP over a backchannel

=item *

accept the SAML ArtifactResponse message

=item *

validate the assertion

=item *

extract and return the attributes (or error detail) in a response object

=back

The method call will return a response object containing either the attribute
details or details of the condition which meant the logon was unsuccessful.  In
the case of an unexpected error, the method call will generate an exception
which you will need to catch and log.

A response from the login service will only include an FLT attribute, whereas a
response from the assertion service may contain a number of identity attributes.
See L<Authen::NZRealMe::ResolutionResponse> for details of methods provided to
access the attribute values.

  my $sp   = Authen::NZRealMe->service_provider( conf_dir => $path_to_config_directory );
  my $resp = eval {
      $sp->resolve_artifact(
          artifact   => $framework->param('SAMLart'),
          request_id => $framework->get_state('login_request_id'),
      );
  };
  if($@) {
      # handle catastrophic failures (e.g.: malformed response) here
  }
  if($resp->is_success) {
      $framework->set_state(login_flt => $resp->flt);
      # ... redirect to main menu etc
  }
  elsif($resp->is_timeout) {
      # Present logon screen again with message
  }
  elsif($resp->is_cancel) {
      # Present logon screen again with message
  }
  elsif($resp->is_not_registered) {
      # Only happens if allow_create set to false
      # and user does not have a logon for our site
  }
  else {
      # Some other failure occurred, user might like to try again later.
      # Should present $resp->status_message to user and also give contact
      # details for RealMe Help Desk
  }

Note: there are two different categories of 'error': the C<resolve_artifact()>
method might throw an exception (caught by eval, details in $@); or a response
object might be returned but with C<< $resp->is_success >> set to false.  The
details of an exception should be logged, but not displayed back to the user.
In the event that your application displays the contents of
C<< $resp->status_message >> you should ensure that you apply appropriate HTML
escaping.

For reference documentation about the Service Provider API, see
L<Authen::NZRealMe::ServiceProvider>.


=head1 CONFIGURATION

This module is configuration-driven - when making an API call, you specify the
path to the config directory and the module picks up everything it needs to
talk to the RealMe login service IdP (Identity Provider) from metadata files
and certificate/key-pair files used for signing/encryption.

=head2 Config Files Overview

The files in the config directory use the following naming convention so you
just need to point the module at the right directory.  The filenames are:

=over 4

=item C<metadata-login-sp.xml>

This file contains config parameters for the 'Service Provider' - your end of
the authentication dialog - which will talk to the login service.  Once you
have generated the SP metadata file (see: L</Generating Config Files>) you will
need to provide it to the RealMe logon service to install at their end.  You
will need to generate separate metadata files for each of your development,
staging and production environments.

=item C<metadata-login-idp.xml>

The login service IdP or Identity Provider metadata file will be provided to
you by RealMe/DIA.  You will simply need to copy it to the config directory and
give it the correct name.

=item C<metadata-assertion-sp.xml>

This file is only required if you are using the assertion service and can be
omitted if you are only using the login service.

This file contains config parameters for the 'Service Provider' - your end of
the authentication dialog - which will talk to the assertion service.  Once you
have generated the SP metadata file (see: L</Generating Config Files>) you will
need to provide it to the RealMe logon service to install at their end.  You
will need to generate separate metadata files for each of your development,
staging and production environments.

=item C<metadata-assertion-idp.xml>

This file is only required if you are using the assertion service and can be
omitted if you are only using the login service.

The assertion service IdP or Identity Provider metadata file will be provided
to you by RealMe/DIA.  You will simply need to copy it to the config directory
and give it the correct name.

=item C<metadata-icms.wsdl>

This file is only required if you are both using the assertion service and need
to resolve the opaque token into an FLT.  It can be omitted if you are only
using the login service or do not need the user's FLT.

The WSDL file will be provided to you by RealMe/DIA.  You will simply need to
copy it to the config directory and give it the correct name.

=item C<sp-sign-crt.pem>

This certificate file is used for generating digital signatures for the SP
metadata file and SAML authentication requests.  For your initial integration
with the RealMe login service development IdP ('MTS'), certificate key-pair
files will be provided to you.  For staging (ITE) and production, you will need
to generate your own and provide the certificate files (not the private key
files) to the RealMe login service.

=item C<sp-sign-key.pem>

This private key is paired with the F<sp-sign-crt.pem> certificate.

=item C<sp-ssl-crt.pem>

This certificate is used for negotiating an SSL connection on the backchannel
to the IdP artifact resolution service.

=item C<sp-ssl-key.pem>

This private key is paired with the F<sp-ssl-crt.pem> certificate.

=back

=head2 Generating Config Files

You must first decide which directory your config files will be stored in.
The examples below assume a config directory path of C</etc/nzrealme>.

=head3 Certificates

Once you've decided on a location, you need to generate two SSL certificates
and their corresponding private keys.  The first will be used for signing the
SAML AuthnRequest messages and the second will be used for mutual SSL
encryption of communications over the back-channel.

It is not necessary to generate the certificates on the same machine where
they will be used however you must have the C<openssl> command-line tools
installed on the machine where you wish to generate them.

The process for generating certificates will depend on which environment you
are connecting to:

=over 4

=item MTS (Development)

You do not need to generate certificates at all for the MTS environment -
simply use the files provided in the MTS integration resources pack.  Copy them
into your config directory and rename as follows:

  mts_mutualssl_saml_sp.pem => sp-sign-key.pem
  mts_mutualssl_saml_sp.cer => sp-sign-crt.pem
  mts_saml_sp.pem           => sp-ssl-key.pem
  mts_saml_sp.cer           => sp-ssl-crt.pem

=item ITE (Staging)

For the ITE environment you can generate self-signed certs.  The C<nzrealme>
tool can prompt you interactively for the required parameters:

  nzrealme --conf-dir /etc/nzrealme make-certs

or you can provide them on the command-line:

  nzrealme --conf-dir /etc/nzrealme make-certs --env ITE \
    --org="Department of Innovation" --domain="innovation.govt.nz"

=item PROD (Production)

For the production environment you can use the C<nzrealme> tool to generate
Certificate Signing Requests which you will then submit to a Certification
Authority who will issue signed certificate files.  Save them in the config
directory using the filenames listed above.

  nzrealme --conf-dir /etc/nzrealme make-certs --env PROD ...

=back

=head3 SP Metadata

After you have generated the certificates, you can generate a metadata file
with the command:

  nzrealme --conf-dir /etc/nzrealme make-meta

You will be prompted to provide the necessary details and can re-run the
command to revise your answers.

Note: You can't simply edit the XML metadata file, because a digital signature
is added when the file is saved.

You will need to provide the SP metadata file to the RealMe login service (via
an upload to the shared workspace).  For ITE and PROD you will also need to
provide the certificate files.  You can assemble a 'bundle' of the required
files with this command:

  nzrealme --conf-dir /etc/nzrealme make-bundle


=head1 TESTING

Normally your application would generate an authentication request URL and
redirect the client to it, however it is also possible to generate one from the
command-line:

  nzrealme --conf-dir /etc/nzrealme make-req

You can paste this URL into a browser and complete a log on.  Once you have
logged on you will be redirected back to the URL for the ACS (as specified in
the SP metadata file that you uploaded).  You can copy the ACS URL from your
browser and paste it into the following command to resolve the artifact passed
in the URL to an FLT:

  nzrealme --conf-dir /etc/nzrealme resolve <ACS URL> <Request ID>

The ACS URL will contain special characters that may need to be quoted.  You'll
also need to supply the Request ID which was output by the original C<make-req>
command.


=head1 API REFERENCE

The C<Authen::NZRealMe> class provides entry points for interactions with the
RealMe login service and is also responsible for dispatching the various
command implemented by the C<nzrealme> command-line utility.

=head2 service_provider( conf_dir => $path_to_config_directory )

This method is the main entry point for the API.  It returns a service_provider
object that will then be used to generate AuthnRequest messages and to resolve
the returned artifacts.  Unless you have set up alternative class mappings (see
below), this method is a simple wrapper for the
L<Authen::NZRealMe::ServiceProvider> constructor.

=head2 class_for( identifier )

This method forms half of a simple dependency injection framework.  Rather
than hard-code the classnames for the various parts of the API, this method
is used to turn a simple functional name (e.g.: C<'service_provider'>) into a
classname like C<Authen::NZRealMe::ServiceProvider>.  This method will also
load the package using C<require>.

You would not usually call this method directly - instead you would use the
C<service_provider> method which calls this.

=head2 register_class( identifier => package )

This method forms the other half of the dependency injection implementation
and is used to override the default mappings.  The most common reason to use
this method is to inject mock object classnames for use during automated
testing.

=head2 run_command( command, args )

This method is called by the C<nzrealme> command-line tool, to delegate tasks to
the appropriate classes.  For more information about available commands, see
C<< nzrealme --help >>

=cut

=head2 Related Classes

Your application should only need to directly interface with the Service
Provider module (as shown above).  The service provider will delegate to other
classes as required.  Reference documentation is available for these other
classes.

=over 4

=item *

L<Authen::NZRealMe::ServiceProvider>

=item *

L<Authen::NZRealMe::ServiceProvider::Builder>

=item *

L<Authen::NZRealMe::ServiceProvider::CertFactory>

=item *

L<Authen::NZRealMe::IdentityProvider>

=item *

L<Authen::NZRealMe::AuthenRequest>

=item *

L<Authen::NZRealMe::ResolutionRequest>

=item *

L<Authen::NZRealMe::ResolutionResponse>

=item *

L<Authen::NZRealMe::ICMSResolutionRequest>

=item *

L<Authen::NZRealMe::LogonStrength>

=item *

L<Authen::NZRealMe::TokenGenerator>

=item *

L<Authen::NZRealMe::XMLSig>

=back


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Authen::NZRealMe

You can also look for information at:

=over 4

=item * Issue tracker on github

L<https://github.com/catalyst/Authen-NZRealMe/issues>

=item * Source code repository on GitHub

L<https://github.com/grantm/Authen-NZRealMe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-NZRealMe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-NZRealMe>

=item * Search CPAN

L<http://search.cpan.org/dist/Authen-NZRealMe/>

=back

Commercial support and consultancy is available through Catalyst IT Limited
L<http://www.catalyst.net.nz>.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2019 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt> and
Haydn Newport E<lt>haydn@catalyst.net.nzE<gt>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

