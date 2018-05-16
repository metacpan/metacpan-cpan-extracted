# Modify this and copy it to bug.pm for bug testing
# Use this as a default file to test for bugs
sub bug() {
    # substr(my $a, 0, 0) = (foo(), bar());
    return $x + $y;
}
1;
