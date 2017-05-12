sub dupa {}

sub foo {
    dupa;
}

sub nested {
    sub bar {
        sub baz {
            dupa();
        }
    }
}
