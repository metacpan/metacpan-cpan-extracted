package Catmandu::Exporter::MARC::Base;
use Moo::Role;
use MARC::Record;
use MARC::Field;

our $VERSION = '1.10';

sub _raw_to_marc_record {
    my ($self,$data) = @_;
    my $marc = MARC::Record->new(); 

    for my $field (@$data) {
        my ($tag, $ind1, $ind2, @data) = @$field;

        if ($tag eq 'LDR') {
            $marc->leader($data[1]);
        }
        elsif ($tag =~ /^00/) {
            my $field = MARC::Field->new($tag,$data[1]);
             $marc->append_fields($field);
        }
        else {
            my $field = MARC::Field->new($tag, $ind1, $ind2, @data);
            $marc->append_fields($field);
        }
    }

    $marc;
}

sub _json_to_raw {
    my ($self,$data) = @_;
    my @record = ();

    push (@record , [ 'LDR', ' ', ' ', '_' , $data->{leader}] ) if defined $data->{leader};
    
    for my $field (@{$data->{fields}}) {
        my ($tag) = keys %$field;
        my $val = $field->{$tag};

        if (ref $val) {
            my $ind1 = $val->{ind1} // ' ';
            my $ind2 = $val->{ind2} // ' ';

            my @parts;
            for my $subfield (@{$val->{subfields}}) {
                my ($code) = keys %$subfield;
                my $str    = $subfield->{$code};
                push @parts , $code, $str;
            }
            push @record , [ $tag, $ind1 , $ind2 , @parts];
        }
        else {
            push @record , [ $tag, ' ' , ' ', '_', $val];
        }
    }

    { _id => $data->{_id} , record => \@record };
}

sub _clean_raw_data {
    my ($self, $tag, @data) = @_;
    my @result = ();
    for (my $i = 0 ; $i < @data ; $i += 2) {
        if (($tag =~ /^00/ || defined $data[$i]) && defined $data[$i+1] && $data[$i+1] =~ /\S+/) {
            push(@result, $data[$i], $data[$i+1]);
        }
    }
    
    @result;
}

1;