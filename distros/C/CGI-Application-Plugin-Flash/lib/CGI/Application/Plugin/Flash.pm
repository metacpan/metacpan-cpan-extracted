package CGI::Application::Plugin::Flash;
use Carp;
use CGI::Session::Flash;
use strict;

our $VERSION = "0.02";


# Export our flash functions and set up the necessary CGI::Application
# hooks.
sub import
{
    my $package = shift;
    my $caller  = caller;

    # Export the flash methods
    {
        no strict 'refs';
        *{"$caller\::flash"}        = \&flash;
        *{"$caller\::flash_config"} = \&flash_config;
    }

    return 1;
}

# Retrieve the flash object.  This method also provides a convenient simple
# syntax for setting and getting data from the flash.
sub flash
{
    my $self = shift;
    my $flash;

    # Create the flash object singleton.
    if (!defined $self->{'__CAP_FLASH_OBJECT'})
    {
        croak "Flash requires session support." unless ($self->can("session"));

        $self->{'__CAP_FLASH_OBJECT'} =
            CGI::Session::Flash->new($self->session, $self->flash_config);
    }

    $flash = $self->{'__CAP_FLASH_OBJECT'};

    # Set or get the values for a specific key.
    if (@_)
    {
        my $key = shift;

        if (@_)
        {
            $flash->set($key => @_);
        }

        return $flash->get($key);
    }
    # Return the flash object.
    else
    {
        return $flash;
    }
}

sub flash_config
{
    my $self = shift;

    # Set the values of the configuration.
    if (@_)
    {
        croak "Invalid flash configuration.  Specify a list of name and values." 
            if (@_ % 2 == 1);

        $self->{'__CAP_FLASH_CONFIG'} = { @_ };
    }

    # Return the config.
    my $config = $self->{'__CAP_FLASH_CONFIG'} || { };
    return wantarray ? %$config : $config;
}

1;
__END__

=pod

=head1 NAME

CGI::Application::Plugin::Flash - Session Flash plugin for CGI::Application

=head1 SYNOPSIS

    use CGI::Application::Plugin::Flash;

    sub some_runmode
    {
        my $self = shift;

        # Set a message in the flash
        $self->flash(info => 'Welcome back!');

        # Alternatively
        my $flash = $self->flash;
        $flash->set(info => "Welcome back!");

        # Set a message in the flash that only lasts for the duration of
        # the current request.
        $self->flash->now(test => 'Only available for this request');

        # ...
    }

=head1 DESCRIPTION

This L<CGI::Application> plugin wraps the L<CGI::Session::Flash> module to
implement a Flash object.  A flash is session data with a specific life cycle.
When you put something into the flash it stays then until the end of the next
request.  This allows you to use it for storing messages that can be accessed
after a redirect, but then are automatically cleaned up.

Since the flash data is accessible from the next request a method of persistance
is required.  We use a session for this so the
L<CGI::Application::Plugin::Session> is required.  The flash is stored in the
session using two keys, one for the data and one for the list of keys that are
to be kept. 

=head1 EXPORTED METHODS

The following methods are exported into your L<CGI::Application> class.

=head2 flash

The flash is implemented as a singleton so the same object will be returned on
subsequent calls.  The first time this is called a new flash object is created
using data from the session.

This method can be called in the following manners:

=over 4

=item $self->flash()

When no arguments are specified the flash object is returned. 
Use this form when you want to use a more advanced feature of the flash.  See
the documentation below for the flash object.

=item $self->flash('KEY')

Retrieve the data from the flash.  See C<get> for more details.

=item $self->flash('KEY' => @data)

Set the data in the flash.  See C<set> for more details.

=back

=head2 flash_config

Call this method to set or get the configuration for the flash.  Setting the
configuration must be done before the first time you call C<flash>, otherwise
the configuration will not take effect.  A good place to put this call is in
your C<cgiapp_init> method.

This is generally not needed as the defaults values should work fine.

When setting the configuration values specify a list of key and value pairs.
The possible values are documented in the
L<CGI::Session::Flash/new|CGI::Session::Flash->new> documentation.

When called with no parameters, the current configuration will be returned as
either a hashref or a list depending on the context.

Example:

    sub cgiapp_init
    {
        my $self = shift;
 
        # Setting it
        $self->flash_config(session_key => 'FLASH');

        # Getting the current configuration
        my $flash_config = $self->flash_config;

        # ...
    }

=head1 FLASH OBJECT

While the basic use of the flash is getting and setting data, which we provide
simple wrapper for, there may be times when you need to access the full power
of the flash object.

Consult the L<CGI::Session::Flash> documentation for details on its usage.

=head1 USING FROM A TEMPLATE

This is an example of how you could use the flash in a template toolkit
template to display some various informational notices.

    [% c.flash('key') %]

And here is a more advanced example.  This could be implemented as a separate
file that gets C<PROCESS>ed from a wrapper.

    [% FOR type IN [ 'error', 'warning', 'info' ] -%]
      [% IF c.flash.has_key(type) -%]
      <div class="flash [% type %]">,
        <strong>[% type %] messages</strong>
        <ul>
        [% FOREACH message in c.flash(type) -%]
          <li>[% message | html %]</li>
        [% END -%]
        </ul>
      </div>
      [% END -%]
    [% END -%]

For working with Template Toolkit see the documentation for
L<CGI::Application::Plugin::TT> and L<Template>.

=head1 CAVEATS

The flash object should automatically flush when the object is destroyed.
However, there can be times when an object may not get properly destroyed
such as in the event of a circular reference.  Because of this, you may want
to explicitly call C<flush> in your C<teardown> method.

    sub teardown
    {
        my $self = shift;

        $self->flash->flush();
        $self->session->flush();
    }

Make sure that the flash is flushed before the session, otherwise your flash
data will not be saved.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-flash at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-Flash>.
 I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<CGI::Session::Flash>, L<CGI::Application>,
L<CGI::Application::Plugin::Session>, L<CGI::Application::Plugin::MessageStack>

Although L<CGI::Session::Flash> and L<CGI::Application::Plugin::MessageStack>
can be used for similar purposes, they have slightly different goals.
First off L<CGI::Session::Flash> is not directly tied to L<CGI::Application>, so
it can be used in other frameworks.  Second L<CGI::Session::Flash> is designed
to work with any kind of data, not necessarily just messages and has a very
predictable lifecycle for the data.  Lastly it has a, at least in my opinion,
simpler interface and may be more familiar to others with experience in other
frameworks.

I encourage you to check out all your options and choose the one that works
best for you.

=head1 AUTHOR

Bradley C Bailey, C<< <cap-flash at brad.memoryleak.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Bradley C Bailey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
