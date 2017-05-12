#!/usr/bin/perl

foreach $f (@ARGV) {
    my $x = $f;

    $x =~ s:.*/::;
    $x =~ s:\..*::;
    print "=head2 \U$x\E\n\n";

    &do_file ($f);
}



sub do_file {
    my $file = shift;

    open FILE, $file;

    print "=over 4\n\n";

OUTER:
    while (<FILE>) {
	next unless s:/\*.*\@func\w*\s+aj:aj:;

	chomp;
	s/[\* ]*//g;

	$a = $_;
	$b = '';
	$return = "";
	while (<FILE>) {
	    last if /\@\@/;
	    last if /\*\//;

	    s/^[\* ]*//;

	    s/^\@(\w+)/\nI<$1>/;
	    $b .= $_;

	    if ($1 eq "return") {
		/\[([^]]+)/;
	        $return = $1;
	    }
	}

	$c = '';
	while (<FILE>) {
	    if (m:/\*.*\@func\w*\s+aj:) {
		redo OUTER;
	    }
	    if (/$a\s*(.*)/) {
		$c = $1;
		last;
	    }
	}

	while ($c !~ /\)/) {
 	    $c .= <FILE>;
	    redo OUTER if $c eq "";
	}
    
	$c =~ s/\).*/)/;
        chomp ($c);

        &print_it ($a, $b, $c, $return);
    }

    print "=back\n\n";

    close (FILE);
}


sub print_it {
    ($a, $b, $c, $return) = @_;
    print "=item *\n\n", "$return B<$a> $c\n", $b, "\n";
}
