package Acme::Oppai;

use strict;
use warnings;
use utf8;

use Encode;
use Encode::Guess;
use Scalar::Util qw(blessed);

our $VERSION = '0.03';

our %BASIC_AA = (
                 oppai => sub {
                     my $word = shift;
                     return <<OPPAI;
　 _ 　∩
(　゜∀゜)彡　$word
　⊂彡
OPPAI
                 },
                 oppai_up => sub {
                     my $word = shift;
                     return <<OPPAI;
　 _ 　∩
(　゜∀゜)彡　$word

OPPAI
                 },
                 oppai_down => sub {
                     my $word = shift;
                     return <<OPPAI;

(　゜∀゜)彡　$word
　⊂彡
OPPAI
                 },

                 Oppai => sub {
                     my $word = shift;
                     return <<OPPAI;
　　　 _ 　∩
　　(　゜∀゜)彡　$word
　　(　 ⊂彡
　 　|　　　|　
　 　し ⌒Ｊ
OPPAI
                 },
                 Oppai_up => sub {
                     my $word = shift;
                     return <<OPPAI;
　　　 _ 　∩
　　(　゜∀゜)彡　$word
　　(　 　　|　
　 　|　　　|　
　 　し ⌒Ｊ
OPPAI
                 },
                 Oppai_down => sub {
                     my $word = shift;
                     return <<OPPAI;
　　　 _ 　
　　(　゜∀゜)　　$word
　　(　 ⊂彡
　 　|　　　|　
　 　し ⌒Ｊ
OPPAI
                 },
                 );

our %BASIC_WORD = (
                 oppai => 'おっぱい!おっぱい!',
                 oppai_up => 'おっぱい!',
                 oppai_down => 'おっぱい!',

                 Oppai => 'おっぱい!おっぱい!',
                 Oppai_up => 'おっぱい!',
                 Oppai_down => 'おっぱい!',
                 );

use overload q("") => sub { 
    my $self = shift;
    my $oppai = ${ $self->[0] };

    if ($self->[1]->{use_utf8}) {
        utf8::decode($oppai) unless utf8::is_utf8($oppai);
    } else {
        utf8::encode($oppai) if utf8::is_utf8($oppai);
    }
    $self->clear;
    $oppai;
};

sub new {
    my $class = shift;
    my %opt = @_;

    my $str = '';
    my $self = [
                \$str,
                \%opt,
                ];
    $self = bless $self, $class;

    $self->clear;
    $self;
}

sub clear {
    my $self = shift;
    my $str = '';
    $self->[0] = \$str;
    $self->[2] = 0;
    $self->[3] = [];
}

sub gen_word {
    my ($self, $type, $word) = @_;

    return $BASIC_WORD{$type} unless $word;
    return $word if utf8::is_utf8($word);
    my $enc = guess_encoding($word, qw(euc-jp shiftjis 7bit-jis utf8));
    return $word unless ref($enc);
    $enc->decode($word);
}

sub gen {
    my ($self, $type, $word) = @_;
    $BASIC_AA{$type}($word);
}

sub base {
    my $proto = shift;
    my $self = blessed($proto) ? $proto : $proto->new;
    my $type = shift;

    if ($self->[1]->{default}) {
        $type .= "_$1" if $self->[1]->{default} =~ /^(up|down)$/;
    } else {
        if ($self->[2] eq 1) {
            ${ $self->[0] } = $self->gen($self->[3]->[0]->{type} . '_up', $self->[3]->[0]->{word});
        }
        $self->[2]++;
        if ($self->[2] ne 1) {
            if ($self->[2] % 2) {
                $type .= "_up";
            } else {
                $type .= "_down";
            }
        }
    }

    my $word = $self->gen_word($type, @_);
    utf8::decode($word) unless utf8::is_utf8($word);
    push @{ $self->[3] }, {type => $type, word => $word};
    ${ $self->[0] } .= $self->gen($type, $word);
    $self;
}

sub oppai { shift->base('oppai', @_) }
sub Oppai { shift->base('Oppai', @_) }

sub massage {
    my $self = shift;
    ${ $self->[0] } .=<<OPPAI;
　　　 _ 　∩
　　(　゜∀゜)彡　おっぱい!おっぱい!
　　(　 ⊂彡
　 　|　　　|　
　 　し ⌒Ｊ
OPPAI
    $self;
}

1;
__END__

=head1 NAME

Acme::Oppai - Oppai! Oppai!

=head1 SYNOPSIS

  perl -MAcme::Oppai -e 'print Acme::Oppai->new->massage';
  perl -MAcme::Oppai -e 'print Acme::Oppai->new->massage->massage->massage->massage->massage->massage->massage';

  perl -MAcme::Oppai -e 'print Acme::Oppai->oppai';
  perl -MAcme::Oppai -e 'print Acme::Oppai->oppai->oppai->oppai';
  perl -MAcme::Oppai -e 'print Acme::Oppai->Oppai->oppai->Oppai("OPPAI!")->oppai("oppai!")';
  perl -MAcme::Oppai -e 'print Acme::Oppai->new(default => 'default')->oppai->oppai->oppai';

  # or

  use Acme::Oppai;

  print Acme::Oppai->oppai;
  print Acme::Oppai->oppai->oppai->oppai->oppai;
  print Acme::Oppai->oppai('your')->oppai('soul')->oppai('message')->oppai;

  my $oppai = Acme::Oppai->new(default => 'default');
  print $oppai->Oppai->Oppai->Oppai;
  print $oppai->oppai->oppai->oppai;
  print $oppai->oppai->Oppai->oppai;

  # Hummm I'm tired...

=head1 DESCRIPTION

display to

  　　　 _ 　∩
  　　(　゜∀゜)彡　おっぱい!おっぱい!
  　　(　 ⊂彡
  　 　|　　　|　
  　 　し ⌒Ｊ

=head1 Method

=over 4

=item new[(%option)]

make object.

=over 4

=item option

=over 4

=item * use_utf8

use utf8 flag.

=item * default

default Asc Art type(up or down or default)

=back

=back

=item Oppai

stack auto oppai

=item oppai

stack auto oppai (small)

=item massage

stack oppai

=back

=head1 SEE ALSO

C<example/pearl>,
L<http://ja.wikipedia.org/wiki/%E3%82%B8%E3%83%A7%E3%83%AB%E3%82%B8%E3%83%A5%E9%95%B7%E5%B2%A1>,
L<http://d.hatena.ne.jp/higepon/20060407/1144400043#c>

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 THANKS TO

Mr.Oppai, higepon, tokuhirom, nipotan, hio, takesako, secondlife

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
