package AmberDB::Locale;

use 5.016;
use warnings;
use utf8;
use Encode qw(decode encode);
use Carp qw(croak cluck);

our $VERSION = '5.25.1';
my $CREATED  = '2017-07-22';

my %LOCALE_CACHE;
my %WARNED_LOCALES;

# -------------------------------------------------------
# AmberDB::Locale — Locale-aware string operations
#
# Formerly a Turkish-only module; now a generic locale
# engine that loads per-language data from AmberDB::Locale::Lang::*
#
# USAGE:
#   # New API (explicit language):
#   my $lang = AmberDB::Locale->new(language => "gb");
#   my $lang = AmberDB::Locale->new(language => "tr");
#
#   # With AmberDB engine (language from cfg, defaults to "gb"):
#   AmberDB->new(cfg => { language => "gb" });
#   # then $self->uc($str) works on the inherited object
# -------------------------------------------------------


# -------------------------------------------------------
# Constructor
# -------------------------------------------------------
sub new {
    my $class = shift;

    my $lang;

    # Handle calling conventions:
    #   1. new(language => "gb")     — named-param API
    #   2. new({ language => "gb" }) — unblessed hash ref API
    #   3. new("gb")                 — positional string API
    #   4. new()                     — no args; use default ("gb")
    if ( @_ ) {
        if ( @_ == 1 && !ref( $_[0] ) ) {
            $lang = $_[0];
        }
        elsif ( @_ == 1 && ref( $_[0] ) eq 'HASH' ) {
            $lang = $_[0]->{language} || $_[0]->{lang};
        }
        elsif ( @_ % 2 == 0 && !ref( $_[0] ) ) {
            my %args = @_;
            $lang = $args{language} || $args{lang};
        }
    }

    my %LANG_ALIAS = (
        'turkish'     => 'tr',
        'tr_tr'       => 'tr',
        'tr-tr'       => 'tr',
        'english'     => 'en',
        'en_us'       => 'en',
        'en_gb'       => 'gb',
        'german'      => 'de',
        'de_de'       => 'de',
        'french'      => 'fr',
        'fr_fr'       => 'fr',
        'spanish'     => 'es',
        'es_es'       => 'es',
        'russian'     => 'ru',
        'ru_ru'       => 'ru',
        'arabic'      => 'ar',
        'ar_sa'       => 'ar',
        'azerbaijani' => 'az',
        'az_az'       => 'az',
        'japanese'    => 'ja',
        'ja_jp'       => 'ja',
        'ja-jp'       => 'ja',
        'global'      => 'gb',
        'gb'          => 'gb',
        'gl'          => 'gb',
        'universal'   => 'gb',
        'uni'         => 'gb',
        'gb_base'     => 'gb',
    );

    $lang = lc( $lang // '' );
    $lang =~ s/[^\w-]//g;
    my $norm_lang = $LANG_ALIAS{$lang} || ( split /[_-]/, $lang )[0] || 'gb';

    # Fast path: instance cache lookup (keyed by class + normalized language)
    my $cache_key = "${class}::${norm_lang}";
    return $LOCALE_CACHE{$cache_key} if $LOCALE_CACHE{$cache_key};

    my $self = bless { _lang => $norm_lang }, $class;
    $self->_load_locale($norm_lang);

    if ( $self->{_lang} ) {
        $LOCALE_CACHE{$cache_key} = $self;
        $LOCALE_CACHE{"${class}::$self->{_lang}"} = $self;
    }

    return $self;
}

# -------------------------------------------------------
# Load locale data from AmberDB::Locale::Lang::<lang>
# Falls back to 'gb' if requested locale not found.
# -------------------------------------------------------
sub _load_locale {
    my ( $self, $lang ) = @_;

    $lang ||= 'gb';
    $self->{_lang} = $lang;

    my $locale_class = "AmberDB::Locale::Lang::$lang";
    my $loaded = eval {
        ( my $path = $locale_class ) =~ s|::|/|g;
        require "$path.pm";
        1;
    };

    unless ($loaded) {
        if ( $lang ne 'gb' ) {
            unless ( $WARNED_LOCALES{$lang}++ ) {
                cluck "AmberDB::Locale: locale '$lang' not found, falling back to 'gb'\n";
            }
            $locale_class = 'AmberDB::Locale::Lang::gb';
            require AmberDB::Locale::Lang::gb;
            $self->{_lang} = 'gb';
        }
    }

    $self->{_locale} = $locale_class->data();

    # Initialize Unicode::Collate::Locale for UCA standard collation
    eval {
        require Unicode::Collate::Locale;
        $self->{_collator} = Unicode::Collate::Locale->new( locale => $lang );
        1;
    } or do {
        # Fallback to base Unicode::Collate if locale-specific table is unavailable
        eval {
            require Unicode::Collate;
            $self->{_collator} = Unicode::Collate->new();
            1;
        };
    };

    $self->_compile_patterns();
    return $self;
}

# -------------------------------------------------------
# Pre-compile regex patterns from locale data
# Called once at construction time — not on each method call.
# -------------------------------------------------------
sub _compile_patterns {
    my ($self) = @_;
    my $loc = $self->{_locale};

    # uc_map regex — sort keys by length descending to match longer patterns first
    if ( my %uc = %{ $loc->{uc_map} || {} } ) {
        my @keys = sort { length($b) <=> length($a) } keys %uc;
        my $chars = join '|', map { quotemeta $_ } @keys;
        $self->{_uc_re} = qr/($chars)/;
    }

    # lc_map regex — sort keys by length descending
    if ( my %lc = %{ $loc->{lc_map} || {} } ) {
        my @keys = sort { length($b) <=> length($a) } keys %lc;
        my $chars = join '|', map { quotemeta $_ } @keys;
        $self->{_lc_re} = qr/($chars)/;
    }

    # sort_map regex
    if ( my %sm = %{ $loc->{sort_map} || {} } ) {
        my @keys = sort { length($b) <=> length($a) } keys %sm;
        my $chars = join '|', map { quotemeta $_ } @keys;
        $self->{_sort_re} = qr/($chars)/;
    }

    # accent_map regex
    if ( my %am = %{ $loc->{accent_map} || {} } ) {
        my @keys = sort { length($b) <=> length($a) } keys %am;
        my $chars = join '|', map { quotemeta $_ } @keys;
        $self->{_accent_re} = qr/($chars)/;
    }

    # ascii_map regex
    if ( my %as = %{ $loc->{ascii_map} || {} } ) {
        my @keys = sort { length($b) <=> length($a) } keys %as;
        my $chars = join '|', map { quotemeta $_ } @keys;
        $self->{_ascii_re} = qr/($chars)/;
    }

    # regex_map regex for search pattern generation
    if ( my %rm = %{ $loc->{regex_map} || {} } ) {
        my @keys = sort { length($b) <=> length($a) } keys %rm;
        my $chars = join '|', map { quotemeta $_ } @keys;
        $self->{_search_re}  = qr/($chars)/;
        $self->{_search_map} = \%rm;
    }

    # Pre-compile phonetic assimilation / final-devoicing rules
    if ( my $pm = $loc->{phonetic_map} ) {
        my @rules;
        if ( ref($pm) eq 'HASH' ) {
            foreach my $pat ( keys %$pm ) {
                push @rules, [ qr/$pat/i, $pm->{$pat} ];
            }
        }
        elsif ( ref($pm) eq 'ARRAY' ) {
            foreach my $pair (@$pm) {
                my ( $pat, $sub ) = @$pair;
                push @rules, [ qr/$pat/i, $sub ];
            }
        }
        $self->{_phonetic_rules} = \@rules;
    }

    # Safe-text character class (alphabet_chars extends a-zA-Z)
    my $extra = $loc->{alphabet_chars} || '';
    my $safe_extra = quotemeta($extra);
    $self->{_safe_re}   = qr/[^a-zA-Z${safe_extra}0-9&.,_\-;:()\s]/;
    $self->{_letter_re} = qr/[a-zA-Z${safe_extra}]/;

    my @splitters = @{ $loc->{word_splitters} || [ "'", "\x{2019}", "\x{2018}", "\x{2032}", "\x{02BC}", "-" ] };
    my $split_chars = join '', map { quotemeta($_) } @splitters;
    $self->{_splitter_re} = qr/[$split_chars]/;

    # Combined html_entities: universal + locale-specific extras
    $self->{_html_entities} = {
        # Universal entities
        '&amp;'    => '&',          '&lt;'     => '<',
        '&gt;'     => '>',          '&quot;'   => '"',
        '&apos;'   => "'",          '&nbsp;'   => ' ',
        '&euro;'   => "\x{20AC}",   '&laquo;'  => "\x{AB}",
        '&raquo;'  => "\x{BB}",     '&lsquo;'  => "\x{2018}",
        '&rsquo;'  => "\x{2019}",   '&ldquo;'  => "\x{201C}",
        '&rdquo;'  => "\x{201D}",   '&hellip;' => "\x{2026}",
        '&ndash;'  => "\x{2013}",   '&mdash;'  => "\x{2014}",
        '&bull;'   => "\x{2022}",   '&trade;'  => "\x{2122}",
        '&copy;'   => "\x{00A9}",   '&reg;'    => "\x{00AE}",
        # Locale-specific extras (override/extend universals)
        %{ $loc->{html_entities} || {} },
    };

    return $self;
}

# =======================================================
# PUBLIC API — UTF-8 Encoding / Decoding & String Operations
# =======================================================

# -------------------------------------------------------
# utf_encode: Converts a Perl Unicode string into raw UTF-8 octets (bytes).
# my $bytes = $lang->utf_encode($string);
# -------------------------------------------------------
sub utf_encode {
    my ( $self, $string ) = @_;
    return unless defined $string;
    utf8::encode($string) if utf8::is_utf8($string);
    return $string;
}

# -------------------------------------------------------
# utf_decode: Decodes raw UTF-8 bytes into a Perl Unicode character string.
# my $chars = $lang->utf_decode($string);
# -------------------------------------------------------
sub utf_decode {
    my ( $self, $string ) = @_;
    return unless defined $string;
    utf8::decode($string) unless utf8::is_utf8($string);
    return $string;
}

# -------------------------------------------------------
# Locale-aware uppercase.
# Applies uc_map substitutions before Perl's CORE::uc().
# my $upper = $lang->uc($string);
# -------------------------------------------------------
sub uc {
    my ( $self, $string ) = @_;
    return unless defined $string;
    $string = $self->utf_decode($string);
    if ( my $re = $self->{_uc_re} ) {
        my $uc_map = $self->{_locale}{uc_map};
        $string =~ s/$re/$uc_map->{$1}/ge;
    }
    return CORE::uc($string);
}

# -------------------------------------------------------
# Locale-aware lowercase.
# Applies lc_map substitutions before Perl's CORE::lc().
# my $lower = $lang->lc($string);
# -------------------------------------------------------
sub lc {
    my ( $self, $string ) = @_;
    return unless defined $string;
    $string = $self->utf_decode($string);
    if ( my $re = $self->{_lc_re} ) {
        my $lc_map = $self->{_locale}{lc_map};
        $string =~ s/$re/$lc_map->{$1}/ge;
    }
    return CORE::lc($string);
}

# -------------------------------------------------------
# Converts search query string into a locale-aware regex pattern.
# Replaces locale-specific casing characters with regex match patterns.
# my $pattern = $lang->search_pattern($query);
# -------------------------------------------------------
sub search_pattern {
    my ( $self, $string ) = @_;
    return '' unless defined $string;
    $string = $self->utf_decode($string);
    if ( my $re = $self->{_search_re} ) {
        my $sm = $self->{_search_map};
        $string =~ s/$re/$sm->{$1}/ge;
    }
    return $string;
}

# -------------------------------------------------------
# Performs regex search matching of search pattern inside target text string.
# Does not re-normalize $aranan; performs matching directly.
# my $bool = $lang->search_regex($string, $aranan);
# -------------------------------------------------------
sub search_regex {
    my ( $self, $string, $aranan ) = @_;
    return 0 unless defined $string && defined $aranan && length($aranan);
    $string = $self->utf_decode($string);
    $aranan = $self->utf_decode($aranan);
    return $string =~ /$aranan/i ? 1 : 0;
}

# -------------------------------------------------------
# Normalizes a single search token/word according to locale
# phonetic assimilation, clitic/apostrophe stripping, and final-devoicing rules.
# $mode_write = 1 | "write" -> "Türkiye'de" => "turkiye turkiyede"
# $mode_write = 0 | "read"  -> "Türkiye'de" => "turkiye"
# my $norm = $lang->normalize_word($word, $mode_write);
# -------------------------------------------------------
sub normalize_word {
    my ( $self, $word, $mode_write ) = @_;
    return '' unless defined $word && length($word);

    # Fast in-memory cache check
    if ( defined $self->{_cache}{nw}{$word} ) {
        return $self->{_cache}{nw}{$word};
    }

    $word = $self->utf_decode($word);

    my $is_write = ( $mode_write && ( $mode_write eq 'write' || $mode_write eq '1' ) ) ? 1 : 0;
    my $L = $self->{_letter_re}   || qr/[a-zA-Z]/;
    my $S = $self->{_splitter_re} || qr/['’‘′ʼ\-]/;

    if ($is_write) {
        # Yazma modunda: Kök ($1) ve Birleşik ($1$2) türetilir, ek ($2) tek başına alınmaz
        $word =~ s/($L+)$S+($L+)/$1 $1$2/g;
    }
    else {
        # Okuma/Arama modunda: Kök ($1) yeterlidir (tek harfli ön eklerde birleşik $1$2 alınır: örn. T-Shirt -> tshirt)
        $word =~ s/($L+)$S+($L+)/(length($1) > 1 ? $1 : "$1$2")/ge;
    }

    my @parts;
    foreach my $w ( split /\s+/, $word ) {
        next unless length $w;
        $w = $self->lc($w);
        $w = $self->to_ascii($w);

        if ( my $rules = $self->{_phonetic_rules} ) {
            foreach my $rule (@$rules) {
                my ( $re, $sub ) = @$rule;
                $w =~ s/$re/$sub/g;
            }
        }
        $w =~ s/^[^a-z0-9]+|[^a-z0-9]+$//g;
        push @parts, $w if length $w;
    }

    my $res = join( " ", @parts );
    $self->{_cache}{nw}{$word} = $res;
    return $res;
}

# -------------------------------------------------------
# Case-folded string normalization for search indexing / matching.
# Normalizes string using NFKC decomposition and locale lowercasing.
# my $folded = $lang->fold($string);
# -------------------------------------------------------
sub fold {
    my ( $self, $string ) = @_;
    return '' unless defined $string;
    require Unicode::Normalize;
    $string = $self->lc($string);
    return Unicode::Normalize::NFKC($string);
}

# -------------------------------------------------------
# Locale-aware case-insensitive equality comparison.
# Returns 1 if strings are equal under locale rules, 0 otherwise.
# my $bool = $lang->ieq($str1, $str2);
# -------------------------------------------------------
sub ieq {
    my ( $self, $s1, $s2 ) = @_;
    return 1 if !defined($s1) && !defined($s2);
    return 0 if !defined($s1) || !defined($s2);
    return $self->fold($s1) eq $self->fold($s2);
}

# -------------------------------------------------------
# Locale-aware ucfirst — capitalize first letter of each word.
# my $str = $lang->ucfirst($string);
# -------------------------------------------------------
sub ucfirst {
    my ( $self, $string ) = @_;
    return unless defined $string;
    $string = $self->lc($string);
    $string =~ s/\A(\S)/$self->uc($1)/e;
    $string =~ s/([\s.!:"\/)(])(\S)/$1 . $self->uc($2)/ge;
    return $string;
}

# -------------------------------------------------------
# Locale-aware sort using Unicode::Collate::Locale.
#
# Provides 100% standard Unicode Collation Algorithm (UCA)
# compliance for any locale (tr, de, fr, ru, ar, ja...).
# Unicode::Collate::Locale is a Perl core module (since 5.12).
#
# @sorted = $lang->sort(\@list);
# @sorted = $lang->sort(\@list, $field_name_or_index);
# -------------------------------------------------------
sub sort {
    my ( $self, $liste, $blok ) = @_;
    return () unless $liste && ref($liste) eq 'ARRAY' && @$liste;

    # Helper: extract value for comparison from item (scalar, arrayref, or hashref)
    my $get_val = sub {
        my ($item) = @_;
        return '' unless defined $item;
        if ( !ref($item) ) {
            return $item;
        }
        elsif ( ref($item) eq 'ARRAY' && defined $blok && $blok ne '' ) {
            return $item->[$blok] // '';
        }
        elsif ( ref($item) eq 'HASH' && defined $blok && $blok ne '' ) {
            return $item->{$blok} // '';
        }
        return "$item";
    };

    # Primary: Unicode::Collate::Locale engine
    if ( my $collator = $self->{_collator} ) {
        if ( defined($blok) && $blok ne '' ) {
            return sort {
                $collator->cmp( $get_val->($a), $get_val->($b) );
            } @$liste;
        }
        return $collator->sort(@$liste);
    }

    # Fallback: custom sort_map Schwartzian transform
    my $sort_map = $self->{_locale}{sort_map} || {};
    my $sort_re  = $self->{_sort_re};

    my $make_key = sub {
        my $s = $self->lc( $_[0] );
        $s =~ s/([a-z])/$1$1/g;
        $s =~ s/$sort_re/$sort_map->{$1}/g if $sort_re;
        $s;
    };

    if ( defined($blok) && $blok ne '' ) {
        return map  { $_->[0] }
               sort { $a->[1] cmp $b->[1] }
               map  { [ $_, $make_key->( $get_val->($_) ) ] }
               @$liste;
    }

    return map  { $_->[0] }
           sort { $a->[1] cmp $b->[1] }
           map  { [ $_, $make_key->( $get_val->($_) ) ] }
           @$liste;
}

# -------------------------------------------------------
# Decode HTML entities (numeric + named universal + locale).
# my $str = $lang->decode_entities($string);
# -------------------------------------------------------
sub decode_entities {
    my ( $self, $string ) = @_;
    return unless defined $string;

    $string =~ s/&#x([0-9a-fA-F]+);/chr(hex($1))/ge;
    $string =~ s/&#([0-9]+);/chr($1)/ge;
    my $ent = $self->{_html_entities};
    $string =~ s{(&[a-zA-Z]+;)}{ $ent->{$1} // $1 }ge;

    return $string;
}

# -------------------------------------------------------
# Normalize accented/exotic chars to locale equivalents,
# strip HTML tags and characters not valid in locale text.
# my $str = $lang->normalize($string);
# -------------------------------------------------------
sub normalize {
    my ( $self, $string ) = @_;
    return unless defined $string;

    $string = $self->decode_entities($string);
    $string =~ s/<[^>]+>/ /g;
    $string =~ s/&[a-z0-9]+;/ /g;

    if ( my $re = $self->{_accent_re} ) {
        my $am = $self->{_locale}{accent_map};
        $string =~ s/$re/$am->{$1}/g;
    }

    my $safe_re = $self->{_safe_re};
    $string =~ s/$safe_re/ /g;
    $string =~ s/^\s+|\s+$//g;
    $string =~ s/\s+/ /g;

    return $string;
}

# Private helper: normalize script digits (Eastern Arabic ٠-٩) & decimal separators
sub normalize_num {
    my ($self, $num) = @_;
    return '' unless defined $num;
    $num =~ tr/٠١٢٣٤٥٦٧٨٩۰۱۲۳۴٥۶۷۸۹/01234567890123456789/;
    $num =~ s/\x{066B}/./g;
    return $num;
}

# -------------------------------------------------------
# Convert locale string to plain ASCII (for slugs, IDs).
# -------------------------------------------------------
sub to_ascii {
    my ( $self, $string, $nonspace ) = @_;
    return unless defined $string;

    $string = $self->utf_decode($string);

    if ($nonspace) {
        $string = $self->lc($string);
    }

    $string = $self->normalize($string);

    if ( my $re = $self->{_ascii_re} ) {
        my $am = $self->{_locale}{ascii_map};
        $string =~ s/$re/$am->{$1}/g;
    }

    require Unicode::Normalize;
    $string = Unicode::Normalize::NFD($string);
    $string =~ s/\p{M}//g;

    $string =~ s/[^a-z0-9&,.\-_ ]+/ /gi;
    $string =~ s/\s+/ /g;

    if ($nonspace) {
        $string = CORE::lc($string);
        $string =~ s/\W+/_/g;
        $string =~ s/_+/_/g;
        $string =~ s/^_|_$//g;
    }

    return $string;
}

# -------------------------------------------------------
# First character of string (for alphabetical index).
# my $char = $lang->first_char($string);
# -------------------------------------------------------
sub first_char {
    my ( $self, $string ) = @_;
    $string =~ s/\s+//g;
    return unless $string;
    $string = $self->uc($string);
    $string = $self->normalize($string);
    $string = substr( $string, 0, 1 );
    $string =~ /[0-9]/ and $string = '0-9';
    return $string;
}

# -------------------------------------------------------
# Convert number to locale words (for invoice/document printing).
#
# my $text = $lang->num2text($number);
# my $text = $lang->num2text($number, numbers => \%custom_data);
# my $text = $lang->num2text($number, currency => { main=>"EUR", sub=>"cent" });
#
# %custom_data can be a complete numbers hash or partial override.
# If locale has no numbers data, falls back to Global Base (gb).
# -------------------------------------------------------
sub num2text {
    my ( $self, $num, %opts ) = @_;

    return '' unless defined $num;

    # Resolve numbers dataset: explicit override > locale > gb fallback
    my $numbers;
    if ( $opts{numbers} ) {
        $numbers = $opts{numbers};
    }
    elsif ( $self->{_locale}{numbers} ) {
        $numbers = $self->{_locale}{numbers};
    }
    else {
        require AmberDB::Locale::Lang::gb;
        $numbers = AmberDB::Locale::Lang::gb->data()->{numbers};
    }

    # Normalize Eastern Arabic-Indic numerals and decimal separator
    $num = $self->normalize_num($num);

    my $dec_sep  = $numbers->{decimal_sep} || '.';
    my $negative_prefix = $numbers->{negative} || 'Minus';

    # Clean leading/trailing whitespace
    $num =~ s/^\s+|\s+$//g;
    return $numbers->{zero} unless length($num);

    # Check for negative sign
    my $is_negative = 0;
    if ( $num =~ s/^\s*[-–—]\s*// ) {
        $is_negative = 1;
    }

    # Clean thousand separators based on decimal_sep convention
    if ( $dec_sep eq ',' ) {
        # Format 1.234,56 -> strip dots used as thousand separators
        $num =~ s/\.(?=\d{3}(?:[^\d]|$))//g;
    }
    elsif ( $dec_sep eq '.' ) {
        # Format 1,234.56 -> strip commas used as thousand separators
        $num =~ s/,(?=\d{3}(?:[^\d]|$))//g;
    }

    # Must contain at least one digit
    unless ( $num =~ /\d/ ) {
        return $numbers->{zero};
    }

    my $ones     = $numbers->{ones}     || [];
    my $tens     = $numbers->{tens}     || [];
    my $hundred  = $numbers->{hundred}  || 'Hundred';
    my $thousand = $numbers->{thousand} || 'Thousand';
    my $million  = $numbers->{million}  || 'Million';
    my $billion  = $numbers->{billion}  || 'Billion';
    my $trillion = $numbers->{trillion} || 'Trillion';
    my $currency = $opts{currency} || $numbers->{currency} || {};
    my $thousand_one_prefix = $numbers->{thousand_one_prefix} // 1;
    my $hundred_one_prefix  = $numbers->{hundred_one_prefix}  // 1;

    # Split integer and decimal parts using locale decimal separator or [.,]
    my $dec_re = quotemeta($dec_sep);
    my ( $ytl, $ykr ) = split /(?:$dec_re|[,.])/, $num, 2;

    $ytl =~ s/\D//g if defined $ytl;

    my ( $str_main, $str_sub );

    # Decimal/subunit part processing
    if ( defined $ykr && $ykr =~ /\d/ ) {
        $ykr =~ s/\D//g;
        $ykr .= '0' if length($ykr) == 1;
        $ykr = substr( $ykr, 0, 2 ) if length($ykr) > 2;

        my $ykr_num = int($ykr);
        if ( $ykr =~ /[49]$/ ) {
            $ykr_num++;
        }

        # Overflow: 100 subunits rolls over +1 to main integer part
        if ( $ykr_num >= 100 ) {
            $ykr_num = 0;
            $ytl = ( defined $ytl && length $ytl ? $ytl : 0 ) + 1;
        }

        if ( $ykr_num > 0 ) {
            my $t = int( $ykr_num / 10 );
            my $o = $ykr_num % 10;
            my $part = '';
            $part .= $tens->[$t-1] . ' ' if $t > 0 && $tens->[$t-1];
            $part .= $ones->[$o-1]        if $o > 0 && $ones->[$o-1];
            $part =~ s/\s+$//;
            $str_sub = $part . ' ' . ( $currency->{sub} || '' ) if $part;
        }
    }

    # Integer/main part processing
    if ( defined $ytl && $ytl ne '' && $ytl > 0 ) {
        my @d = ( $ytl =~ /(.)/g );

        my $str = '';
        my $ones_d   = $d[-1]  || 0;
        my $tens_d   = $d[-2]  || 0;
        my $hund_d   = $d[-3]  || 0;
        my $th1_d    = $d[-4]  || 0;
        my $th10_d   = $d[-5]  || 0;
        my $th100_d  = $d[-6]  || 0;
        my $mil1_d   = $d[-7]  || 0;
        my $mil10_d  = $d[-8]  || 0;
        my $mil100_d = $d[-9]  || 0;
        my $bil1_d   = $d[-10] || 0;
        my $bil10_d  = $d[-11] || 0;
        my $bil100_d = $d[-12] || 0;

        # Units (1-999)
        $str = $ones->[$ones_d-1] || '' if $ones_d && $ones_d > 0;
        if ($tens_d && $tens_d > 0) {
            $str = $tens->[$tens_d-1] . ( $str ? " $str" : '' );
        }
        if ($hund_d && $hund_d > 0) {
            my $h = ( $hund_d == 1 && !$hundred_one_prefix )
                ? $hundred
                : $ones->[$hund_d-1] . " $hundred";
            $str = $h . ( $str ? " $str" : '' );
        }

        # Thousands (1,000 - 999,999)
        if ($th1_d || $th10_d || $th100_d) {
            my $th_part = '';
            if ($th1_d) {
                my $prefix = ( $th1_d == 1 && !$th10_d && !$th100_d && !$thousand_one_prefix )
                    ? '' : $ones->[$th1_d-1] . ' ';
                $th_part = $prefix;
            }
            $th_part = $tens->[$th10_d-1] . " $th_part" if $th10_d && $th10_d > 0;
            if ($th100_d && $th100_d > 0) {
                my $h = ( $th100_d == 1 && !$hundred_one_prefix )
                    ? $hundred
                    : $ones->[$th100_d-1] . " $hundred";
                $th_part = "$h $th_part";
            }
            $th_part =~ s/\s+$//;
            $str = "$th_part $thousand" . ( $str ? " $str" : '' );
        }

        # Millions (1,000,000 - 999,999,999)
        if ($mil1_d || $mil10_d || $mil100_d) {
            my $mil_part = '';
            $mil_part .= $ones->[$mil1_d-1] . ' ' if $mil1_d && $mil1_d > 0;
            $mil_part  = $tens->[$mil10_d-1] . " $mil_part" if $mil10_d && $mil10_d > 0;
            if ($mil100_d && $mil100_d > 0) {
                my $h = $mil100_d == 1 ? $hundred : $ones->[$mil100_d-1] . " $hundred";
                $mil_part = "$h $mil_part";
            }
            $mil_part =~ s/\s+$//;
            $str = "$mil_part $million" . ( $str ? " $str" : '' );
        }

        # Billions (1,000,000,000 - 999,999,999,999)
        if ($bil1_d || $bil10_d || $bil100_d) {
            my $bil_part = '';
            $bil_part .= $ones->[$bil1_d-1] . ' ' if $bil1_d && $bil1_d > 0;
            $bil_part  = $tens->[$bil10_d-1] . " $bil_part" if $bil10_d && $bil10_d > 0;
            if ($bil100_d && $bil100_d > 0) {
                my $h = $bil100_d == 1 ? $hundred : $ones->[$bil100_d-1] . " $hundred";
                $bil_part = "$h $bil_part";
            }
            $bil_part =~ s/\s+$//;
            $str = "$bil_part $billion" . ( $str ? " $str" : '' );
        }

        $str =~ s/\s+/ /g;
        $str =~ s/^\s+|\s+$//g;
        $str_main = "$str " . ( $currency->{main} || '' );
        $str_main =~ s/\s+/ /g;
        $str_main =~ s/\s+$//;
    }

    my $result = join ' ', grep { defined && length } ( $str_main, $str_sub );
    $result = $numbers->{zero} unless length($result);

    if ( $is_negative && $result ne $numbers->{zero} ) {
        $result = "$negative_prefix $result";
    }

    return $result;
}

# -------------------------------------------------------
# UTF-8 character-based substring (character count, not byte count).
# Safe against cutting UTF-8 multibyte characters in half.
#
# Signatures:
#   $lang->substring($string, $length)           # offset=0
#   $lang->substring($string, $offset, $length)  # explicit offset
# -------------------------------------------------------
sub substring {
    my $self   = shift;
    my $string = shift;
    return '' unless defined $string;

    my ( $offset, $length );
    if ( @_ == 1 ) {
        $offset = 0;
        $length = $_[0];
    }
    else {
        ( $offset, $length ) = @_;
    }

    $length //= length($string);
    return $string if $offset == 0 && length($string) <= $length;

    my $is_raw = !utf8::is_utf8($string);
    my $ustr   = $self->utf_decode($string);
    my $cut    = substr( $ustr, $offset, $length );
    return $is_raw ? $self->utf_encode($cut) : $cut;
}

# -------------------------------------------------------
# Month names list accessor for current locale (12 elements)
# my $months = $lang->months();
# -------------------------------------------------------
sub months {
    my ($self) = @_;
    return $self->{_locale}{months} || [
        "January", "February", "March",     "April",   "May",      "June",
        "July",    "August",   "September", "October", "November", "December"
    ];
}

# -------------------------------------------------------
# Day names list accessor for current locale (7 elements, Sun..Sat)
# my $days = $lang->days();
# -------------------------------------------------------
sub days {
    my ($self) = @_;
    return $self->{_locale}{days} || [
        "Sunday",   "Monday", "Tuesday", "Wednesday",
        "Thursday", "Friday", "Saturday"
    ];
}

# -------------------------------------------------------
# Format numeric value according to locale conventions.
#
# my $formatted = $lang->format_number(1234567.89);              # "1.234.567,89" (tr)
# my $formatted = $lang->format_number(1234567.89, decimals=>0); # "1.234.568"
# my $formatted = $lang->format_number(1234567.89, decimals=>3); # "1.234.567,890"
# -------------------------------------------------------
sub format_number {
    my ( $self, $num, %opts ) = @_;
    return '' unless defined $num && length($num);

    $num = $self->normalize_num($num);
    $num =~ s/^\s+|\s+$//g;
    return '0' if $num eq '';

    my $fmt        = $self->{_locale}{number_format} || {};
    my $dec_sep    = $opts{decimal_sep} // $fmt->{decimal_sep} // '.';
    my $group_sep  = $opts{group_sep}   // $fmt->{group_sep}   // ',';
    my $group_size = $fmt->{group_size} || 3;

    my $is_neg = 0;
    if ( $num =~ s/^\s*-// ) {
        $is_neg = 1;
    }

    # Normalize input separator if string contains commas/dots
    $num =~ s/,/./g unless $dec_sep eq '.';

    my $decimals = $opts{decimals};
    if ( !defined $decimals ) {
        if ( $num =~ /\.(\d+)/ ) {
            $decimals = length($1);
            $decimals = 2 if $decimals < 2;
        }
        else {
            $decimals = 0;
        }
    }

    if ( $decimals > 0 ) {
        $num = sprintf( "%.${decimals}f", $num );
    }
    else {
        $num = sprintf( "%.0f", $num );
    }

    my ( $int_part, $dec_part ) = split /\./, $num, 2;
    $int_part //= '0';

    # Insert thousand group separators
    1 while $int_part =~ s/(\d+)(\d{$group_size})/$1$group_sep$2/;

    my $res = $int_part;
    if ( defined $decimals && $decimals > 0 && defined $dec_part ) {
        $res .= $dec_sep . $dec_part;
    }

    return $is_neg ? "-$res" : $res;
}

# -------------------------------------------------------
# Format currency value according to locale conventions.
#
# my $str = $lang->format_currency(1234.50);          # "₺1.234,50" (tr default)
# my $str = $lang->format_currency(1234.50, 'EUR');   # "1.234,50 €"
# my $str = $lang->format_currency(1234.50, currency => 'USD');
# -------------------------------------------------------
sub format_currency {
    my $self   = shift;
    my $amount = shift;
    return '' unless defined $amount;

    my %opts;
    my $code;

    if ( @_ == 1 && !ref( $_[0] ) ) {
        $code = $_[0];
    }
    elsif ( @_ % 2 == 0 ) {
        %opts = @_;
        $code = $opts{currency} || $opts{code};
    }

    $code ||= $self->{_locale}{default_currency} || 'TRY';
    my $code_uc = CORE::uc($code);

    require AmberDB::Locale::Currency;
    my $universal = AmberDB::Locale::Currency->by_code($code_uc);
    my $currencies = $self->{_locale}{currencies} || {};
    my $override   = $currencies->{$code_uc} || {};

    my $symbol   = $opts{symbol}   // $override->{symbol}   // ( $universal ? $universal->{symbol} : $code_uc );
    $symbol = $self->utf_decode($symbol) if defined $symbol;
    my $digits   = $opts{decimals} // $override->{digits}   // ( $universal ? $universal->{digits} : 2 );
    my $position = $opts{position} // $override->{position} // $self->{_locale}{currency_position} // 'prefix';
    my $space    = $opts{space}    // $override->{space}    // $self->{_locale}{currency_space}    // 0;

    my $num_str = $self->format_number( $amount, decimals => $digits, %opts );

    my $gap = $space ? ' ' : '';
    if ( $position eq 'suffix' ) {
        return "${num_str}${gap}${symbol}";
    }
    else {
        return "${symbol}${gap}${num_str}";
    }
}

# -------------------------------------------------------
# Format timestamp or date string into locale date format.
#
# my $str = $lang->format_date(time());                  # "06.08.2026" (short)
# my $str = $lang->format_date(time(), 'full');          # "Perşembe, 6 Ağustos 2026"
# my $str = $lang->format_date(time(), 'YYYY-MM-DD');    # "2026-08-06"
# -------------------------------------------------------
sub format_date {
    my ( $self, $time, $pattern_or_style ) = @_;
    return '' unless defined $time && length($time);

    $pattern_or_style ||= 'short';

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday );

    if ( $time =~ /^\d+$/ ) {
        ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = localtime($time);
        $year += 1900;
        $mon  += 1;
    }
    elsif ( $time =~ /^(\d{4})[.\/-](\d{2})[.\/-](\d{2})(?:[ T](\d{2}):(\d{2}):?(\d{2})?)?/ ) {
        $year = $1;
        $mon  = int($2);
        $mday = int($3);
        $hour = defined $4 ? int($4) : 0;
        $min  = defined $5 ? int($5) : 0;
        $sec  = defined $6 ? int($6) : 0;

        require Time::Local;
        my $ep = eval { Time::Local::timelocal( $sec, $min, $hour, $mday, $mon - 1, $year ) };
        if ( defined $ep ) {
            $wday = ( localtime($ep) )[6];
        }
        else {
            $wday = 0;
        }
    }
    else {
        return $time;
    }

    my $formats = $self->{_locale}{date_format} || {};
    my $pattern = $formats->{$pattern_or_style} || $pattern_or_style;

    my $months = $self->months();
    my $days   = $self->days();

    my $month_name = $months->[ $mon - 1 ] || '';
    my $day_name   = $days->[$wday]         || '';
    my $short_mon  = substr( $month_name, 0, 3 );
    my $short_day  = substr( $day_name, 0, 3 );

    my %tokens = (
        'YYYY' => sprintf( '%04d', $year ),
        'YY'   => sprintf( '%02d', $year % 100 ),
        'MMMM' => $month_name,
        'MMM'  => $short_mon,
        'MM'   => sprintf( '%02d', $mon ),
        'M'    => $mon,
        'DD'   => sprintf( '%02d', $mday ),
        'D'    => $mday,
        'dddd' => $day_name,
        'ddd'  => $short_day,
        'HH'   => sprintf( '%02d', $hour ),
        'H'    => $hour,
        'mm'   => sprintf( '%02d', $min ),
        'm'    => $min,
        'ss'   => sprintf( '%02d', $sec ),
        's'    => $sec,
    );

    my $re = join '|', map { quotemeta $_ } sort { length($b) <=> length($a) } keys %tokens;
    $pattern =~ s/($re)/$tokens{$1}/g;

    return $pattern;
}

# -------------------------------------------------------
# Parse locale formatted date string back into unix timestamp / date components.
#
# my $epoch = $lang->parse_date("06.08.2026");            # timestamp
# my $hash  = $lang->parse_date("06.08.2026", hash => 1); # { year=>2026, month=>8, day=>6 }
# -------------------------------------------------------
sub parse_date {
    my ( $self, $str, %opts ) = @_;
    return unless defined $str && length($str);

    $str =~ s/^\s+|\s+$//g;

    my ( $day, $month, $year, $hour, $min, $sec ) = ( 0, 0, 0, 0, 0, 0 );

    if ( $str =~ /^(\d{1,2})[.\/-](\d{1,2})[.\/-](\d{4})(?:\s+(\d{1,2}):(\d{1,2}):?(\d{1,2})?)?/ ) {
        my ( $p1, $p2, $p3 ) = ( int($1), int($2), int($3) );
        $hour = int( $4 // 0 );
        $min  = int( $5 // 0 );
        $sec  = int( $6 // 0 );

        my $fmt = $self->{_locale}{date_format}{short} || 'DD.MM.YYYY';
        if ( $fmt =~ /^MM/i ) {
            $month = $p1;
            $day   = $p2;
            $year  = $p3;
        }
        else {
            $day   = $p1;
            $month = $p2;
            $year  = $p3;
        }
    }
    elsif ( $str =~ /^(\d{4})[.\/-](\d{1,2})[.\/-](\d{1,2})(?:\s+(\d{1,2}):(\d{1,2}):?(\d{1,2})?)?/ ) {
        $year  = int($1);
        $month = int($2);
        $day   = int($3);
        $hour  = int( $4 // 0 );
        $min   = int( $5 // 0 );
        $sec   = int( $6 // 0 );
    }

    return unless $year && $month && $day;

    if ( $opts{hash} ) {
        return {
            year   => $year,
            month  => $month,
            day    => $day,
            hour   => $hour,
            minute => $min,
            second => $sec,
        };
    }

    require Time::Local;
    return eval { Time::Local::timelocal( $sec, $min, $hour, $day, $month - 1, $year ) };
}

# Private helper: securely evaluate sanitized CLDR plural expressions
sub _eval_plural_rule {
    my ( $self, $cond, $count ) = @_;
    return 0 unless defined $cond && length $cond;

    my $n = abs( $count // 0 );

    # Whitelist strictly only digits, 'n', whitespace, arithmetic and logical operators
    return 0 unless $cond =~ /^[n0-9+\-*\/%&|!=<>()\s]+$/;

    # Replace 'n' variable token with actual numeric value
    ( my $expr = $cond ) =~ s/\bn\b/$n/g;

    # Safely evaluate numeric expression isolated from global DIE handlers
    my $res = eval {
        local $SIG{__DIE__} = sub {};
        eval $expr; ## no critic
    };
    return $res ? 1 : 0;
}

# -------------------------------------------------------
# Evaluate CLDR plural rule and select template.
#
# my $text = $lang->plural(1, { one => "{count} ürün", other => "{count} ürün" });
# my $text = $lang->plural(5, { one => "{count} item", other => "{count} items" });
# -------------------------------------------------------
sub plural {
    my ( $self, $count, $forms ) = @_;
    return '' unless defined $forms;

    $count //= 0;
    my $form_key = 'other';

    my $rule = $self->{_locale}{plural_rule} || 'one{n==1}other';

    for my $key (qw(zero one two few many)) {
        if ( $rule =~ /\b$key\{([^{}]+)\}/ ) {
            my $cond = $1;
            if ( $self->_eval_plural_rule( $cond, $count ) ) {
                $form_key = $key;
                last;
            }
        }
    }

    my $template;
    if ( ref($forms) eq 'HASH' ) {
        $template = $forms->{$form_key} // $forms->{other} // $forms->{one} // '';
    }
    else {
        $template = "$forms";
    }

    my $fmt_count = $self->format_number($count, decimals => 0);
    $template =~ s/\{count\}|\{n\}/$fmt_count/g;

    return $template;
}

# -------------------------------------------------------
# Language tag accessor
# my $tag = $lang->language;   # "tr", "en", "de" ...
# -------------------------------------------------------
sub language { return $_[0]->{_lang} }

1;

__END__

=encoding utf8

=head1 NAME

AmberDB::Locale - Multilingual text processing, collation, number/currency formatting, and search normalization engine

=head1 SYNOPSIS

  # =========================================================================
  # 1. DIRECT USAGE VIA AMBERDB INSTANCE ($adb inherits AmberDB::Locale):
  # Reads active language from config (default is 'gb' or configured language)
  # =========================================================================
  my $adb = AmberDB->new(cfg => { language => "gb" });

  # Case Conversions & Comparison
  my $upper  = $adb->uc("ığdır");                         # "IĞDIR"
  my $lower  = $adb->lc("İSTANBUL");                      # "istanbul"
  my $title  = $adb->ucfirst("istanbul büyükşehir");      # "İstanbul Büyükşehir"
  my $folded = $adb->fold("İSTANBUL");                    # "istanbul"
  my $same   = $adb->ieq("İstanbul", "istanbul");         # 1

  # Unicode Collation Algorithm (UCA) Sorting
  my @sorted = $adb->sort(["İzmir", "Ankara", "Van", "Şanlıurfa", "Bursa", "Çanakkale"]);
  # => ("Ankara", "Bursa", "Çanakkale", "İzmir", "Şanlıurfa", "Van")

  # Text Normalization & Transliteration (Turkish rules: ü -> u, ç -> c)
  my $clean = $adb->normalize("<p>Kâr &amp; zarar &ccedil;izelgesi</p>"); # "Kar zarar cizelgesi"
  my $ascii = $adb->to_ascii("müller");                   # "muller"   (Turkish: ü -> u)
  my $slug  = $adb->to_ascii("İstanbul Kâr & Zarar!", 1); # "istanbul_kar_zarar"

  # UTF-8 Safe Substring (character-based, safe for multibyte chars)
  my $sub = $adb->substring("Çanakkale", 0, 4);           # "Çana"

  # Number to Written Text (Invoices / Cheques)
  my $text = $adb->num2text(1234.56);
  # => "Bin İki Yüz Otuz Dört TL Elli Altı KR" (Note: "Bin", not "Bir Bin")

  # Number & Currency Formatting
  my $num  = $adb->format_number(1234567.89);            # "1.234.567,89"
  my $curr = $adb->format_currency(1234.50, "EUR");       # "1.234,50 €"

  # Date Formatting & Parsing
  my $date = $adb->format_date(time(), "full");          # "Cuma, 28 Ağustos 2026"
  my $ep   = $adb->parse_date("28.08.2026");             # Unix timestamp

  # Pluralization (CLDR)
  my $msg  = $adb->plural(5, { one => "{count} ürün", other => "{count} ürün" });

  # Search Token Normalization
  my $norm = $adb->normalize_word("Türkiye'de", 1);      # "turkiye turkiyede"

  # =========================================================================
  # 2. CROSS-LANGUAGE COMPARISON & STANDALONE USAGE:
  # =========================================================================
  use AmberDB::Locale;

  my $tr = AmberDB::Locale->new(language => "tr");
  my $de = AmberDB::Locale->new(language => "de");
  my $en = AmberDB::Locale->new(language => "en");
  my $fr = AmberDB::Locale->new(language => "fr");
  my $ru = AmberDB::Locale->new(language => "ru");

  # --- A. ASCII Transliteration Differences (to_ascii) ---
  $tr->to_ascii("müller");          # "muller"    (Turkish rule: ü -> u)
  $de->to_ascii("müller");          # "mueller"   (German DIN 5007 rule: ü -> ue)
  $de->to_ascii("Große Straße");    # "Grosse Strasse" (ß -> ss)
  $tr->to_ascii("çarşı");           # "carsi"     (ç -> c, ş -> s, ı -> i)
  $fr->to_ascii("façade Noël");     # "facade Noel"

  # --- B. Case Conversion Differences (uc / lc) ---
  $tr->uc("istanbul");              # "İSTANBUL"  (Turkish dotted i -> İ)
  $en->uc("istanbul");              # "ISTANBUL"  (Standard English i -> I)
  $tr->lc("IĞDIR");                 # "ığdır"     (Turkish dotless I -> ı)
  $en->lc("IĞDIR");                 # "iğdır"     (Standard English I -> i)
  $de->uc("weiß");                  # "WEISS"     (German ß -> SS)

  # --- C. Number Formatting Differences (format_number) ---
  $tr->format_number(1234567.89);   # "1.234.567,89" (Group: dot, Dec: comma)
  $de->format_number(1234567.89);   # "1.234.567,89" (Group: dot, Dec: comma)
  $en->format_number(1234567.89);   # "1,234,567.89" (Group: comma, Dec: dot)
  $fr->format_number(1234567.89);   # "1 234 567,89" (Group: space, Dec: comma)

  # --- D. Written Number Differences (num2text) ---
  $tr->num2text(1000);              # "Bin TL"           (Turkish: "Bin", no "Bir" prefix)
  $en->num2text(1000);              # "One Thousand USD" (English: requires "One" prefix)
  $de->num2text(1000);              # "Eins Tausend EUR" (German: requires "Eins" prefix)

  # --- E. Pluralization Differences (plural) ---
  # English: 2 forms (one, other)
  $en->plural(1, { one => "{count} item", other => "{count} items" }); # "1 item"
  $en->plural(5, { one => "{count} item", other => "{count} items" }); # "5 items"

  # Russian: 4 forms (one, few, many, other)
  my %ru_apple = (
      one   => "{count} яблоко",
      few   => "{count} яблока",
      many  => "{count} яблок",
      other => "{count} яблока"
  );
  $ru->plural(1,  \%ru_apple);      # "1 яблоко"  (ends in 1, except 11)
  $ru->plural(3,  \%ru_apple);      # "3 яблока"  (ends in 2-4, except 12-14)
  $ru->plural(5,  \%ru_apple);      # "5 яблок"   (ends in 5-9, 0, or 11-14)
  $ru->plural(21, \%ru_apple);      # "21 яблоко"

=head1 DESCRIPTION

C<AmberDB::Locale> is a comprehensive, high-performance, locale-aware text processing engine designed for multilingual Perl applications. It provides a unified API for:

=over 4

=item * Locale-aware case conversion (e.g., Turkish C<I/ı>, C<İ/i>, German C<ß -E<gt> SS>).

=item * 100% standard Unicode Collation Algorithm (UCA) sorting via C<Unicode::Collate::Locale>.

=item * ASCII transliteration and URL slug generation with language-specific rules (e.g. German DIN 5007-2 C<ü -E<gt> ue> vs. Turkish C<ü -E<gt> u>).

=item * Written number and cheque printing conversion supporting integer, decimal, negative numbers, and Eastern Arabic/Persian numerals.

=item * Precision number and ISO 4217 currency formatting with customizable decimal and group separators.

=item * Bidirectional date/time formatting with full pattern tokens (C<YYYY>, C<MMMM>, C<dddd>, C<HH:mm:ss>) and parsing.

=item * Unicode NFKC case-folding and phonetic search token normalization for high-performance inverted indexes.

=item * CLDR-standard plural form evaluation across Western, Slavic, and Eastern languages.

=item * UTF-8 character-safe substring extraction preventing multi-byte corruption.

=back

Language-specific datasets and rule tables are decoupled into modular packages (e.g. C<AmberDB::Locale::Lang::gb>, C<AmberDB::Locale::Lang::tr>, C<AmberDB::Locale::Lang::de>, C<AmberDB::Locale::Lang::en>, C<AmberDB::Locale::Lang::ru>, C<AmberDB::Locale::Lang::fr>, C<AmberDB::Locale::Lang::es>, C<AmberDB::Locale::Lang::az>, C<AmberDB::Locale::Lang::ar>, C<AmberDB::Locale::Lang::ja>).

B<Inheritance Note:> C<AmberDB> inherits from C<AmberDB::Locale> via C<use parent>. When an C<AmberDB> instance is constructed, it automatically initializes its locale subsystem from C<$adb-E<gt>config('language')>. All methods documented below can be called directly on C<$adb> (e.g. C<$adb-E<gt>format_currency(...)>).

=head1 CONSTRUCTOR

=head2 new([%options | $hashref | $language_code])

Creates and returns an C<AmberDB::Locale> instance configured for the specified language. Instances are cached internally for high-throughput reuse.

  # 1. Named-parameter API (recommended)
  my $lang = AmberDB::Locale->new(language => 'tr');

  # 2. Hashref API
  my $lang = AmberDB::Locale->new({ language => 'de' });

  # 3. Positional string API
  my $lang = AmberDB::Locale->new('fr');

  # 4. Default (falls back to Global Base 'gb')
  my $lang = AmberDB::Locale->new();

Supported language codes include C<"gb"> (Global Base - default), C<"tr">, C<"en">, C<"de">, C<"fr">, C<"es">, C<"ru">, C<"az">, C<"ar">, C<"ja"> and common aliases (such as C<"global">, C<"turkish">, C<"tr_tr">, C<"english">, C<"german">, etc.).
If an unsupported language is specified, a warning is issued and the instance falls back to C<"gb">.

=head1 METHODS

=head2 Case Conversions & Comparison

=head3 uc($string)

Converts C<$string> to uppercase according to locale-specific casing rules.

  # Turkish dotted/dotless I handling:
  $tr->uc("ığdır");     # "IĞDIR"
  $tr->uc("istanbul");  # "İSTANBUL" (Turkish i -> İ)

  # English standard casing:
  $en->uc("istanbul");  # "ISTANBUL" (English i -> I)

  # German sharp S:
  $de->uc("straße");    # "STRASSE"  (German ß -> SS)

=head3 lc($string)

Converts C<$string> to lowercase according to locale-specific casing rules.

  # Turkish dotted/dotless I handling:
  $tr->lc("İSTANBUL");  # "istanbul" (Turkish İ -> i)
  $tr->lc("IĞDIR");     # "ığdır"    (Turkish I -> ı)

  # English standard casing:
  $en->lc("IĞDIR");     # "iğdır"    (English I -> i)

=head3 ucfirst($string)

Capitalizes the first letter of each word in C<$string> under locale rules. The string is first lowercased, and then the first character following word-starting delimiters (spaces, punctuation, brackets) is uppercased according to locale rules.

  $tr->ucfirst("istanbul büyükşehir belediyesi");
  # => "İstanbul Büyükşehir Belediyesi"

  $tr->ucfirst("ahmet (ısparta) - izmir");
  # => "Ahmet (Isparta) - İzmir"

=head3 fold($string)

Applies Unicode NFKC normalization and locale lowercasing to produce a case-folded string suitable for search indexing and matching.

  my $key = $tr->fold("İSTANBUL"); # "istanbul"

=head3 ieq($str1, $str2)

Performs a locale-aware, case-insensitive comparison between C<$str1> and C<$str2>. Returns C<1> if they are equal under locale rules, C<0> otherwise.

  $tr->ieq("İstanbul", "istanbul"); # 1 (true)
  $tr->ieq("IĞDIR", "ığdır");       # 1 (true)
  $tr->ieq("Ankara", "İzmir");      # 0 (false)

=head2 Sorting

=head3 sort(\@list [, $field_or_index])

Sorts an array reference C<\@list> using the Unicode Collation Algorithm (UCA) tailored for the active locale.

  # 1. Simple array of strings (respects Turkish alphabetical ordering: Ç, Ğ, İ, Ö, Ş, Ü)
  my @sorted = $tr->sort(["İzmir", "Ankara", "Van", "Şanlıurfa", "Bursa", "Çanakkale"]);
  # => ("Ankara", "Bursa", "Çanakkale", "İzmir", "Şanlıurfa", "Van")

  # 2. Array of hash references (sort by hash key)
  my @products = (
      { id => 1, title => "Şemsiye" },
      { id => 2, title => "Ayna" },
      { id => 3, title => "Çanta" }
  );
  my @sorted_products = $tr->sort(\@products, "title");
  # => ({ id => 2, title => "Ayna" }, { id => 3, title => "Çanta" }, { id => 1, title => "Şemsiye" })

  # 3. Array of array references (sort by element column index)
  my @rows = (
      [ 101, "Van" ],
      [ 102, "Adana" ],
      [ 103, "Çorum" ]
  );
  my @sorted_rows = $tr->sort(\@rows, 1);
  # => ([102, "Adana"], [103, "Çorum"], [101, "Van"])

=head2 Text Normalization & Transliteration

=head3 normalize($string)

Cleans and normalizes C<$string> by decoding HTML entities, stripping HTML tags, mapping locale-specific accents (such as circumflex vowels C<â, î, û>), filtering characters outside the locale's safe character set, and collapsing whitespace.

  my $clean = $tr->normalize('<p>Kâr &amp; zarar &ccedil;izelgesi</p>');
  # => "Kar zarar cizelgesi"

=head3 to_ascii($string [, $nonspace])

Transliterates localized text into plain ASCII characters according to per-language phonetic and transliteration conventions.

=over 4

=item * B<Turkish (C<trE<gt>>):> C<ç -E<gt> c>, C<ğ -E<gt> g>, C<ı/İ -E<gt> i>, C<ö -E<gt> o>, C<ş -E<gt> s>, C<ü -E<gt> u>

  $tr->to_ascii("müller");          # "muller"
  $tr->to_ascii("çarşı");           # "carsi"

=item * B<German (C<deE<gt>>, DIN 5007-2):> C<ä -E<gt> ae>, C<ö -E<gt> oe>, C<ü -E<gt> ue>, C<ß -E<gt> ss>

  $de->to_ascii("müller");          # "mueller"
  $de->to_ascii("Große Straße");    # "Grosse Strasse"

=item * B<French (C<frE<gt>>):>

  $fr->to_ascii("façade Noël");     # "facade Noel"

=item * B<Spanish (C<esE<gt>>):>

  $es->to_ascii("año niño");        # "ano nino"

=back

If C<$nonspace = 1> (slug mode), the string is lowercased and spaces/punctuation are converted to single underscores:

  $tr->to_ascii("İstanbul", 1);               # "istanbul"
  $tr->to_ascii("Kâr & Zarar Tablosu!", 1);   # "kar_zarar_tablosu"

=head3 first_char($string)

Returns the normalized, uppercase first character of C<$string> for alphabetical indexing (e.g. A-Z catalog directories). Returns C<"0-9"> if the string begins with a digit.

  $tr->first_char("  çarşı  ");    # "Ç"
  $tr->first_char("123abc");       # "0-9"
  $tr->first_char("İzmir");        # "İ"

=head2 UTF-8 Encoding & Slicing

=head3 utf_encode($string) / utf_decode($string)

Converts a Perl Unicode character string into raw UTF-8 octet bytes (C<utf_encode>) or decodes raw UTF-8 bytes into Perl Unicode characters (C<utf_decode>). Safe against double-encoding.

  my $bytes = $lang->utf_encode($unicode_str);
  my $chars = $lang->utf_decode($raw_bytes);

=head3 substring($string, [$offset], $length)

Extracts a substring from C<$string> based on character count rather than byte count. Prevents cutting multibyte UTF-8 characters in half. Works transparently on both decoded Unicode strings and raw UTF-8 byte strings.

  $tr->substring("Çanakkale", 0, 4); # "Çana" (4 characters, 5 bytes)
  $tr->substring("İstanbul", 2, 3);  # "tan"

  # Default offset is 0 if omitted:
  $tr->substring("Şanlıurfa", 5);     # "Şanlı"

=head2 Search Engine Tokenization & Regex

=head3 search_pattern($query)

Converts a search query string into a locale-aware regex pattern. Replaces locale-specific casing characters with regex character classes.

  my $pat = $tr->search_pattern("sırdaş");
  # => pattern matching both "sırdaş", "SIRDAŞ", "Sırdaş" under Turkish rules

=head3 search_regex($string, $pattern)

Performs a case-insensitive, locale-aware regex match of C<$pattern> inside C<$string>. Returns C<1> on match, C<0> otherwise.

  my $found = $tr->search_regex("İstanbul Boğazı", "istanbul"); # 1

=head3 normalize_word($word, [$mode_write])

Normalizes a single search token according to locale phonetic assimilation, clitic/apostrophe stripping, and final-devoicing rules.

=over 4

=item * B<Write Mode (C<$mode_write = 1>):> Generates both the root token and joined compound token to index clitic variants (e.g. C<"Türkiye'de"> -E<gt> C<"turkiye turkiyede">).

=item * B<Read Mode (C<$mode_write = 0> or omitted):> Strips clitics and suffixes to resolve the base root (e.g. C<"Türkiye'de"> -E<gt> C<"turkiye">; single-letter prefixes like C<"T-Shirt"> resolve to C<"tshirt">).

=back

  my $write_tokens = $tr->normalize_word("Türkiye'de", 1); # "turkiye turkiyede"
  my $query_token  = $tr->normalize_word("Türkiye'de", 0); # "turkiye"

=head2 Number & Currency Processing

=head3 num2text($number [, %options])

Converts numeric values (integers or floating-point decimals) into written words in the target locale. Ideal for generating formal banking receipts, invoices, and cheques.

  # Turkish rules: "1000" is "Bin TL" (NOT "Bir Bin TL")
  $tr->num2text(0);       # "Sıfır"
  $tr->num2text(1);       # "Bir TL"
  $tr->num2text(100);     # "Yüz TL"
  $tr->num2text(1000);    # "Bin TL"
  $tr->num2text(1234.56); # "Bin İki Yüz Otuz Dört TL Elli Altı KR"
  $tr->num2text(-42);     # "Eksi Kırk İki TL"

  # English rules: requires "One Thousand"
  $en->num2text(1000);    # "One Thousand USD"
  $en->num2text(1234.56); # "One Thousand Two Hundred Thirty Four USD Fifty Six cent"

  # German rules:
  $de->num2text(1000);    # "Eins Tausend EUR"

Accepts Eastern Arabic (C<٠١٢٣٤٥٦٧٨٩>) and Persian (C<۰۱۲۳۴۵۶۷۸۹>) digits automatically.

Options:

=over 4

=item * C<currency =E<gt> { main =E<gt> "EUR", sub =E<gt> "cent" }>: Custom currency labels.

  $tr->num2text(99.99, currency => { main => "EUR", sub => "cent" });
  # => "Doksan Dokuz EUR Doksan Dokuz cent"

=item * C<numbers =E<gt> \%custom_hash>: Overrides number word definitions with custom dictionaries.

=back

=head3 format_number($number [, %options])

Formats C<$number> with locale-specific decimal and thousand grouping separators.

  # Turkish conventions (group: dot, decimal: comma)
  $tr->format_number(1234567.89);                # "1.234.567,89"
  $tr->format_number(1234567.89, decimals => 0); # "1.234.568"
  $tr->format_number(1234567.89, decimals => 3); # "1.234.567,890"

  # German conventions (group: dot, decimal: comma)
  $de->format_number(1234567.89);                # "1.234.567,89"

  # English conventions (group: comma, decimal: dot)
  my $en = AmberDB::Locale->new(language => "en");
  $en->format_number(1234567.89);                # "1,234,567.89"

  # French conventions (group: space, decimal: comma)
  my $fr = AmberDB::Locale->new(language => "fr");
  $fr->format_number(1234567.89);                # "1 234 567,89"

Available options: C<decimals>, C<decimal_sep>, C<group_sep>.

=head3 format_currency($amount [, $currency_code | %options])

Formats monetary amounts using locale conventions or specific ISO 4217 currency settings.

  # Default Turkish currency (TRY)
  $tr->format_currency(1234.50);                    # "₺1.234,50"

  # Explicit ISO code
  $tr->format_currency(1234.50, 'EUR');             # "1.234,50 €"
  $tr->format_currency(1234.50, currency => 'USD'); # "$1.234,50"

Custom formatting overrides:

  $tr->format_currency(100, symbol => 'TL', position => 'suffix', space => 1);
  # => "100,00 TL"

=head3 ISO 4217 Currency Dictionary

C<AmberDB::Locale> integrates a master dictionary of ISO 4217 currency definitions, numeric codes, currency symbols, and default subunit decimal precision (implemented internally via C<AmberDB::Locale::Currency>).

Direct dictionary lookups, symbol conversions, and select dropdown lists can be accessed via:

  use AmberDB::Locale::Currency;

  # Symbol and name lookups
  my $sym  = AmberDB::Locale::Currency->symbol('TRY'); # '₺'
  my $name = AmberDB::Locale::Currency->name('USD');   # 'US Dollar'
  my $info = AmberDB::Locale::Currency->by_code('EUR');
  # => { num => '978', name => 'Euro', symbol => '€', digits => 2 }

  # Dropdown options for UI forms
  my @options = AmberDB::Locale::Currency->all();
  # => ( [ 'TRY', 'Turkish Lira' ], [ 'USD', 'US Dollar' ], ... )

  # List active ISO codes
  my @codes = AmberDB::Locale::Currency->active_codes();
  # => ('TRY', 'USD', 'EUR', 'GBP', 'RUB', 'AZN', 'SAR', 'JPY', 'CHF', 'CAD', 'AUD', 'CNY')

Supported helper methods:

=over 4

=item * C<AmberDB::Locale::Currency-E<gt>by_code($iso_code)> - Returns the currency definition hash reference for the given 3-letter ISO 4217 code (case-insensitive), containing C<num>, C<name>, C<symbol>, and C<digits>.

=item * C<AmberDB::Locale::Currency-E<gt>symbol($iso_code)> - Returns the currency symbol for the given ISO code (e.g. C<'₺'>, C<'$'>, C<'€'>, C<'£'>, C<'₽'>, C<'¥'>). If the code is unknown, returns the uppercase code itself.

=item * C<AmberDB::Locale::Currency-E<gt>name($iso_code)> - Returns the English currency name for the given ISO code.

=item * C<AmberDB::Locale::Currency-E<gt>all()> - Returns a list of 2-element array references C<[ $code, $name ]> ordered by priority, suitable for rendering HTML C<E<lt>selectE<gt>> form dropdowns.

=item * C<AmberDB::Locale::Currency-E<gt>active_codes()> - Returns the list of active 3-letter ISO 4217 currency codes supported by the dictionary.

=back

=head2 Date & Time Operations

=head3 format_date($time_or_string [, $pattern_or_style])

Formats a Unix epoch timestamp or ISO date string into a localized date/time representation.

  my $epoch = 1787832600; # 2026-08-28 14:30:00

  # Standard styles:
  $tr->format_date($epoch);             # "28.08.2026" (short, default)
  $tr->format_date($epoch, 'medium');   # "28 Ağu 2026"
  $tr->format_date($epoch, 'long');     # "28 Ağustos 2026"
  $tr->format_date($epoch, 'full');     # "Cuma, 28 Ağustos 2026"
  $tr->format_date($epoch, 'time');     # "14:30"
  $tr->format_date($epoch, 'datetime'); # "28.08.2026 14:30"

  # Custom format pattern tokens:
  $tr->format_date($epoch, 'YYYY-MM-DD'); # "2026-08-28"
  $tr->format_date($epoch, 'DD/MM/YYYY'); # "28/08/2026"

  # Input can also be ISO date strings:
  $tr->format_date("2026-08-28", 'full'); # "Cuma, 28 Ağustos 2026"

Supported pattern tokens:

=over 4

=item * C<YYYY>, C<YY> - 4-digit / 2-digit year

=item * C<MMMM>, C<MMM>, C<MM>, C<M> - Full month name, short month, 2-digit month, 1-digit month

=item * C<DD>, C<D> - 2-digit day, 1-digit day

=item * C<dddd>, C<ddd> - Full day name, short day name

=item * C<HH>, C<H> - Hour (2-digit / 1-digit)

=item * C<mm>, C<m> - Minute (2-digit / 1-digit)

=item * C<ss>, C<s> - Second (2-digit / 1-digit)

=back

=head3 parse_date($string [, %options])

Parses a localized date string (e.g. C<"28.08.2026"> or C<"2026-08-28 14:30:00">) back into a Unix epoch timestamp or component hash.

  my $epoch = $tr->parse_date("28.08.2026"); # Unix timestamp

  my $hash = $tr->parse_date("28.08.2026", hash => 1);
  # => { year => 2026, month => 8, day => 28, hour => 0, minute => 0, second => 0 }

=head2 HTML Entity Decoding

=head3 decode_entities($string)

Decodes numeric (hex C<&#x...;>, decimal C<&#...;>) and named HTML entities in C<$string>, incorporating both universal entities and locale-specific extra entities.

  $tr->decode_entities("&amp; &lt; &gt; &#x20AC; &ccedil;");
  # => "& < > € ç"

=head2 Pluralization

=head3 plural($count, \%forms)

Selects and interpolates the appropriate plural form from C<\%forms> based on CLDR plural rules for the active locale.

  # English (2 forms: one, other)
  my $en = AmberDB::Locale->new(language => "en");
  $en->plural(1, { one => "{count} item", other => "{count} items" }); # "1 item"
  $en->plural(5, { one => "{count} item", other => "{count} items" }); # "5 items"

  # Russian (4 forms: one, few, many, other)
  my $ru = AmberDB::Locale->new(language => "ru");
  my %ru_apple = (
      one   => "{count} яблоко",
      few   => "{count} яблока",
      many  => "{count} яблок",
      other => "{count} яблока"
  );
  $ru->plural(1,  \%ru_apple); # "1 яблоко"   (ends in 1, except 11)
  $ru->plural(3,  \%ru_apple); # "3 яблока"   (ends in 2-4, except 12-14)
  $ru->plural(5,  \%ru_apple); # "5 яблок"    (ends in 5-9, 0, or 11-14)
  $ru->plural(21, \%ru_apple); # "21 яблоко"  (ends in 1, except 11)

  # Turkish (regular count)
  my $tr = AmberDB::Locale->new(language => "tr");
  $tr->plural(5, { one => "{count} ürün", other => "{count} ürün" }); # "5 ürün"

Placeholders C<{count}> or C<{n}> in template strings are automatically replaced with formatted number values.

=head2 Accessors

=head3 language()

Returns the active language tag (e.g., C<"tr">, C<"en">, C<"de">).

=head3 months()

Returns an array reference containing the 12 localized month names.

=head3 days()

Returns an array reference containing the 7 localized day names starting from Sunday.

=head1 AUTHOR

Maruf Cetin <marufcetin@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017-2026 Maruf Cetin.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.

=cut


