package CodeBaseTestsubs;

use strict;
use vars qw(@ISA @EXPORT $datadir);


require Exporter;

@EXPORT = qw($datadir drop_table table_filename abspath);
@ISA = qw(Exporter);


$datadir = "testdata";
$datadir = "../$datadir"  unless -d $datadir;


sub table_filename {
    my $filename = shift;
    
    $filename = "$datadir/$filename" unless $filename =~ m!/!;
    return $filename;
}


sub drop_table {
    my($filename) = @_;
    
    $filename = "$datadir/$filename" unless $filename =~ m!/!;

    unlink("$filename.dbf") if -f "$filename.dbf";
    unlink("$filename.dbt") if -f "$filename.dbt";
    unlink("$filename.mdx") if -f "$filename.mdx";
}

sub abspath {
    my $path = shift;
    if ($path =~ m!(^[^/])|/..?/!) {
	my $pwd = $1 ? `pwd` : '';
	chomp($pwd);
	$path = $pwd . '/' . $path;
	$path =~ s!//+!/!g;
	$path =~ s!/\.(?=/)!!g;
	1 while ($path =~ s!/[^./][^/]*/../!/!);
	1 while ($path =~ s!^/\.\.(?=/)!!g);
    }
    return $path;
}

1;

