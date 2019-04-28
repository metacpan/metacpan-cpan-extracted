# encoding: Windows1252
# This file is encoded in Windows-1252.
die "This file is not encoded in Windows-1252.\n" if q{‚ } ne "\x82\xa0";

use Windows1252;

print "1..9\n";

my $var = '456';
my $heredoc = '';

# <<~EOF
$heredoc = <<~EOF;
    123
      $var
    789
    EOF
if ($heredoc eq "123\n  456\n789\n") {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# <<~"EOF"
$heredoc = <<~"EOF";
    123
      $var
    789
    EOF
if ($heredoc eq "123\n  456\n789\n") {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# <<~  "EOF"
$heredoc = <<~  "EOF";
    123
      $var
    789
    EOF
if ($heredoc eq "123\n  456\n789\n") {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# <<~EOF
$heredoc = <<~EOF;
		123
			$var
		789
		EOF
if ($heredoc eq "123\n\t456\n789\n") {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# <<~"EOF"
$heredoc = <<~"EOF";
		123
			$var
		789
		EOF
if ($heredoc eq "123\n\t456\n789\n") {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# <<~  "EOF"
$heredoc = <<~  "EOF";
		123
			$var
		789
		EOF
if ($heredoc eq "123\n\t456\n789\n") {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# <<~EOF
$heredoc = <<~EOF;
	 	 123
	 	 	 $var
	 	 789
	 	 EOF
if ($heredoc eq "123\n\t 456\n789\n") {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# <<~"EOF"
$heredoc = <<~"EOF";
	 	 123
	 	 	 $var
	 	 789
	 	 EOF
if ($heredoc eq "123\n\t 456\n789\n") {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# <<~  "EOF"
$heredoc = <<~  "EOF";
	 	 123
	 	 	 $var
	 	 789
	 	 EOF
if ($heredoc eq "123\n\t 456\n789\n") {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

__END__
