block silly {
    my $id = attr('id');
    my $class = attr('class');
    my $xxx = attr('xxx');
    my $unknown = attr('unknown');
    
    my $is_ok = 0;
    
    if (defined($id) && !ref($id) && $id eq 'stupid' &&
        defined($class) && !ref($class) && $class eq 'bad' &&
        defined($xxx) && !ref($xxx) && $xxx == 42 &&
        !defined($unknown)) {
        # everything as we expect...
        $is_ok = 1;
    }
    
    div sillyblock {
        block_content;
        "OK: $is_ok";
    };
};

template {
    b { 'before block' };
    
    silly stupid.bad(xxx => 42) { 'just my 2 cent' };
    
    b { 'after block' };
};
