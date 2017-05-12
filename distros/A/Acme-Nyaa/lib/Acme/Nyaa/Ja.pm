package Acme::Nyaa::Ja;
use parent 'Acme::Nyaa';
use strict;
use warnings;
use utf8;

my $RxComma = qr/[、(?:, )]/;
my $RxPeriod = qr/[。！]/;
my $RxEndOfList = qr#[）)-=+|}＞>/:;"'`\]]#;
my $RxConversation = qr/[「『].+[」』]/;
my $RxEndOfSentence = qr/(?:[!！?？…]+|[.]{2,}|[。]{2,}|[、]{2,}|[,]{2,})/;

my $Cats = [ '猫', 'ネコ', 'ねこ' ];
my $Separator = qq(\x1f\x1f\x1f);
my $HiraganaNya = 'にゃ';
my $KatakanaNya = 'ニャ';
my $FightingCats = [
    '「マーオ」',
    '「マーオ!」',
    '「マーーオ」',
    '「マーーオ!」',
    '「マーーーオ!!」',
    '「マーーーーオ!!!」',
];
my $Copulae = [ 'だ', 'です', 'である', 'どす', 'かもしれない', 'らしい', 'ようです' ];
my $HiraganaTails = [ 
    'にゃ', 'にゃー', 'にゃ〜', 'にゃーーーー!', 'にゃん', 'にゃーん', 'にゃ〜ん', 
    'にゃー!', 'にゃーーー!!', 'にゃーー!',
];
my $KatakanaTails = [
    'ニャ', 'ニャー', 'ニャ〜', 'ニャーーーー!', 'ニャん', 'ニャーん', 'ニャ〜ん',
    'ニャー!', 'ニャーーー!!', 'ニャーー!', 
];
my $DoNotBecomeCat = [
    # See http://ja.wikipedia.org/wiki/モーニング娘。
    'モーニング娘。',
    'カントリー娘。',
    'ココナッツ娘。',
    'ミニモニ。',
    'エコモニ。',
    'ハロー!モーニング。',
    'エアモニ。',
    'モーニング刑事。',
    'モー娘。',
];

sub new {
    # Constructor
    my $class = shift;
    my $argvs = { @_ };

    return $class if ref $class eq __PACKAGE__;
    $argvs->{'language'} = 'ja';
    return bless $argvs, __PACKAGE__;
}

sub language {
    # Set language to use
    my $self = shift;

    $self->{'language'} ||= 'ja';
    return $self->{'language'};
}

sub object {
    # Wrapper method for new()
    my $self = shift;
    return __PACKAGE__->new unless ref $self;
    return $self;
}
*objects = *object;
*findobject = *object;

sub cat {
    my $self = shift;
    my $argv = shift;
    my $flag = shift // 0;

    my $ref1 = ref $argv;
    my $text = undef;
    my $neko = undef;
    my $nyaa = undef;

    return q() if( $ref1 ne '' && $ref1 ne 'SCALAR' );
    $text = $ref1 eq 'SCALAR' ? $$argv: $argv;
    return q() unless length $text;

    eval { 
        $self->reckon( \$text );
        $neko = $self->toutf8( $text );
    };
    return $text if $@;

    $neko =~ s{($RxPeriod)}{$1$Separator}g;
    $neko .= $Separator unless $neko =~ m{$Separator};

    my $hiralength = scalar @$HiraganaTails;
    my $katalength = scalar @$KatakanaTails;
    my $writingset = [ split( $Separator, $neko ) ];
    my $haschomped = 0;
    my ( $r1,$r2 ) = 0;

    for my $e ( @$writingset ) {

        next if $e =~ m/\A$RxPeriod\s*\z/;
        next if $e =~ m/$RxEndOfList\s*\z/;
        next if grep { $e =~ m/\A$_\s*/ } @$DoNotBecomeCat;
        next if grep { $e =~ m/$_$RxPeriod?\z/ } @$HiraganaTails;
        next if grep { $e =~ m/$_$RxPeriod?\z/ } @$KatakanaTails;
        next if grep { $e =~ m/$_$RxEndOfSentence?\s*\z/ } @$HiraganaTails;
        next if grep { $e =~ m/$_$RxEndOfSentence?\s*\z/ } @$KatakanaTails;
        next if grep { $e =~ m/$_\s*\z/ } @$FightingCats;

        # Do not convert if the string contain only ASCII characters.
        # ASCII文字しか入ってない時は何もしない
        next if $e =~ m{\A[\x20-\x7E]+\z};

        # ひらがな、またはカタカナが入ってないなら次へ
        next unless $e =~ m{[\p{InHiragana}\p{InKatakana}]+};

        # Cats may be hard to speak a word which ends with a character 'ね'.
        # 「ね」の後ろにニャーがあると猫が喋りにくそう
        next if $e =~ m{[ねネ]$RxPeriod?\s*\z};

        $haschomped = chomp $e;

        if( $e =~ m/な$RxPeriod?\s*\z/ ) {
            # な => にゃー
            $e =~ s/な($RxPeriod?)(\s*)\z/$HiraganaNya$1$2/;

        } elsif( $e =~ m/ナ$RxPeriod?\s*\z/ ) {
            # ナ => ニャー
            $e =~ s/ナ($RxPeriod?)(\s*)\z/$HiraganaNya$1$2/;

        } elsif( $e =~ m/\p{InHiragana}$RxPeriod\s*\z/ ) {

            $r1 = int rand $katalength;
            $e =~ s/($RxPeriod)(\s*)\z/$KatakanaTails->[ $r1 ]$1$2/;

        } elsif( $e =~ m/\p{InKatakana}$RxPeriod\s*\z/ ) {

            $r1 = int rand $hiralength;
            $e =~ s/($RxPeriod)(\s*)\z/$HiraganaTails->[ $r1 ]$1$2/;

        } elsif( $e =~ m/\p{InCJKUnifiedIdeographs}$RxPeriod?\s*\z/ ) {

            $r1 = int rand $hiralength;
            $r2 = int rand scalar @$Copulae;
            $e =~ s/($RxPeriod?)(\s*)\z/$Copulae->[ $r2 ]$KatakanaTails->[ $r1 ]$1$2/;

        } else {
            if( $e =~ m/($RxEndOfSentence)\s*\z/ ) {
                # ... => ニャー..., ! => ニャ!
                my $eos = $1;

                if( $e =~ m/\p{InKatakana}$RxEndOfSentence\s*\z/ ) {

                    $r1 = int rand( $hiralength / 2 );
                    $e =~ s/$RxEndOfSentence/$HiraganaTails->[ $r1 ]$eos/g;

                } elsif( $e =~ m/\p{InHiragana}$RxEndOfSentence\s*\z/ ) {

                    $r1 = int rand( $katalength / 2 );
                    $e =~ s/$RxEndOfSentence/$KatakanaTails->[ $r1 ]$eos/g;

                } else {
                    $r1 = int rand( $katalength / 2 );
                    $r2 = int rand( scalar @$Copulae );
                    $e =~ s/$RxEndOfSentence/$Copulae->[ $r2 ]$KatakanaTails->[ $r1 ]$eos/g;
                }

            } elsif( $e =~ m/$RxConversation\s*\z/ ) {

                # 0.5の確率で会話の後ろで猫が喧嘩をする
                if( $e =~ m/\A(.*$RxConversation[ ]*)($RxConversation.*)\s*\z/ ) {

                    $r1 = int rand scalar @$FightingCats;
                    $e = $1.$FightingCats->[ $r1 ].$2 if int(rand(10)) % 2;
                }
                $r1 = int rand scalar @$FightingCats;
                $e .= $FightingCats->[ $r1 ] if int(rand(10)) % 2;

            } else {

                $r1 = int rand $katalength;

                if( $e =~ m/[0-9\p{Latin}]\s*\z/ ) {

                    $r2 = int rand scalar @$Copulae;
                    $e =~ s/(\s*?)\z/ $Copulae->[ $r2 ]$KatakanaTails->[ $r1 ]$1/;

                } elsif( $e =~ m/\p{InKatakana}\s*\z/ ) {

                    $e =~ s/(\s*?)\z/$HiraganaTails->[ $r1 ]$1/;

                } else {
                    $e =~ s/(\s*?)\z/$KatakanaTails->[ $r1 ]$1/;
                }
            }
        }

        $e =~ s/[!]$RxPeriod/! /g;
        $e .= qq(\n) if $haschomped;

    } # End of for(@$writingset)

    return $self->utf8to( join( '', @$writingset ) ) unless $flag;
    return join( '', @$writingset );
}

sub neko {
    my $self = shift;
    my $argv = shift;
    my $flag = shift // 0;

    my $ref1 = ref $argv;
    my $text = undef;
    my $neko = undef;

    return q() if( $ref1 ne '' && $ref1 ne 'SCALAR' );
    $text = $ref1 eq 'SCALAR' ? $$argv : $argv;
    return q() unless length $text;


    eval { 
        $self->reckon( \$text );
        $neko = $self->toutf8( $text ); 
    };
    return $text if $@;

    my $nounstable = {
        '神' => 'ネコ',
        '神' => 'ネコ',
    };

    for my $e ( keys %$nounstable ) {

        next unless $neko =~ m{$e};
        my $f = $nounstable->{ $e };

        $neko =~ s{\A[$e]\z}{$f};
        $neko =~ s{\A[$e](\p{InHiragana})}{$f$1};
        $neko =~ s{\A[$e](\p{InKatakana})}{$f$1};
        $neko =~ s{(\p{InHiragana})[$e](\p{InHiragana})}{$1$f$2}g;
        $neko =~ s{(\p{InHiragana})[$e](\p{InKatakana})}{$1$f$2}g;
        $neko =~ s{(\p{InKatakana})[$e](\p{InKatakana})}{$1$f$2}g;
        $neko =~ s{(\p{InKatakana})[$e](\p{InHiragana})}{$1$f$2}g;
        $neko =~ s{(\p{InHiragana})[$e]($RxPeriod|$RxComma)?\z}{$1$f$2}g;
        $neko =~ s{(\p{InKatakana})[$e]($RxPeriod|$RxComma)?\z}{$1$f$2}g;
    }

    return $self->utf8to( $neko ) unless $flag;
    return $neko;
}

sub nyaa {
    my $self = shift;
    my $argv = shift || q();
    my $text = ref $argv ? $$argv : $argv;
    my $nyaa = [];

    push @$nyaa, @$KatakanaTails, @$HiraganaTails;
    return $text.$nyaa->[ int rand( scalar @$nyaa ) ];
}

sub straycat {
    my $self = shift;
    my $argv = shift // return q();
    my $noun = shift // 0;

    my $ref1 = ref $argv;
    my $data = [];
    my $text = q();

    my $nekobuffer = q();
    my $leftbuffer = q();
    my $buffersize = 144;
    my $entityrmap = {
        '&#12289;' => '、',
        '&#12290;' => '。',
    };

    return q() unless $ref1 =~ m/(?:ARRAY|SCALAR)/;
    push @$data, $ref1 eq 'ARRAY' ? @$argv : $$argv;
    return q() unless scalar @$data;

    for my $r ( @$data ) {

        # To be a cat
        if( $r =~ m|[^\x20-\x7e]+| ) {
            # Encode if any multibyte character exsits
            eval { 
                $self->reckon( \$r );
                $nekobuffer .=  $self->toutf8( $r );
            };
            next if $@;

        } else {
            $nekobuffer .= $r;
        }

        for my $e ( keys %$entityrmap ) {
            # Convert character entity reference to character itself.
            next unless $nekobuffer =~ m/$e/;
            $nekobuffer =~ s/$e/$entityrmap->{ $e }/g;
        }

        if( length $nekobuffer < $buffersize ) {

            if( $nekobuffer =~ m/(.+$RxPeriod)(.*)/msx ) {

                $nekobuffer = $1;
                $leftbuffer = $2;

            } else {
                next;
            }
        }

        if( $nekobuffer =~ m|[^\x20-\x7e]+| ) {
            # Convert if any multibyte character exsits
            $nekobuffer = $self->cat( \$nekobuffer, 1 );
        }

        if( $noun ) {
            # Convert noun
            $nekobuffer = $self->neko( \$nekobuffer, 1 ) if $nekobuffer =~ m|[^\x20-\x7e]+|;
            $leftbuffer = $self->neko( \$leftbuffer, 1 ) if $leftbuffer =~ m|[^\x20-\x7e]+|;
        }

        $text .= $nekobuffer;
        $nekobuffer  = $leftbuffer;
        $leftbuffer  = q();
    }

    $text .= $nekobuffer if length $nekobuffer;
    return $self->utf8to( $text );
}

sub reckon {
    # Recognize text encoding
    my $self = shift;
    my $argv = shift;

    my $ref1 = ref $argv;
    my $text = $ref1 eq 'SCALAR' ? $$argv: $argv;
    return q() unless length $text;

    use Encode::Guess qw(shiftjis euc-jp 7bit-jis);
    $self->{'utf8flag'} = utf8::is_utf8 $text;

    my $code = Encode::Guess->guess( $text );
    my $name = q();
    return q() unless ref $code;

    # What encoding
    $name = $code->name;
    $name = $1 if $name =~ m/\A(.+) or .+/;

    if( $name ne 'ascii' ) {
        $self->{'encoding'} ||= $name;
    }
    return $self->{'encoding'};
}

1;

__END__
=encoding utf8

=head1 NAME

Acme::Nyaa - Convert texts like which a cat is talking in Japanese

=head1 SYNOPSIS

    use Acme::Nyaa::Ja;
    my $kijitora = Acme::Nyaa::Ja->new();

    # the following code is equivalent to the above.

    use Acme::Nyaa;
    my $kijitora = Acme::Nyaa->new( 'language' => 'ja' );


    print $kijitora->cat( \'猫がかわいい。' );  # => 猫がかわいいニャー。
    print $kijitora->neko( \'神と和解せよ' );   # => ネコと和解せよ

=head1 DESCRIPTION
  
Acme::Nyaa is a converter which translate Japanese texts to texts like which a cat talking.
Language modules are available only Japanese (L<Acme::Nyaa::Ja>) for now.

=head1 CLASS METHODS

=head2 B<new()>

new() is a constructor of Acme::Nyaa::Ja

    my $kijitora = Acme::Nyaa::Ja->new();
    my $sabatora = Acme::Nyaa->new( 'language' => 'ja' );

=head1 INSTANCE METHODS

=head2 B<cat( I<\$text> )>

cat() is a converter that appends string C<ニャー> at the end of each sentence.

    my $kijitora = Acme::Nyaa::Ja->new;
    my $nekotext = '猫がかわいい。';
    print $kijitora->cat( \$nekotext );
    # 猫がかわいいニャーー!!

=head2 B<neko( I<\$text> )>

neko() is a converter that replace a noun with C<ネコ>.

    my $kijitora = Acme::Nyaa::Ja->new;
    my $nekotext = '人の道も行いも神は見ている';
    print $kijitora->neko( \$nekotext );
    # 人の道も行いもネコは見ている

=head2 B<nyaa( [I<\$text>] )>

nyaa() returns string: C<ニャー>.

    my $kijitora = Acme::Nyaa->new;
    print $kijitora->nyaa();        # ニャー
    print $kijitora->nyaa('京都');  # 京都にゃー

=head2 B<straycat( I<\@array-ref> | I<\$scalar-ref> [,1] )>

straycat() converts multi-lined sentences. If 2nd argument is given then
this method also replace each noun with C<ネコ>.

    my $nekoobject = Acme::Nyaa::Ja->new;
    my $filehandle = IO::File->new( 't/a-part-of-i-am-a-cat.ja.txt', 'r' );
    my @nekobuffer = <$filehandle>;
    print $nekoobject->straycat( \@nekobuffer );

    # 吾輩は猫であるニャ。名前はまだ無いニャーー! 
    # どこで生まれたか頓と見當がつかぬニャーん。何ても暗薄いじめじめした所でニャーニャー泣いて
    # 居た事丈は記憶して居るニャーん。吾輩はこゝで始めて人間といふものを見たニャーん。然もあとで聞くと
    # それは書生といふ人間で一番獰惡な種族であつたさうだニャーーー!! 此書生といふのは時々我々を捕
    # へて煮て食ふといふ話であるニャ〜。

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 SEE ALSO

L<Acme::Nyaa>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

