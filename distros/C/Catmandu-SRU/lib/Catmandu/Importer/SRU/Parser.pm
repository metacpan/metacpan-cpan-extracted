package Catmandu::Importer::SRU::Parser;

use Moo;
use XML::LibXML::Simple qw(XMLin);

our $VERSION = '0.428';

sub parse {
    my ($self, $record) = @_;

    return unless defined $record;

    # By default we use XML::LibXML::Simple to keep backwards compatible...
    my $xs = XML::LibXML::Simple->new();
    $record->{recordData}
        = $xs->XMLin($record->{recordData}, KeepRoot => 1, NsStrip => 1);

    $record;
}

1;
__END__

=head1 NAME

Catmandu::Importer::SRU::Parser - Package transforms SRU responses into Perl

=head1 SYNOPSIS

  package MyParser;

  use Moo;

  sub parse {
	my ($self,$record) = @_;
	my $schema  = $record->{recordSchema};
	my $packing = $record->{recordPacking};
	my $data    = $record->{recordData};

	... do some magic...

	return $perl_hash;
  }

=head1 DESCRIPTION

L<Catmandu::Importer::SRU> can optionally include a parser to transform the
returned records from SRU requests.  Any such parser needs to implement one
instance method C<parse> which receives an SRU-record and returns a perl hash.

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=cut
