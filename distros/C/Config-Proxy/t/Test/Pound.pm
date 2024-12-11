package Test::Pound;
use strict;
use warnings;
use parent 'Config::Pound';
use File::Basename;
use File::Temp;

sub new {
    my $class = shift;

    my $file = new File::Temp;
    while (<main::DATA>) {
	print $file $_;
    }
    close $file;
    return $class->SUPER::new($file->filename)->parse;
}

1;

    
    
