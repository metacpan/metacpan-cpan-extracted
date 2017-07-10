=head1 NAME

Catmandu::Exporter::MARC::ALEPHSEQ - Exporter for MARC records to Ex Libris' Aleph sequential

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC to MARC --type ALEPHSEQ < /foo/data.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "/foo/bar.mrc" , type => 'ISO');
    my $exporter = Catmandu->exporter('MARC', file => "marc.txt", type => 'ALEPHSEQ' );

    $exporter->add($importer);
    $exporter->commit;

=head1 CONFIGURATION

=over

=item file

Write output to a local file given by its path or file handle.  Alternatively a
scalar reference can be passed to write to a string and a code reference can be
used to write to a callback function.

=item fh

Write the output to an L<IO::Handle>. If not specified,
L<Catmandu::Util::io|Catmandu::Util/IO-functions> is used to create the output
handle from the C<file> argument or by using STDOUT.

=item fix

An ARRAY of one or more fixes or file scripts to be applied to exported items.

=item encoding

Binmode of the output stream C<fh>. Set to "C<:utf8>" by default.

=back

=head1 METHODS

See L<Catmandu::Exporter>, L<Catmandu::Addable>, L<Catmandu::Fixable>,
L<Catmandu::Counter>, and L<Catmandu::Logger> for a full list of methods.

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut
package Catmandu::Exporter::MARC::ALEPHSEQ;
use Catmandu::Sane;
use Catmandu::Util qw(xml_escape is_different :array :is);
use List::Util;
use Moo;

our $VERSION = '1.161';

with 'Catmandu::Exporter', 'Catmandu::Exporter::MARC::Base';

has record               => (is => 'ro' , default => sub { 'record'});
has record_format        => (is => 'ro', default => sub { 'raw'} );
has skip_empty_subfields => (is => 'ro' , default => sub { 0 });

sub add {
    my ($self,$data) = @_;

    if ($self->record_format eq 'MARC-in-JSON') {
        $data = $self->_json_to_raw($data);
    }

    my $_id    = sprintf("%-9.9d", $data->{_id} // 0);
	my $record = $data->{$self->record};

    my @lines = ();

    for my $field (@$record) {
        my ($tag,$ind1,$ind2,@data) = @$field;

        $ind1 = ' ' unless defined $ind1;
        $ind2 = ' ' unless defined $ind2;

        @data = $self->_clean_raw_data($tag,@data) if $self->skip_empty_subfields;

        next if $#data == -1;

        # Joins are faster than perl string concatenation
        if (index($tag,'LDR') == 0) {
            my $ldr = $data[1];
            $ldr =~ s/ /^/og;
            push @lines , join('', $_id , ' ' , $tag , $ind1 , $ind2 , ' L ', $ldr );
        }
        elsif (index($tag,'008') == 0) {
            my $f008 = $data[1];
            $f008 =~ s/ /^/og;
            push @lines , join('', $_id , ' ' , $tag , $ind1 , $ind2 , ' L ', $f008 );
        }
        elsif (index($tag,'FMT') == 0 || index($tag,'00') == 0) {
            push @lines , join('', $_id , ' ' , $tag , $ind1 , $ind2 , ' L ', $data[1] );
        }
        else {
             my @line = ('', $_id , ' ' , $tag , $ind1 , $ind2 , ' L ');
             while (@data) {
                 my ($code,$val) = splice(@data, 0, 2);
                 next unless $code =~ /[A-Za-z0-9]/o;
                 next unless is_string($val);
                 $val =~ s{[[:cntrl:]]}{}g;
                 push @line , '$$' , $code , $val;
             }
             push @lines , join('', @line);
       }
    }

    $self->fh->print(join("\n",@lines) , "\n");
}

sub commit {
	my $self = shift;
	$self->fh->flush;
}

1;
