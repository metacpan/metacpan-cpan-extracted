package Archive::Cpio::NewAscii;

use Archive::Cpio::Common;

my $TRAILER    = 'TRAILER!!!';
my $BLOCK_SIZE = 512;

my @HEADER = (
    magic => 6,
    inode => 8,
    mode => 8,
    uid => 8,
    gid => 8,
    nlink => 8,
    mtime => 8,
    datasize => 8,
    devMajor => 8,
    devMinor => 8,
    rdevMajor => 8,
    rdevMinor => 8,
    namesize => 8,
    checksum => 8,
);

sub new {
    my ($class, $magic) = @_;
    bless { magic => hex($magic) }, $class;
}

sub read_one {
    my ($o, $FHwp) = @_;
    my $entry = read_one_header($o, $FHwp);

    $entry->{name} = $FHwp->read($entry->{namesize});
    $entry->{name} =~ s/\0$//;

    $entry->{name} ne $TRAILER or return;
    $FHwp->read(padding(4, $entry->{namesize} + 2));

    $entry->{data} = $FHwp->read($entry->{datasize});
    $FHwp->read(padding(4, $entry->{datasize}));

    cleanup_entry($entry);

    $entry;
}

sub read_one_header {
    my ($o, $FHwp) = @_;

    my %h;
    my @header = @HEADER;
    while (@header) {
        my $field = shift @header;
        my $size =  shift @header;
        $h{$field} = $FHwp->read($size);
        $h{$field} =~ /^[0-9A-F]*$/si or die "bad header value $h{$field}\n";
        $h{$field} = hex $h{$field};
    }
    $h{magic} == $o->{magic} or die "bad magic ($h{magic} vs $o->{MAGIC})\n";

    \%h;
}

sub write_one {
    my ($o, $F, $entry) = @_;

    $entry->{magic} = $o->{magic};
    $entry->{namesize} = length($entry->{name}) + 1;
    $entry->{datasize} = length($entry->{data});

    write_or_die($F, pack_header($entry) .
                     $entry->{name} . "\0" .
                     "\0" x padding(4, $entry->{namesize} + 2));
    write_or_die($F, $entry->{data});
    write_or_die($F, "\0" x padding(4, $entry->{datasize}));

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
}

sub pack_header {
    my ($h) = @_;

    my $packed = '';
    my @header = @HEADER;
    while (@header) {
        my $field = shift @header;
        my $size =  shift @header;

        $packed .= sprintf("%0${size}X", $h->{$field} || 0);
    }
    $packed;
}

1;
