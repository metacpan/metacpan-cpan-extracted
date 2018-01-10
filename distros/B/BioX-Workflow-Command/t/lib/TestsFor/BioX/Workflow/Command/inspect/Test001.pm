package TestsFor::BioX::Workflow::Command::inspect::Test001;

use Test::Class::Moose;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use Capture::Tiny ':all';
use BioX::Workflow::Command;
use YAML::XS;

extends 'TestMethod::Base';

#This tests the functionality with sample_by_dir: 0

sub write_test_file {
    my $test_dir = shift;

    my $fh;
    my $href = {
        global => [
            { indir     => 'data/raw' },
            { outdir    => 'data/processed' },
            { sample_rule => "Sample_(\\d.*)" },
            { gatk => '{$self->outdir}/{$sample}/gatk' },
        ],
        rules => [
            {
                rule1 => {
                    'local' => [
                        { local_rule1 => 'mylocalrule1' },
                        { before_meta => "# HPC things\n#HPC mem=64GB" },
                        { local_rule2 => 'mylocalrule2' },
                    ],
                    process =>
                      'Executing rule1 {$self->local_rule1} for {$sample}',
                },
            },
            {
                rule2 => {
                    'local' => [
                        { local_rule1 => 'mylocalrule1' },
                        { local_rule2 => 'mylocalrule2' }
                    ],
                    process =>
                      'Executing rule2 {$self->local_rule1} for {$sample}',
                },
            },
        ]
    };

    #Write out the config
    open( $fh, ">$test_dir/conf/test1.1.yml" )
      or die print "Couldn't open file! $!";
    my $yaml = Dump $href;
    print $fh $yaml;
    close($fh);

    #Create some samples
    open( $fh, ">$test_dir/data/raw/Sample_01" )
      or die print "Couldn't open file! $!";
    print $fh "";
    close($fh);

    open( $fh, ">$test_dir/data/raw/Sample_02" )
      or die print "Couldn't open file! $!";
    print $fh "";
    close($fh);
}


## this is just a quick make sure everything doesn't blow up test
sub test_002 : Tags(construction) {
    my $self = shift;

    my $test_methods = TestMethod::Base->new();
    my $test_dir     = $test_methods->make_test_dir();
    write_test_file($test_dir);

    my $cwd = getcwd();

    my $t = "$test_dir/conf/test1.1.yml";

    if(-f $t){
      diag('Workflow exists!');
    }
    else{
      diag('Workflow does not exist!');
    }

    MooseX::App::ParsedArgv->new( argv => [ "inspect", "--workflow", $t ] );

    my $test = BioX::Workflow::Command->new_with_command();

    ok(1);
}

1;
