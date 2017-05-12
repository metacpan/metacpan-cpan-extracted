package Archive::Cpio::ODC;

use Archive::Cpio::Common;

my $TRAILER    = 'TRAILER!!!';
my $BLOCK_SIZE = 512;

my @HEADER = (
    magic => 6,
    dev => 6,
    inode => 6,
    mode => 6,
    uid => 6,
    gid => 6,
    nlink => 6,
    rdev => 6,
    mtime => 11,
    namesize => 6,
    datasize => 11,
);

sub new {
    my ($class, $magic) = @_;
    bless { magic => oct($magic) }, $class;
}

sub read_one {
    my ($o, $FHwp) = @_;
    my $entry = read_one_header($o, $FHwp);

    $entry->{name} = $FHwp->read($entry->{namesize});
    $entry->{name} =~ s/\0$//;

    $entry->{name} ne $TRAILER or return;

    $entry->{data} = $FHwp->read($entry->{datasize});

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
        $h{$field} =~ /^[0-9]*$/si or die "bad header value $h{$field}\n";
        $h{$field} = oct $h{$field};
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
                     $entry->{name} . "\0" . $entry->{data});

    cleanup_entry($entry);
}

sub write_trailer {
    my ($o, $F) = @_;

    write_one($o, $F, { name => $TRAILER, data => '', nlink => 1 });
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

        $packed .= sprintf("%0${size}lo", $h->{$field} || 0);
    }
    $packed;
}

1;
