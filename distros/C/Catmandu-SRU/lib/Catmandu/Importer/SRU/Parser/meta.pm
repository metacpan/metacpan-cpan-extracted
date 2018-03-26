package Catmandu::Importer::SRU::Parser::meta;

use Moo;

sub parse { }

1;
__END__

=head1 NAME

Catmandu::Importer::SRU::Parser::meta - Package transforms SRU responses metadata into a Perl hash

=head1 SYNOPSIS

  my $importer = Catmandu::Importer::SRU->new(
    base   => 'http://www.unicat.be/sru',
    query  => 'tit=cinema',
    parser => 'meta',
  );

=head1 DESCRIPTION

This L<Catmandu::Importer::SRU::Parser> returns a single item with the
L<SRU SearchRetrieve Response Parameters|http://www.loc.gov/standards/sru/sru-1-1.html#responseparameters>
of a request.

=over

=item version

SRU version of the response, e.g. C<1.1>.

=item numberOfRecords

Number of records matched by the query. If the query fails this will be C<0>.

=item resultSetId

Identifier for a result set that was created through the execution of the query.

=item resultSetIdleTime

Number of seconds after which the created result set will be deleted.

=item nextRecordPosition

Next position within the result set following the final returned record (unless
this is the last part of the result set).

=item diagnostics

An array of diagnostics, each with C<uri>, C<details> (optional), and C<message> (optional).

=item extraResponseData

Additional, profile specific information.

=item echoedSearchRetrieveRequest

The request parameters as hash of key-value pairs.

=back

In addition field C<requestUrl> contains the full request URL.

=cut
