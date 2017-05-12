use strict;
use warnings;

package CouchDB::View::Server;

use JSON::XS;
use IO::Handle;

my $j = JSON::XS->new;

{
  our @d;
  sub dmap { push @d, [@_] }
}

sub new  { bless $_[1] => $_[0] }

sub in   { @_ > 1 ? ($_[0]->{in}   = $_[1]) : $_[0]->{in}   }
sub out  { @_ > 1 ? ($_[0]->{out}  = $_[1]) : $_[0]->{out}  }
sub funs { @_ > 1 ? ($_[0]->{funs} = $_[1]) : $_[0]->{funs} }

my %fun_cache;

sub run {
  my $self = shift;

  $self = $self->new if not ref $self; # autovivify

  $self->in  or $self->in (IO::Handle->new_from_fd(\*STDIN, 'r'));
  $self->out or $self->out(IO::Handle->new_from_fd(\*STDOUT, 'w'));

  $self->out->autoflush(1);

  while (defined(my $line = $self->in->getline)) {
    $self->process($line);
  }
}

sub process {
  my ($self, $line) = @_;
  chomp($line);
  my $input = $j->decode($line);
  my ($cmd, @args) = @$input;
  $self->can($cmd)->($self, @args);
}

sub reset {
  my ($self) = @_;
  delete $self->{funs};
  $self->out->print("true\n");
}

sub add_fun {
  my ($self, $code) = @_;
  my $sub = $fun_cache{$code} ||= eval $code;
  if (my $e = $@) {
    $self->out->print(
      $j->encode({
        error => {
          id => "map_compilation_error",
          reason => $e,
        },
      }), "\n",
    );
  } else {
    push @{ $self->{funs} ||= [] }, $sub;
    $self->out->print("true\n");
  }
}

sub map_doc {
  my ($self, $doc) = @_;
  my @result;
  for my $sub (@{ $self->funs || [] }) {
    our @d;
    local @d;
    eval { $sub->($doc) };
    # we don't have any concept of 'fatal' yet
    if (my $e = $@) {
      warn $e;
    } else {
      push @result, [@d];
    }
  }

  $self->out->print($j->utf8->encode(\@result), "\n");
}


1;
__END__

=head1 NAME

CouchDB::View::Server

=head1 SYNOPSIS

In C</etc/couchdb/couch.ini>:

  [Couch Query Servers]
  # ... other view servers, like text/javascript
  # replace '/usr/local/bin' with the correct path on your machine
  text/perl=/usr/local/bin/couchdb-view-server.pl

That's it!  Errors will end up in the same place as other CouchDB errors.

The rest of this document will only be of interest to people who are
subclassing CouchDB::View::Server.

=head1 METHODS

=head2 reset

=head2 add_fun

=head2 map_doc

All these methods perform the functions described at L<the view server wiki
page|http://wiki.apache.org/couchdb/ViewServer>.

=head1 SEE ALSO

L<CouchDB::View::Document>
L<CouchDB::View>

=cut

=begin Pod::Coverage
  
  in
  out
  funs
  dmap
  new
  process
  run

=end Pod::Coverage
