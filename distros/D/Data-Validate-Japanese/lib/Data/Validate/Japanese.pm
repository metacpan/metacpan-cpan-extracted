# $Id: /mirror/perl/Data-Validate-Japanese/trunk/lib/Data/Validate/Japanese.pm 2553 2007-09-19T01:14:58.848056Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Data::Validate::Japanese;
use strict;
use warnings;
use 5.008;
use vars qw($VERSION);

$VERSION = '0.01001';

my %regexps = (
    katakana => qr(\p{InKatakana}),
    hiragana => qr(\p{InHiragana}),
    kanji    => qr(\p{InCJKUnifiedIdeographs}),
    h_katakana => qr(\p{InHalfwidthAndFullwidthForms}),
    ascii      => qr([[:ascii]])
);

sub new
{
    bless {}, shift;
}

{
    foreach my $type (keys %regexps) {
        eval <<"        EOSUB";
            sub is_$type {
                my (\$self, \$value, \$opts) = \@_;
                \$self->contains_only(\$value, { $type => 1 });
            }
        EOSUB
        die if $@;
    }
}

sub contains_only
{
    my ($self, $value, $opts) = @_;
    $opts ||= {};

    my $re = do {
        my $str = sprintf(
            '^(?:%s)$',
            join('|', map { "$regexps{$_}+" } grep { $opts->{$_} } keys %regexps)
        );
        qr($str);
    };

    return $value =~ /$re/;
}

1;

__END__

=head1 NAME

Data::Validate::Japanese - Validate Japanese Input

=head1 SYNOPSIS

  use Data::Validate::Japanese;
  my $dvj = Data::Validate::Japanese->new;
  $ok = $dvj->is_hiragana($data);
  $ok = $dvj->is_katakana($data);
  $ok = $dvj->is_kanji($data);
  $ok = $dvj->is_h_katakana($data);

  $dvj->contains_only($value, { 
    hiragana   => 1,
    katakana   => 1,
    kanji      => 1,
    h_katakana => 1,
    ascii      => 1
  });

=head1 DESCRIPTION

Data::Validate::Japanese aims to be the base (or at least, the common 
link between) the myriad different data validator infrastructures, and
their Japanese-specific extensions. There are just too many validators
with too many different interfaces, but it's not like the core handling
of Japanese characters change.

=head1 METHODS

All methods return true or false unless otherwise stated.
All methods also expect Japanese characters that have successfully been 
decoded to Perl's internal unicode format.

=head2 new()

Creates a new instance of Data::Validate::Japanese

=head2 is_hiragana($value)

Checks if a value contains half-width katakana only. Returns true or false

=head2 is_katakana($value)

Checks if a value contains half-width katakana only. Returns true or false

=head2 is_kanji($value)

Checks if a value contains half-width katakana only. Returns true or false

=head2 is_h_katakana($value)

Checks if a value contains half-width katakana only. Returns true or false

=head2 is_ascii($value)

Checks if a value contains only ascii

=head2 contains_only($value, \%candidates)

Checks if a value contains characters within the range from the list of candidates

=head1 AUTHORS

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut