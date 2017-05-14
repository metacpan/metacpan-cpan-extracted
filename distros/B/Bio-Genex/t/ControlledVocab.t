# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Spotter.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..34\n"; }
END {print "not ok 1\n" unless $loaded;}
use Carp;



use lib 't';

# use TestDB qw($TEST_CONTROLLEDVOCAB $TEST_CONTROLLEDVOCAB_DESCRIPTION);
use Bio::Genex::ControlledVocab;
use Bio::Genex;
$loaded = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# testing a random attribute
my $p = Bio::Genex::ControlledVocab->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for AL_Coating
$p = Bio::Genex::AL_Coating->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for AL_DefaultSpotConcUnits
$p = Bio::Genex::AL_DefaultSpotConcUnits->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for AL_TechnologyType
$p = Bio::Genex::AL_TechnologyType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for AL_Medium
$p = Bio::Genex::AL_Medium->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for AL_IdentifierCode
$p = Bio::Genex::AL_IdentifierCode->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for ALS_SpotType
$p = Bio::Genex::ALS_SpotType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for AM_EquationType
$p = Bio::Genex::AM_EquationType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for AM_SpotMeasurementUnits
$p = Bio::Genex::AM_SpotMeasurementUnits->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for AM_Type
$p = Bio::Genex::AM_Type->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for ContactType
$p = Bio::Genex::ContactType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for EF_MajorCategory
$p = Bio::Genex::EF_MajorCategory->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for EF_MinorCategory
$p = Bio::Genex::EF_MinorCategory->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for ES_QuantitySeriesType
$p = Bio::Genex::ES_QuantitySeriesType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for ES_TreatmentType
$p = Bio::Genex::ES_TreatmentType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for HS_ThresholdType
$p = Bio::Genex::HS_ThresholdType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for PRT_Type
$p = Bio::Genex::PRT_Type->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SCN_ModelDescription
$p = Bio::Genex::SCN_ModelDescription->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SMP_AgeUnits
$p = Bio::Genex::SMP_AgeUnits->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SMP_DevelopmentStageName
$p = Bio::Genex::SMP_DevelopmentStageName->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SMP_DevelopmentStageUnits
$p = Bio::Genex::SMP_DevelopmentStageUnits->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SMP_GeneticStatus
$p = Bio::Genex::SMP_GeneticStatus->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SMP_OrganismIntactness
$p = Bio::Genex::SMP_OrganismIntactness->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SMP_OrganType
$p = Bio::Genex::SMP_OrganType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SMP_PrimaryCellType
$p = Bio::Genex::SMP_PrimaryCellType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SMP_SexMatingType
$p = Bio::Genex::SMP_SexMatingType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SMP_TissueType
$p = Bio::Genex::SMP_TissueType->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SPC_GeneralClassification
$p = Bio::Genex::SPC_GeneralClassification->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SPC_CellStructure
$p = Bio::Genex::SPC_CellStructure->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SPT_ModelDescription
$p = Bio::Genex::SPT_ModelDescription->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SW_Name
$p = Bio::Genex::SW_Name->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for SW_Type
$p = Bio::Genex::SW_Type->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# testing a random attribute for USF_Type
$p = Bio::Genex::USF_Type->new();
$p->description(555);
if ($p->description() == 555){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

__END__
# no info in DB yet


# test fetch
$p = Bio::Genex::ControlledVocab->new(id=>$TEST_CONTROLLEDVOCAB);
$p->fetch();
if ($p->description() eq $TEST_CONTROLLEDVOCAB_DESCRIPTION){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

# test delayed_fetch
$p = Bio::Genex::ControlledVocab->new(id=>$TEST_CONTROLLEDVOCAB);
if (not defined $p->get_attribute('description')){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

if ($p->description() eq $TEST_CONTROLLEDVOCAB_DESCRIPTION){
  print "ok ", $i++, "\n";
} else {
  print "not ok ", $i++, "\n";
}

