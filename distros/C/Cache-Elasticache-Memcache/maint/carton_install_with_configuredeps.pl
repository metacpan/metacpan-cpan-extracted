#!/usr/bin/env perl

use Carton::Environment;
use Carton::Builder;
use Carton::Mirror;

my $install_path = '';
my $cpanfile_path = '';
my @without = ();
my $mirror = Carton::Mirror->new($ENV{PERL_CARTON_MIRROR} || $Carton::Mirror::DefaultMirror);

my $env = Carton::Environment->build($cpanfile_path, $install_path);

my $builder = Carton::Builder->new(
    cascade => 1,
    mirror  => $mirror,
    without => \@without,
    cpanfile => $env->cpanfile,
);

$env->cpanfile->load;

#install configuredeps
my $reqs = CPAN::Meta::Requirements->new;
$reqs->add_requirements($env->cpanfile->prereqs->requirements_for('configure', 'requires'));
$reqs->clear_requirement('perl');
foreach my $requirement (keys %{$reqs->{requirements}}) {
    print "Installing configure dependency:- $requirement\n";
    $builder->run_cpanm(
        '-L', $env->install_path,
        (map { ("--mirror", $_->url) } $builder->effective_mirrors),
        ( $builder->index ? ("--mirror-index", $builder->index) : () ),
        ( $builder->cascade ? "--cascade-search" : () ),
        ( $builder->custom_mirror ? "--mirror-only" : () ),
        "--save-dists", $env->install_path."/cache",
        $builder->groups,
        $requirement,
    );
}

$builder->install($env->install_path);
$env->snapshot->find_installs($env->install_path, $env->cpanfile->requirements);
$env->snapshot->save;

print "DONE!\n";
