package Acme::Test::LogicalEquivalence;
# ABSTRACT: Test if expressions are logically equivalent
# KEYWORDS: test logic

use 5.008;
use warnings;
use strict;

our $VERSION = '0.001'; # VERSION

use Exporter qw(import);
use Test::More;
use namespace::clean -except => [qw(import)];

our @EXPORT_OK = qw(is_logically_equivalent);


sub is_logically_equivalent {
    my $numvars = shift;
    my $sub1 = shift;
    my $sub2 = shift;

    my $equivalence = 1;

    for (my $i = 0; $i < 2 ** $numvars; ++$i) {
        my @vars = split(//, substr(unpack("B32", pack('N', $i)), -$numvars));

        (local $a, local $b) = @vars;
        my $r1 = !!$sub1->(@vars);

        (local $a, local $b) = @vars;
        my $r2 = !!$sub2->(@vars);

        my $test = !($r1 xor $r2);

        my $args = join(', ', map { $_ ? 'T' : 'F' } @vars);
        ok($test, "expr1($args) <=> expr2($args)");

        $equivalence = '' if !$test;
    }

    return $equivalence;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Test::LogicalEquivalence - Test if expressions are logically equivalent

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Test::More;
    use Acme::Test::LogicalEquivalence qw(is_logically_equivalent);

    # test two expressions with 2 variables using the special vars $a and $b
    is_logically_equivalent(2, sub { $a && $b }, sub { $b && $a });

    # same as above
    is_logically_equivalent(2, sub { $_[0] && $_[1] }, sub { $_[1] && $_[0] });

    # you can do as many vars as you like
    is_logically_equivalent(3, sub { $_[0] || ($_[1] && $_[2]) },
                               sub { ($_[0] || $_[1]) && ($_[0] || $_[2]) });

    done_testing;

=head1 DESCRIPTION

Some expressions are "logically equivalent" to other expressions, but it may not be easy to tell if
one or both of the expressions are reasonably complicated. Or maybe you're like many other people
and are too lazy to go through the effort... Either way, why not let your computer prove logical
equivalence for you?

=head1 FUNCTIONS

=head2 is_logically_equivalent

Test logical equivalence of two subroutines.

    my $is_equivalent = is_logically_equivalent($numvars, &sub1, &sub2);

This will execute both of the subroutines one or more times (depending on how many variables you
specify) with different inputs. The subroutines shall be considered logically equivalent if, for all
combinations of inputs, they both return the same thing.

Returns true if the subroutines are logically equivalent, false otherwise.

=head1 SEE ALSO

=over 4

=item *

What is logical equivalence? Start here: L<https://en.wikipedia.org/wiki/Logical_equivalence>

=back

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
