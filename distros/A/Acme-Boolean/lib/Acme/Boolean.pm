package Acme::Boolean;
# ABSTRACT: There is more then one way to be true.
$Acme::Boolean::VERSION = '0.7';
use strict;
use warnings;

use boolean ':all';

use base 'Exporter';

no strict 'refs';

my @true = map {
    *{"$_"} = \&true;
    $_;
} map { ($_, uc($_)) } qw(yes verifiable trusty accurate actual appropriate authentic authoritative correct dependable direct exact factual fitting genuine honest indubitable kosher lawful legal legitimate natural normal perfect precise proper pure regular right rightful sincere straight trustworthy truthful typical undeniable undesigning undoubted unerring unfaked unfeigned unquestionable veracious veridical veritable wash);

sub NO { false }
sub no { false }

my @false = map {
    *{$_} = \&false;
    $_;
} map { ($_, uc($_)) } qw(untrue wrong incorrect errorneous fallacious untruthful nah apocryphal beguiling bogus casuistic concocted counterfactual deceitful deceiving delusive dishonest distorted erroneous ersatz fake fanciful faulty fictitious fishy fraudulent illusive imaginary improper inaccurate inexact invalid lying mendacious misleading misrepresentative mistaken phony sham sophistical specious spurious unfounded unreal unsound);

push @false, 'NO', 'no';

my @ad = map {
    *{$_} = sub($) { shift; };
    $_;
} map { ($_, uc($_)) } qw(just so totally very definitely really certainly surely unquestionably undoubtedly absolutely exactly);

sub NOT($) { not shift }
push @ad, 'NOT';

our @EXPORT = (qw(true false), @ad, @true, @false);
our @EXPORT_OK = qw(isTrue isFalse isBoolean);
our %EXPORT_TAGS = (
    default => [@EXPORT],
    all     => [@EXPORT, @EXPORT_OK]
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Boolean - There is more then one way to be true.

=head1 VERSION

version 0.7

=head1 SYNOPSIS

To be more literalistic:

    use Acme::Boolean;

    $decision = correct if verifiable;

    sub do_me_a_favor {
       nah;
    }

=head1 DESCRIPTION

This module provides a lot of words for you to express from the very
trustful to the toally errorneous;

=head2 TRUE

These words can be used to refer to a true value:

yes verifiable trusty accurate actual appropriate authentic authoritative
correct dependable direct exact factual fitting genuine honest
indubitable kosher lawful legal legitimate natural normal perfect
precise proper pure regular right rightful sincere straight trustworthy
truthful typical undeniable undesigning undoubted unerring unfaked
unfeigned unquestionable veracious veridical veritable wash

=head2 FALSE

And these words evaluates to false:

no untrue wrong incorrect errorneous fallacious untruthful nah apocryphal
beguiling bogus casuistic concocted counterfactual deceitful deceiving
delusive dishonest distorted erroneous ersatz fake fanciful faulty
fictitious fishy fraudulent illusive imaginary improper inaccurate
inexact invalid lying mendacious misleading misrepresentative
mistaken phony sham sophistical specious spurious unfounded unreal
unsound

=head2 Adjectives

Optionally it's possible to say it more nicely:

    $that = so correct;

(I wish I could alias "is" to "=" in that statement.)

Or you can:

    return very wrong;

In your lovely sub.

At this moment you can use these adjectives in front of any of those
true/false vocabularies:

so totally very definitely really certainly surely unquestionably
just undoubtedly absolutely.

Adjectives can be stacked too:

    say "ok" if very very very perfect; #=> ok

=head2 Caveats

Noted here that the word C<no> is also a keyword for unimporting
pragmas/modules and thus one must write C<&no> to get the wanted
boolean. Alternatively, one may go with the all caps version C<NO>,
although that may accidently include some emotions to the logic.

In fact, if strong emotion is intentionally wished for, all the introduced
words comes with a all caps version at your disposal.

Here are some notable examples:

    my $p = SO true;
    my $q = NOT exactly lying;

Be notified that readers my not preceive such embedded emotion the same
way writers put it.

=head2 Special forms

The builtin keyword C<not> that flips true/false value is a nice
add-on to boolean words but the all caps version is not provided by
perl. Therefore C<Acme::Boolean> completes perl by providing the all
caps C<NOT> unary operator.

    my $f = NOT yes; # false
    my $t = NOT NOT yes; # true

The keyword C<NO> is also stackable this expression means NO:

    NO NO NO NO NO

Be very careful on using NO with other Acme::Boolean keywords for it
always reduce everything on its right-hand side to a false
value. After all, NO means NO. So this means NO.

    NO really not fishy

However, this expression means YES:

    NO, really not fishy

Be aware of the significance of punctuations.

=head2 SEE ALSO

L<boolean>, the plain version of this module.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Kang-min Liu.

This is free software, licensed under:

  The MIT (X11) License

=cut
