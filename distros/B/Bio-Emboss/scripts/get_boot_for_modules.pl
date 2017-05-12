#!/usr/bin/perl

$xsfile = "emboss-boot-xs.inc";
$cfile  = "emboss-boot-c.inc";

$mregex = q/(?:aj|emb)/;

$cpp = ""; # --- remember cpp if/else/end instructions
while (<>) {
    if (/^#(?:if|else|end)/) {
	$cpp .= $_;
	next;
    }

    # --- lines starting with "aj.." or "emb..." ?
    next unless /^($mregex\w+).*\(.*\)/o;

    $method = $1;

    push (@methods, [$cpp, $method]);
    $cpp = "";
}

push (@methods, [$cpp, ""]) if $cpp;


# --- write prototypes

open (OUT, ">$cfile");

foreach (@methods) {
    ($cpp, $method) = @$_;

    print OUT $cpp;
    next unless $method;

    print OUT "  XS(XS_Bio__Emboss_$method); /* prototype */\n";
}

close (OUT);

open (OUT, ">$xsfile");

print OUT "BOOT:\n";

foreach (@methods) {
    ($cpp, $method) = @$_;

    print OUT $cpp;
    next unless $method;

    print OUT "        newXS(\"Bio::Emboss::${method}\", XS_Bio__Emboss_$method, file);\n";
}

print OUT "\n";
