# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;

print "1..6\n";

if ($^O !~ /linux/) {
    for my $tno (1..6) {
        print "ok - $tno SKIP $^O\n";
    }
    exit;
}

my $var = '456';
my $heredoc = '';

# <<~`EOF`
$heredoc = <<~`EOF`;
    echo 123
      echo $var
    echo 789
    EOF
if ($heredoc eq "123\n456\n789\n") {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# <<~  `EOF`
$heredoc = <<~  `EOF`;
    echo 123
      echo $var
    echo 789
    EOF
if ($heredoc eq "123\n456\n789\n") {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# <<~`EOF`
$heredoc = <<~`EOF`;
		echo 123
			echo $var
		echo 789
		EOF
if ($heredoc eq "123\n456\n789\n") {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# <<~  `EOF`
$heredoc = <<~  `EOF`;
		echo 123
			echo $var
		echo 789
		EOF
if ($heredoc eq "123\n456\n789\n") {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# <<~`EOF`
$heredoc = <<~`EOF`;
	 	 echo 123
	 	 	 echo $var
	 	 echo 789
	 	 EOF
if ($heredoc eq "123\n456\n789\n") {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# <<~  `EOF`
$heredoc = <<~  `EOF`;
	 	 echo 123
	 	 	 echo $var
	 	 echo 789
	 	 EOF
if ($heredoc eq "123\n456\n789\n") {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

__END__
