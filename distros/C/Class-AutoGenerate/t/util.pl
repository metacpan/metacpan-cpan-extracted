sub require_not_ok($;$) {
    my ($class, $message) = @_;
    eval "require $class";
    ok($@, ($message||"not require $class"));
}

1;
