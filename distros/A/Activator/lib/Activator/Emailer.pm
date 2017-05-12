package Activator::Emailer;

use strict;
use Email::Send;
use MIME::Lite;
use Template;
use Activator::Registry;
use Exception::Class::TryCatch;
use Data::Dumper;
use Hash::Merge;
use Activator::Log qw( :levels );

=head1 NAME

Activator::Emailer - Send emails from anywhere within a project in the same way using role-based configuration.

=head1 SYNOPSIS

Configure defaults with Activator::Registry configuration (See
L<CONFIGURATION>), then:

  use Activator::Emailer;
  my $tt_vars = { data => 'any data your template needs',
                  other_data => $my_data,
                };
  my $mailer = Activator::Emailer->new(
     To          => 'person@test.com',
     Cc          => 'other@test.com, other2@test.com'
     Subject     => 'Test Subject',
  );
  $mailer->send( $tt_vars );

Reuse the mailer object to send another mail to someone else using a different
body template, plus an attachment:

  $mailer->set_cc( '' );
  $mailer->set_to( 'someone_else@other-domain.com' );
  $mailer->set_html_body( '/path/to/html_body.tt' );
  $tt_vars = $my_alternate_data_hashref;
  $mailer->attach( Type        => 'application/pdf',
                   Path        => 'path/to/doc.pdf',
                   Filename    => 'doc.pdf',
                   Disposition => 'attachment' );
  $mailer->send( $tt_vars );

=head1 DESCRIPTION

C<Activator::Emailer> is a simple wrapper to L<Mime::Lite>,
L<Template::Toolkit> and L<Email::Send> that uses your project's
L<Activator::Registry> to facilitate easy sending of multipart
text/html email from any module in your project. Emailer can talk to
any MTAs that L<Email::Send> can.

=head2 Full Example

  use Activator::Emailer;
  my $tt_vars = { data => $my_data,
                  other_data => 'any data your template needs'
                };
  my $mailer = Activator::Emailer->new(
     From        => 'no-reply@test.com',
     To          => 'person@test.com',
     Cc          => 'other@test.com, other2@test.com'
     Subject     => 'Test Subject',
     html_header => '/path/to/html_header.tt',
     html_body   => '/path/to/html_body.tt',
     html_footer => '/path/to/html_footer.tt',
     email_wrap  => '/path/to/email/wrapper/template',
     mailer_type => 'Gmail',
     mailer_args => [ username => 'user@gmail.com',
                      password => '123456'
                    ],
  );
  $mailer->attach( Type        => 'application/pdf',
                   Path        => 'path/to/doc.pdf',
                   Filename    => 'invoice.pdf',
                   Disposition => 'attachment'
  $mailer->send( $tt_vars );

The next section shows how to simplify this.

=head1 CONFIGURATION

As is seen in the previous section, a lot of information is needed to
send an email. Fortunately, most of the information is reusable. You
can utilize L<Activator::Registry> to simplify creation of emails:

  'Activator::Registry':
    'Activator::Emailer': 
      From: noreply@domain.com
      mailer_type: Gmail     # any of the send methods Email::Send supports
      mailer_args:           # any of the args required by your Email::Send::<TYPE>
        - username: <username>
        - password: <password>
      html_header: /fully/qualified/path/to/header/tt/template
      html_footer: relative/path/to/footer/tt/template
      html_body:   relative/path/to/body/tt/template
      email_wrap:  /path/to/email/wrapper/template
      tt_options:
        INCLUDE_PATH: /path/to/tt/templates

In the simplist case, you can now send as such:

  my $mailer = Activator::Emailer->new(
     To          => 'person@test.com',
     Subject     => 'Test Subject',
  );
  $mailer->send( { data => $my_data } );


=head1 TEMPLATES SETUP

You must create 4 template for emails to work. Each template has a
variable C<Activator_Emailer_format> available so you can do HTML or text
specific template blocks. Note that it is suggested that you utilize
the TT chomping close tag (C<-%]>) to maintain format.

=head2 File 1: html_header

This is the most basic header, but you can add as much HTML as you
like, including limited style and script tags:

 <html>
 <body>

=head2 File 2: html_body

Put whatever html you like in this section.

 <h1>Body</h1>
 <p>This is only an example</p>
 [% IF Activator_Emailer_format == 'text' -%]
 ========================================
 [% ELSE -%]
 <hr>
 [% END -%]

=head2 File 3: html_footer

This is the most basic footer, but you can add as much HTML as you like:

 </body>
 </html>

=head2 File 4: email_wrap.tt

Copy this verbatim, trim the leading space:

  [% USE HTML.Strip -%]
  [% BLOCK html_header -%]
  [% INCLUDE html_header %]
  [% END -%]
  [% BLOCK html_footer %]
  [% INCLUDE html_footer %]
  [% END -%]
  [% BLOCK body -%]
  [% INCLUDE html_body %]
  [% END -%]
  [% IF format == 'text' -%]
  [% FILTER html_strip emit_spaces = 0 -%]
  [% INCLUDE body %]
  [% END -%]
  [% ELSE -%]
  [% INCLUDE html_header -%]
  [% INCLUDE body %]
  [% INCLUDE html_footer -%]
  [% END -%]

Note that you can put the files anywhere. See L<CONFIGURATION> for more details.

=head1 METHODS

=head2 C<new( %args )>

Create an C<Activator::Emailer> object. Valid C<%args> are described below.

=over

=item *

The following are sent directly to L<MIME::Lite>, and likewise
injected directly into the mail header ( hence the capitalization )

 * From - A single email address
 * To - A single email address
 * Subject - A string
 * Cc - A string consisting of a comma separated list of email addresses

=item *

The following are used for sending with L<Email::Send>:

 * mailer_type - Any valid Email::Send subclass
 * mailer_args - Any args to pass to the <mailer_type> class

=item *

The following are used with L<Template::Toolkit>

 * tt_include_path - The INCLUDE_PATH for template toolkit. Useful
                     for reusing project templates within an email

=item *

The following are custom to C<Activator::Emailer>:

 * html_header - A template file or string to use for the top of the
                 HTML portion of the email
 * html_footer - A template file or string to use for the bottom of
                 the HTML portion of the email
 * html_body   - A template file or string to use for the html portion.
                 of the email Also, this will be stripped of all HTML
                 tags ( using HTML::Strip ) and used for the body of
                 the text portion of the email.

=back

=cut

sub new {
    my ( $pkg, %args ) = @_;

    my $config = Activator::Registry->get( 'Activator::Emailer' ) || {};
    my $self = Hash::Merge::merge( \%args, $config );
    bless ( $self ), $pkg;

    $self->{attachments} = [];
    my $args = { mailer => $self->{mailer_type} };
    if ( keys %{ $self->{mailer_args} } ) {
	$args->{mailer_args} = [ %{ $self->{mailer_args} } ];
    }
    $self->{sender} = Email::Send->new( $args );
    return $self;
}

=head2 send( $tt_vars )

Send the email using C<$tt_vars> for the L<Template::Toolkit> C<process> method.

=cut

sub send {
    my ( $self, $tt_vars ) = @_;

    # TODO: test that tt_vars is a hashref

    $tt_vars->{'Activator_Emailer_format'} = 'text';
    $tt_vars->{html_header} = $self->{html_header};
    $tt_vars->{html_body}   = $self->{html_body};
    $tt_vars->{html_footer} = $self->{html_footer};

    my $text_body = '';
    my $html_body = '';

    my $tt = Template->new( $self->{tt_options} ) ||
      Activator::Exception::Emailer->throw( 'tt_new_error', $Template::ERROR, "\n" );

    $tt->process( $self->{email_wrap}, $tt_vars, \$text_body ) ||
      Activator::Exception::Emailer->throw( 'tt_process_error', $tt->error(), "\n" );

    $tt_vars->{'Activator_Emailer_format'} = 'html';
    $tt->process( $self->{email_wrap}, $tt_vars, \$html_body ) ||
      Activator::Exception::Emailer->throw( 'tt_process_error', $tt->error(), "\n" );

    my @email_args = (
		      From    => $self->{From},
		      To      => $self->{To},
		      Cc      => $self->{Cc},
		      Subject => $self->{Subject},
		      SkipBad => 1,
		     );

    push @email_args, ( Type => 'multipart/alternative' );

    my $email = MIME::Lite->new( @email_args );
    $email->attach(
		   Type => 'TEXT',
		   Data => $text_body,
		  );

    $email->attach(
		   Type => 'text/html',
		   Data => $html_body,
		  );

    foreach my $attachment( @{ $self->{attachments} } ) {
	$email->attach( @$attachment );
    }

    DEBUG("----------------------------------------\nCreated email:\n".
	  $email->as_string .
	  "\n----------------------------------------"
	 );

    try eval {
	my $retval = $self->{sender}->send( $email->as_string);
	die $retval unless $retval;
    };
    if ( catch my $e ) {
	Activator::Exception::Emailer->throw( 'send_error', $e );
    }
}

=head2 attach( %args )

Attach an item to this email. When C<send()> is called, C<%args> is
just passed through to the L<MIME::Lite> attach function.

=cut

sub attach {
    my ( $self, %attachment ) = @_;
    push @{ $self->{attachments} }, [ %attachment ];
}

=head2 valid_email ( $email )

Sanity check on the email address. Throws exception on failure.

=cut

sub valid_email {
    my $addr = shift;   

    #characters allowed on name: 0-9a-Z-._ on host: 0-9a-Z-. on between: @
    return 0 if ( $addr !~ /^[0-9a-zA-Z\.\-\_]+\@[0-9a-zA-Z\.\-]+$/ ); 

    #must start or end with alpha or num
    return 0 if ( $addr =~ /^[^0-9a-zA-Z]|[^0-9a-zA-Z]$/); 

    #name must end with alpha or num
    return 0 if ( $addr !~ /([0-9a-zA-Z]{1})\@./ ); 

    #host must start with alpha or num
    return 0 if ( $addr !~ /.\@([0-9a-zA-Z]{1})/ ); 

    #pair .- or -. or -- or .. not allowed
    return 0 if ( $addr =~ /.\.\-.|.\-\..|.\.\..|.\-\-./g ); 

    #pair ._ or -_ or _. or _- or __ not allowed
    return 0 if ( $addr =~ /.\.\_.|.\-\_.|.\_\..|.\_\-.|.\_\_./g ); 

    #host must end with '.' plus 2, 3 or 4 alpha for TopLevelDomain (MUST be modified in future!)
    return 0 if ( $addr !~ /\.([a-zA-Z]{2,4})$/ ); 

    return 1;
}

=head2 setters

Each value that can be passed to C<new()> can be modified by calling
C<set_E<lt>VALUEE<gt>>, where value is lowercased.

=cut

sub set_from {
    my ( $self, $value ) = @_;
    $self->{From} = $value;
}

sub set_to {
    my ( $self, $value ) = @_;
    $self->{To} = $value;
}

sub set_cc {
    my ( $self, $value ) = @_;
    $self->{Cc} = $value;
}

sub set_subject {
    my ( $self, $value ) = @_;
    $self->{Subject} = $value;
}

sub set_html_header {
    my ( $self, $value ) = @_;
    $self->{html_header} = $value;
}

sub set_html_body {
    my ( $self, $value ) = @_;
    $self->{html_body} = $value;
}

sub set_html_footer {
    my ( $self, $value ) = @_;
    $self->{html_footer} = $value;
}

sub set_mailer_type {
    my ( $self, $value ) = @_;
    $self->{mailer_type} = $value;
}

sub set_mailer_args {
    my ( $self, $value ) = @_;
    $self->{mailer_args} = $value;
}

=head1 See Also

L<Activator::Registry>, L<Activator::Exception>, L<MIME::Lite>,
L<Email::Send>, L<Template::Toolkit>, L<Exception::Class::TryCatch>,
L<Class::StrongSingleton>

=head1 AUTHOR

Karim A. Nassar ( karim.nassar@acm.org )

=head1 License

The Activator::Emailer module is Copyright (c) 2007 Karim A. Nassar.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, or as specified in the Perl README file.

=cut


1;
