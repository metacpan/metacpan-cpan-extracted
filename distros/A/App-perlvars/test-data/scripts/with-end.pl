use strict;
use warnings;

sub greet {
    my $unused_after_end;
    return 'hi';
}

greet();

__END__

Trailing text after __END__ with an unbalanced brace } that would
close the synthetic wrapper early if it were not stripped first.
