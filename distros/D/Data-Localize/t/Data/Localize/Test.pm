
package t::Data::Localize::Test;
use strict;
use base qw(Exporter);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

our @EXPORT_OK = qw(write_po test_localizer);

BEGIN {
    %ENV = 
        map { ($_ => $ENV{$_}) }
        grep { /^DATA_LOCALIZE/ || /^ANY_MOOSE/ }
        keys %ENV;

    # silence wide character warnings
    my $tb = Test::Builder->new();
    binmode $_, ':utf8'
        for map { $tb->$_ } qw( output failure_output todo_output );
}

sub write_po {
    my $po = shift;

    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'ja.po');
    open(my $fh, '>', $file) or die "Could not open $file: $!";

    binmode($fh, ':utf8');
    print $fh $po;
    close($fh);

    return $file;
}

sub test_localizer {
    my ($loc) = @_;
}

1;