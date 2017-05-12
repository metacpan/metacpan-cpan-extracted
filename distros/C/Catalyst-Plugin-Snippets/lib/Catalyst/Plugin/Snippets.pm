#!/usr/bin/perl

package Catalyst::Plugin::Snippets;

use strict;
use warnings;
use MRO::Compat;

BEGIN { eval { require JSON::Syck } }

our $VERSION = "0.03";

sub setup {
    my $app = shift;
    my $ret = $app->maybe::next::method(@_);

    %{ $app->config->{snippets} } = (
        format            => "plain",
        allow_refs        => 1,
        use_session_id    => 0,
        json_content_type => "application/javascript+json",
        content_type      => "text/plain",
        %{ $app->config->{snippets} || {} },
    );

    $ret;
}

sub snippet {
    my ( $c, $namespace, $key, @args ) = @_;

    my $meth = @args ? "set" : "get";

    my $o = $c->_snippet_opts($namespace);

    my $cache_key = $c->_snippet_key( $namespace, $key, $o );

    $c->cache->$meth( $cache_key, @args );
}

sub _snippet_key {
    my ( $c, $namespace, $key, $options ) = @_;

    my @long_key = ( "snippet", $namespace, $key );

    push @long_key, $c->sessionid if $options->{use_session_id};

    return join ":", @long_key;
}

sub _snippet_opts {
    my ( $c, $namespace, @opts ) = @_;

    my $override = @opts == 1 ? shift @opts : { @opts };

    my %options = (
        %$override,
        %{ $c->config->{"snippets:$namespace"} || {} },
        %{ $c->config->{"snippets"} },
    );

    return \%options;
}

sub serve_snippet {
    my ( $c, $namespace, @_opts ) = @_;

    $namespace ||= $c->action->name;

    my $options = $c->_snippet_opts($namespace, @_opts);

    my $key = join( "/", @{ $c->request->arguments } );    # deparse ;-)

    my $value = $c->snippet( $namespace, $key );

    $c->send_snippet( $value, $options );
}

sub send_snippet {
    my ( $c, $value, $options ) = @_;

    $c->_snippet_sender($options)->( $options, $value );
}

sub _snippet_sender {
    my ( $c, $options ) = @_;

    my $formatter = $options->{format};

    if ( ref $formatter ) {
        return sub { $c->_send_snippet( $formatter->( @_ ) ) };
    } else {
        my $name = "_send_snippet_$formatter";
        return sub { $c->$name( @_ ) }
    }
}

sub _send_snippet {
    my ( $c, $content_type, $body ) = @_;
    $c->response->content_type($content_type);
    $c->response->body($body);
}

sub _send_snippet_json {
    my ( $c, $options, $value ) = @_;
    $c->_send_snippet(
        $options->{json_content_type},
        JSON::Syck::Dump($value),
    );
}

sub _send_snippet_plain {
    my ( $c, $options, $value ) = @_;
    no warnings 'uninitialized';
    $c->_send_snippet( $options->{content_type}, "$value" );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Snippets - Make sharing data with clients easy

=head1 SYNOPSIS

    package MyApp;

    # use this plugin, and any Cache plugin
	use Catalyst qw/
        Cache::FastMmap
        Snippets
    /;

    package MyApp::Controller::Foo;

    sub action : Local {
        my ( $self, $c ) = @_;
        # ...
        $c->snippet( $namespace, $key, $value );
    }

    sub foo : Local {
        my ( $self, $c ) = @_;
        $c->serve_snippet( $namespace, \%options ); # namespace defaults to $c->action->name;
    }

    sub other_action : Private {
        my ( $self, $c ) = @_;
        my $value = $c->snippet( $namespace, $key );
    }

=head1 DESCRIPTION

This plugin provides a means of setting data that can then be queried by a
client in a different request.

This is useful for making things such as progress meters and statistics amongst
other things.

This plugin provides an API for storing data, and a way to conveniently fetch
it too.

=head1 METHODS

=over 4

=item snippet $namespace, $key, [ $value ]

This is an accessor for the client exposed data.

If given a value it will set the value, and otherwise it will retrieve it.

=item serve_snippet [ $namespace, ] [ %options ]

This method will serve data bits to the client based on a key. The namespace
defaults to the action name.

The optional options array reference will take this values. This array will
take it's default first from C<< $c->config->{"snippets:$namespace"} >> and
then it will revert to C<< $c->config->{snippets} >>.

See the L</CONFIGURATION> section for detailed options.

=item serialize_snippet $value, \%options

This method is automatically called by C<serve_snippet> to serialize the
value in question.

=item send_snippet $value, \%options

This method is automatically called by C<serve_snippet> to set the response
body.

=back

=head1 INTERNAL METHODS

=over 4

=item setup

Set up configuration defaults, etc.

=back

=head1 CONFIGURATION

=over 4

=item format

This takes either C<json>, C<plain> (the default) or a code reference.

The C<json> format specifies that all values values will be serialized as a
JSON expression suitable for consumption by javascript. This is reccomended for
deep structures.

You can also use a code reference to implement your own serializer. This code reference should return two values: the content type, and a a value to set C<< $c->response->body >> to

=item allow_refs

If this is disabled reference values will raise an
error instead of being returned to the client.

This is true by default.

=item use_session_id

This fields allows you to automatically create a different "namespace" for each
user, when used in conjunction with L<Catalyst::Plugin::Session>.

This is false by default.

=item content_type

When the formatter type is C<plain> you may use this field to specify the
content-type header to use.

This option defaults to C<text/plain>.

=item json_content_type

Since no one seems to agree on what the "right" content type for JSON data is,
we have this option too ;-).

This option defaults to C<application/javascript+json>

=back

=head1 PRIVACY CONCERNS

Like session keys, if the values are private the key used by your code should
be sufficiently hard to guess to protect the privacy of your users.

Please use the C<use_session_id> option for the appropriate namespace unless
you have a good reason not to.

=head1 RECIPES

=head2 Ajax Progress Meter

Suppuse your app runs a long running process in the server.

    sub do_it {
        my ( $self, $c ) = @_;

        IPC::Run::run(\@cmd);

        # done
    }

The user might be upset that this takes a long while. If you can track
progress, along these lines:

    my $progress = 0;

    IPC::Run::run(\@cmd, ">", sub {
        my $output = shift;
        $progress++ if ( $output =~ /made_progress/ );
    });

then you can make use of this data to report progress to the user:

    $c->snippet( progress => $task_id => ++$progress )
        if ( $output =~ /made_progress/  );

Meanwhile, javascript code with timers could periodically poll the server using
an ajax request to update the progress level. To expose this data to the client
create an action somewhere:

    sub progress : Local {
        my ( $self, $c ) = @_;
        $c->serve_snippet;
    }

and have the client query for C<"/controller/progress/$task_id">.

=cut


