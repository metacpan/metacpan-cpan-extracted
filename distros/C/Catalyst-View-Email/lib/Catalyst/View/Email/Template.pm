package Catalyst::View::Email::Template;

use Moose;
use Carp;
use Scalar::Util qw/ blessed /;
extends 'Catalyst::View::Email';

our $VERSION = '0.36';
$VERSION = eval $VERSION;
=head1 NAME

Catalyst::View::Email::Template - Send Templated Email from Catalyst

=head1 SYNOPSIS

Sends templated mail, based upon your default view. It captures the output
of the rendering path, slurps in based on mime-types and assembles a multi-part
email using L<Email::MIME::Creator> and sends it out.

=head1 CONFIGURATION

WARNING: since version 0.10 the configuration options slightly changed!

Use the helper to create your view:
    
    $ script/myapp_create.pl view Email::Template Email::Template

For basic configuration look at L<Catalyst::View::Email/CONFIGURATION>.

In your app configuration (example in L<YAML>):

    View::Email::Template:
        # Optional prefix to look somewhere under the existing configured
        # template  paths.
        # Default: none
        template_prefix: email
        # Define the defaults for the mail
        default:
            # Defines the default view used to render the templates.
            # If none is specified neither here nor in the stash
            # Catalysts default view is used.
            # Warning: if you don't tell Catalyst explicit which of your views should
            # be its default one, C::V::Email::Template may choose the wrong one!
            view: TT

=head1 SENDING EMAIL

Sending email works just like for L<Catalyst::View::Email> but by specifying 
the template instead of the body and forwarding to your Email::Template view:

    sub controller : Private {
        my ( $self, $c ) = @_;

        $c->stash->{email} = {
            to          => 'jshirley@gmail.com',
            cc          => 'abraxxa@cpan.org',
            from        => 'no-reply@foobar.com',
            subject     => 'I am a Catalyst generated email',
            template    => 'test.tt',
            content_type => 'multipart/alternative'
        };
        
        $c->forward( $c->view('Email::Template') );
    }

Alternatively if you want more control over your templates you can use the following idiom
to override the defaults. If charset and encoding given, the body become properly encoded.

    templates => [
        {
            template        => 'email/test.html.tt',
            content_type    => 'text/html',
            charset         => 'utf-8',
            encoding        => 'quoted-printable',
            view            => 'TT', 
        },
        {
            template        => 'email/test.plain.mason',
            content_type    => 'text/plain',
            charset         => 'utf-8',
            encoding        => 'quoted-printable',
            view            => 'Mason', 
        }
    ]



=head1 HANDLING ERRORS

See L<Catalyst::View::Email/HANDLING ERRORS>.

=cut

# here the defaults of Catalyst::View::Email are extended by the additional
# ones Template.pm needs.

has 'stash_key' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { "email" },
    lazy    => 1,
);

has 'template_prefix' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { '' },
    lazy    => 1,
);

has 'default' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            view         => 'TT',
            content_type => 'text/html',
        };
    },
    lazy => 1,
);

# This view hitches into your default view and will call the render function
# on the templates provided.  This means that you have a layer of abstraction
# and you aren't required to modify your templates based on your desired engine
# (Template Toolkit or Mason, for example).  As long as the view adequately
# supports ->render, all things are good.  Mason, and others, are not good.

#
# The path here is to check configuration for the template root, and then
# proceed to call render on the subsequent templates and stuff each one
# into an Email::MIME container.  The mime-type will be stupidly guessed with
# the subdir on the template.
#

# Set it up so if you have multiple parts, they're alternatives.
# This is on the top-level message, not the individual parts.
#multipart/alternative

sub _validate_view {
    my ( $self, $view ) = @_;

    croak "C::V::Email::Template's configured view '$view' isn't an object!"
      unless ( blessed($view) );

    croak
      "C::V::Email::Template's configured view '$view' isn't an Catalyst::View!"
      unless ( $view->isa('Catalyst::View') );

    croak
"C::V::Email::Template's configured view '$view' doesn't have a render method!"
      unless ( $view->can('render') );
}

=head1 METHODS

=over 4

=item generate_part

Generates a MIME part to include in the email. Since the email is template based
every template piece is a separate part that is included in the email.

=cut

sub generate_part {
    my ( $self, $c, $attrs ) = @_;

    my $template_prefix      = $self->template_prefix;
    my $default_view         = $self->default->{view};
    my $default_content_type = $self->default->{content_type};
    my $default_charset      = $self->default->{charset}; 

    my $view;

    # use the view specified for the email part
    if (   exists $attrs->{view}
        && defined $attrs->{view}
        && $attrs->{view} ne '' )
    {
        $view = $c->view( $attrs->{view} );
        $c->log->debug(
            "C::V::Email::Template uses specified view $view for rendering.")
          if $c->debug;
    }

    # if none specified use the configured default view
    elsif ($default_view) {
        $view = $c->view($default_view);
        $c->log->debug(
            "C::V::Email::Template uses default view $view for rendering.")
          if $c->debug;
    }

    # else fallback to Catalysts default view
    else {
        $view = $c->view;
        $c->log->debug(
"C::V::Email::Template uses Catalysts default view $view for rendering."
        ) if $c->debug;
    }

    # validate the per template view
    $self->_validate_view($view);

    # prefix with template_prefix if configured
    my $template =
      $template_prefix ne ''
      ? join( '/', $template_prefix, $attrs->{template} )
      : $attrs->{template};

    # setup the attributes (merge with defaults)
    my $e_m_attrs = $self->SUPER::setup_attributes( $c, $attrs );

    # render the email part
    my $output = $view->render(
        $c,
        $template,
        {
            content_type => $e_m_attrs->{content_type},
            stash_key    => $self->stash_key,
            %{$c->stash},
        }
    );
    if ( ref $output ) {
        croak $output->can('as_string') ? $output->as_string : $output;
    }

    if ( exists $e_m_attrs->{encoding} 
        && defined $e_m_attrs->{encoding} 
        && exists $e_m_attrs->{charset} 
        && defined $e_m_attrs->{charset} ) {

        return Email::MIME->create(
            attributes => $e_m_attrs,
            body_str   => $output,
        );

    } else {

        return Email::MIME->create(
            attributes => $e_m_attrs,
            body       => $output,
        );
    }
}

=item process

The process method is called when the view is dispatched to. This creates the
multipart message and then sends the message contents off to
L<Catalyst::View::Email> for processing, which in turn hands off to
L<Email::Sender::Simple>.

=cut

around 'process' => sub {
    my ( $orig, $self, $c, @args ) = @_;
    my $stash_key = $self->stash_key;
    return $self->$orig( $c, @args )
      unless $c->stash->{$stash_key}->{template}
          or $c->stash->{$stash_key}->{templates};

    # in case of the simple api only one
    my @parts = ();

    # now find out if the single or multipart api was used
    # prefer the multipart one

    # multipart api
    if (   $c->stash->{$stash_key}->{templates}
        && ref $c->stash->{$stash_key}->{templates} eq 'ARRAY'
        && ref $c->stash->{$stash_key}->{templates}[0] eq 'HASH' )
    {

        # loop through all parts of the mail
        foreach my $part ( @{ $c->stash->{$stash_key}->{templates} } ) {
            push @parts,
              $self->generate_part(
                $c,
                {
                    view         => $part->{view},
                    template     => $part->{template},
                    content_type => $part->{content_type},
                    charset      => $part->{charset},
                    encoding     => $part->{encoding},
                 }
              );
        }
    }

    # single part api
    elsif ( $c->stash->{$stash_key}->{template} ) {
        my $part_args = { template => $c->stash->{$stash_key}->{template} };
        if (my $ctype = $c->stash->{$stash_key}->{content_type}) {
            $part_args->{content_type} = $ctype;
        }
        push @parts,
          $self->generate_part( $c, $part_args );
    }

    delete $c->stash->{$stash_key}->{body};
    $c->stash->{$stash_key}->{parts} ||= [];
    push @{ $c->stash->{$stash_key}->{parts} }, @parts;
    
    return $self->$orig($c);

};

=back

=head1 TODO

=head2 ATTACHMENTS

There needs to be a method to support attachments.  What I am thinking is
something along these lines:

    attachments => [
        # Set the body to a file handle object, specify content_type and
        # the file name. (name is what it is sent at, not the file)
        { body => $fh, name => "foo.pdf", content_type => "application/pdf" },
        # Or, specify a filename that is added, and hey, encoding!
        { filename => "foo.gif", name => "foo.gif", content_type => "application/pdf", encoding => "quoted-printable" },
        # Or, just a path to a file, and do some guesswork for the content type
        "/path/to/somefile.pdf",
    ]

=head1 SEE ALSO

=head2 L<Catalyst::View::Email> - Send plain boring emails with Catalyst

=head2 L<Catalyst::Manual> - The Catalyst Manual

=head2 L<Catalyst::Manual::Cookbook> - The Catalyst Cookbook

=head1 AUTHORS

J. Shirley <jshirley@gmail.com>

Simon Elliott <cpan@browsing.co.uk>

Alexander Hartmaier <abraxxa@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
