=head1 NAME

Catmandu::Importer::MARC::Record - Package that imports an array of MARC::Record  

=head1 SYNOPSIS

    # From perl
    use Catmandu;
    use MARC::Record;

    my $record = MARC::Record->new();
    my $field = MARC::Field->new('245','','','a' => 'My title.');
    $record->append_fields($field);

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/data.mrc' , records => [$record]);
    my $fixer    = Catmandu->fixer("marc_map('245a','title')");

    $importer->each(sub {
        my $item = shift;
        ...
    });

    # or using the fixer

    $fixer->fix($importer)->each(sub {
        my $item = shift;
        printf "title: %s\n" , $item->{title};
    });

=head1 METHODS

=head2 new(records => [ <Marc::Record> , ... ] , id => $field)

Parse an array of L<MARC::Record> into a L<Catmandu::Iterable>. Optionally provide an
id attribute specifying the source of the system identifer '_id' field (e.g. '001').

=head1 INHERTED METHODS

=head2 count

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. 

=head1 SEE ALSO

L<MARC::Record>

=cut
package Catmandu::Importer::MARC::Record;
use Catmandu::Sane;
use Catmandu::Importer::MARC::Decoder;
use Moo;

our $VERSION = '1.13';

with 'Catmandu::Importer';

has id        => (is => 'ro' , default => sub { '001' });
has records   => (is => 'rw');
has decoder   => (
    is   => 'ro',
    lazy => 1 , 
    builder => sub {
        Catmandu::Importer::MARC::Decoder->new;
    } );

sub generator {
    my ($self) = @_;
    my @records = @{$self->records};

    sub  {
      $self->decoder->decode(shift @records, $self->id);
    }
}


1;