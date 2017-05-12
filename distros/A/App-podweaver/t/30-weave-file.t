#!perl

use warnings;
use strict;

use Test::More;
use Test::MockObject;
use Test::Differences;

use File::Copy;
use File::Spec;
use File::Temp;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Nester;
use Pod::Elemental::Transformer::Pod5;
use Software::License::Perl_5;

use App::podweaver;

my @tests = (
    #    POD          END  DATA  UNCHANGED
    [ qw/no           no   no/,   0 ],
    [ qw/block        no   no/,   0 ],
    [ qw/interlaced   no   no/,   0 ],
    [ qw/no           with no/,   0 ],
    [ qw/block-before with no/,   1 ],
    [ qw/block-after  with no/,   1 ],
    [ qw/interlaced   with no/,   0 ],
    [ qw/no           no   with/, 0 ],
    [ qw/block        no   with/, 1 ],
    [ qw/interlaced   no   with/, 0 ],
    );

my $tests_per_test = 7;
my $extra_tests_for_changed = 1;
my $test_files     = 't/test_files/30-weave-file';

plan tests => (
    ( scalar( @tests ) * $tests_per_test ) +
    ( scalar( grep { !$_->[ 3 ] } @tests ) * $extra_tests_for_changed )
    );

my ( $mock_weaver, $weaver_args );

$mock_weaver = Test::MockObject->new();
$mock_weaver->set_isa( 'Pod::Weaver' );
$mock_weaver->mock( 'weave_document',
    sub 
    { 
        $weaver_args = $_[ 1 ];

        #  Normalize the Pod so that we can compare it more easily.
        #  Possibly defeats some of the point of mocking the object by
        #  making it sensitive to upstream changes.
        if( $_[ 1 ]->{ pod_document } )
        {
            Pod::Elemental::Transformer::Pod5->new->transform_node(
                $_[ 1 ]->{ pod_document } );

            my $nester = Pod::Elemental::Transformer::Nester->new( {
                top_selector => s_command( [ qw(head1) ] ),
                content_selectors => [
                    s_flat,
                    s_command( [ qw(head2 head3 head4 over item back) ]),
                    ],
                } );
            $nester->transform_node( $_[ 1 ]->{ pod_document } );
        }

        return( $_[ 1 ]->{ pod_document } );
    } );

my $file_temp = File::Temp->newdir( 'app_podweaver_XXXX', { TMPDIR => 1 } )
    or die "Unable to create File::Temp";

my $license = Software::License::Perl_5->new( {
    holder => 'Sam Graham',
    } );

foreach my $test ( @tests )
{
    my ( $pod, $end, $data, $unchanged ) = @{$test};

    my $file_stem = "$pod-pod-$end-end-$data-data";
    my $test_name = "$pod pod" .
        ( $end  eq 'no' ? '' : ', __END__'  ) .
        ( $data eq 'no' ? '' : ', __DATA__' );

    my $in_file       = "$test_files/$file_stem.in.txt";
    my $expected_file = "$test_files/$file_stem.out.txt";

    #  Take a copy of the test file, because if App::podweaver breaks it
    #  could overwrite the original and break subsequent test runs.
    my $copied_file   = File::Spec->catfile(
        $file_temp->dirname(),
        "$file_stem.txt",
        );
    copy( $in_file, $copied_file ) or
        die "Unable to copy $in_file to $copied_file: $!";
    my $woven_file    = "$copied_file.new";

    my $original_contents =
        do { local $/; open my $fh, '<', $copied_file; <$fh> };


    #  TODO:  check return code.
    App::podweaver->weave_file(
        weaver       => $mock_weaver,
        dist_version => '1.10',       #  Different to version in the file.
        new          => 1,
        filename     => $copied_file,
        license      => $license,
        );


    #
    #  Check args passed to mock_weaver were correct
    #

    #
    #  1: Is there a ppi_document?
    ok( defined( $weaver_args->{ ppi_document } ),
        "$test_name passes a ppi_document" );
    #
    #  2: Is there a pod_document?
    ok( defined( $weaver_args->{ pod_document } ),
        "$test_name passes a pod_document" );

    #
    #  3: is filename right?
    is( $weaver_args->{ filename }, $copied_file,
        "$test_name passes correct filename" );

    #
    #  4: is version right?
    is( $weaver_args->{ version }, '1.00',
        "$test_name passes correct version" );

    #
    #  5: is license right?
    is_deeply( $weaver_args->{ license }, $license,
        "$test_name passes correct license" );


    #
    #  Check output
    #

    #
    #  6: was original file unchanged?
    my $contents =
        do { local $/; open my $fh, '<', $copied_file;    <$fh> };
    eq_or_diff( $contents, $original_contents,
        "$test_name left original file unchanged" );

    if( $unchanged )
    {
        #
        #  7: does output file exist?
        ok( ( not -e $woven_file ), "$test_name skips unchanged output file" );
    }
    else
    {
        SKIP:
        {
            #
            #  7: does output file exist?
            skip 'No output file produced', 1
                unless ok( ( -e $woven_file ),
                    "$test_name produces output file" );

            #
            #  8: does output file match expected?
            my $expected =
                do { local $/; open my $fh, '<', $expected_file; <$fh> };
            my $woven    =
                do { local $/; open my $fh, '<', $woven_file;    <$fh> };
            eq_or_diff( $woven, $expected,
                "$test_name produces correct output" );

        }
    }
}

#  TODO: test new => 1
#  TODO: test new default
#  TODO: test no_backup => 1
#  TODO: test no_backup default
