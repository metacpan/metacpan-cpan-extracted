package TestsFor::BioX::Workflow::Test001;
use Test::Class::Moose;
use BioX::Workflow;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw[can_run];
use Data::Dumper;
use Capture::Tiny ':all';
use Slurp;

sub test_001 : Tags(samples) {
    my $test = shift;

    make_path("$Bin/example/data/raw/test001");
    make_path("$Bin/example/data/processed/test001");

    for ( my $i = 1; $i <= 5; $i++ ) {
        my $cmd = "touch $Bin/example/data/raw/test001/sample$i.csv";
        system($cmd);
    }

    ok(1);
}

sub test_002 : Tags(construct) {
    my $test = shift;

    #TODO to keep or not to keep?
    open( my $fh, ">$Bin/example/test001.yml" );
    print $fh <<EOF;
---
global:
    - indir: t/example/data/raw/test001
    - outdir: t/example/data/processed/test001
    - file_rule: (.*).csv\$
rules:
    - backup:
        process: cp {\$self->indir}/{\$sample}.csv {\$self->outdir}/{\$sample}.csv
    - grep_VARA:
        process: |
            echo "Working on {\$self->{indir}}/{\$sample}.csv"
            grep -i "VARA" {\$self->indir}/{\$sample}.csv >> {\$self->outdir}/{\$sample}.grep_VARA.csv
    - grep_VARB:
        process: |
            grep -i "VARB" {\$self->indir}/{\$sample}.grep_VARA.csv >> {\$self->outdir}/{\$sample}.grep_VARA.grep_VARB.csv
EOF

    close($fh);

    ok(1);
}

sub test_003 : Tags(init_things) {
    my $test = shift;

    my $obj = BioX::Workflow->new( workflow => "$Bin/example/test001.yml" );
    isa_ok( $obj, 'BioX::Workflow' );

    capture { $obj->init_things };

    isa_ok( $obj->global_attr, 'Data::Pairs' );
    isa_ok( $obj->samples,     'ARRAY' );

    my $samples = [ 'sample1', 'sample2', 'sample3', 'sample4', 'sample5' ];
    @{$samples} = sort( @{$samples} );
    @{ $obj->samples } = sort( @{ $obj->samples } );
    is_deeply( $obj->samples, $samples, "Samples are right" );

    my $aref = [
        { indir     => "t/example/data/raw/test001" },
        { outdir    => "t/example/data/processed/test001" },
        { file_rule => '(.*).csv$' }
    ];
    is_deeply( $obj->yaml->{global}, $aref, "Global vars are ok" );
}

sub test_004 : Tags(process) {
    my $test = shift;

    my $obj = BioX::Workflow->new( workflow => "$Bin/example/test001.yml" );
    isa_ok( $obj, 'BioX::Workflow' );

    capture { $obj->init_things };

    my $process_got = $obj->yaml->{rules};

    my $cmd2 = <<EOF;
echo "Working on {\$self->{indir}}/{\$sample}.csv"
grep -i "VARA" {\$self->indir}/{\$sample}.csv >> {\$self->outdir}/{\$sample}.grep_VARA.csv
EOF

    my $cmd3 = <<EOF;
grep -i "VARB" {\$self->indir}/{\$sample}.grep_VARA.csv >> {\$self->outdir}/{\$sample}.grep_VARA.grep_VARB.csv
EOF

    my $process_exp = [
        {   backup => {
                process =>
                    'cp {$self->indir}/{$sample}.csv {$self->outdir}/{$sample}.csv'
            }
        },
        { grep_VARA => { process => $cmd2 } },
        { grep_VARB => { process => $cmd3 } }
    ];

    for ( my $i = 0; $i < @{$process_got}; $i++ ) {
        is_deeply( $process_got->[$i], $process_exp->[$i],
            "Process $i matches" );
    }
}

sub test_005 : Tags(attr) {
    my $obj = BioX::Workflow->new( workflow => "$Bin/example/test001.yml" );
    isa_ok( $obj, 'BioX::Workflow' );

    capture { $obj->init_things };

    my $process_got = $obj->yaml->{rules};

    ok(1);
}

sub test_006 : Tags(output) {
    my $test = shift;

    my $obj = BioX::Workflow->new( workflow => "$Bin/example/test001.yml" );
    isa_ok( $obj, 'BioX::Workflow' );

    my $expected = slurp("$Bin/example/test001.sh");
    $expected =~ s/\$Bin/$Bin/g;

    #Can't just do run here because it collects datetime and options
    my $got = capture {
        $obj->init_things;
        $obj->write_workflow_meta('start');

        $obj->write_pipeline;

        $obj->write_workflow_meta('end');
    };

    #use Text::Diff;
    #my $diff = diff \$got,   \$expected;

    #diag("Diff is ".$diff);
    #return;

    is( $got, $expected, "Got expected output!" );
    ok( -d "$Bin/example/data/processed/test001" );

    my @processes = qw(backup grep_VARA grep_VARB);

    foreach my $process (@processes) {
        ok( -d "$Bin/example/data/processed/test001/$process" );
    }
}

1;
