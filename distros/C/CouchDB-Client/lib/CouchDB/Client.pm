
package CouchDB::Client;

use strict;
use warnings;

our $VERSION = '0.09';

use JSON::Any       qw(XS JSON DWIW);
use LWP::UserAgent  qw();
use HTTP::Request   qw();
use Encode          qw(encode);
use Carp            qw(confess);

use CouchDB::Client::DB;

sub new {
	my $class = shift;
	my %opt = @_ == 1 ? %{$_[0]} : @_;

	my %self;
	if ($opt{uri}) {
		$self{uri} = $opt{uri};
		$self{uri} .= '/' unless $self{uri} =~ m{/$};
	}
	else {
		$self{uri} = ($opt{scheme} || 'http')      . '://' .
					 ($opt{host}   || 'localhost') . ':'   .
					 ($opt{port}   || '5984')      . '/';
	}
	$self{json} = ($opt{json} || JSON::Any->new(utf8 => 1, allow_blessed => 1));
	$self{ua}   = ($opt{ua}   || LWP::UserAgent->new(agent => "CouchDB::Client/$VERSION"));

	return bless \%self, $class;
}

sub testConnection {
	my $self = shift;
	eval { $self->serverInfo; };
	return 0 if $@;
	return 1;
}

sub serverInfo {
	my $self = shift;
	my $res = $self->req('GET');
	return $res->{json} if $res->{success};
	confess("Connection error: $res->{msg}");
}

sub newDB {
	my $self = shift;
	my $name = shift;
	return CouchDB::Client::DB->new(name => $name, client => $self);
}

sub listDBNames {
	my $self = shift;
	my $res = $self->req('GET', '_all_dbs');
	return $res->{json} if $res->{success};
	confess("Connection error: $res->{msg}");
}

sub listDBs {
	my $self = shift;
	return [ map { $self->newDB($_) } @{$self->listDBNames} ];
}

sub dbExists {
	my $self = shift;
	my $name = shift;
	$name =~ s{/$}{};
	return (grep { $_ eq $name } @{$self->listDBNames}) ? 1 : 0;
}

# --- CONNECTION HANDLING ---
sub req {
	my $self = shift;
	my $meth = shift;
	my $path = shift;
	my $content = shift;
	my $headers = undef;

	if (ref $content) {
		$content = encode('utf-8', $self->{json}->encode($content));
        $headers = HTTP::Headers->new('Content-Type' => 'application/json');
	}
	my $res = $self->{ua}->request( HTTP::Request->new($meth, $self->uriForPath($path), $headers, $content) );
	my $ret = {
		status  => $res->code,
		msg     => $res->status_line,
		success => 0,
	};
	if ($res->is_success) {
		$ret->{success} = 1;
		$ret->{json} = $self->{json}->decode($res->content);
	}
	return $ret;
}

# --- HELPERS ---
sub uriForPath {
	my $self = shift;
	my $path = shift() || '';
	return $self->{uri} . $path;
}


1;

=pod

=head1 NAME

CouchDB::Client - Simple, correct client for CouchDB

=head1 SYNOPSIS

	use CouchDB::Client;
	my $c = CouchDB::Client->new(uri => 'https://dbserver:5984/');
	$c->testConnection or die "The server cannot be reached";
	print "Running version " . $c->serverInfo->{version} . "\n";
	my $db = $c->newDB('my-stuff')->create;

	# listing databases
	$c->listDBs;
	$c->listDBNames;


=head1 DESCRIPTION

This module is a client for the CouchDB database.

=head1 METHODS

=over 8

=item new

Constructor. Takes a hash or hashref of options: C<uri> which specifies the server's URI;
C<scheme>, C<host>, C<port> which are used if C<uri> isn't provided and default to 'http',
'localhost', and '5984' respectively; C<json> which defaults to a JSON::Any object with
utf8 and allow_blessed turned on but can be replaced with anything with the same interface;
and C<ua> which is a LWP::UserAgent object and can also be replaced.

=item testConnection

Returns true if a connection can be made to the server, false otherwise.

=item serverInfo

Returns a hashref of the server metadata, typically something that looks like
C<<< { couchdb => "Welcome", version => "0.8.0-incubating"} >>>. It throws
an exception if it can't connect.

=item newDB $NAME

Returns a new C<CouchDB::Client::DB> object for a database of that name. Note that the DB
does not need to exist yet, and will not be created if it doesn't.

=item listDBNames

Returns an arrayref of all the database names that the server knows of. Throws an exception
if it cannot connect.

=item listDBs

Same as above but returns an arrayref of C<CouchDB::Client::DB> objects instead.

=item dbExists $NAME

Returns true if a database of that name exists, false otherwise.

=back

=head1 INTERNAL METHODS

You will use these at your own risk

=over 8

=item req $METHOD, $PATH, $CONTENT

$METHOD is the HTTP method to use; $PATH the part of the path that follows C<scheme://host:port/>;
and $CONTENT a Perl data structure. The latter, if present, is encoded to JSON and the request
is made using the given method and path. The return value is a hash containing a boolean indicating
C<success>, a C<status> being the HTTP response code, a descriptive C<msg>, and a C<json> field
containing the response JSON.

=item uriForPath $PATH

Gets a path and returns the complete URI.

=back

=head1 AUTHOR

Robin Berjon, <robin @t berjon d.t com>
Maverick Edwards, <maverick @t smurfbane d.t org> (current maintainer)

=head1 BUGS

Please report any bugs or feature requests to bug-couchdb-client at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CouchDB-Client.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Robin Berjon, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may
have available.

=cut
