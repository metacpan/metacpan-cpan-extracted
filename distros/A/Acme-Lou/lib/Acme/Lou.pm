package Acme::Lou;
use 5.010001;
use strict;
use warnings;
use utf8;
our $VERSION = '0.04';

use Exporter 'import';
use Encode;
use File::ShareDir qw/dist_file/;
use Text::Mecabist;

our @EXPORT_OK = qw/lou/;

sub lou {
    my $text = shift || "";
    return Acme::Lou->new->translate($text);
}

sub new {
    my $class = shift;
    my $self = bless {
        mecab_option => {
            userdic => dist_file('Acme-Lou', Text::Mecabist->encoding->name .'.dic'),
        },
        lou_rate => 100,
        @_,
    }, $class;
}

sub translate {
    my ($self, $text, $opt) = @_;
    my $rate = $opt->{lou_rate} // $self->{lou_rate};
    
    my $parser = Text::Mecabist->new($self->{mecab_option});
    
    return $parser->parse($text, sub {
        my $node = shift;
        return if not $node->readable;
        
        my $word  = $node->extra1 or return; # ルー単語 found
        my $okuri = $node->extra2 // "";
        
        return if int(rand 100) > $rate;
        
        if ($node->prev and
            $node->prev->is('接頭詞') and
            $node->prev->lemma =~ /^[ごお御]$/) {
            $node->prev->skip(1);
        }
        
        if ($node->is('形容詞') and
            $node->is('基本形') and
            $node->next and $node->next->pos =~ /助詞|記号/) {
            $okuri = "";
        }

        $node->text($word . $okuri);
    })->stringify();
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Lou - Let's together with Lou Ohshiba 

=head1 SYNOPSIS

    use utf8;
    use Acme::Lou qw/lou/;

    print lou("人生には、大切な三つの袋があります。");
    # => ライフには、インポータントな三つのバッグがあります。

=head1 DESCRIPTION

Translate Japanese text into Lou Ohshiba (Japanese comedian) style. 

=head1 METHODS

=head2 $lou = Acme::Lou->new() 

Creates an Acme::Lou object.

=head2 $lou->translate($text [, \%options ])

    $lou = Acme->Lou->new();
    $out = $lou->translate($text, { lou_rate => 50 });

Return translated unicode string.

I<%options>:

=over 4

=item * lou_rate

Percentage of translating. 100(default) means full, 0 means do nothing.

=back

=head1 EXPORTS

No exports by default.

=head2 lou

    use Acme::Lou qw/lou/;

    my $text = <<'...';
    祇園精舎の鐘の声、諸行無常の響きあり。
    沙羅双樹の花の色、盛者必衰の理を現す。
    奢れる人も久しからず、唯春の夜の夢のごとし。
    - 「平家物語」より
    ...

    print lou($text);

    # 祇園テンプルのベルのボイス、諸行無常のエコーあり。
    # 沙羅双樹のフラワーのカラー、盛者必衰のリーズンをショーする。
    # プラウドすれるヒューマンも久しからず、オンリースプリングのイーブニングのドリームのごとし。
    # - 「平家ストーリー」より

Shortcut to C<< Acme::Lou->new->translate() >>.

=head1 OBSOLETED FUNCTION

To keep this module working, following functions are obsoleted. sorry.

=over

=item * html input/output

=back

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 SEE ALSO

L<https://lou5.jp/>

L<http://taku910.github.io/mecab/>

Special thanks to Taku Kudo

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=for stopwords lou ohshiba unicode html

=cut
