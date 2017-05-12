package Acme::Pinoko;

use 5.008_008;
use strict;
use warnings;
use utf8;

use Carp   ();
use Encode ();
use Module::Load ();
use Data::Recursive::Encode ();
use Lingua::JA::Regular::Unicode ();
use Lingua::JA::Halfwidth::Katakana;

our $VERSION = '0.02';

# KyTea でデフォルトじゃないモデルを使う場合は変更が必要な場合もある
our $KYTEA_POSTAG_NUM  = 0;
our $KYTEA_PRONTAG_NUM = 1;

my @PARSERS = qw/Text::MeCab Text::KyTea/;

my %HIRAGANA_INVALID_POS;
@HIRAGANA_INVALID_POS{qw/助詞 語尾 副詞 動詞 助動詞 形容詞 形状詞 連体詞 接頭詞 接頭辞 代名詞/} = ();

my %TERMINATOR_CHAR;
@TERMINATOR_CHAR{ split(//, "。｡.． 　\n\t…‥!！") } = ();

sub _options
{
    return {
        parser        => 'Text::MeCab',
        parser_config => undef,
    };
}

sub new
{
    my $class = shift;
    my %args  = (ref $_[0] eq 'HASH' ? %{$_[0]} : @_);

    my $options = $class->_options;

    for my $key (keys %args)
    {
        if ( ! exists $options->{$key} ) { Carp::croak "Unknown option: '$key'"; }
        else                             { $options->{$key} = $args{$key};       }
    }

    Carp::croak "Invalid parser: '$options->{parser}'" if ! grep { $options->{parser} eq $_ } @PARSERS;

    Module::Load::load($options->{parser});

    my $self = bless $options, $class;

    $self->_load_parser;

    return $self;
}

sub say
{
    my ($self, $text) = @_;

    return unless defined $text;
    return $self->_to_pinoko( $self->_parse(\$text) );
}

sub _load_parser
{
    my ($self) = @_;

    $self->{parser_name} = delete $self->{parser};

    if ($self->{parser_name} eq 'Text::MeCab')
    {
        my $mecab;

        if ( ! $self->{paser_config} ) { $mecab = Text::MeCab->new;                         }
        else                           { $mecab = Text::MeCab->new($self->{parser_config}); }

        $self->{parser}  = $mecab;
        $self->{encoder} = Encode::find_encoding(Text::MeCab::ENCODING());
    }
    else # Text::KyTea
    {
        my $kytea;

        if ( ! $self->{parser_config} ) { $kytea = Text::KyTea->new({ tagmax => 1 });        }
        else                            { $kytea = Text::KyTea->new($self->{parser_config}); }

        $self->{parser} = $kytea;
    }

    return;
}

sub _parse
{
    my ($self, $text_ref) = @_;

    my (@surfaces, @poses, @prons);

    if ($self->{parser_name} eq 'Text::MeCab')
    {
        my $encoder = $self->{encoder};

        for my $text ( split(/(\s+)/, $$text_ref) )
        {
            if ($text =~ /\s/)
            {
                push(@surfaces, $text);
                push(@poses, '記号');
                push(@prons, 'UNK');
                next;
            }

            my $encoded_text = $encoder->encode($text);

            for (my $node = $self->{parser}->parse($encoded_text); $node; $node = $node->next)
            {
                next if $node->stat == 2 || $node->stat == 3;

                my $surface = $encoder->decode($node->surface);
                push(@surfaces, $surface);

                my ($pos, $pron) = (split(/,/, $encoder->decode($node->feature), 9))[0,7];

                if ( (! defined $pron) || $pron eq '*' )
                {
                    if ($surface =~ /^\p{InKatakana}+$/) { $pron = Lingua::JA::Regular::Unicode::katakana2hiragana($surface); }
                    else                                 { $pron = 'UNK';                                                     }
                }
                else { $pron = Lingua::JA::Regular::Unicode::katakana2hiragana($pron); }

                push(@poses, $pos);
                push(@prons, $pron);
            }
        }
    }
    else # Text::KyTea
    {
        my $results = $self->{parser}->parse($$text_ref);

        $results = Data::Recursive::Encode->decode_utf8($results);

        for my $result (@{$results})
        {
            push(@surfaces, $result->{surface});
            push(@poses,    $result->{tags}[$KYTEA_POSTAG_NUM][0]{feature});
            push(@prons,    $result->{tags}[$KYTEA_PRONTAG_NUM][0]{feature});
        }
    }

    return (\@surfaces, \@poses, \@prons);
}

sub _to_pinoko
{
    my ($self, $surfaces_ref, $poses_ref, $prons_ref) = @_;

    my $ret = '';

    for my $i (0 .. $#{$prons_ref})
    {
        my $surf = $surfaces_ref->[$i];

        if (
             $poses_ref->[$i] eq '記号'
         ||  $poses_ref->[$i] eq '補助記号'
         || ( $prons_ref->[$i] eq 'UNK' && $surf =~ /[^\p{InHalfwidthKatakana}]/ )
         || $surf =~ /^[a-zA-Zａ-ｚＡ-Ｚ0-9０-９]+$/
        )
        {
            $ret .= $surf;
        }
        elsif ($surf =~ /[^\p{InHiragana}]/)
        {
            if (
                $surf eq '手術'
             || $surf eq '笑'
             || $surf eq 'シーウーノ'
             || $surf eq 'アラマンチュ'
             || $surf eq 'シーウーノアラマンチュ'
             || $surf =~ /^アッチョンブリケー*/
            )
            {
                $ret .= $surf;
            }
            else
            {
                # e.g. 「ｱめりカ合衆国の州」の場合
                # @surfaces の中身は以下の通り
                # [0]: ｱめりカ
                # [1]: 合衆国
                # [2]: の
                # [3]: 州
                my @surfaces = grep { length } split(/([0-9０-９]*[\p{Han}ケヶ]+[0-9０-９]*|[^\p{Han}]+)/, $surf);

                my (@kanji_prons, $regexp);

                for my $surface (@surfaces)
                {
                    if ($surface =~ /[0-9０-９]*[\p{Han}ケヶ]/) { $regexp .= "(.+)"; }
                    else
                    {
                        if ($self->{parser_name} eq 'Text::MeCab')
                        {
                            $regexp .= Lingua::JA::Regular::Unicode::katakana2hiragana($surface);
                        }
                        else # Text::KyTea
                        {
                            if ($surface =~ /(?:ず|づ)/)
                            {
                                my $pron = Lingua::JA::Regular::Unicode::katakana2hiragana($surface);
                                my $du = $pron; $du =~ tr/ず/づ/;
                                my $zu = $pron; $zu =~ tr/づ/ず/;

                                $regexp .= "(?:$du|$zu)";
                            }
                            else
                            {
                                if ($surface =~ /[あ-おぁ-ぉア-オァ-ォ]{1}/)
                                {
                                    $regexp .= "[" . Lingua::JA::Regular::Unicode::katakana2hiragana($surface) . "|ー]";
                                }
                                else { $regexp .= Lingua::JA::Regular::Unicode::katakana2hiragana($surface); }
                            }
                        }
                    }
                }

                if ($regexp =~ /\(\.\+\)/)
                {
                    $regexp =~ tr/\x{005F}\x{3000}\x{3095}/\x{FF3F}\x{FF3F}\x{304B}/; # 「_　ゕ」-> 「＿＿か」
                    @kanji_prons = $prons_ref->[$i] =~ /$regexp/;
                }

                for my $surface (@surfaces)
                {
                    if ($surface =~ /\p{Han}/)
                    {
                        my $pron        = shift @kanji_prons;
                        my $pinoko_pron = $self->pinoko($pron);

                        if ( (! defined $pinoko_pron) || $pron eq $pinoko_pron ) { $ret .= $surface; }
                        else                                                     { $ret .= $pron;    }
                    }
                    else
                    {
                        if ($surface =~ /[^\p{InHalfwidthKatakana}]/)
                        {
                            if ($surface =~ /^\p{InKatakana}+$/)
                            {
                                my $pron = Lingua::JA::Regular::Unicode::katakana2hiragana($surface);
                                $ret .= Lingua::JA::Regular::Unicode::hiragana2katakana($self->pinoko($pron));
                            }
                            else { $ret .= $surface; }
                        }
                        else # 半角カタカナのみ
                        {
                            # 半角文字を kataka2hiragana すると濁点等が分離してしまうので
                            # 一旦全角にしてから kataka2hiragana する
                            my $pron = Lingua::JA::Regular::Unicode::katakana_h2z($surface);
                            $pron    = Lingua::JA::Regular::Unicode::katakana2hiragana($pron);
                            $ret    .= Lingua::JA::Regular::Unicode::katakana_z2h(
                                           Lingua::JA::Regular::Unicode::hiragana2katakana($self->pinoko($pron))
                                    );
                        }
                    }
                }
            }
        }
        else # 平仮名のみ
        {
            my $pos  = $poses_ref->[$i];
            my $pron = $prons_ref->[$i];

            if ($pos eq '助詞' || $pos eq '語尾' || $pos eq '助動詞')
            {
                my $next_pos = $poses_ref->[$i + 1];
                $next_pos = '' unless defined $next_pos;

                my $next_surface = $surfaces_ref->[$i + 1];
                $next_surface = '' unless defined $next_surface;

                my $next_next_surface = $surfaces_ref->[$i + 2];
                $next_next_surface = '' unless defined $next_next_surface;

                if (
                    exists $HIRAGANA_INVALID_POS{$next_pos}
                 || $next_surface eq '？'
                 || $next_surface eq '?'
                 || (
                        ($next_pos eq '名詞' || $next_pos eq '記号' || $next_pos eq '補助記号')
                     && ! exists $TERMINATOR_CHAR{$next_surface}
                     && $next_surface ne '･･'
                     && ! ($next_surface eq '･'  &&  $next_next_surface eq '･')
                     && ! ($next_surface eq '・' &&  $next_next_surface eq '・')
                     && $next_surface !~ /^ｗ+$/
                    )
                )
                {
                    $ret .= $pron;
                }
                else
                {
                    if ($pron eq 'わ')
                    {
                        if ( int( rand(2) ) == 0 ) { $ret .= 'わのよ'; }
                        else                       { $ret .= 'わのね'; }
                    }
                    elsif ($pron eq 'の')
                    {
                        if ( $i != 0 && $poses_ref->[$i - 1] eq '名詞' && ($next_surface eq '' || $next_surface =~ /\s/) )
                        {
                            $ret .= 'の';
                        }
                        else { $ret .= 'のよさ'; }
                    }
                    elsif ($pron eq 'うよ')
                    {
                        $ret .= 'うよのさ';
                    }
                    elsif ( $i != 0 && ($pron eq 'よ' || $pron eq 'ね') )
                    {
                        my $prev_surface = $surfaces_ref->[$i - 1];

                        if ($pron eq 'よ')
                        {
                               if ($prev_surface eq 'わ' || $prev_surface eq 'だ')
                                                          { $ret .= 'のよ';   }
                            elsif ($prev_surface ne 'の') { $ret .= 'よのさ'; }
                            else                          { $ret .= 'よさ';   }
                        }
                        else # ね
                        {
                            if ($prev_surface eq 'わ' || $prev_surface eq 'よ') { $ret .= 'のね'; }
                            else                                                { $ret .= 'ね';   }
                        }
                    }
                    else { $ret .= $pron; }
                }
            }
            else { $ret .= $pron; }
        }
    }

    return $self->pinoko($ret);
}

sub pinoko
{
    local $_ = $_[1];

    return unless defined $_;

    s/奥さん/おくたん/g;
    s/手術/シウツ/g;
    s/しゅじゅつ/しうつ/g;
    s/憂鬱/ユーツ/g;
    s/抜群/バチグン/g;
    s/ウソツキ/ウソチュキ/g; # MeCab専用
    s/あくせさり/あくちぇちゃい/g;
    s/す/ちゅ/g;
    s/づ/じゅ/g;
    s/じ(?=め)/じゅ/g;
    s/ず(?!ー)/じゅ/g;
    s/っつ/っちゅ/g;
    s/けど/けよ/g;
    s/あのね/あんね/g;
    s/こども/こよも/g;
    s/なんだ/なんや/g;
    s/それで/そいれ/g;
    s/そりゃ[あー]/そやァ/g;
    s/うそつき/うそちゅき/g;
    s/(?<!のよ|よの)さ(?!せ)/ちゃ/g;      # のよさ, よのさ, させ           でなければ さ -> ちゃ
    s/(?<!そい)れ(?!ちょ|ちゅ|でぃ)/え/g; # そいれ, れちょ, れちゅ, れでぃ でなければ れ -> え
    s/し(?!う|ち)/ち/g;                   # しう, しち                     でなければ し -> ち
    s/れでぃー?/れれい/g;
    s/きゃんでぃー?/きゃんれー/g;
    s/り(?!ゃ|ゅ|ょ)/い/g;
    s/(?<!な)のよのね/のよね/g;
    tr/でらるろ/れやゆよ/;
    s/ど(?!よ)/ろ/g;
    s/だ(?!のよ|ゆ|が)/ら/g;

    $_;
}

1;

__END__

=encoding utf8

=head1 NAME

Acme::Pinoko - Acchonburike!

=for test_synopsis
my (%config);

=head1 SYNOPSIS

  use Acme::Pinoko;
  use utf8;

  my $pinoko = Acme::Pinoko->new(%config);
  print $pinoko->say('ピノコ１８のレディなのよ');
  # -> ピノコ１８のレレイなのよさ

=head1 DESCRIPTION

Acme::Pinoko converts standard Japanese text to Pinoko-ish Japanese text.

Pinoko is a Japanese manga character. She speaks with a lisp and
therefore her spoken Japanese is slightly different from standard Japanese.

=head1 METHODS

=head2 $pinoko = Acme::Pinoko->new(%config)

Creates a new Acme::Pinoko instance.

  my $pinoko = Acme::Pinoko->new(
      parser        => 'Text::MeCab' or 'Text::KyTea',  # default is 'Text::MeCab'
      parser_config => \%parser_config,                 # default is undef
  );

=head2 $pinoko_ish_text = $pinoko->say($text)

Pinoko says $text.

=head1 AUTHOR

pawa E<lt>pawapawa@cpan.orgE<gt>

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Black_Jack_%28manga%29#Characters>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
