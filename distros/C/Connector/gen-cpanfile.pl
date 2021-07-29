use CPAN::Meta;
use Data::Dumper;
use Module::CPANfile;
my $meta = CPAN::Meta->load_file('MYMETA.json');
my $file = Module::CPANfile->from_prereqs($meta->prereqs);
$file->save('cpanfile');

# load to recreate with round-trip
$file = Module::CPANfile->load('cpanfile');
$file = Module::CPANfile->from_prereqs($file->prereq_specs);
$file->save('cpanfile');

