sub provide_line_numbers {
    my $lines      = prefilter(shift);
    my $lines_orig = prefilter(shift);
    my @contents;

    my $line_num = 1;
    foreach my $i ( 0 .. $#$lines ) {
        my ( $line, $line_with_vars ) =
          ( $lines->[$i], $lines_orig->[$i] );
        chomp $line_with_vars;

        if ($line =~ /^#line\s+([0-9]+)/) {
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
    return postfilter(\@contents);
}

1;
