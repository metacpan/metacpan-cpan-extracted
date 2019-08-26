package Catmandu::Fix::search_sru;

our $VERSION = '0.424';

use Moo;
use namespace::clean;
use Catmandu;
use Catmandu::Util::Path qw(as_path);
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Builder';

has path         => (fix_arg => 1);
has base         => (fix_arg => 1);
has recordschema => (fix_opt => 1, default => sub {'oai_dc'});
has parser       => (fix_opt => 1, default => sub {'simple'});
has limit        => (fix_opt => 1, default => sub {10});
has fixes        => (fix_opt => 1);

sub _build_fixer {
    my ($self) = @_;
    as_path($self->path)->updater(
        if_string => sub {
            my $query = shift;
            if (my $response = $self->sru_request($query)) {
                return $response if defined $response->[0];
            }
            return $query;
        }
    );
}

sub sru_request {
    my ($self, $query) = @_;
    my $importer = Catmandu->importer(
        'SRU',
        base         => $self->base,
        parser       => $self->parser,
        query        => $query,
        recordSchema => $self->recordschema,
        limit        => $self->limit,
    );
    my $records;
    if (my $fixes = $self->fixes) {
        my $fixer = Catmandu->fixer($fixes);
        $records = $fixer->fix($importer)->to_array;

    }
    else {
        $records = $importer->to_array;
    }
    return $records;
}

1;

__END__
 
=head1 NAME
 
Catmandu::Fix::search_sru - use the value as SRU query, and replace it by SRU search result
 
=head1 SYNTAX
  
 search_sru( <path>, <url> )
  
 search_sru( <path>, <url>, [recordschema:<SCHEMA>], [parser:<PARSER>], [limit:<INTEGER>], [fixes :<STRING|FILE>] )

 # From the command line

 $ echo '{"issn":"1940-5758"}' | catmandu convert JSON to YAML --fix 'search_sru(issn,"http://services.dnb.de/sru/zdb")'

 $ echo '{"issn":"dnb.iss = 1164-5563"}' | catmandu convert JSON to YAML --fix 'search_sru(issn, "http://services.dnb.de/sru/zdb", recordschema:MARC21-xml, parser:marcxml, fixes:"marc_map(245a,dc_title);remove_field(record)")'

=head1 PARAMETERS
 
=head2 path
 
The location in the perl hash where the query is stored.
 
See L<Catmandu::Fix/"PATHS"> for more information about paths.
 
=head2 url
 
Base URL of the SRU server.
 
=head2 recordschema
 
SRU record schema. Use SRU Explain operation to look up available schemas.
 
Default is 'oai_dc'.
 
=head2 parser
 
Controls how records are parsed before importing.

Available parsers: 'marcxml', 'meta', 'mods', 'picaxml', 'raw', 'simple', 'struct'. 
 
Default is 'simple'.

=head2 limit
 
Number of records to fetch. This is translated to SRU request parameter maximumRecords.

Default is 10.
 
=head2 fixes
 
 L<Catmandu::Fix> to transform the parsed records of the SRU response.
   
=head1 SEE ALSO
 
L<Catmandu::Fix>
 
L<Catmandu::SRU>
 
=head1 AUTHOR
 
Johann Rolschewski C<< <jorol at cpan.org> >>

=cut
