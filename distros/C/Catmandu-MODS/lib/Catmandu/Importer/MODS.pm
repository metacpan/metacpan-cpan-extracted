package Catmandu::Importer::MODS;

our $VERSION = "0.31";

use Catmandu::Sane;
use MODS::Record;
use Moo;

with 'Catmandu::Importer';

has type => (
    is => 'ro',
    isa => sub {
        die "type must be 'xml' or 'json'" unless grep { $_[0] eq $_ } qw(xml json);
    },
    lazy => 1,
    builder => sub {
        ($_[0]->file and $_[0]->file =~ /\.json$/) ? 'json' : 'xml';
    }
);

sub generator {
    my ($self) = @_;
    sub {
        state $i = 0;
        #result: MODS::Record::Mods or MODS::Record::ModsCollection
        state $mods = do {
            #starting from version 0.11 of MODS::Record utf8 is enabled by issuing JSON->new->utf8(1)
            if($MODS::Record::VERSION >= 0.11){
                if($self->type eq "json"){
                    $self->fh->binmode(":raw");
                }
            }
            #before version 0.11 of MODS::Record, decoding needed to be done yourself
            else{
                if($self->type eq "json"){
                    $self->fh->binmode(':utf8');
                }
            }
            my $m = $self->type eq "xml" ? MODS::Record->from_xml($self->fh) : MODS::Record->from_json($self->fh);
            my $res = ref($m) eq "MODS::Element::Mods" ? [$m] : $m->mods;
            $res;
        };
        return $i < scalar(@$mods) ? $mods->[$i++] : undef;
    };
}

1;
__END__

=head1 NAME

Catmandu::Importer::MODS - Catmandu Importer for importing mods records

=head1 SYNOPSIS

  use Catmandu::Importer::MODS;

  my $importer = Catmandu::Importer::MODS->new(file => "modsCollection.xml");

  my $numModsElements = $importer->each(sub{
      my $modsElement = shift; # a MODS::Element::Mods object
  });

=head1 DESCRIPTION

This L<Catmandu::Importer> reads MODS records to be processed with L<Catmandu>.
In case of a simple "mods" document, one  L<MODS::Element::Mods> item is
imported. In case of a "modsCollection", several items are imported.

See L<Catmandu::Importer>, L<Catmandu::Iterable>, L<Catmandu::Logger> and
L<Catmandu::Fixable> for methods and options derived from these modules.

Make sure your files are expressed in UTF-8.

=head1 CONFIGURATION

=over

=item type

Set to C<xml> by default, as MODS is usually expressed in XML. Use C<json> (or
provide a file with extension C<.json>) for a custom JSON format, introduced in
module L<MODS::Record>.

=back

=head1 SEE ALSO

See L<Catmandu::MODS> for more information about MODS and Catmandu.

=cut
