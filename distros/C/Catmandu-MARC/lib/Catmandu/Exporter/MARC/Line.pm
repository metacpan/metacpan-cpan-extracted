=head1 NAME

Catmandu::Exporter::MARC::Line - Exporter for MARC records to Index Data's MARC Line format

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert MARC to MARC --type Line < t/camel.mrc

    # From Perl
    use Catmandu;

    my $importer = Catmandu->importer('MARC', file => "t/camel.mrc", type => 'ISO');
    my $exporter = Catmandu->exporter('MARC', file => "camel.line", type => 'Line' );

    $exporter->add($importer);
    $exporter->commit;

=head1 CONFIGURATION

=over

=item file

Write output to a local file given by its path or file handle. Alternatively a
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

=head1 AUTHOR

Johann Rolschewski,  E<lt>jorol at cpanE<gt>

=head1 SEE ALSO

L<Catmandu::Exporter>

=cut

package Catmandu::Exporter::MARC::Line;
use Catmandu::Sane;
use Moo;

our $VERSION = '1.271';

with 'Catmandu::Exporter', 'Catmandu::Exporter::MARC::Base';

has record        => (is => 'ro', default => sub {'record'});
has record_format => (is => 'ro', default => sub {'raw'});

sub add {
    my ($self, $data) = @_;

    if ($self->record_format eq 'MARC-in-JSON') {
        $data = $self->_json_to_raw($data);
    }

    for my $field (@{$data->{record}}) {
        my ($field, $ind1, $ind2, @sf) = @$field;

        if (!defined($ind1) || $ind1 =~ /^\s*$/) {$ind1 = ' '}
        if (!defined($ind2) || $ind2 =~ /^\s*$/) {$ind2 = ' '}

        next unless ($field =~ /^(LDR|\d{3})/);

        my @sf_map = ();

        for (my $i = 0; $i < @sf; $i += 2) {
            if ($field eq 'LDR' || $field < 10) {
                push @sf_map, $sf[$i + 1] if (defined($sf[$i + 1]));
            }
            else {
                push @sf_map, '$' . $sf[$i], $sf[$i + 1]
                    if (defined($sf[$i + 1]));
            }
        }

        my $sf_str = join(" ", @sf_map);

        my $line;

        if ($field =~ /^\d{3}$/ && $field >= 10) {
            $line = "$field $ind1$ind2 $sf_str\n";
        }
        elsif ($field eq 'LDR') {
            $line = "$sf_str\n";
        }
        else {
            $line = "$field $sf_str\n";
        }

        $self->fh->print($line);
    }

    $self->fh->print("\n");
}

sub commit {
    my ($self) = @_;
    $self->fh->flush;

    1;
}

1;
