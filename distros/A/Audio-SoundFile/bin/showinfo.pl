#!/usr/bin/perl -Iblib/arch -Iblib/lib

=head1 NAME

 showinfo - Dumps sound file information stored in header

=cut

use Audio::SoundFile;

$reader = new Audio::SoundFile::Reader(shift, \$header);
$reader->close;

while (my($k, $v) = each %{$header}) {
    print "$k: $v\n";
}

exit(0);
