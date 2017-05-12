package Acme::Test::42;

use strict;

our $VERSION = 0.1;

use Test::Builder::Module;
our @ISA = qw(Test::Builder::Module);
our @EXPORT = qw(ok not_ok);

my $CLASS = __PACKAGE__;

sub ok($;$) {
    return $CLASS->builder->ok($_[0] eq 42, $_[1]);
}

sub not_ok($;$) {
    return $CLASS->builder->ok($_[0] ne 42, $_[1]);
}

42;

__END__

=head1 NAME

Acme::Test::42 - Test the answer to ultimate question

=head1 SYNOPSIS

 use Acme::Test::42 qw(no_plan);
 # . . .
 ok($answer, 'Answer to the question');
 not_ok($answer / 2, 'Not an answer');
 
=head1 ABSTRACT

Acme::Test::42 provides a mechanism for probing if the answer is correct.

=head1 DESCRIPTION

Acme::Test::42 exports two subroutines, C<ok> and C<not_ok>, each of them expects two arguments:
the answer and optional comment.

The module is based on standard L<Test::Builder> and follows the L<TAP> standard but unlike
Test::Simple and Test::More does not expect true or false values and checks if the given
value is an answer to the ultimate question of life, the Universe, and everything.

Perl people often use this answer in their talks
(see L<http://www.slideshare.net/newsearch/slideshow?q=perl>) and as a boolean value
returned by Perl packages (see L<Acme::ReturnValue>), which makes Acme::Test::42 so important.

=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENSE

Acme::Test::42 module is a free software.
You may redistribute and (or) modify it under the same terms as Perl whichever version it is.

=cut
