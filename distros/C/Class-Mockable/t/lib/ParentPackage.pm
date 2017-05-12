package ParentPackage;

sub wrapped_method_in_parent {
    my $class = shift;
    return "wrapped method in parent, called on $class";
}

1;
