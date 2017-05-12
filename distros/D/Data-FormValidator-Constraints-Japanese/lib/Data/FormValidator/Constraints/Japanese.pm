# $Id: Japanese.pm 5 2007-02-05 09:11:33Z daisuke $
#
# Copyright (c) 2006 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Data::FormValidator::Constraints::Japanese;
use strict;
use vars qw($VERSION %EXPORT_TAGS @EXPORT_OK);
use base qw(Exporter);
use Encode;
my %CLOSURES;

BEGIN
{
    $VERSION = '0.04';

    my @closures = qw(
        hiragana
        katakana
        jp_zip
    );
    push @closures, map { 'jp_' . $_ . '_email' } qw(mobile imode vodafone ezweb);
    foreach my $func (@closures) {
        my $code = qq!
            sub $func { 
                \$CLOSURES{$func} ||= sub {
                    my \$dfv = shift;
                    \$dfv->name_this('$func');
                    no strict 'refs';
                    return &{"_match_$func"}(\@_);
                };
                return \$CLOSURES{$func};
            };
        !;
        eval $code;
        die "Couldn't create $func: $@" if $@;
    }

    
    %EXPORT_TAGS = (
        closures => [@closures, 'jp_length'],
    );
    $EXPORT_TAGS{all} = [ 
        (map { "match_" . $_ } grep { $_ ne 'jp_length' } map { @$_ } values %EXPORT_TAGS),
        map { @$_ } values %EXPORT_TAGS
    ];
    @EXPORT_OK = @{$EXPORT_TAGS{all}};
}

my $DASH_UTF = decode('euc-jp', "¡¼¡Ý¡½-");
sub _match_hiragana
{
    require Encode::Detect;
    my($value) = @_;
    my $utf = decode('Detect', $value);
    return $utf !~ /[^\p{InHiragana}$DASH_UTF]/;
}

sub _match_katakana
{
    require Encode::Detect;
    my($value) = @_;
    my $utf = decode('Detect', $value);
    return $utf !~ /[^\p{InKatakana}$DASH_UTF]/;
}

sub _match_jp_mobile_email
{
    require Mail::Address::MobileJp;
    Mail::Address::MobileJp::is_mobile_jp($_[0]);
}

sub _match_jp_zip
{
    $_[0] =~ /^\d{3}\-?\d{4}$/
}

sub _match_jp_imode_email
{
    require Mail::Address::MobileJp;
    Mail::Address::MobileJp::is_imode($_[0]);
}

sub _match_jp_ezweb_email
{
    require Mail::Address::MobileJp;
    Mail::Address::MobileJp::is_ezweb($_[0]);
}

sub _match_jp_vodafone_email
{
    require Mail::Address::MobileJp;
    Mail::Address::MobileJp::is_vodafone($_[0]);
}

sub _check_jp_length
{
    require Encode::Detect;
    my $l = length(decode('Detect', $_[0]));
    return 
        @_ >= 2 ? $_[1] <= $l && $_[2] >= $l :
        $_[1] <= $l;
}

sub jp_length
{
    my($min, $max) = @_;
    return sub {
        my $dfv = shift;
        $dfv->name_this('jp_length');
        no strict 'refs';
        return &{"_check_jp_length"}(@_, $min, $max);
    };
}

1;

__END__

=head1 NAME

Data::FormValidator::Constraints::Japanese - Japan-Specific Constraints For Data::FormValidator

=head1 SYNOPSIS

  use Data::FormValidator::Constraints::Japanese qw(:all);

  my $rv = Data::FormValidator->check(\%input, {
     hiragana          => hiragana(),
     katakana          => katakana(),
     jp_mobile_email   => jp_mobile_email(),
     jp_imode_email    => jp_imode_email(),
     jp_ezweb_email    => jp_ezweb_email(),
     jp_vodafone_email => jp_vodafone_email(),
     jp_zip            => jp_zip(),
     jp_length         => jp_length(1, 10),
  }, 

  # or, use the regular functions
  my $rv = Data::FormValidator->check(\%input, {
     nihongo => sub {
        my($dfv, $value) = @_;
        return match_hiragana($value) && ! match_katakana($value);
     }
  });

=head1 DESCRIPTION

D::FM::C::Japanese provides you with constraint methods that makes it easier to
validate your Japanese input using Data::FormValidator.

=head1 FUNCTIONS

=head2 hiragana

Returns a closure that checks if the input is all in hiragana

=head2 katakana

Returns a closure that checks if the input is all in katakana

=head2 jp_zip

Returns a closure that checks if the input is a valid Japanese zipcode
(This is probably insufficient for edge cases). It also does not check
if the zip code actually exists.

=head2 jp_mobile_email

=head2 jp_imode_email

=head2 jp_ezweb_email

=head2 jp_vodafone_email

=head2 jp_length

=head1 TODO

I'm sure there are lots of other constraints. I'll release more upon
request, or when I encounter something new to validate. Patches welcome.

=head1 AUTHOR

Copyright (c) 2006-2007 Daisuke Maki E<lt>dmaki@endeworks.jpE<gt>
All rights reserved.

=cut