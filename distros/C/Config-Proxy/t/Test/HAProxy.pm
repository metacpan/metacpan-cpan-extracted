package Test::HAProxy;
use strict;
use warnings;
use parent 'Config::HAProxy';
use File::Basename;
use File::Temp;

my $offset;

sub new {
    my $class = shift;

    my $file = new File::Temp;
    if (defined($offset)) {
	seek(*main::DATA, $offset, 0)
    } else {
	$offset = tell(*main::DATA)
    }
    while (<main::DATA>) {
	print $file $_;
    }
    close $file;
    return $class->SUPER::new($file->filename)->parse;
}

1;
