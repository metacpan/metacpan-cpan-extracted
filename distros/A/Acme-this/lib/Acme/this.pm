package Acme::this;
$Acme::this::VERSION = '0.02';
use strict;
use warnings;

sub import {
    print <<EOF
The Zen of Perl, by bellaire

Beauty is subjective.
Explicit is recommended, but not required.
Simple is good, but complex can be good too.
And although complicated is bad,
Verbose and complicated is worse.
Brief is better than long-winded.
But readability counts.
So use whitespace to enhance readability.
Not because you're required to.
Practicality always beats purity.
In the face of ambiguity, do what I mean.
There's more than one way to do it.
Although that might not be obvious unless you're a Monk.
At your discretion is better than not at all.
Although your discretion should be used judiciously.
Just because the code looks clean doesn't mean it is good.
Just because the code looks messy doesn't mean it is bad.
Reuse via CPAN is one honking great idea -- let's do more of that!
EOF
}

1;

__END__
=pod

=head1 NAME

Acme::this - The Zen of Perl

=head1 SYNOPSIS

    use Acme::this;
    The Zen of Perl, by bellaire

    Beauty is subjective.
    Explicit is recommended, but not required.
    Simple is good, but complex can be good too.
    And although complicated is bad,
    Verbose and complicated is worse.
    Brief is better than long-winded.
    But readability counts.
    So use whitespace to enhance readability.
    Not because you're required to.
    Practicality always beats purity.
    In the face of ambiguity, do what I mean.
    There's more than one way to do it.
    Although that might not be obvious unless you're a Monk.
    At your discretion is better than not at all.
    Although your discretion should be used judiciously.
    Just because the code looks clean doesn't mean it is good.
    Just because the code looks messy doesn't mean it is bad.
    Reuse via CPAN is one honking great idea -- let's do more of that!

=head1 DESCRIPTION

Print the Zen of Perl when used.

=head1 ACKNOWLEDGEMENTS

All the credit to <bellaire>, who wrote the Zen of Perl in
L<http://www.perlmonks.org/?node_id=752029>

=head1 AUTHOR

=over 4

=item *
Miquel Ruiz <mruiz@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Miquel Ruiz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
