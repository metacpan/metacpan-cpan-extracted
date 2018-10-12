package t::helper;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(test_file test_cpanfile test_snapshot);

use Carton::Snapshot;
use Module::CPANfile;
use Path::Class qw();

sub test_file {
    return Path::Class::file('t', 'files', @_);
}

sub test_cpanfile {
    return Module::CPANfile->load(test_file($_[0] . '.cpanfile')->stringify);
}

sub test_snapshot {
    my $snapshot = Carton::Snapshot->new(path => test_file($_[0] . '.snapshot')->stringify);
    $snapshot->load;
    return $snapshot;
}

1;
