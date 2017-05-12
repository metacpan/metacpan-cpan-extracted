package Apache2::RequestUtil;

sub request {
    bless {}, 'Mock::Apache';
}

1;
