package Archive::Cpio::FileHandle_with_pushback;

sub new {
    my ($class, $F) = @_;
    bless { F => $F, already_read => '' }, $class;
}

sub pushback {
    my ($FHwp, $s) = @_;

    $FHwp->{already_read} .= $s;
}

sub read {
    my ($FHwp, $size) = @_;

    $size or return;

    $size =~ /^\d+$/ or die "bad size $size\n";

    my $tmp = '';

    if ($FHwp->{already_read}) {
        $tmp = substr($FHwp->{already_read}, 0, $size);
        substr($FHwp->{already_read}, 0, $size) = '';
        $size -= length($tmp);
    }
    read($FHwp->{F}, $tmp, $size, length($tmp)) == $size or die "unexpected end of file while reading (got $tmp)\n";
    $tmp;
}

sub read_ahead {
    my ($FHwp, $size) = @_;

    my $s = $FHwp->read($size);
    $FHwp->pushback($s);
    $s;
}

1;
