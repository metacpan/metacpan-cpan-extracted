#!/usr/bin/perl

while (<>) {
    next unless /\S/;

    chomp;
    $type = $1 if s/^\s*((?:const\s+)?\w+(?:\s*\*)?)\s*//;

    s/;.*//;

    $paraml = $1 if s/\((.*)\)//;
    $param1 =~ s/\s+$//;
    $param1 =~ s/^\s+//;

    @params = grep {$_ ne "void"} split (/\s*,\s*/, $paraml);

    ##map { s/^const\s*//; } @params;

    @output = ();
    push (@output, "RETVAL") unless $type eq "void";

    @l1 = map { /(\w+)\s*$/ } @params;
    $l1 = join (", ", @l1);
    $l1 = "" if $l1 eq "void";

    foreach $a (@params) {
	if ($a !~ /char\s*\*/ and (! ($a =~ s/void\s*\*/char */)) and $a =~ s/\*/\&/) {
	    
	    push (@output, $a =~ /(\w+)$/);
	}
    }

    $l2 = join ("\n", map { "       $_" } @params);
    $l2 .= "\n" if length($l2);

    s/\s+$//;

    $output = join "\n", map { "       $_" } @output;

    my $l3 = <<EOF if @output;
    OUTPUT:
$output
EOF

    print <<EOF;
$type
$_ ($l1)
$l2$l3
EOF
}
