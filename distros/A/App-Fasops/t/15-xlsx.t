use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;
use Spreadsheet::XLSX;

my $result = test_app( 'App::Fasops' => [qw(help xlsx)] );
like( $result->stdout, qr{xlsx}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(xlsx)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(xlsx t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

{    # population
    my $temp = Path::Tiny->tempfile;
    $result = test_app( 'App::Fasops' => [ qw(xlsx t/example.fas -o ), $temp->stringify ] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
    like( $result->stdout, qr{Section \[4}, 'sections 4 writed' );

    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    # row-col
    is( $sheet->{Cells}[1][1]{Val},  "G",  "Cell content 1" );
    is( $sheet->{Cells}[19][8]{Val}, "D1", "Cell content 2" );
}

{    # population --noindel
    my $temp = Path::Tiny->tempfile;
    $result = test_app( 'App::Fasops' => [ qw(xlsx t/example.fas --noindel -o ), $temp->stringify ] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
    like( $result->stdout, qr{Section \[4}, 'sections 4 writed' );

    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    # row-col
    is( $sheet->{Cells}[1][1]{Val},  "G",  "Cell content 1" );
    is( $sheet->{Cells}[19][8]{Val}, "C", "Cell content 2" );
}

{    # population --nocomplex
    my $temp = Path::Tiny->tempfile;
    $result = test_app( 'App::Fasops' => [ qw(xlsx t/example.fas --nocomplex -o ), $temp->stringify ] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
    unlike( $result->stdout, qr{Section \[4}, 'sections 4 not writed' );

    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    # row-col
    is( $sheet->{Cells}[13][7]{Val}, "D1", "Cell content 1" );
    is( $sheet->{Cells}[13][8]{Val}, "T", "Cell content 2" );
}

{    # population --nosingle
    my $temp = Path::Tiny->tempfile;
    $result = test_app( 'App::Fasops' => [ qw(xlsx t/example.fas --nosingle -o ), $temp->stringify ] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
    unlike( $result->stdout, qr{Section \[4}, 'sections 4 not writed' );

    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    # row-col
    is( $sheet->{Cells}[13][3]{Val}, "I1", "Cell content 1" );
    is( $sheet->{Cells}[13][4]{Val}, "G", "Cell content 2" );
}

{    # population --min --max
    my $temp = Path::Tiny->tempfile;
    $result = test_app( 'App::Fasops' => [ qw(xlsx t/example.fas --min 0.3 --max 0.7 -o ), $temp->stringify ] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
    unlike( $result->stdout, qr{Section \[4}, 'sections 4 not writed' );

    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    # row-col
    is( $sheet->{Cells}[13][1]{Val}, "D1", "Cell content 1" );
    is( $sheet->{Cells}[13][5]{Val}, "T", "Cell content 2" );
}

{    # outgroup
    my $temp = Path::Tiny->tempfile;
    $result = test_app(
        'App::Fasops' => [ qw(xlsx t/example.fas -l 50 --outgroup -o ), $temp->stringify ] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
    like( $result->stdout, qr{Section \[2}, 'sections 2 writed' );
    unlike( $result->stdout, qr{Section \[4}, 'sections 4 not writed' );

    my $xlsx  = Spreadsheet::XLSX->new( $temp->stringify );
    my $sheet = $xlsx->{Worksheet}[0];

    # row-col
    is( $sheet->{Cells}[1][1]{Val}, "A",  "Outgroup Cell content 1" );
    is( $sheet->{Cells}[8][4]{Val}, "I1", "Outgroup Cell content 2" );
}

done_testing();
