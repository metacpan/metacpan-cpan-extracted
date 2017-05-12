package Catmandu::Exporter::Table;

our $VERSION = '0.3.0';

use Catmandu::Sane;
use Moo;
use Text::MarkdownTable;
use IO::Handle::Util ();
use IO::File;
use JSON::XS ();

with 'Catmandu::Exporter';

# JSON Table Schema
has schema => (
    is => 'ro',
    coerce => sub {
        my $schema = $_[0];
        unless (ref $schema and ref $schema eq 'HASH') {
            $schema = \*STDIN if $schema eq '-';
            my $fh = ref $schema 
                    ? IO::Handle::Util::io_from_ref($schema) 
                    : IO::File->new($schema, "r");
            die "failed to load JSON Table Schema from $schema" unless $fh;
            local $/; 
            $schema = JSON::XS::decode_json(<$fh>);
        }
        $schema;
    }
);

has fields => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        return unless $_[0]->schema;
        [ map { $_->{name} } @{$_[0]->schema->{fields}} ];
    }
);

has columns => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        return unless $_[0]->schema;
        [ map { $_->{title} // $_->{name} } @{$_[0]->schema->{fields}} ];
    }
);

has widths   => (is => 'ro');
has condense => (is => 'ro');
has header   => (is => 'ro');

has _table => (
    is      => 'lazy',
    default => sub {
        Text::MarkdownTable->new(
            file => $_[0]->fh,
            map { $_ => $_[0]->$_ }
            grep { defined $_[0]->$_ }
            qw(fields columns widths condense header)
        );
    },
);

sub add { 
    $_[0]->_table->add($_[1]) 
}

sub commit { 
    $_[0]->_table->done 
}

1;
__END__

=head1 NAME

Catmandu::Exporter::Table - ASCII/Markdown table exporter

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-Exporter-Table.png)](https://travis-ci.org/LibreCat/Catmandu-Exporter-Table)
[![Coverage Status](https://coveralls.io/repos/LibreCat/Catmandu-Exporter-Table/badge.png)](https://coveralls.io/r/LibreCat/Catmandu-Exporter-Table)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-Exporter-Table.png)](http://cpants.cpanauthors.org/dist/Catmandu-Exporter-Table)

=end markdown

=head1 SYNOPSIS

With L<catmandu> command line client:

  echo '{"one":"my","two":"table"} {"one":"is","two":"nice"}' | \ 
  catmandu convert JSON --multiline 1 to Table
  | one | two   |
  |-----|-------|
  | my  | table |
  | is  | nice  |

  catmandu convert CSV to Table --fields id,name --columns ID,Name < sample.csv
  | ID | Name |
  |----|------|
  | 23 | foo  |
  | 42 | bar  |
  | 99 | doz  |

In Perl scripts:

  use Catmandu::Exporter::Table;
  my $exp = Catmandu::Exporter::Table->new;
  $exp->add({ title => "The Hobbit", author => "Tolkien" });
  $exp->add({ title => "Where the Wild Things Are", author => "Sendak" });
  $exp->add({ title => "One Thousand and One Nights" });
  $exp->commit;

  | author  | title                       |
  |---------|-----------------------------|
  | Tolkien | The Hobbit                  |
  | Sendak  | Where the Wild Things Are   |
  |         | One Thousand and One Nights |

=head1 DESCRIPTION

This L<Catmandu::Exporter> exports data in tabular form, formatted in
MultiMarkdown syntax.

The output can be used for simple display, for instance to preview Excel files
on the command line. Use L<Pandoc|http://johnmacfarlane.net/pandoc/> too
further convert to other table formats, e.g. C<latex>, C<html5>, C<mediawiki>:

    catmandu convert XLS to Table < sheet.xls | pandoc -t html5

By default columns are sorted alphabetically by field name.

=head1 CONFIGURATION

Table output can be controlled with the options C<fields>, C<columns>,
C<widths>, and C<condense> as documented in L<Text::MarkdownTable>. 

=over

=item file

=item fh

=item encoding

=item fix

Standard options of L<Catmandu:Exporter>

=item condense

Write table in condense format with unaligned columns.

=item fields

Field names as comma-separated list or array reference.

=item columns

Column names as comma-separated list or array reference. By default field
names are used as column names.

=item header

Include header lines. Enabled by default.

=item widths

Column widths as comma-separated list or array references. Calculated from all
rows by default. Long cell values can get truncated with this option.

=item schema

Supply fields and (optionally) columns in a L<JSON Table
Schema|http://dataprotocols.org/json-table-schema/> as JSON file or hash
reference having the following structure:

  {
    "fields: [
      { "name": "field-name-1", "title": "column title 1 (optional)" },
      { "name": "field-name-2", "title": "column title 2 (optional)" },
      ...
    ]
  }

=back

=head1 METHODS

See L<Catmandu::Exporter> 

=head1 SEE ALSO

This module is based on L<Text::MarkdownTable>.

Similar Catmandu Exporters for tabular data include
L<Catmandu::Exporter::CSV>, L<Catmandu::Exporter::XLS>, and
L<Catmandu::Exporter::XLSX>.

=cut
