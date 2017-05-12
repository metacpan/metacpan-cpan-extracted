package Data::Google::Visualization::DataSource;
BEGIN {
  $Data::Google::Visualization::DataSource::VERSION = '0.01';
}

use strict;
use warnings;

use Moose;
use Clone qw/clone/;
use JSON::XS;
use Digest::MD5 qw/md5_hex/;

=head1 NAME

Data::Google::Visualization::DataSource - Google Chart Datasources

=head1 VERSION

version 0.01

=head1 DESCRIPTION

Helper class for implementing the Google Chart Tools Datasource Protocol (v0.6)

=head1 SYNOPSIS

 # Step 1: Create the container based on the HTTP request
 my $datasource = Data::Google::Visualization::DataSource->new({
    tqx => $q->param('tqx'),
    xda => ($q->header('X-DataSource-Auth') || undef)
 });

 # Step 2: Add data
 $datasource->datatable( Data::Google::Visualiation::DataSource object );

 # Step 3: Show the user...
 my ( $headers, $body ) = $datasource->serialize;

 printf("%s: %s\n", @$_) for $headers;
 print "\n" . $body . "\n";

=head1 OVERVIEW

The L<Google Visualization API|https://developers.google.com/chart/interactive/docs/reference>
is a nifty bit of kit for generating pretty pictures from your data. By design
it has a fair amount of Google-cruft, such as non-standard JSON and stuffing
configuration options in to a single CGI query parameter. It's also got somewhat
confusing documentation, and some non-obvious rules for generating certain
message classes.

L<Data::Google::Visualization::DataTable> takes care of preparing data for the
API, but this module implements the I<Google Chart Tools Datasource Protocol>,
or I<Google Visualization API wire protocol>, or whatever it is they've decided
to call it this week.

B<This documentation is not laid out like standard Perl documentation, because
it needs extra explanation. You should read this whole document sequentially if
you wish to make use of it.>

=head1 THREE SIMPLE STEPS

There's quite a bit of logic around how to craft a response, how to throw
errors, how to throw warnings, etc. After some thought, I have discovered an
interface that hopefully won't make you want to throw yourself off a cliff.

At its essence, Google Datasources allow querying clients to specify a I<lot>
about what they want the response to look like. This information is specified
in the C<tqx> parameter
(L<Request Format|https://developers.google.com/chart/interactive/docs/dev/implementing_data_source#requestformat>)
and also somewhat implied by the existence of an C<X-DataSource-Auth> header.

In order to use this module, you will need to create a container for the
outgoing data. This is as easy as passing in whatever the caller gave you as
their C<tqx> parameter.

You then set any data and any messages you wish to. This is your chance to tell
the user they're not logged in, or you can't connect to the database, or - if
everything worked out, build and set the
L<Data::Google::Visualization::DataTable> object they're ultimately requesting.

Finally, serialize attempts to build the response, checking the messages to see
if we should return an error or actual data, and giving you appropriate headers
and the body itself.

=head2 Container Creation

Our first job is to specify what the response container will look like, and the
easiest way to do this is to pass C<new()> the contents of the C<tqx> parameter
and the C<X-DataSource-Auth> header.

=head3 new()

 # Give the user what they requested
 ->new({ tqx => $q->param('tqx') });

 # Be conscientious and pass in contents of X-DataSource-Auth
 ->new({
    tqx => $q->param('tqx'),
    datasource_auth => $q->header('X-DataSource-Auth')
 });

 # Set it by hand...
 ->new({ reqId => 3, out => 'json', sig => 'deadbeef' });

C<new()> will set the following object attributes based on this, all based on
the I<Request Format> linked above:

=over 4

=item C<reqId> - allegedy required, and required to be an int. In fact, the
documentation reveals that if you leave it blank, it should default to 0.

=item C<version> - allows the calling client to specify the version of the API
it wishes to use. Please note this module currently ONLY CLAIMS TO support
C<0.06>. If any other version is passed, a C<warning> message will be added, but
we will try to continue anyway - see L<Adding Messages> below.

=item C<sig> - allows the client to specify an identifier for the last request
retrieved, so it's not redownloaded. If the C<sig> matches the data we were
about to send, we'll follow the documentation, and add an C<error> message, as
per L<Adding Messages> below.

=item C<out> - output format. This defaults to C<json>, although whether JSON or
JSONP is returned depends on if C<X-DataSource-Auth> has been included - see the
Google docs. Other formats are theoretically provided for, but this version of
the software doesn't support them, and will add an C<error> message (at
serialization time) if they're specified.

=item C<responseHandler> - in the case of our outputting JSONP, we wrap our
payload in a function call to this method name. It defaults to
C<google.visualization.Query.setResponse>. An effort is made to strip out
unsafe characters.

=item C<outFileName> - certain output formats allow us to specify that the data
should be returned as a named file. This is simply ignored in this version.

=item C<datasource_auth> - this does NOT correspond to the normal request object
- instead it's used to capture the C<X-DataSource-Auth> header, whose presence
will cause us to output JSON instead of using the C<responseHandler>.

=back

=cut

# Inputs
has 'datatable' =>
    ( is => 'rw', isa => 'Data::Google::Visualization::DataTable' );
has 'datasource_auth' =>
    ( is => 'rw', isa => 'Str', required => 0 );
has 'reqId' => # Set to Str as we only want to throw an error at inst time
    ( is => 'rw', isa => 'Str', default => 0 );
has 'version' =>
    ( is => 'rw', isa => 'Str', required => 0 );
has 'sig' =>
    ( is => 'rw', isa => 'Str', required => 0, default => '' );
has 'out' =>
    ( is => 'rw', isa => 'Str', default => 'json' );
has 'responseHandler' =>
    ( is => 'rw', isa => 'Str', default => 'google.visualization.Query.setResponse' );
has 'outFileName' =>
    ( is => 'rw', isa => 'Str', required => 0 );

my %allowed_keys = map { $_ => 1 }
    qw/reqId version sig out responseHandler outFileName/;

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $options = shift;
    my $tqx = delete $options->{'tqx'} || '';
    for my $option ( split(/;/, $tqx ) ) {
        my ( $key, $value ) = split(/:/, $option);
        $options->{ $key } = $value if $allowed_keys{ $key };
    }

    $class->$orig( $options );
};

=head2 Adding Messages

Having created our container, we then need to put data in it. There are two
types of data - messages, and the DataTable.

Messages are errors or warnings that need to be passed back to the client, but
they also have potential to change the rest of the data payload. The following
algorithm is used:

 1. Have any error messages been added? If so, discard all but the first, set
    the response status to 'error', and discard the DataTable and all warning
    messages. We discard all the other messages (error and warning) to prevent
    malicious data discovery.

 2. An integrity check is run on the attributes that have been set. We check the
    attributes listed above, and generate any needed messages from those. If we
    generate any error messages, step 1 is rerun.

 2. Have any warning messages been added? If so, set the response status to
    'warning'. Include all warning messages and the DataTable in the response.

 3. If there are no warning or error messages, set the response status to 'ok',
    and include the DataTable in the response.

When messages are described as discarded, they are not included in the returned
C<body> - they're still available to the developer in the returned C<messages>.
See the documentation on C<serialize> below.

=head3 add_message()

Messages are added using the C<add_message> method:

 $datasource->add_message({
    type    => 'error',         # Required. Can also be 'warning'
    reason  => 'access_denied', # Required. See Google Docs for allowed options
    message => 'Unauthorized User', # Optional
    detailed_message => 'Please login to use the service' # Optional
 });

=cut

has 'messages' => ( is => 'rw', isa => 'HashRef[ArrayRef]',
    default => sub {
        { errors => [], warnings => [] }
    } );
our $allowed_messages = {
    warning => {
        data_truncated => 1,
        other => 1,
    },
    error => {
        not_modified => 1,
        user_not_authenticated => 1,
        unknown_data_source_id => 1,
        access_denied => 1,
        unsupported_query_operation => 1,
        invalid_query => 1,
        invalid_request => 1,
        internal_error => 1,
        not_supported => 1,
        illegal_formatting_patterns => 1,
        other => 1,
    }
};

sub add_message {
    my ( $self, $options ) = @_;
    die sprintf(
        "Type: %s Reason: %s not permitted by spec",
        $options->{'type'}, $options->{'reason'}
    ) unless $allowed_messages
        ->{$options->{'type'}}
        ->{$options->{'reason'}};

    my $message = {
        reason => $options->{'reason'},
        ( $options->{'message'} ? (message => $options->{'message'}) : () ),
        ( $options->{'detailed_message'} ?
            (message => $options->{'detailed_message'}) : () ),
    };
    push( @{ $self->messages->{ $options->{ 'type' } . 's'} }, $message);
    $message;
}

=head3 datatable

The datatable is added via the C<datatable> method:

 $datasource->datatable( $datatable_object );

and must be a L<Data::Google::Visualization::DataTable> object. If you know
you've already added an C<error> message, you don't need to set this - it won't
be checked.

=head2 Generating Output

Up to this point, we've just accumulated data without actually acting on it. If
the user has specified some inputs we can't handle, well we haven't checked that
yet.

To kick the whole circus off, call C<serialize>.

=head3 serialize

 my ( $headers, $body, $messages ) = $datasource->serialize();

Serialize accepts no arguments, and does not change the state of the underlying
object. It returns:

B<headers>

An arrayref or arrayrefs, which in B<this version of this module> will always
be:

 [[ 'Content-Type', 'text/javascript' ]]

However, don't use that knowledge, as future versions will definitely add new
headers, based on other user options - C<Content-Disposition>, for starters.
You should return all received headers to the user. As future versions will
allow returning of different data types, you must allow control of
C<Content-Type> and C<Content-Disposition> to fall to this module in their
entirity.

B<body>

A JSON-like string containing the response. Google JSON is not real JSON (see
the continually linked documentation), and what's more, this may well be JSONP
instead. This string will come back UTF-8 encoded, so make sure whatever you're
serving this with doesn't re-encode that.

B<messages>

 {
    errors => [
        {
            reason  => 'not_modified',
            message => 'Data not modified'
        }
    ]
    warnings => []
 }

A hashref of arrayrefs containing all messages raised. You B<must not> show this
to the user - it's purely for your own debugging. When we talk about messages
being discarded in the L<Adding Messages> section, they will turn up here
instead. B<DO NOT MAKE DECISIONS ABOUT WHAT TO RETURN TO THE USER BY POKING
THROUGH THIS DATA>. The C<not_modified> error is a great example of why not - it
is not an error for the user, and the user has to act a certain way on getting
it - it's expected in the normal course of use.

=cut

sub serialize {
    my $self = shift;

    # First build the minimal payload, based on inputs
    my $payload = {
        version => 0.6,
        reqId   => 0 + ($self->reqId || 0),
    };

    # Build the default headers
    my $headers = [
        [ 'Content-type', 'text/javascript' ]
    ];

    # Work with the messages
    if ( $self->messages->{'errors'}->[0] ) {
        # Set the status to error
        $payload->{'status'} = 'error';

        # Don't include more than the first, as per the docs
        $payload->{'errors'} = [ %{ $self->messages->{'errors'}->[0] } ];

        # We don't actually have anything more to add at this point, except the
        # type-appropriate wrapping.
        return $headers, $self->_wrap( $payload ), clone( $self->messages );

    } elsif ( $self->messages->{'warnings'}->[0] ) {
        # Set the status to warning
        $payload->{'status'} = 'warning';
        $payload->{'warnings'} = clone($self->messages->{'warnings'});
    } else {
        $payload->{'status'} = 'ok';
    }

    # Add any data
    die "You must set a Data::Google::Visualization::DataTable via 'datatable' unless you've set an error message"
        unless ( $self->datatable && $self->datatable->can('output_javascript') );
    $payload->{'table'} = $self->datatable->output_javascript;

    # Check for non-modified via sig. We need a way of serializing
    # the payload hash in the same way each time, which means ordering
    # the keys
    my $checksum_data =
        encode_json [$headers, @{$payload}{qw/ status table warnings /}];
    my $checksum = md5_hex( $checksum_data );
    $payload->{'sig'} = $checksum;

    if ( $self->sig eq $checksum_data ) {
        return $headers, $self->_wrap({
            status => 'error',
            errors => [{reason => 'not_modified', message => 'Data not modified'}]
        }), clone( $self->messages );
    }

    # OK, all good. Let's do this...
    return $headers, $self->_wrap( $payload ), clone( $self->messages );
}

my $_placeholder = "2ox3Rb3dxrYisGnZPMkgiqiwsdeCLFv8eb3atZbjdCYWYdmR6i";
sub _wrap {
    my ( $self, $payload ) = @_;

    # Generate the payload. Because of the fake JSON, we're going to
    # create a JSON-a-like string with a placeholder, and then put
    # the datatable in that placeholder.
    my $potential = encode_json({
        reqId => $self->reqId,
        status => $payload->{'status'},
        ( $self->messages->{'errors'}->[0] ?
            ( errors => [$self->messages->{'errors'}->[0]] ) :
            ( $self->messages->{'warnings'}->[0] ?
                ( warnings => $self->messages->{'warnings'} ) :
                ()
            )
        ),
        ($payload->{'table'} ?
            ( table => $_placeholder ) : () ),
        ( $payload->{'sig'} ? (sig => $payload->{'sig'}) : () )
    });
    if ( my $dt = $payload->{'table'} ) {
        $potential =~ s/"$_placeholder"/$dt/;
    }

    # Wrap it as appropriate
    unless ( $self->datasource_auth ) {
        my $wrap = $self->responseHandler;
        $potential = sprintf(
            "%s(%s);", $wrap, $potential
        );
    }

    # Hand it all back to the user
    return $potential;
}

=head1 BUGS, TODO

It'd be nice to support the other data types, but currently
L<Data::Google::Visualization::DataTable> serializes its data a little too early
which makes this impracticle. I tend to do hassle-related development, so if you
are in desparate need of this feature, I recommend emailing me.

=head1 SUPPORT

If you find a bug, please use
L<this modules page on the CPAN bug tracker|https://rt.cpan.org/Ticket/Create.html?Queue=Data-Google-Visualization-DataSource>
to raise it, or I might never see.

=head1 AUTHOR

Peter Sergeant C<pete@clueball.com>

=head1 SEE ALSO

L<Data::Google::Visualization::DataTable> - for preparing your data

L<Python library that does the same thing|http://code.google.com/p/google-visualization-python/>

L<Google Visualization API|http://code.google.com/apis/visualization/documentation/reference.html#dataparam>.

L<Github Page for this code|https://github.com/sheriff/data-google-visualization-datatable-perl>

=head1 COPYRIGHT

Copyright 2012 Peter Sergeant, some rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;