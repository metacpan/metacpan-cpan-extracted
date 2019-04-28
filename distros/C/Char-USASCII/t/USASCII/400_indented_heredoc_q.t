# encoding: USASCII
# This file is encoded in US-ASCII.
die "This file is not encoded in US-ASCII.\n" if q{‚ } ne "\x82\xa0";

use USASCII;

print "1..9\n";

my $var = '456';
my $heredoc = '';

# <<~\EOF
$heredoc = <<~\EOF;
    123
      $var
    789
    EOF
if ($heredoc eq "123\n  \$var\n789\n") {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# <<~'EOF'
$heredoc = <<~'EOF';
    123
      $var
    789
    EOF
if ($heredoc eq "123\n  \$var\n789\n") {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# <<~  'EOF'
$heredoc = <<~  'EOF';
    123
      $var
    789
    EOF
if ($heredoc eq "123\n  \$var\n789\n") {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# <<~\EOF
$heredoc = <<~\EOF;
		123
			$var
		789
		EOF
if ($heredoc eq "123\n\t\$var\n789\n") {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# <<~'EOF'
$heredoc = <<~'EOF';
		123
			$var
		789
		EOF
if ($heredoc eq "123\n\t\$var\n789\n") {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# <<~  'EOF'
$heredoc = <<~  'EOF';
		123
			$var
		789
		EOF
if ($heredoc eq "123\n\t\$var\n789\n") {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# <<~\EOF
$heredoc = <<~\EOF;
	 	 123
	 	 	 $var
	 	 789
	 	 EOF
if ($heredoc eq "123\n\t \$var\n789\n") {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# <<~'EOF'
$heredoc = <<~'EOF';
	 	 123
	 	 	 $var
	 	 789
	 	 EOF
if ($heredoc eq "123\n\t \$var\n789\n") {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# <<~  'EOF'
$heredoc = <<~  'EOF';
	 	 123
	 	 	 $var
	 	 789
	 	 EOF
if ($heredoc eq "123\n\t \$var\n789\n") {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

__END__
