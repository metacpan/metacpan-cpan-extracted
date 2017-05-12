package Archive::Cpio::OldBinary;

use Archive::Cpio::Common;

my $TRAILER    = 'TRAILER!!!';
my $BLOCK_SIZE = 512;

my @HEADER = qw(
  magic
  dev
  ino
  mode
  uid
  gid
  nlink
  rdev
  mtime_high
  mtime_low
  namesize
  datasize_high
  datasize_low
);

sub new {
    my ($class, $magic) = @_;
    bless { magic => unpack('v', $magic) }, $class;
}

sub read_one {
    my ($o, $FHwp) = @_;
    my $entry = read_one_header($o, $FHwp);

    $entry->{name} = $FHwp->read($entry->{namesize});
    $entry->{name} =~ s/\0$//;

    $entry->{name} ne $TRAILER or return;
    $FHwp->read(padding(2, $entry->{namesize}));

    $entry->{data} = $FHwp->read($entry->{datasize});
    $FHwp->read(padding(2, $entry->{datasize}));

    cleanup_entry($entry);

    $entry;
}

sub read_one_header {
    my ($o, $FHwp) = @_;

    my %h;
    my @vals = unpack('v*', $FHwp->read(2 * @HEADER));
    foreach my $field (@HEADER) {
        $h{$field} = shift @vals;
    }
    foreach ('mtime', 'datasize') {
        $h{$_} = $h{$_ . '_high'} * 0x10000 + $h{$_ . '_low'};
    }

    $h{magic} == $o->{magic} or die "bad magic ($h{magic} vs $o->{MAGIC})\n";

    \%h;
}

sub write_one {
    my ($o, $F, $entry) = @_;

    $entry->{magic} = $o->{magic};
    $entry->{namesize} = length($entry->{name}) + 1;
    $entry->{datasize} = length($entry->{data});

    foreach ('mtime', 'datasize') {
        $entry->{$_ . '_high'} = int($entry->{$_} / 0x10000);
        $entry->{$_ . '_low'} = $entry->{$_} % 0x10000;
    }

    write_or_die($F, pack_header($entry) .
                     $entry->{name} . "\0" .
                     "\0" x padding(2, $entry->{namesize}));
    write_or_die($F, $entry->{data});
    write_or_die($F, "\0" x padding(2, $entry->{datasize}));

    cleanup_entry($entry);
}

sub write_trailer {
    my ($o, $F) = @_;

    write_one($o, $F, { name => $TRAILER, data => '', nlink => 1 });
    write_or_die($F, "\0" x padding($BLOCK_SIZE, tell($F)));
}

sub cleanup_entry {
    my ($entry) = @_;

    foreach ('datasize', 'namesize', 'magic') {
        delete $entry->{$_};
    }
    foreach (keys %$entry) {
        /_low$|_high$/ and delete $entry->{$_};
    }
}

sub pack_header {
    my ($h) = @_;
    pack('v*', map { $h->{$_} || 0 } @HEADER);
}

1;
