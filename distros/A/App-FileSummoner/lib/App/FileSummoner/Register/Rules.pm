package App::FileSummoner::Register::Rules;
BEGIN {
  $App::FileSummoner::Register::Rules::VERSION = '0.005';
}

use strict;
use warnings;
use File::Spec;
use File::Basename qw(basename dirname);

use Exporter 'import';
our @EXPORT = qw(
  HasExt
  IsInsideDirectory
  PathContains
);

sub IsInsideDirectory {
    my ($dir) = @_;
    return sub {
        my ($fileName) = @_;
        return $dir eq basename( dirname($fileName) );
    };
}

sub PathContains {
    my ($pathPart) = @_;
    return sub {
        my ($fileName) = @_;
        return $fileName =~ /\Q$pathPart\E/;
    };
}

sub HasExt {
    my ($ext) = @_;
    return sub {
        shift =~ qr/\.$ext$/;
    };
}

1;
