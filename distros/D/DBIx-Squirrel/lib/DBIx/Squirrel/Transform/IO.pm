package    # hide from PAUSE
    DBIx::Squirrel::Transform::IO;

use strict;
use warnings;
use DBIx::Squirrel::Iterator qw/result/;

BEGIN {
    require DBIx::Squirrel unless keys(%DBIx::Squirrel::);
    require Exporter;
    $DBIx::Squirrel::Transform::IO::VERSION   = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::Transform::IO::ISA       = qw/Exporter/;
    @DBIx::Squirrel::Transform::IO::EXPORT_OK = qw/stdout stderr/;
    @DBIx::Squirrel::Transform::IO::EXPORT
        = @DBIx::Squirrel::Transform::IO::EXPORT_OK;
}

sub stdout {
    if (@_) {
        my $format = shift;
        return sub {
            printf STDOUT $format, @_;
            return result;
        }
    }
    else {
        return sub {
            printf STDOUT result;
            return result;
        }
    }
}

sub stderr {
    if (@_) {
        my $format = shift;
        return sub {
            printf STDERR $format, @_;
            return result;
        }
    }
    else {
        return sub {
            printf STDERR result;
            return result;
        }
    }
}

1;
