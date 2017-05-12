use strict;
use warnings;

package CouchDB::View::Document;

use URI::Escape;
use Data::Dump::Streamer;
use JSON::XS;

my $j = JSON::XS->new;

sub new { bless $_[1] => $_[0] }

sub code_to_string {
  my ($self, $code) = @_;
  return sprintf 'do { my $CODE1; %s; $CODE1 }
',
    Data::Dump::Streamer->new->Data($code)->Out;
}

sub as_hash {
  my ($self) = @_;
  return {
    $self->{_rev} ? (_rev => $self->{_rev}) : (),

    _id  => $self->{_id},

    language => 'text/perl',

    views => {
      map { 
        $_ => $self->code_to_string($self->{views}{$_})
      } keys %{ $self->{views} },
    },
  };
}

sub as_json {
  my ($self) = @_;

  return $j->encode($self->as_hash);
}

sub uri_id { uri_escape(shift->{_id}) }

1;
__END__

=head1 NAME

CouchDB::View::Document - CouchDB design document abstraction

=head1 SYNOPSIS

  my $doc = CouchDB::View::Document->new({
    _id => "_design/mystuff",
    views => {
      by_name => sub {
        my ($doc) = @_;
        dmap($doc->name, $doc);
      },
      by_whatsit => sub {
        my ($doc) = @_;
        require Whatsit::Parser;
        dmap(Whatsit::Parser->parse($doc), $doc);
      },
    },
  });

  # use with a hypothetical client
  $couchdb_client->put(
    '/mydatabase/' . $doc->uri_id,
    $doc->as_json,
  );

=head1 DESCRIPTION

CouchDB::View::Document provides a Perlish interface to creating L<CouchDB views|http://wiki.apache.org/couchdb/HttpViewApi>.  It uses L<Data::Dump::Streamer> to serialize coderefs, which are deserialized and used by L<CouchDB::View::Server>.

=head1 WRITING VIEWS

Read the L<CouchDB wiki page on views|http://wiki.apache.org/couchdb/Views> if
you have not already.  Only Perl specifics will be mentioned here.

The C<map> function is already used in Perl.  Instead, use C<dmap()> (as in the
L</SYNOPSIS>) to map keys to values.

Perl does not have C<null>.  Use C<undef>.

All the limitations of Data::Dump::Streamer apply to your view functions.  In
particular, if they use external modules, they will need to C<require> or
C<use> them explicitly (see the Whatsit::Parser example in the L</SYNOPSIS>).
Likewise, closed-over variables will be dumped, but external named subroutines
will not, so this won't work:

  sub elide {
    my $str = shift;
    $str =~ s/^(.{10}).+/$1.../;
    return $str;
  }

  my $doc = CouchDB::View::Document->new({
    ...
    views => {
      elided => sub {
        dmap(elide($doc->{title}), $doc);
      }
    },
  });

The definition of C<elide> is not transferred to the view server.

=head1 METHODS

=head2 new

  my $doc = CouchDB::View::Document->new(\%arg);

Create a new design document.  See the L<CouchDB view
API|http://wiki.apache.org/couchdb/HttpViewApi> for the details of C<\%arg>,
though C<language> is ignored (always 'text/perl').

=head2 as_json

  print $doc->as_json;

Use C<as_hash> (below) and JSON::XS to encode the result.  This is suitable for
passing directly to a PUT to CouchDB.

=head2 uri_id

  print $doc->uri_id;
  # '_design%2Fmyview'

Convenience method for the document name, since '/' must be escaped.

=head2 as_hash

  print Dumper($doc->as_hash);

Return a hashref suitable for serializing to JSON, including serialized
coderefs.

=head2 code_to_string

This method is called with a coderef and is expected to return a serialized
representation of it.  You probably don't need to use this unless you're
subclassing CouchDB::View::Document.

=head1 SEE ALSO

L<CouchDB::View::Server>
L<CouchDB::View>

=cut
