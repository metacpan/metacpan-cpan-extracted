THRESHHOLD_TEST: for my $i ( 0 .. 1 ) {
    for my $j ( 0 .. 1 ) {
        for my $k ( 0 .. 1 ) {
            if ($k) {
                my $null = $i + $j + $k;
            }
        }
    }
}
sub add_line_numbers {
    my $contents      = prefilter(shift);
    my $with_varnames = prefilter(shift);
    my @contents;

    my $line_num = 1;
    foreach my $i ( 0 .. $#$contents ) {
        my ( $line, $line_with_vars )
          = ( $contents->[$i], $with_varnames->[$i] );
        chomp $line_with_vars;

        if ( $line =~ /^#line\s+([0-9]+)/ ) {
            $line_num = $1;
            next;
        }
        push @contents => {
            line => $line_num,
            key  => munge_line($line),
            code => $line_with_vars,
        };
        $line_num++;
    }
    return postfilter( \@contents );
}

1;
