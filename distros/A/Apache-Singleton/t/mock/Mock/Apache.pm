package Mock::Apache;

my %pnotes;

sub pnotes {
    my($self, $key, $val) = @_;
    $pnotes{$key} = $val if $val;
    return $pnotes{$key};
}

1;
