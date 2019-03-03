# NAME

Catalyst::Plugin::Starch - Catalyst session plugin via Starch.

# SYNOPSIS

    package MyApp;
    
    use Catalyst qw(
        Starch::Cookie
        Starch
    );
    
    __PACKAGE__->config(
        'Plugin::Starch' => {
            cookie_name => 'my_session',
            store => { class=>'::Memory' },
        },
    );

# DESCRIPTION

Integrates [Starch](https://metacpan.org/pod/Starch) with [Catalyst](https://metacpan.org/pod/Catalyst) providing a compatible replacement
for [Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session).

Is is recommended that as part of implementing this module in your site
that you also create an in-house unit test using [Test::Starch](https://metacpan.org/pod/Test::Starch).

Note that this plugin is a [Moose::Role](https://metacpan.org/pod/Moose::Role) which means that Catalyst will
apply the plugin to the Catalyst object in reverse order than that listed
in the `use Catalyst` stanza.  This may not matter for you, but to be safe,
declare the `Starch` plugin **after** any other Starch plugins or any other
plugins that depend on sessions.

# CONFIGURATION

Configuring Starch is a matter of setting the `Plugin::Starch` configuration
key in your root Catalyst application class:

    __PACKAGE__->config(
        'Plugin::Starch' => {
            store => { class=>'::Memory' },
        },
    );

In addition to the arguments you would normally pass to [Starch](https://metacpan.org/pod/Starch) you
can also pass a `plugins` argument which will be combined with the plugins
from ["default\_starch\_plugins"](#default_starch_plugins).

See [Starch](https://metacpan.org/pod/Starch) for more information about configuring Starch.

# COMPATIBILITY

This module is mostly API compliant with [Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session).  The way you
configure this plugin will be different, but all your code that uses sessions, or
other plugins that use sessions, should not need to be changed unless they
depend on undocumented features.

Everything documented in the ["METHODS" in Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session#METHODS) section is
supported except for:

- The `flash`, `clear_flash`, and `keep_flash` methods are not implemented
as its really a terrible idea.  If this becomes a big issue for compatibility
with existing code and plugins then this may be reconsidered.
- The `session_expire_key` method is not supported, but can be if it is deemed
a good feature to port.

Everything in the ["INTERNAL METHODS" in Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session#INTERNAL-METHODS) section is
supported except for:

- The
`check_session_plugin_requirements`, `setup_session`, `initialize_session_data`,
`validate_session_id`, `generate_session_id`, `session_hash_seed`,
`calculate_extended_session_expires`, `calculate_initial_session_expires`,
`create_session_id_if_needed`, `delete_session_id`, `extend_session_expires`,
`extend_session_id`, `get_session_id`, `reset_session_expires`,
`set_session_id`, and `initial_session_expires`
methods are not supported.  Some of them could be, if a good case for their
existence presents itself.
- The `setup`, `prepare_action`, and `finalize_headers` methods are not altered
because they do not need to be.

The above listed unimplemented methods and attributes will throw an exception
if called.

# PERFORMANCE

Benchmarking [Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session) and [Catalyst::Plugin::Starch](https://metacpan.org/pod/Catalyst::Plugin::Starch)
it was found that Starch is 1.5x faster (or, ~65% the run-time).  While this
is a fairly big improvement, the difference in real-life should be a savings
of one or two millisecond per request.

Most of this performance gain is made by the fact that Starch does not use
[Moose](https://metacpan.org/pod/Moose) and instead it uses [Moo](https://metacpan.org/pod/Moo) which has many run-time performance
benefits.

# ATTRIBUTES

## sessionid

The ID of the session.

## session\_expires

Returns the time when the session will expire (in epoch time).  If there
is no session then `0` will be returned.

## session\_delete\_reason

Returns the `reason` value passsed to ["delete\_session"](#delete_session).
Two common values are:

- `address mismatch`
- `session expired`

## default\_starch\_plugins

This attribute returns the base set plugins that the ["starch"](#starch)
object will be built with.  Note that this does not include any
additional plugins you specify in the ["CONFIGURATION"](#configuration).

The intention of this attribute is for other Catalyst plugins, such as
[Catalyst::Plugin::Starch::Cookie](https://metacpan.org/pod/Catalyst::Plugin::Starch::Cookie), to be able to declare
additional Starch plugins by `around()`ing this and injecting
their own plugins into the array ref.

## starch\_state

This holds the underlying [Starch::State](https://metacpan.org/pod/Starch::State) object.

# CLASS ATTRIBUTES

## starch

The [Starch::Manager](https://metacpan.org/pod/Starch::Manager) object.  This gets automatically constructed from
the `Plugin::Starch` Catalyst configuration key per ["CONFIGURATION"](#configuration).

# METHODS

## session

    $c->session->{foo} = 45;
    $c->session( foo => 45 );
    $c->session({ foo => 45 });

Returns a hash ref of the session data which may be modified and
will be stored at the end of the request.

A hash list or a hash ref may be passed to set values.

## delete\_session

    $c->delete_session();
    $c->delete_session( $reason );

Deletes the session, optionally with a reason specified.

## save\_session

Saves the session to the store.

## change\_session\_id

    $c->change_session_id();

Generates a new ID for the session but retains the session
data in the new session.

Some interesting discussion as to why this is useful is at
["METHODS" in Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session#METHODS) under the `change_session_id`
method.

## change\_session\_expires

Sets the expires duration on the session which defaults to the
global expires set in ["CONFIGURATION"](#configuration).

## session\_is\_valid

Currently this always returns `1`.

## delete\_expired\_sessions

Calls ["reap\_expired" in Starch::Store](https://metacpan.org/pod/Starch::Store#reap_expired) on the store.  This method is
here for backwards compatibility with [Catalyst::Plugin::Session](https://metacpan.org/pod/Catalyst::Plugin::Session)
which expects you to delete expired sessions within the context of
an HTTP request.  Since starch is available independently from Catalyst
you should consider calling `reap_expired` yourself within a cronjob.

If the store does not support expired session reaping then an
exception will be thrown.

# SUPPORT

Please submit bugs and feature requests to the
Catalyst-Plugin-Starch GitHub issue tracker:

[https://github.com/bluefeet/Catalyst-Plugin-Starch/issues](https://github.com/bluefeet/Catalyst-Plugin-Starch/issues)

# AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

# ACKNOWLEDGEMENTS

Thanks to [ZipRecruiter](https://www.ziprecruiter.com/)
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
