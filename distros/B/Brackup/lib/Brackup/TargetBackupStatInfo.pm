package Brackup::TargetBackupStatInfo;

use strict;
use warnings;
use Carp qw(croak);
use POSIX qw(strftime);

sub new {
    my ($class, $target, $fn, %opts) = @_;
    my $self = {
        target => $target,
        filename => $fn,
        time => delete $opts{time},
        size => delete $opts{size},
    };
    croak "unknown options: " . join(", ", keys %opts) if %opts;

    return bless $self, $class;
}

sub target {
    return $_[0]->{target};
}

sub filename {
    return $_[0]->{filename};
}

sub time {
    return $_[0]->{time};
}

sub localtime {
    return strftime("%a %d %b %Y %T", localtime( $_[0]->{time} ));
}

sub size {
    return $_[0]->{size};
}


1;

