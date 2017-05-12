package CouchDB::ExternalProcess;

use strict;
use warnings;

use Attribute::Handlers;
use JSON::Any;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.02';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

my %actions = (
    _meta => \&_meta
);
my %metadata;

=head1 NAME

CouchDB::ExternalProcess - Make creating Perl-based external processs for CouchDB
easy

=head1 SYNOPSIS

In C<MyProcess.pm>:

  package MyProcess;
  use base qw/CouchDB::ExternalProcess/;

  sub _before {
      my ($self, $request) = @_;
      # Do something with the hashref $request
      return $request;
  }

  sub hello_world :Action {
      my ($self, $req) = @_;
      my $response = {
          body => "Hello, " . $req->{query}->{greeting_target} . "!"
      };
      return $response;
  }

  sub _after {
      my ($self,$response) = @_;
      # Do something with the hashref $response
      return $response;
  }

In CouchDB's C<local.ini>:

  [external]
  my_process = perl -MMyProcess -e 'MyProcess->new->run'

  [httpd_db_handlers]
  _my_process = {couch_httpd_external, handle_external_req, <<"my_process">>}


Now queries to the database I<databaseName> as:
  
  http://myserver/databaseName/_my_process/hello_world/?greeting_target=Sally

Will return a document with Content-Type "text/html" and a body containing:

  Hello, Sally!

For more information, including the request and response data structure formats,
see:

L<http://wiki.apache.org/couchdb/ExternalProcesses>
  
=head1 DESCRIPTION

This module makes creating CouchDB External Processes simple and concise.

=head1 USAGE


=head1 METHODS

=cut

=head2 new

Create an external process, just needs C<run()> to be called to start processing
STDIN.

=cut
sub new
{
    my ($class, %parameters) = @_;

    my $self = bless ({}, ref ($class) || $class);

    $self->jsonParser(JSON::Any->new);

    return $self;
}

=head2 run

Run the action, read lines from STDIN and process them one by one

Named arguments can be passed to run like run(a => 1, c => 2). 

Accepted arguments are:

=over

=item in_fh

File Handle to read input from. *STDIN by default

=item out_fh

File handle to write output to. *STDOUT by default

=back

=cut
sub run {
    my $self = shift;
    my %opts = @_;

    my $in_fh = $opts{in_fh} || *STDIN;
    my $out_fh = $opts{out_fh} || *STDOUT;

    $SIG{__DIE__} = sub {
        close($in_fh);
        close($out_fh);
        $self->_destroy();
        print STDERR "Error In ExternalProcess '".(ref $self)."': @_";
        exit();
    };

    $self->_init;

    $| = 1;
    while(my $reqJson = <$in_fh>) {
        my $output = $self->_process($reqJson);
        print $out_fh $output . $/;
    }

    close($in_fh);
    close($out_fh);

    $self->_destroy;
}

=head2 jsonParser

getter/setter for the JSON::Any instance used for an instance.

All methods of an ExternalProcess class should use this processor so they can
share the same magical 'true' and 'false' markers.

=cut
sub jsonParser {
    my ($self, $jp) = @_;
    $self->{jsonParser} = $jp if $jp;
    return $self->{jsonParser};
}

=head1 CHILD CLASS METHODS

These methods may be overridden by child classes to add processing to various
parts of the script and request handling lifecycle

=cut

=head2 _init

Called at program startup before any requests are processed.

=cut
sub _init {
}

=head2 _destroy

Called when STDIN is closed, or at program termination (if possible)

=cut
sub _destroy {
}

=head2 _before

Receives, and can manipulate or replace, the JSON request as hash reference
produced by JSON::Any before the requested action is processed. 

=cut
sub _before {
    return $_[1];
}

=head2 _after

Passed the return value of whatever action was called, as a hash reference
parseable by JSON::Any. May modify or replace it.

=cut
sub _after {
    return $_[1];
}

=head2 _error

Passed any errors that occur during processing. Returns a hash reference to be
used as the response.

The default response for an error $error is:

  {
      code => 500,
      json => {
          error => $error
      }
  }

=cut

sub _error {
    my ($self, $error) = @_;
    return {
        code => 500,
        json => {
            error => $error
        }
    }
}

=head2 _extract_action_name

Extracts the name of the action to handle a request. 

Receives the request object. Defaults to:

C<$req->{path}->[2]>

=cut
sub _extract_action_name {
    my ($self,$req) = @_;
    return $req->{path}->[2];
}

=head1 PROVIDED ACTIONS

=head2 _meta

Returns metadata about the methods we're providing

If your module has the following Actions:

  sub foo :Action :Description("Foo!") :Args("Some data") {
    # ... 
  }

  sub bar :Action
          :Description("Get your Bar on!")
          :Args({name => "Name of something", color => "RGB Color Value"}) 
  {
    # ... 
  }

Then requesting the '_meta' action will return the following JSON:

  {
    "foo": {
        "description": "Foo!",
        "args": "Some data"
    },
    "bar": }
        "description": "Get your Bar on!",
        "args": "Some data"
    }
  }

=cut
sub _meta {
    return {
        json => \%metadata,
    };
}

=head1 INTERNAL METHODS - Ignore these!

=head2 _process

Process a request.

Receives one argument, a JSON string, does all CouchDB::ExternalProcess
processing and returns a valid External Process response.

=cut
sub _process {
    my ($self, $reqJson) = @_;

    my $req = $self->jsonParser->jsonToObj($reqJson);
    my $response = {};

    # TODO: Strip first component off and use that as name?
    my $actionName = $self->_extract_action_name($req);

    eval {
        # Do we have the requested action ...
        if(!defined($actionName) || !defined($actions{$actionName})) {
            die("The specified action is not defined\n");
        }

        # Run _before
        $req = $self->_before($req);

        # Run the action
        $response = $actions{$actionName}->($self, $req);

        # Run _after
        $response = $self->_after($response);
    };

    if($@) {
        chomp($@);
        my $error = $@;
        eval {
            $response = $self->_error($error);
        };
        if($@) {
            $response->{code} = 500;
            $response->{json}->{error} = [ $error, $@ ];
        }
    }

    return $self->jsonParser->objToJson($response);
}


=head2 Action

Processes 'Action' Attribute

=cut
sub Action :ATTR {
    my $args = attrArgs(@_);
    my $subName = *{$args->{symbol}}{NAME};

    my @reservedNames = qw/
        _meta _init _error _destroy _before _after _process new run
    /;

    if(grep { $_ eq $subName} @reservedNames) {
        die("'$subName' is a reserved method name and cannot be used as an action name");
    }

    $actions{ $subName } = $args->{referent};
}

=head2 Description

Processes 'Description' Attribute

=cut
sub Description :ATTR {
    my $args = attrArgs(@_);
    die(":Description attribute must specify a string describing the method")
        unless $args->{data};
    my $subName = *{$args->{symbol}}{NAME};
    $metadata{ $subName } ||= {};
    $metadata{ $subName }->{description} = $args->{data};
}

=head2 Args

Processes 'Args' Attribute

=cut
sub Args :ATTR {
    my $args = attrArgs(@_);
    die(":Args attribute must specify a list of arguments the method accepts")
        unless $args->{data};
    my $subName = *{$args->{symbol}}{NAME};
    $metadata{ $subName } ||= {};
    $metadata{ $subName }->{args} = $args->{data};
}

=head2 attrArgs

Helper method to process Attribute::Handlers arguments

=cut
sub attrArgs {
    my %args;
    @args{qw/ package symbol referent attr data phase filename linenum /} = @_;
    return \%args;
}

=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Mike Walker
    CPAN ID: FANSIPANS
    mike-cpan-couchdb-externalprocess@napkindrawing.com
    http://napkindrawing.com/

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

CouchDB ExternalProcesses L<http://wiki.apache.org/couchdb/ExternalProcesses>

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

