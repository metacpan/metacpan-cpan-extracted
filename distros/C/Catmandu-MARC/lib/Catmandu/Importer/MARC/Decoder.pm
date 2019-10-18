package Catmandu::Importer::MARC::Decoder;

use Catmandu::Sane;
use Moo;

our $VERSION = '1.254';

sub fake_marc_file {
    my ($self,$fh,$class) = @_;

    my $obj = {
        filename    => scalar($fh),
        fh          => $fh,
        recnum      => 0,
        warnings    => [],
    };

    return( bless $obj , $class );
}

sub decode {
    my ($self, $record, $id) = @_;
    return unless eval { $record->isa('MARC::Record') };
    my @result = ();

    push @result , [ 'LDR' , ' ', ' ' , '_' , $record->leader ];

    for my $field ($record->fields()) {
        my $tag  = $field->tag;
        my $ind1 = $field->indicator(1) // ' ';
        my $ind2 = $field->indicator(2) // ' ';

        my @sf = ();

        if ($field->is_control_field) {
            push @sf , '_', $field->data;
        }

        for my $subfield ($field->subfields) {
            push @sf , @$subfield;
        }

        push @result, [$tag,$ind1,$ind2,@sf];
    }

    my $sysid = undef;

    if ($id =~ /^00/ && $record->field($id)) {
        $sysid = $record->field($id)->data();
    }
    elsif ($id =~ /^([0-9]{3})([[0-9a-zA-Z])$/) {
        my $field = $record->field($1);
        $sysid = $field->subfield($2) if ($field);
    }
    elsif (defined $id  && $record->field($id)) {
        $sysid = $record->field($id)->subfield("a");
    }

    return { _id => $sysid , record => \@result };
}

1;
