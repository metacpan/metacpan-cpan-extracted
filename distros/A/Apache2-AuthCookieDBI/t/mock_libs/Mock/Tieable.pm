package Mock::Tieable;

sub TIEHASH {
    my ($variable, @args) = @_;
    my $self = { args => \@args };
    bless $self, __PACKAGE__;
    return $variable;
}

sub AUTOLOAD {};

1;