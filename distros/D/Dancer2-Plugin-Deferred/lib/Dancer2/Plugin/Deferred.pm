use 5.008001;
use strict;
use warnings;

package Dancer2::Plugin::Deferred;
our $AUTHORITY = 'cpan:YANICK';
$Dancer2::Plugin::Deferred::VERSION = '0.008000';
# ABSTRACT: Defer messages or data across redirections
# VERSION

use Dancer2::Core::Types qw/Str/;
use URI;
use URI::QueryParam;

use Dancer2::Plugin 0.200000;

has var_key => (
    is => 'ro',
    isa => Str,
    from_config => sub { 'dpdid' },
);

has var_keep_key => (
    is => 'ro',
    isa => Str,
    from_config => sub { 'dpd_keep' },
);

has params_key => (
    is => 'ro',
    isa => Str,
    from_config => sub { 'dpdid' },
);

has session_key_prefix => (
    is => 'ro',
    isa => Str,
    from_config => sub { 'dpd_' },
);

has template_key => (
    is => 'ro',
    isa => Str,
    from_config => sub { 'deferred' },
);

plugin_keywords 'deferred', 'all_deferred', 'deferred_param';

sub deferred {
    my ( $plugin, $key, $value ) = @_;
    my $app = $plugin->app;

    my $id = $plugin->_get_id;

    # message data is flat "dpd_$id" to avoid race condition with
    # another session
    my $data = $app->session->read(  $plugin->session_key_prefix . $id ) || {};
    
    # set value or destructively retrieve it
    if ( defined $value ) {
        $data->{$key} = $value;
    }
    else {
        $value =
            $app->request->var( $plugin->var_keep_key )
          ? $data->{$key}
          : delete $data->{$key};
    }

    # store remaining data or clear it if no deferred messages are left
    if ( keys %$data ) {
        $app->session->write( $plugin->session_key_prefix . $id => $data );
        $app->request->var( $plugin->var_key => $id );
    }
    else {
        $app->session->delete( $plugin->session_key_prefix . $id );
        $app->request->var( $plugin->var_key => undef );
    }
    return $value;
};

sub all_deferred {
    my $plugin = shift;
    my $app = $plugin->app;

    my $id = $plugin->_get_id;
    my $data = $plugin->app->session->read( $plugin->session_key_prefix . $id ) || {};

    unless ( $app->request->var( $plugin->var_keep_key ) ) {
        $app->session->delete( $plugin->session_key_prefix . $id );
        $app->request->var( $plugin->var_key, undef );
    }
    return $data;
}

sub deferred_param {
    my $plugin = shift;

    $plugin->app->request->var( $plugin->var_keep_key => 1 );

    return ( $plugin->params_key => $plugin->app->request->var( $plugin->var_key ) );
}

# not crypto strong, but will be stored in session, which should be
sub _get_id {
    my $plugin = shift;

    return $plugin->app->request->var( $plugin->var_key )
      || sprintf( "%08d", int( rand(100_000_000) ) );
}

sub BUILD {
    my $plugin = shift;

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template',
            code => sub {
                my $data = shift;
                $data->{$plugin->template_key} = $plugin->all_deferred;
            }
        )
    );

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                my $id = $plugin->app->request->params->{ $plugin->params_key };
                $plugin->app->request->var( $plugin->var_key => $id )
                  if $id;
            }
        )
    );

    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'after',
            code => sub {
                my $response = shift;
                if (   $plugin->app->request->var( $plugin->var_key )
                    && $response->status =~ /^3/ )
                {
                    my $u = URI->new( $response->header("Location") );
                    $u->query_param( $plugin->deferred_param );
                    $response->header( "Location" => $u );
                }
            }
        )
    );
};

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Deferred - Defer messages or data across redirections

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Dancer2::Plugin::Deferred;

  get '/defer' => sub {
    deferred error => "Klaatu barada nikto";
    redirect '/later';
  };

  get '/later' => sub {
    template 'later';
  };

  # in template 'later.tt'
  <% IF deferred.error %>
  <div class="error"><% deferred.error %></div>
  <% END %>

=head1 DESCRIPTION

This L<Dancer2> plugin provides a method for deferring a one-time message across
a redirect.  It is similar to "flash" messages, but without the race conditions
that can result from multiple tabs in a browser or from AJAX requests.  It is
similar in design to L<Catalyst::Plugin::StatusMessage>, but adapted for Dancer2.

It works by creating a unique message ID within the session that holds deferred
data.  The message ID is automatically added as a query parameter to redirection
requests.  It's sort of like a session within a session, but tied to a request
rather than global to the browser.  (It will even chain across multiple
redirects.)

When a template is rendered, a pre-template hook retrieves the data and
deletes it from the session.  Alternatively, the data can be retrieved manually
(which will also automatically delete the data.)

Alternatively, the message ID parameters can be retrieved and used to
construct a hyperlink for a message to be retrieved later.  In this case,
the message is preserved past the template hook.  (The template should be
sure not to render the message if not desired.)

=for Pod::Coverage method_names_here

=head1 USAGE

=head2 deferred

  deferred $key => $value;
  $value = deferred $key; # also deletes $key

This function works just like C<var> or C<session>, except that it lasts only
for the current request and across any redirects.  Data is deleted if accessed.
If a key is set to an undefined value, the key is deleted from the deferred
data hash.

=head2 all_deferred

  template 'index', { deferred => all_deferred };

This function returns all the deferred data as a hash reference and deletes
the stored data.  This is called automatically in the C<before_template_render>
hook, but is available if someone wants to have manual control.

=head2 deferred_param

  template 'index' => { link => uri_for( '/other', { deferred_param } ) };

This function returns the parameter key and value used to propagate the
message to another request.  Using this function toggles the C<var_keep_key>
variable to true to ensure the message remains to be retrieved by the link.

=head1 CONFIGURATION

=for :list * C<var_key: dpdid> -- this is the key in the C<var> hash containing the message ID
* C<var_keep_key: dpd_keep> -- if this key in C<var> is true, retrieving values will not be destructive
* C<params_key: dpdid> -- this is the key in the C<params> hash containing the message ID
* C<session_key_prefix: dpd_> -- the message ID is appended to this prefix and used to store deferred data in the session
* C<template_key: deferred> -- this is the key to deferred data passed to the template

=head1 SEE ALSO

=for :list * L<Dancer2>
* L<Dancer::Plugin::FlashMessage>
* L<Dancer::Plugin::FlashNote>
* L<Catalyst::Plugin::StatusMessage>

=head1 ACKNOWLEDGMENTS

Thank you to mst for explaining why L<Catalyst::Plugin::StatusMessages> does
what it does and putting up with my dumb ideas along the way.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Yanick Champoux <yanick@cpan.org>

=item *

Deluxaran <deluxaran@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020, 2018, 2016 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
