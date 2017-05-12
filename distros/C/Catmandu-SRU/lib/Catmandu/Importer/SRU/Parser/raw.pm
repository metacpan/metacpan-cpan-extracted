=head1 NAME

  Catmandu::Importer::SRU::Parser::raw - Package transforms SRU responses into a Perl hash

=head1 SYNOPSIS

my %attrs = (
    base => 'http://www.unicat.be/sru',
    query => '(isbn=0855275103 or isbn=3110035170 or isbn=9010017362 or isbn=9014026188)',
    recordSchema => 'marcxml' ,
    parser => 'raw' ,
);

my $importer = Catmandu::Importer::SRU->new(%attrs);

=head1 DESCRIPTION

Transforms each SRU record into a Perl hash containing the following fields:

  * recordSchema - the SRU record schema (see: http://www.loc.gov/standards/sru/recordSchemas/index.html)
  * recordPacking - the SRU format (can be 'string' or 'xml')
  * recordPosition - the result number
  * recordData - the unparsed record payload 

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=cut
package Catmandu::Importer::SRU::Parser::raw;

use Moo;

sub parse {
	return $_[1];
}

1;