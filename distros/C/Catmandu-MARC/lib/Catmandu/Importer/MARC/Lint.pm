=head1 NAME

Catmandu::Importer::MARC::Lint - Package that imports USMARC records validated with MARC::Lint

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type Lint --fix "marc_map('245a','title')" < /foo/data.mrc

    # From perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/data.mrc', type => 'Lint');
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

=head1 DESCRIPTION

All items produced with the Catmandu::Importer::MARC::Lint importer contain three keys:

     '_id'    : the system identifier of the record (usually the 001 field)
     'record' : an ARRAY of ARRAYs containing the record data
     'lint'   : the output of MARC::Lint's check_record on the MARC record

=head1 CONFIGURATION

=over

=item id

The MARC field which contains the system id (default: 001)

=item file

Read input from a local file given by its path. Alternatively a scalar
reference can be passed to read from a string.

=item fh

Read input from an L<IO::Handle>. If not specified, L<Catmandu::Util::io> is used to
create the input stream from the C<file> argument or by using STDIN.

=item encoding

Binmode of the input stream C<fh>. Set to C<:utf8> by default.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to imported items.

=back

=head1 METHODS

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited.

=head1 SEE ALSO

L<Catmandu::Importer>,
L<Catmandu::Iterable>

=cut
package Catmandu::Importer::MARC::Lint;
use Catmandu::Sane;
use Moo;
use MARC::File::USMARC;
use MARC::Lint;
use Catmandu::Importer::MARC::Decoder;

our $VERSION = '1.253';

with 'Catmandu::Importer';

has id        => (is => 'ro' , default => sub { '001' });
has decoder   => (
    is   => 'ro',
    lazy => 1 ,
    builder => sub {
        Catmandu::Importer::MARC::Decoder->new;
    } );

sub generator {
    my ($self) = @_;
    my $lint = MARC::Lint->new;
    my $file = MARC::File::USMARC->in($self->fh);
    # MARC::File doesn't provide support for inline files
    $file = $self->decoder->fake_marc_file($self->fh,'MARC::File::USMARC') unless $file;
    sub  {
       my $marc = $file->next();

       return undef unless $marc;
       
       my $doc  = $self->decoder->decode($marc,$self->id);
       $lint->check_record( $marc );
       $doc->{lint} = [$lint->warnings];
       $doc;
    }
}

1;
