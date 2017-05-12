package CGI::Application::Plugin::JSON;
use warnings;
use strict;
use JSON::Any;
use base 'Exporter';

our @EXPORT_OK = qw(
    to_json
    from_json
    json_header 
    json_body
    json_callback
    add_json_header 
    clear_json_header 
    json_header_string 
    json_header_value
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

=head1 NAME

CGI::Application::Plugin::JSON - easy manipulation of JSON headers

=cut

our $VERSION = '1.02';

=head1 SYNOPSIS

    use CGI::Application::Plugin::JSON ':all';

    # add_json_header() is cumulative
    $self->add_json_header( foo => 'Lorem ipsum...');
    $self->add_json_header( bar => [ 0, 2, 3, 4 ] );
    $self->add_json_header( baz => { stuff => 1, more_stuff => 2 } );

    # json_header() is not cumulative
    $self->json_header( foo => 'Lorem ipsum...');

    # in case we're printing our own headers
    print "X-JSON: " . $self->json_header_string();

    # clear out everything in the outgoing JSON headers
    $self->clear_json_header();

    # or send the JSON in the document body
    $self->json_body( { foo => 'Lorem ipsum', bar => [ 0, 2, 3 ] } );

    # send the JSON back in the document body, but execute it using a Javascript callback
    $self->json_callback('alert', { foo => 'Lorem ipsum', bar => [ 0, 2, 3 ] } );

=head1 DESCRIPTION

When communicating with client-side JavaScript, it is common to send
data in C<X-JSON> HTTP headers or through the document body as content-type
C<application/json>.

This plugin adds a couple of convenience methods to make that just a 
little bit easier.

=head1 HEADER METHODS

=head2 json_header

This method takes name-value pairs and sets them to be used in the outgoing
JSON. It is not cummulative and works similarly to C<header_props>. Use it
only if you have all of the values up front. In most cases L<add_json_header>
is probably what you want.

    # only the 2nd call will actually set data that will be sent
    $self->json_header( foo => 'Lorem ipsum...');
    $self->json_header( bar => [ 0, 2, 3, 4 ] );

=cut 

sub json_header {
    my ($self, %data) = @_;
    my $private = $self->param('__CAP_JSON') || {};
    $private->{header} = \%data;
    $self->param('__CAP_JSON' => $private);
    return ' '; # so it can be used as the return value from an rm
}

=head2 add_json_header

This method takes name-value pairs and sets them to be used in the outgoing
JSON. It is cummulative and works similarly to C<header_add>; meaning multiple
calls will add to the hash of outgoing values.

    # both 'foo' and 'bar' will exist in the hash sent out 
    $self->json_header( foo => 'Lorem ipsum...');
    $self->json_header( bar => [ 0, 2, 3, 4 ] );

=cut

sub add_json_header {
    my ($self, %data) = @_;
    my $private = $self->param('__CAP_JSON') || {};
    $private->{header} ||= {};
    $private->{header} = { %{$private->{header}}, %data };
    $self->param('__CAP_JSON' => $private);
    return ' '; # so it can be used as the return value from an rm
}

=head2 clear_json_header

This method will remove anything that was previously set by both L<json_header>
and L<add_json_header>. This means that no C<X-JSON> header will be sent.

=cut

sub clear_json_header {
    my $self = shift;
    my $private = $self->param('__CAP_JSON') || {};
    delete $private->{header};
    $self->param('__CAP_JSON' => $private);
}

=head2 json_header_string

This method will create the actual HTTP header string that will be sent
to the browser. This plugin uses it internally to send the header, but
it might be useful to use directly if you are printing your own HTTP headers
(using a C<header_type> of C<none>).

    $self->header_type('none');
    print $self->json_header_string();

=cut

sub json_header_string {
    my $self = shift;
    my $private = $self->param('__CAP_JSON') || {};
    return $self->to_json($private->{header} || {});
}

=head2 json_header_value

This method will return the values being sent in the JSON header.
If you pass in the key of the value you want, you will get just that
value. Else all name-value pairs will be returned.

    my $value = $self->json_header_value('foo');

    my %values = $self->json_header_value();

=cut

sub json_header_value {
    my ($self, $key) = @_;
    my $private = $self->param('__CAP_JSON') || {};

    if( defined $private->{header} ) {
        if( defined $key ) {
            return $private->{header}->{$key};
        } else {
            return %{$private->{header}};
        }
    } else {
        return;
    }
}

=head1 BODY METHODS

=head2 json_body

This method will take the given Perl structure, turn it
into JSON, set the appropriate content-type, and then
return the JSON.

    return $self->json_body({ foo => 'stuff', bar => [0,1,2,3]} );

=cut

sub json_body {
    my ($self, $data) = @_;
    my $private = $self->param('__CAP_JSON') || {};
    $private->{json_body} = 1;
    $self->param(__CAP_JSON => $private);
    return $self->to_json($data);
}

=head2 json_callback

This method will take the given Perl structure, turn it
into JSON, set the appropriate content-type, and then
return a Javascript snippet where the given callback
is called with the resulting JSON.

    return $self->json_callback('alert', { foo => 'stuff', bar => [0,1,2,3]} );

    # would result in something like the following being sent to the client
    alert({ foo => 'stuff', bar => [0,1,2,3]});

=cut

sub json_callback {
    my ($self, $callback, $data) = @_;
    my $private = $self->param('__CAP_JSON') || {};
    $private->{json_callback} = 1;
    $self->param(__CAP_JSON => $private);
    return $callback . '(' . $self->to_json($data) . ')';
}
=head1 MISC METHODS

=head2 to_json

This method is just a convenient wrapper around L<JSON::Any>'s C<encode>.

=cut

sub to_json {
    my ($self, $data) = @_;
    return JSON::Any->encode($data);
}

=head2 from_json

This method is just a convenient wrapper around L<JSON::Any>'s C<decode>.

=cut

sub from_json {
    my ($self, $data) = @_;
    return JSON::Any->decode($data);
}

sub import {
    my $caller = scalar(caller);
    $caller->add_callback( postrun => \&_send_headers );

    __PACKAGE__->export_to_level(1, @_);
}

sub _send_headers {
    my $self = shift;
    my $private = $self->param('__CAP_JSON') || {};

    if( defined $private->{header} ) {
        $self->header_add( '-x-json' => $self->json_header_string );
    }

    if( defined $private->{json_body} ) {
        $self->header_add('-type' => 'application/json');
    } elsif ( defined $private->{json_callback} ) {
        $self->header_add('-type' => 'text/javascript');
    }
}

1;

__END__

=head1 AUTHOR

Michael Peters, C<< <mpeters@plusthree.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-viewsource@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-JSON>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Michael Peters, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

