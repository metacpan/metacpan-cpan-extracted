=head1 NAME

Catmandu::Importer::MARC::ISO - Package that imports ISO MARC records

=head1 SYNOPSIS

    # From the command line (ISO is the default importer for MARC)
    $ catmandu convert MARC --fix "marc_map('245a','title')" < /foo/bar.mrc

    # From perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/bar.mrc');
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
package Catmandu::Importer::MARC::ISO;
use Catmandu::Sane;
use Moo;
use MARC::File::USMARC;
use Catmandu::Importer::MARC::Decoder;

our $VERSION = '1.271';

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
    my $file = MARC::File::USMARC->in($self->fh);

    # MARC::File doesn't provide support for inline files
    $file = $self->decoder->fake_marc_file($self->fh,'MARC::File::USMARC') unless $file;
    sub  {
      $self->decoder->decode($file->next(),$self->id);
    }
}

1;
