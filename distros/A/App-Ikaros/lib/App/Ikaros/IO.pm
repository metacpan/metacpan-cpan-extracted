package App::Ikaros::IO;
use strict;
use warnings;

sub read {
    my ($filename) = @_;
    open my $fh, '<', $filename;
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

sub write {
    my ($filename, $content) = @_;
    open my $fh, '>', $filename;
    print $fh $content;
    close $fh;
}

1;
