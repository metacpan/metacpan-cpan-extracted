package TestKit::Parts::Args;

sub feature_args_takes_arguments { 1 }
sub feature_args_export {
    my ($self, $caller, @arguments) = @_;

    *{"${caller}::args"} = sub { \@arguments };
}

1;
