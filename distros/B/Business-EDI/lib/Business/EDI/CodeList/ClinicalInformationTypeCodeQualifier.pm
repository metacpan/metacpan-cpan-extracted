package Business::EDI::CodeList::ClinicalInformationTypeCodeQualifier;

use base 'Business::EDI::CodeList';
my $VERSION     = 0.02;
sub list_number {6415;}
my $usage       = 'B';

# 6415  Clinical information type code qualifier                [B]
# Desc: Code qualifying the type of clinical information.
# Repr: an..3

my %code_hash = (
'1' => [ 'Anamnesis',
    'Medical history.' ],
'2' => [ 'Diagnosis',
    'Medical diagnosis.' ],
'3' => [ 'Medical treatment',
    'Information regarding medical treatment.' ],
'4' => [ 'Symptom',
    'Change in the physical or mental condition of a person regarded as an evidence of a disease.' ],
'5' => [ 'Medical examination',
    'Information regarding a medical examination.' ],
'6' => [ 'Discharge diagnosis',
    'Medical diagnosis at the time of discharge.' ],
'7' => [ 'Diagnosis related group',
    'Grouping of related diagnosis.' ],
'8' => [ 'Intervention',
    'Information regarding a medical intervention.' ],
'9' => [ 'Prognosis',
    'Information regarding the probable course and/or termination of a disease.' ],
'10' => [ 'Examination result',
    'Information regarding the result of a medical examination.' ],
'11' => [ 'Laboratory analysis result',
    'Information regarding the result of a laboratory analysis.' ],
'12' => [ 'Medicinal treatment',
    'Information regarding a treatment with medicinal products.' ],
'13' => [ 'Patient medical instruction',
    'Information regarding the medical instruction given to a patient.' ],
'14' => [ 'Medical instruction to physician',
    'Information regarding the medical instruction given to a physician.' ],
'15' => [ 'Medical observation',
    'Information regarding medical observation.' ],
);
sub get_codes { return \%code_hash; }

1;
