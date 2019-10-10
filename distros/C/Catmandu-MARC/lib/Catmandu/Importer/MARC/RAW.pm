=head1 NAME

Catmandu::Importer::MARC::RAW - Package that imports ISO 2709 encoded MARC records

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC --type RAW --fix "marc_map('245a','title')" < /foo/bar.mrc

    # From perl
    use Catmandu;

    # import records from file
    my $importer = Catmandu->importer('MARC',file => '/foo/bar.mrc' , type => 'RAW');
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
package Catmandu::Importer::MARC::RAW;
use Catmandu::Sane;
use Moo;
use MARC::Parser::RAW;

our $VERSION = '1.252';

with 'Catmandu::Importer';

has id => (is => 'ro' , default => sub { '001' });

sub generator {
    my $self = shift;
    my $parser = MARC::Parser::RAW->new($self->fh);
    sub {
    	my $record = $parser->next();

        return undef unless defined $record;

    	my $id;
    	for my $field (@$record) {
    		my ($tag,$ind1,$ind2,$p,$data,@q) = @$field;
    		if ($tag eq $self->id) {
    			$id = $data;
    			last;
    		}
    	}

    	+{ _id => $id , record => $record };
    };
}


1;
