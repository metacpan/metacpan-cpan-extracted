use 5.008001;
use strict;
use warnings;

package Dancer::Plugin::Deferred;
# ABSTRACT: Defer messages or data across redirections
our $VERSION = '0.003'; # VERSION

use Carp qw/croak/;
use URI;
use URI::QueryParam;

use Dancer ':syntax';
use Dancer::Plugin;

my $conf;

register 'deferred' => sub {
  my ( $self, $key, $value ) = plugin_args(@_);
  $conf ||= _get_conf();

  my $id = _get_id();

  # message data is flat "dpd_$id" to avoid race condition with
  # another session
  my $data = session( $conf->{session_key_prefix} . $id ) || {};

  # set value or destructively retrieve it
  if ( defined $value ) {
    $data->{$key} = $value;
  }
  else {
    $value = var( $conf->{var_keep_key} ) ? $data->{$key} : delete $data->{$key};
  }

  # store remaining data or clear it if no deferred messages are left
  if ( keys %$data ) {
    session $conf->{session_key_prefix} . $id => $data;
    var $conf->{var_key}                      => $id;
  }
  else {
    session $conf->{session_key_prefix} . $id => undef;
    var $conf->{var_key}                      => undef;
  }

  return $value;
};

# destructively return all keys
register 'all_deferred' => \&_get_all_deferred;

sub _get_all_deferred {
  $conf ||= _get_conf();
  my $id = _get_id();
  my $data = session( $conf->{session_key_prefix} . $id ) || {};
  unless ( var $conf->{var_keep_key} ) {
    session $conf->{session_key_prefix} . $id => undef;
    var $conf->{var_key}                      => undef;
  }
  return $data;
}

register 'deferred_param' => \&_get_deferred_param;

sub _get_deferred_param {
  my ($arg) = @_;
  $conf ||= _get_conf();
  var $conf->{var_keep_key} => 1;
  return ( $conf->{params_key} => var $conf->{var_key} );
}

hook 'before_template' => sub {
  my $data = shift;
  $conf ||= _get_conf();
  $data->{ $conf->{template_key} } = _get_all_deferred();
};

hook 'before' => sub {
  $conf ||= _get_conf();
  my $id = params->{ $conf->{params_key} };
  var( $conf->{var_key} => $id )
    if $id;
};

hook 'after' => sub {
  my $response = shift;
  $conf ||= _get_conf();
  if ( var( $conf->{var_key} ) && $response->status =~ /^3/ ) {
    my $u = URI->new( $response->header("Location") );
    $u->query_param( _get_deferred_param() );
    $response->header( "Location" => $u );
  }
};

# not crypto strong, but will be stored in session, which should be
sub _get_id {
  $conf ||= _get_conf();
  return var( $conf->{var_key} )
    || sprintf( "%08d", int( rand(100_000_000) ) );
}

sub _get_conf {
  return {
    var_key            => 'dpdid',
    var_keep_key       => 'dpd_keep',
    params_key         => 'dpdid',
    session_key_prefix => 'dpd_',
    template_key       => 'deferred',
    %{ plugin_setting() },
  };
}

register_plugin for_versions => [ 1, 2 ];

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Dancer::Plugin::Deferred - Defer messages or data across redirections

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Dancer::Plugin::Deferred;

  get '/defer' => sub {
    deferred error => "Klaatu barada nikto";
    redirect '/later';
  }

  get '/later' => sub {
    template 'later';
  }

  # in template 'later.tt'
  <% IF deferred.error %>
  <div class="error"><% deferred.error %></div>
  <% END %>

=head1 DESCRIPTION

This L<Dancer> plugin provides a method for deferring a one-time message across
a redirect.  It is similar to "flash" messages, but without the race conditions
that can result from multiple tabs in a browser or from AJAX requests.  It is
similar in design to L<Catalyst::Plugin::StatusMessage>, but adapted for Dancer.

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

=over 4

=item *

C<var_key: dpdid> -- this is the key in the C<var> hash containing the message ID

=item *

C<var_keep_key: dpd_keep> -- if this key in C<var> is true, retrieving values will not be destructive

=item *

C<params_key: dpdid> -- this is the key in the C<params> hash containing the message ID

=item *

C<session_key_prefix>: dpd_> -- the message ID is appended to this prefix and used to store deferred data in the session

=item *

C<template_key: deferred> -- this is the key to deferred data passed to the template

=back

=head1 SEE ALSO

=over 4

=item *

L<Dancer>

=item *

L<Dancer::Plugin::FlashMessage>

=item *

L<Dancer::Plugin::FlashNote>

=item *

L<Catalyst::Plugin::StatusMessage>

=back

=head1 ACKNOWLEDGMENTS

Thank you to mst for explaining why L<Catalyst::Plugin::StatusMessages> does
what it does and putting up with my dumb ideas along the way.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/dancer-plugin-deferred/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/dancer-plugin-deferred>

  git clone git://github.com/dagolden/dancer-plugin-deferred.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
