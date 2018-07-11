package Test::HAProxy;
use strict;
use warnings;
use parent 'Config::HAProxy';
use File::Basename;
use File::Temp;
use autodie;

sub new {
    my $class = shift;

    my $file = new File::Temp;
    while (<main::DATA>) {
	print $file $_;
    }
    close $file;
    $class->SUPER::new($file->filename)->parse;
}

1;

    
    
