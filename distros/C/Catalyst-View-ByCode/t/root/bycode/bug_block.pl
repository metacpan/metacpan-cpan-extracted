#
# before fixing these blocks failed getting attr() values
#
block block1 => sub {
    my $id = attr('id');
    my $class = attr('class');
    my $xxx = attr('xxx');
    my $unknown = attr('unknown');
    
    my $is_ok = 0;
    
    if (defined($id) && !ref($id) && $id eq 'stupid1' &&
        defined($class) && !ref($class) && $class eq 'bad1' &&
        defined($xxx) && !ref($xxx) && $xxx == 42 &&
        !defined($unknown)) {
        # everything as we expect...
        $is_ok = 1;
    }
    
    div block1 {
        block_content;
        "OK: $is_ok";
    };
};

block 'block2', sub {
    my $id = attr('id');
    my $class = attr('class');
    my $xxx = attr('xxx');
    my $unknown = attr('unknown');
    
    my $is_ok = 0;
    
    if (defined($id) && !ref($id) && $id eq 'stupid2' &&
        defined($class) && !ref($class) && $class eq 'bad2' &&
        defined($xxx) && !ref($xxx) && $xxx == 43 &&
        !defined($unknown)) {
        # everything as we expect...
        $is_ok = 1;
    }
    
    div block2 {
        block_content;
        "OK: $is_ok";
    };
};


#
# before and after fixing this block is able to get attr() values
#
block block3 {
    my $id = attr('id');
    my $class = attr('class');
    my $xxx = attr('xxx');
    my $unknown = attr('unknown');
    
    my $is_ok = 0;
    
    if (defined($id) && !ref($id) && $id eq 'stupid3' &&
        defined($class) && !ref($class) && $class eq 'bad3' &&
        defined($xxx) && !ref($xxx) && $xxx == 44 &&
        !defined($unknown)) {
        # everything as we expect...
        $is_ok = 1;
    }
    
    div block3 {
        block_content;
        "OK: $is_ok";
    };
};

template {
    b { 'block1:' };
    block1 stupid1.bad1(xxx => 42) { '-1-' };
    
    b { 'block2:' };
    block2 stupid2.bad2(xxx => 43) { '-2-' };
    
    b { 'block3:' };
    block3 stupid3.bad3(xxx => 44) { '-3-' };
    
    b { 'after blocks' };
};
