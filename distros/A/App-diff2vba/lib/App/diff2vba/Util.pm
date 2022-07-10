package App::diff2vba;
use v5.14;
use warnings;

sub split_string {
    local $_ = shift;
    my $count = shift;
    my $len = int((length($_) + $count - 1) / $count);
    my @split;
    while (length) {
	push @split, substr($_, 0, $len, '');
    }
    @split == $count or die;
    @split;
}

1;
