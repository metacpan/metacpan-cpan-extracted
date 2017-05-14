package Catmandu::Exporter::PNX;

use Catmandu::Sane;

our $VERSION = '0.03';

use Moo;
use Catmandu::PNX;

with 'Catmandu::Exporter';

has 'pnx'      => (is => 'lazy');

sub _build_pnx {
    return Catmandu::PNX->new;
}

sub add {
    my ($self, $data) = @_;

    my $id = $data->{control}->{sourcerecordid} // 'undefined';

    if ($self->count == 0) {
        $self->fh->print($self->_oai_header());
    }

    my $deleted = $data->{deleted} ? 1 : 0;

    $self->fh->print($self->_oai_record_header($id, deleted => $deleted));

    delete $data->{deleted};

    my $xml = $self->pnx->to_xml($data);

    $xml =~ s{<\?xml.*\?>\n}{};

    $self->fh->print($xml) if $xml;

    $self->fh->print($self->_oai_record_footer());
}

sub commit {
    my ($self) = @_;

    $self->fh->print(_oai_footer());
}

sub _oai_header {
    my $str =<<EOF;
<?xml version="1.0"  encoding="UTF-8"?>
<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="
        http://www.openarchives.org/OAI/2.0/  http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
<ListRecords>
EOF
    $str;
}

sub _oai_record_header {
    my ($self,$id,%opts) = @_;

    my $str =<<EOF;
<record>
EOF

    if ($opts{deleted}) {
        $str .= "<header status=\"deleted\">\n";
    }
    else {
        $str .= "<header>\n";
    }

    $str .= <<EOF;
<identifier>$id</identifier>
</header>
<metadata>
EOF
    $str;
}

sub _oai_record_footer {
    my $str =<<EOF;
</metadata>
</record>
EOF
    $str;
}

sub _oai_footer {
    my $str =<<EOF;
</ListRecords>
</OAI-PMH>
EOF
    $str;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Exporter::PNX - a Primo normalized XML (PNX) exporter

=head1 SYNOPSIS

    # From the commandline
    $ catmandu convert JSON --fix myfixes to PNX < /tmp/data.json

    # From Perl

    use Catmandu;

    # Print to STDOUT
    my $exporter = Catmandu->exporter('PNX');

    $exporter->add_many($arrayref);
    $exporter->add_many($iterator);
    $exporter->add_many(sub { });

    $exporter->add($hashref);

    printf "exported %d objects\n" , $exporter->count;

    # Get an array ref of all records exported
    my $data = $exporter->as_arrayref;

=head1 DESCRIPTION

This is a L<Catmandu::Exporter> for converting Perl into Primo normalized XML (PNX).

=head1 SEE ALSO

L<Catmandu::Exporter>, L<Catmandu-PNX>

=cut
