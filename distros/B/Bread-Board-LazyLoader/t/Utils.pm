package t::Utils;
use strict;
use warnings;

use Exporter 'import';
use File::Temp qw(tempdir);

our @EXPORT = qw(create_builder_file test_shared
    clear_history
    file_loaded
    mark_file_loaded
);

{
    my $dir;

    sub create_builder_file {
        my $fh = File::Temp->new(
            UNLINK => 0,
            dir    => ( $dir ||= tempdir( CLEANUP => 1 ) )
        );
        $fh->print(@_);
        $fh->close;
        return $fh->filename;
    }
}

# place to share data between test and builder_file
# to recognize the laziness
my $test_shared;

sub test_shared {
    $test_shared = shift() if @_;
    $test_shared;
}

# just a way to test laziness
my $at = 0;
my %file_loaded_at;

sub clear_history {
    $at = 0;
    undef %file_loaded_at;
}

sub file_loaded {
    my ($file) = @_;
    return $file_loaded_at{$file};
}

sub mark_file_loaded {
    my ($file) = @_;

    $file_loaded_at{$file} = ++$at;
}

sub file_loaded_at {
    my ($file) = @_;

}

1;

# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78:

