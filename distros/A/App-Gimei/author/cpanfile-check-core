use v5.42;

use List::Util qw(max);
use FindBin;
use File::Spec;
use Cwd 'abs_path';
use Module::CoreList;
use Module::CPANfile;

my @core_modules = ();
my @non_core_modules = ();

sub required_modules ($cpanfile_path) {
    my @modules;

    say "Analyzing cpanfile: $cpanfile_path";
    my $cpanfile = Module::CPANfile->load($cpanfile_path);
    my $prereqs = $cpanfile->prereqs;

    for my $phase ($prereqs->phases) {
        for my $type ($prereqs->types_in($phase)) {
            my $phase_prereqs = $prereqs->requirements_for($phase, $type);
            push @modules, $phase_prereqs->required_modules;
        }
    }

    return @modules;
}

my $root_dir = abs_path(File::Spec->catdir( $FindBin::Bin, '..' ));
my $cpanfile_path = File::Spec->catfile( $root_dir, 'cpanfile' );

my @modules = required_modules($cpanfile_path);

for my $module (@modules) {

    next if $module eq 'perl';  # skip 'perl'

    if (Module::CoreList->is_core($module)) {
        push @core_modules, $module;
    } else {
        push @non_core_modules, $module;
    }
}

print "core modules:\n";
for my $module (@core_modules) {
    print "  $module\n";
}

print "non-core modules:\n";
for my $module (@non_core_modules) {
    print "  $module\n";
}
