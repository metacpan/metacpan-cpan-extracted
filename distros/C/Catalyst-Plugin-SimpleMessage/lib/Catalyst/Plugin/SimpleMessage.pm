package Catalyst::Plugin::SimpleMessage;

{
  $Catalyst::Plugin::SimpleMessage::VERSION = '0.0.2';
}

use strictures 1;
 
=head1 NAME
 
Catalyst::Plugin::SimpleMessage - Handle passing multiple types of messages between screens of a web application using session or stash.
 
 
=head1 SYNOPSIS
 
In MyApp.pm:
 
    use Catalyst qr/
        SimpleMessage
    /;
 
In controller where you want to save a message for display on the next page (here, once the "delete" action taken is complete, we are redirecting to a "list" page to show the status [we don't want to leave the delete action in the browser URL]):
 
   $c->response->redirect($c->uri_for($self->action_for('list'),
        { $c->sm_get_token_param() => $c->sm_session({ message => 'Deleted widget', type => 'success' }) }));
 
Or, to display an error message:
 
   $c->response->redirect($c->uri_for($self->action_for('list'),
        { $c->sm_get_token_param() => $c->sm_session({ message => 'Error deleting widget', type => 'danger' }) }));

If you do not need a redirect, you can pass the message using stash:

    $c->sm_stash({ message => 'Your email was not confirmed yet', type => 'warning' });
 
And, to display the output (here using L<Template Toolkit|Template> and L<Twitter Bootstrap|http://getbootstrap.com/>):
 
    ...
    [% FOREACH item IN c.sm_get() %]
        <span class="alert alert-[% item.type %]">[% item.message %]</span>
    [% END %]
    ...
 
 
=head1 DESCRIPTION
 
There are a number of ways people commonly use to pass messages between screens in a web application.
 
=over 4
 
=item *
 
Using $c->flash: The "flash" feature does provide a mechanism where the application can redirect to an appropriate URL, but it can also lead to a race condition where the wrong status message is displayed in the wrong browser window or tab (and can therefore be confusing to the users of your application).
 
=item *
 
Query parameters in the URL: This suffers from issues related to long/ugly URLs and leaves the message displayed even after a browser refresh.
 
=back
 
 
This plugin attempts to address these issues through the following mechanisms:
 
=over 4
 
=item *
 
Stores messages in the C<$c-E<gt>session> so that the application is free to redirect to the appropriate URL after an action is taken.
 
=item *
 
Associates a random 8-digit "token" with each message, so it's completely unambiguous what message should be shown in each window/tab.
 
=item *
 
Only requires that the token (not the full message) be included in the redirect URL.
 
=item *
 
Automatically removes the message after the first time it is displayed. That way, if users hit refresh in their browsers they only see the messages the first time.
 
=back
 
 
=head1 METHODS
 
 
=head2 sm_get_messages

Returns an array ref with messages sent through C<$c-E<gt>sm_session> and C<$c-E<gt>sm_stash>. You can send messages through C<$c-E<gt>sm_session> and C<$c-E<gt>sm_stash> and both will be available, messages sent throught stash are available only for the current request.

=head2 sm_get

Alias for sm_get_messages

=cut

sub sm_get_messages {
    my ($self) = @_;
    
    my $conf = $self->__sm_config();    
    my $token  = $self->request->param($conf->{token_param}) || undef;
    
    # if stash key must be an array
    $self->stash->{$conf->{stash_prefix}} = [] if(ref($self->stash->{$conf->{stash_prefix}}) ne 'ARRAY');
    
    if($token && (ref($self->session->{$conf->{session_prefix}}->{$token}) eq 'ARRAY')) {
        my $searray = delete $self->session->{$conf->{session_prefix}}->{$token};
        push(@{ $self->stash->{$conf->{stash_prefix}} }, @$searray);
    }
    
    return $self->stash->{$conf->{stash_prefix}};
}
*sm_get = \&sm_get_messages;


=head2 sm_get_token_param

Return the token_param name. Default is "__sm"

=cut

sub sm_get_token_param {
    my ($self) = @_;
    return $self->__sm_config()->{token_param};
}


=head2 sm_set_messages_session

Send messages through the session and return a token. You can send multiple messages:

    my $token = $c->sm_session({ message => 'Product added with success', type => 'success' }, { message => 'You must define a price before selling', type => 'warning' });
    $c->response->redirect($c->uri_for($self->action_for('list'), { $c->sm_get_token_param() => $token }));

=head2 sm_session

Alias for sm_set_messages_session

=cut

sub sm_set_messages_session {
    my ($self, @messages) = @_;
    
    my $conf = $self->__sm_config();
    
    my $token = int(rand(90_000_000))+10_000_000;
    $self->session->{$conf->{session_prefix}} = {} if(ref($self->session->{$conf->{session_prefix}}) ne 'HASH');    
    $self->session->{$conf->{session_prefix}}->{$token} = \@messages;
    
    return $token;    
}
*sm_session = \&sm_set_messages_session;


=head2 sm_set_messages_stash

Send messages through the stash. You can send multiple messages:

    my $token = $c->sm_stash({ message => 'You account is active', type => 'info' }, { message => 'You do not have credit', type => 'danger' });

Messages sent through stash will be available only for the current request.

=head2 sm_stash

Alias for sm_set_messages_stash

=cut

sub sm_set_messages_stash {
    my ($self, @messages) = @_;
    
    my $conf = $self->__sm_config();
    
    if(ref($self->stash->{$conf->{stash_prefix}}) ne 'ARRAY') {
        $self->stash->{$conf->{stash_prefix}} = \@messages;
    } else {
        push(@{ $self->stash->{$conf->{stash_prefix}} }, @messages);
    }
}
*sm_stash = \&sm_set_messages_stash;
 
 
=head1 CONFIGURABLE OPTIONS
 
 
=head2 session_prefix
 
The location inside $c->session where messages will be stored.  Defaults to "C<__sm>".


=head2 stash_prefix
 
The location inside $c->stash where messages will be stored.  Defaults to "C<__sm>".
 
 
=head2 token_param
 
The name of the URL param that holds the token on the page where you want to retrieve/display the status message.  Defaults to "C<__sm>".
 

 
 
=head2 Configuration Example
 
Here is a quick example showing how Catalyst::Plugin::SimpleMessage can be configured
 
 
    # Configure Catalyst::Plugin::SimpleMessage
    __PACKAGE__->config(
        'Plugin::SimpleMessage' => {
            session_prefix       => '__sm',
            stash_prefix         => '__sm',
            token_param          => '__sm'
        }
    );
 
 
=head1 INTERNALS
 
Note: You normally shouldn't need any of the information in this section to use L<Catalyst::Plugin::SimpleMessage>.
 
 
=head2 __sm_config
 
Handles default values for config and lets them be overriden from the MyApp configuration.
 
=cut
 
sub __sm_config {
    my ($self) = @_;
 
    my %config = (
        session_prefix       =>  '__sm',
        stash_prefix         =>  '__sm',
        token_param          =>  '__sm',
        %{ $self->config->{'Plugin::SimpleMessage'} || {} }
    );
    
    return \%config;
    
};
 

=head1 CODE

Github

    https://github.com/geovannyjs/Catalyst-Plugin-SimpleMessage
 
=head1 AUTHOR
 
Geovanny Junio, geovannyjs@gmail.com
 
 
This module was based on L<Catalyst::Plugin::StatusMessage>. Many thanks to Kennedy Clark (HKCLARK). 
 
=head1 COPYRIGHT
 
This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.
 
=cut
 
1;
