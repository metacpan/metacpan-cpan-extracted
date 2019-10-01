use 5.010;
use strict;
use warnings;
use Test2::V0;

use App::GitFind::Base;

sub run {
    my $text = pop @_;
    my $name = shift @_;

    my $got = [_qwc $text];
    is $got, [@_], $name;
}

run 'one element', 'single', <<'EOT';
single
EOT

run 'two elements', '1', '2', <<'EOT';
1
2
EOT

run 'two elements on one line', '1', '2', <<'EOT';
1 2
EOT

run 'two elements on one line followed by comment', '1', '2', <<'EOT';
1 2 # foo
EOT

run 'two elements on one line followed by empty comment', '1', '2', <<'EOT';
1 2 #
EOT

run 'one element followed by empty comment', '1', <<'EOT';
1 #
EOT

run 'one element followed by comment', '1', <<'EOT';
1 # foo
EOT

run 'one element followed immediately by comment', '1', <<'EOT';
1# foo
EOT

run 'one element followed immediately by empty comment', '1', <<'EOT';
1#
EOT

run 'one element with multiline comment', '1', <<'EOT';
1   # An element.
# More description
EOT

run 'one element with multiline indented comment', '1', <<'EOT';
1   # An element.
    # More description
EOT

run 'two elements with multiline comments', '1', '2', <<'EOT';
1   # An element.
# More description
2   # An element.
# More description
EOT

run 'two elements with multiline indented comments', '1', '2', <<'EOT';
1   # An element.
    # More description
2   # An element.
    # More description
EOT

done_testing();
