package Catmandu::Exporter::Breaker;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use Carp;
use Path::Tiny;
use namespace::clean;

our $VERSION = '0.11';

with 'Catmandu::Exporter';

has fields  => (is => 'ro');
has handler => (is => 'rw', default => sub {'json'} , coerce => \&_coerce_handler );

sub _coerce_handler {
  my ($handler) = @_;

  return $handler if is_invocant($handler) or is_code_ref($handler);

  if (is_string($handler) && !is_number($handler)) {
      my $class = $handler =~ /^\+(.+)/ ? $1
        : "Catmandu::Exporter::Breaker::Parser::$handler";

      my $handler;
      eval {
          $handler = Catmandu::Util::require_package($class)->new;
      };
      if ($@) {
        croak $@;
      } else {
        return $handler;
      }
  }
  else {
  	  die "Need a Breaker::Parser"
  }
}

sub add {
	my ($self, $data) = @_;
	$self->handler->add($data,$self->fh,$self);
}

sub commit {
    my ($self) = @_;

    if ($self->fields) {
        my $tags = $self->handler->tags // {};
        my @tags = map { "$_\n" } sort keys %$tags;
        path($self->fields)->spew_utf8(@tags);
    }
}


1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::Breaker - Package that exports OAI-PMH DC in a Breaker format

=head1 SYNOPSIS

    # Using the default breaker
    $ catmandu convert JSON to Breaker < data.json

    # Using a OAI_DC breaker
    $ catmandu convert OAI --url http://biblio.ugent.be/oai to Breaker --handler oai_dc

    # Using a MARCXML breaker
    $ catmandu convert MARC to Breaker --handler marc

    # Using an XML breaker
    $ catmandu convert XML --path book to Breaker --handler xml < t/book.xml > data.breaker

    # Write a fields file containing all unique fields
    $ catmandu convert XML --path book to Breaker --handler xml --fields data.fields < t/book.xml > data.breaker

    # Find the usage statistics of fields in the XML file above
    $ catmandu breaker data.breaker

    # Convert the Breaker format by line into JSON
    $ catmandu convert Breaker < data.breaker

    # Convert the Breaker format by line into JSON using the fields file
    $ catmandu convert Breaker --fields data.fields < data.breaker

=head1 DESCRIPTION

Inspired by the article "Metadata Analysis at the Command-Line" by Mark Phillips in
L<http://journal.code4lib.org/articles/7818> this exporter breaks a metadata records
into the Breaker format which can be analyzed further by command line tools.

=head1 BREAKER FORMAT

   <record-identifier><tab><metadata-field><tab><metadata-value>

=head1 SEE ALSO

L<Catmandu::Importer::Breaker>

=cut
