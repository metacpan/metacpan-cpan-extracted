use strict;
use warnings;

package    # hide from PAUSE
  DBIx::Squirrel::Transform::IO;

BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::Transform::IO::VERSION   = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::Transform::IO::ISA       = qw/Exporter/;
    @DBIx::Squirrel::Transform::IO::EXPORT    = qw/stdout stderr/;
    @DBIx::Squirrel::Transform::IO::EXPORT_OK = qw/stdout stderr/;
}

use DBIx::Squirrel::util qw/result/;

sub stdout {
    if (@_) {
        my $format = shift;
        return sub {
            printf STDOUT $format, result;
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
            printf STDERR $format, result;
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
