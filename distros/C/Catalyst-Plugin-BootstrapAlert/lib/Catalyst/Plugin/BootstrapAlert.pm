package Catalyst::Plugin::BootstrapAlert;

use 5.006;

use strict;
use warnings;

=head1 NAME

Catalyst::Plugin::BootstrapAlert - Replacement for Catalyst::Plugin::StatusMessage inline with Bootstrap alert names (success, info, warning, and danger).

=head1 VERSION

Version 0.50

=cut

our $VERSION = '0.50';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

Replacement for Catalyst::Plugin::StatusMessage using Bootstrap alert names (success, info, warning, and danger),
whilst also keeping C<status_msg> and C<error_msg> as aliases.

Storing an array-ref of msgs, or even an array-ref of hash-refs is fine, in TT you'd want to use the C<list> VMethod:

    [% IF danger_alert.list.size %]
                        <div class="alert alert-danger" role="alert">
        [% FOREACH each_danger_alert IN danger_alert.list %]
                            <p>[% each_danger_alert %]</p>
        [% END %]
                        </div>
    [% END %]

Calling C<list> on an actual list just returns the list, so essentially a no-op.

See http://www.template-toolkit.org/docs/manual/VMethods.html#section_list

In MyApp.pm:

    use Catalyst qr/
        BootstrapAlert
    /;

In controller where you want to save a message for display on the next page:

   $c->response->redirect( "/?mid=" . $c->set_success_alert("It worked!") );

Or, to save an danger message:

   $c->response->redirect( "/?mid=" . $c->set_error_msg("Error deleting widget") );

Then, in the controller action that corresponds to the redirect above:

    sub list :Path {
        my ($self, $c) = @_;
        ...
        $c->load_bootstrap_alerts;
        ...
    }

This would mean simply changing C<load_status_msgs> if using C<Catalyst::Plugin::StatusMessage>.

And, to display the output (here using L<Template Toolkit|Template>):

    ...
    <span class="message">[% success_alert %]</span>
    <span class="error">[% error_msg %]</span>
    ...

=head1 METHODS

=head2 load_bootstrap_alerts

Load all alerts that match the token parameter on the URL (e.g.,
http://example.com/dashboard?mid=1234567890) into the stash
for display by the viewer.

In general, you will want to include this in an C<auto> or "base" (if
using Chained dispatch) controller action.  Then, if you have a
"template wrapper page" that displays "C<success_alert>", "C<info_alert>",
"C<warning_alert>", and "C<danger_alert>", you can automatically and safely send status messages to
any related controller action.

=cut

sub load_bootstrap_alerts
{
    my $self = shift;

    my $config = $self->_plugin_bootstrap_alert_config;

    my $param = $self->request->params->{ $config->{ alert_param } } || return;

    foreach my $type ( @{ $config->{ alert_types } } )
    {
        my $key = $type . '_alert_stash_key';

        my $value = $self->_get_bootstrap_alert( $type, $param );

        if ( defined $value )
        {
            $self->stash( $config->{ $key } => $value );
        }

        # the aliases for Catalyst::Plugin::StatusMessage

        my $alias_key = $type . '_alert_stash_key_alias';

        if ( my $alias = $config->{ $alias_key } )
        {
            if ( exists $self->stash->{ $config->{ $key } } )
            {
                $self->stash( $alias => $self->stash->{ $config->{ $key } } );
            }
        }
    }
}

=head2 set_success_alert

Sets the success alert text.

=cut

sub set_success_alert { return shift->_set_bootstrap_alert( 'success', shift ) }

=head2 set_info_alert

Sets the info alert text.

=cut

sub set_info_alert { return shift->_set_bootstrap_alert( 'info', shift ) }

=head2 set_warning_alert

Sets the warning alert text.

=cut

sub set_warning_alert { return shift->_set_bootstrap_alert( 'warning', shift ) }

=head2 set_danger_alert

Sets the danger alert text.

=cut

sub set_danger_alert { return shift->_set_bootstrap_alert( 'danger', shift ) }

=head2 set_status_msg

Sets the success alert text - this is an alias for when you're switching out Catalyst::Plugin::StatusMessage.

=cut

sub set_status_msg { return shift->set_success_alert( shift ) }

=head2 set_error_msg

Sets the danger alert text - this is an alias for when you're switching out Catalyst::Plugin::StatusMessage.

=cut

sub set_error_msg  { return shift->set_danger_alert( shift ) }

=head1 CONFIGURABLE OPTIONS

Here is a quick example showing how Catalyst::Plugin::BootstrapAlert
can be configured:

    # Configure Catalyst::Plugin::BootstrapAlert
    __PACKAGE__->config(
        'Plugin::BootstrapAlert' => {

            session_key => 'my_status_msg',
            
            alert_param => 'my_mid',
            
            alert_types => [ qw( success info warning danger ) ],

            success_alert_stash_key => 'success_alert',
            info_alert_stash_key    => 'info_alert',
            warning_alert_stash_key => 'warning_alert',
            danger_alert_stash_key  => 'danger_alert',

            success_alert_stash_key_alias => 'status_msg',
            danger_alert_stash_key_alias  => 'error_msg',
        }
    );

=head2 _plugin_bootstrap_alert_config

Subref that handles default values and lets them be overriden from the MyApp
configuration.

=cut

sub _plugin_bootstrap_alert_config
{
    my $self = shift;

    my %config = (
        session_key => 'bootstrap_alerts',

        alert_param => 'mid',

        alert_types => [ qw( success info warning danger ) ],

        success_alert_stash_key => 'success_alert',
        info_alert_stash_key    => 'info_alert',
        warning_alert_stash_key => 'warning_alert',
        danger_alert_stash_key  => 'danger_alert',

        success_alert_stash_key_alias => 'status_msg',
        danger_alert_stash_key_alias  => 'error_msg',

        %{ $self->config->{ "Plugin::BootstrapAlert" } || {} }
    );

    return \%config;
}

=head1 INTERNALS

Note: You normally shouldn't need any of the information in this section
to use L<Catalyst::Plugin::BootstrapAlert>.

=head2 _set_bootstrap_alert

This is called by all of the public methods, passing the type of alert, and the alert message.

=cut

sub _set_bootstrap_alert
{
    my $self = shift;

    my $type = shift;

    my $msg = shift;   # could be an array-ref of multiple msgs

    my $config = $self->_plugin_bootstrap_alert_config;

    my $param = int( rand( 90_000_000 ) ) + 10_000_000;

    $self->session->{ $config->{ session_key } }->{ $type }->{ $param } = $msg;

    return $param;
}

=head2 _get_bootstrap_alert

Fetch the requested message type from the user's session

=cut

sub _get_bootstrap_alert
{
    my $self = shift;

    my $type = shift;

    my $param = shift;

    my $config = $self->_plugin_bootstrap_alert_config;

    if ( exists $self->session->{ $config->{ session_key } }->{ $type }->{ $param } )
    {
        return delete( $self->session->{ $config->{ session_key } }->{ $type }->{ $param } );
    }

    return undef;
}


=head1 AUTHOR

Rob Brown, C<< <rob at lavoco.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-bootstrapalert at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-BootstrapAlert>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::BootstrapAlert


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-BootstrapAlert>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-BootstrapAlert>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-BootstrapAlert>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-BootstrapAlert/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

