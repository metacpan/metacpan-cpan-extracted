package Acme::eng2kor;
# ABSTRACT: English to Korean Translator


use utf8;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use JSON qw/decode_json/;
use Const::Fast;
use URI::Escape qw/uri_escape_utf8/;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use namespace::autoclean;

const my $GOOGLE_TRANSLATE_API_URL => "http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=%s&langpair=%s";
const my @SUPPORT_LANG_TAGS => qw/ach af ak am ar az be bem bg bh bn br bs ca co cs cy da de el en eo es et eu fa fi fo fr fy ga gd gl gn gu ha haw hi hr ht hu hy ia id ig is it iw ja jw ka kg kk km kn ko ku ky la lg ln lo lt lua lv mfe mg mi mk ml mn mo mr ms mt ne nl nn no ny nyn oc om or pa pl ps qu rm rn ro ru rw sd sh si sk sl sn so sq sr st su sv sw ta te tg th ti tk tl tn to tr tt tw ug uk ur uz vi wo xh yi yo zu/;

subtype 'LangTags'
    => as 'Str'
    => where { my $lang = $_; grep { /^$lang$/ } @SUPPORT_LANG_TAGS; };

has 'src' => (
    is => 'rw',
    isa => 'LangTags',
    default => 'en'
);

has 'dst' => (
    is => 'rw',
    isa => 'LangTags',
    default => 'ko'
);

has 'text' => (
    is => 'rw',
    isa => 'Str'
);

has 'translated' => (
    is => 'rw',
    isa => 'Str'
);


sub translate {
    my ($self, $word) = @_;
    map { s/^\s+//; s/\s+$// } $word if defined $word;
    return $self->_google_translate($word);
}


sub _google_translate {
    my ($self, $word) = @_;
    $self->text($word) if defined $word;
    my $text = uri_escape_utf8($self->text);
    my $escaped_uri = sprintf($GOOGLE_TRANSLATE_API_URL, $text, $self->src . '|' . $self->dst);
    my $json = $self->get_json($escaped_uri);
    $self->translated($json->{responseData}{translatedText});
    return $json;
}


sub get_json {
    my ($self, $url) = @_;
    my $req = HTTP::Request->new( GET => $url );
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->request($req);
    die $res->status_line, "\n" unless $res->is_success;
    return decode_json($res->content);
}

__PACKAGE__->meta->make_immutable;


1;

__END__
=pod

=encoding utf-8

=head1 NAME

Acme::eng2kor - English to Korean Translator

=head1 VERSION

version v0.0.2

=head1 SYNOPSIS

    use utf8;
    use Acme::eng2kor;
    binmode STDOUT, ':encoding(UTF-8)';
    my $app = Acme::eng2kor->new;
    $app->translate('hello');
    print $app->text, "\n";         # hello
    print $app->translated, "\n";   # 안녕하세요

=head1 DESCRIPTION

Yet Another Translator

=head1 METHODS

=head2 translate

Internal interface

=head2 _google_translate

Used google translate api

=head2 get_json

Return decoded json text after HTTP IO.

=head1 SUPPORT LANGUAGES

Google translate available language list is below.

    ach: Luo
    af: Afrikaans
    ak: Akan
    am: Amharic
    ar: Arabic
    az: Azerbaijani
    be: Belarusian
    bem: Bemba
    bg: Bulgarian
    bh: Bihari
    bn: Bengali
    br: Breton
    bs: Bosnian
    ca: Catalan
    co: Corsican
    cs: Czech
    cy: Welsh
    da: Danish
    de: German
    el: Greek
    en: English
    eo: Esperanto
    es: Spanish
    et: Estonian
    eu: Basque
    fa: Persian
    fi: Finnish
    fo: Faroese
    fr: French
    fy: Frisian
    ga: Irish
    gd: Scots Gaelic
    gl: Galician
    gn: Guarani
    gu: Gujarati
    ha: Hausa
    haw: Hawaiian
    hi: Hindi
    hr: Croatian
    ht: Haitian Creole
    hu: Hungarian
    hy: Armenian
    ia: Interlingua
    id: Indonesian
    ig: Igbo
    is: Icelandic
    it: Italian
    iw: Hebrew
    ja: Japanese
    jw: Javanese
    ka: Georgian
    kg: Kongo
    kk: Kazakh
    km: Cambodian
    kn: Kannada
    ko: Korean
    ku: Kurdish
    ky: Kyrgyz
    la: Latin
    lg: Luganda
    ln: Lingala
    lo: Laothian
    lt: Lithuanian
    lua: Tshiluba
    lv: Latvian
    mfe: Mauritian Creole
    mg: Malagasy
    mi: Maori
    mk: Macedonian
    ml: Malayalam
    mn: Mongolian
    mo: Moldavian
    mr: Marathi
    ms: Malay
    mt: Maltese
    ne: Nepali
    nl: Dutch
    nn: Norwegian (Nynorsk)
    no: Norwegian
    ny: Chichewa
    nyn: Runyakitara
    oc: Occitan
    om: Oromo
    or: Oriya
    pa: Punjabi
    pl: Polish
    ps: Pashto
    qu: Quechua
    rm: Romansh
    rn: Kirundi
    ro: Romanian
    ru: Russian
    rw: Kinyarwanda
    sd: Sindhi
    sh: Serbo-Croatian
    si: Sinhalese
    sk: Slovak
    sl: Slovenian
    sn: Shona
    so: Somali
    sq: Albanian
    sr: Serbian
    st: Sesotho
    su: Sundanese
    sv: Swedish
    sw: Swahili
    ta: Tamil
    te: Telugu
    tg: Tajik
    th: Thai
    ti: Tigrinya
    tk: Turkmen
    tl: Filipino
    tn: Setswana
    to: Tonga
    tr: Turkish
    tt: Tatar
    tw: Twi
    ug: Uighur
    uk: Ukrainian
    ur: Urdu
    uz: Uzbek
    vi: Vietnamese
    wo: Wolof
    xh: Xhosa
    yi: Yiddish
    yo: Yoruba
    zu: Zulu

=head1 SEE ALSO

* L<http://code.google.com/intl/en/apis/ajaxlanguage/>

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

