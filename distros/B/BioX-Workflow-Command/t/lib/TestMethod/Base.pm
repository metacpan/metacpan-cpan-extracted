package TestMethod::Base;

use Test::Class::Moose;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use BioX::Workflow::Command;
use Cwd;
use File::Spec;
use File::Temp;
use File::Spec;
use File::Slurp;
use Cwd;

sub make_test_dir {

    my $tmpdir = File::Spec->tmpdir();
    my $tmp    = File::Temp->newdir(
        UNLINK   => 0,
        CLEANUP  => 0,
        TEMPLATE => File::Spec->catdir( $tmpdir, 'bioxworkflowXXXXXXX' )
    );
    my $test_dir = $tmp->dirname;

    remove_tree($test_dir);
    make_path($test_dir);
    make_path( File::Spec->catdir( $test_dir, 'data', 'raw' ) );
    make_path( File::Spec->catdir( $test_dir, 'data', 'analysis' ) );
    make_path( File::Spec->catdir( $test_dir, 'conf' ) );

    chdir($test_dir);

    return cwd();
}

sub make_test_env {
    my $self     = shift;
    my $workflow = shift;
    my $args     = shift || [];

    my $init_args = [ "run", "--workflow", $workflow ];
    if ( $args && ref($args) eq 'ARRAY' ) {
        map { push( @{$init_args}, $_ ) } @{$args};
    }

    MooseX::App::ParsedArgv->new( argv => $init_args );

    my $test = BioX::Workflow::Command->new_with_command();

    #This should map what we have in run up to iterate rules
    $test->print_opts;
    $test->load_yaml_workflow;
    $test->apply_global_attributes;
    $test->get_global_keys;
    $test->get_samples;
    $test->write_workflow_meta('start');

    return $test;
}

sub test_shutdown {

    my $cwd = cwd();
    chdir("$Bin");
    remove_tree($cwd);
}

sub print_diff {
    my $got    = shift;
    my $expect = shift;

    use Text::Diff;

    my $diff = diff \$got, \$expect;
    diag("Diff is\n\n$diff\n\n");

    my $fh;
    open( $fh, ">got.diff" ) or die print "Couldn't open $!\n";
    print $fh $got;
    close($fh);

    open( $fh, ">expect.diff" ) or die print "Couldn't open $!\n";
    print $fh $expect;
    close($fh);

    open( $fh, ">diff.diff" ) or die print "Couldn't open $!\n";
    print $fh $diff;
    close($fh);

    ok(1);
}

1;
