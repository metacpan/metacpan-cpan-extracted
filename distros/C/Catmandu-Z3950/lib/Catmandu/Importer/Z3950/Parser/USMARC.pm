package Catmandu::Importer::Z3950::Parser::USMARC;
 
use Catmandu::Sane;
use MARC::File::USMARC;
use Moo;

has 'id' => (is => 'ro' , default => sub { '001'} );

sub parse {
    my ($self,$str) = @_;
 
    return undef unless defined $str;

    my $record = MARC::File::USMARC->decode($str);

    $self->decode_marc($record);
}

sub decode_marc {
    my ($self, $record) = @_;
    return unless eval { $record->isa('MARC::Record') };
    my @result = ();

    push @result , [ 'LDR' , undef, undef, '_' , $record->leader ];

    for my $field ($record->fields()) {
        my $tag  = $field->tag;
        my $ind1 = $field->indicator(1);
        my $ind2 = $field->indicator(2);

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
    my $id = $self->id;

    if ($id =~ /^00/ && $record->field($id)) {
        $sysid = $record->field($id)->data();
    }
    elsif ($id =~ /^(\d{3})([\da-zA-Z])$/) {
        my $field = $record->field($1);
        $sysid = $field->subfield($2) if ($field);
    }
    elsif (defined $id  && $record->field($id)) {
        $sysid = $record->field($id)->subfield("a");
    }

    return { _id => $sysid , record => \@result };
}

1;