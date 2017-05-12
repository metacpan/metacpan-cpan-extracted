package Archive::Cpio::Common;

use Archive::Cpio::FileHandle_with_pushback;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(padding write_or_die max begins_with);

sub magics() {
    {
        "070707" => 'ODC',
        "070701" => 'NewAscii',
        "\xC7\x71" => 'OldBinary', # swabbed 070707
        "\x71\xC7" => 'OldBinary', # 070707
    };
}

sub padding {
    my ($nb, $offset) = @_;

    my $align = $offset % $nb;
    $align ? $nb - $align : 0;
}

sub write_or_die {
    my ($F, $val) = @_;
    print $F $val or die "writing failed: $!\n";
}

sub max  { my $n = shift; $_ > $n and $n = $_ foreach @_; $n }
sub begins_with {
    my ($s, $prefix) = @_;
    index($s, $prefix) == 0;
}

1;
