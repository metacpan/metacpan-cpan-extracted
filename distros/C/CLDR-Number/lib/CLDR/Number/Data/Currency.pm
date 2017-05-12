package CLDR::Number::Data::Currency;

use v5.8.1;
use utf8;
use strict;
use warnings;
use charnames qw( :full );

# This module does not have a publicly supported interface and may change in
# backward incompatible ways in the future. Please use one of the documented
# classes instead.

our $VERSION      = '0.19';
our $CLDR_VERSION = '29';

# Numbers: Currencies
our $LOCALES = {
    root => {
        AUD => 'A$',
        BRL => 'R$',
        CAD => 'CA$',
        CNY => 'CN¥',
        EUR => '€',
        GBP => '£',
        HKD => 'HK$',
        ILS => '₪',
        INR => '₹',
        JPY => 'JP¥',
        KRW => '₩',
        MXN => 'MX$',
        NZD => 'NZ$',
        TWD => 'NT$',
        USD => 'US$',
        VND => '₫',
        XAF => 'FCFA',
        XCD => 'EC$',
        XOF => 'CFA',
        XPF => 'CFPF',
    },
    af => {
        MXN => 'MXN',
        THB => '฿',
        ZAR => 'R',
    },
    'af-NA' => {
        NAD => '$',
    },
    ak => {
        GHS => 'GH₵',
    },
    am => {
        AUD => 'AU$',
        ETB => 'ብር',
        THB => '฿',
    },
    ar => {
        AED => "د.إ.\N{RIGHT-TO-LEFT MARK}",
        AUD => 'AU$',
        BHD => "د.ب.\N{RIGHT-TO-LEFT MARK}",
        DZD => "د.ج.\N{RIGHT-TO-LEFT MARK}",
        EGP => "ج.م.\N{RIGHT-TO-LEFT MARK}",
        IDR => 'ر.إن.',
        IQD => "د.ع.\N{RIGHT-TO-LEFT MARK}",
        IRR => 'ر.إ.',
        JOD => "د.أ.\N{RIGHT-TO-LEFT MARK}",
        KMF => "ف.ج.ق.\N{RIGHT-TO-LEFT MARK}",
        KWD => "د.ك.\N{RIGHT-TO-LEFT MARK}",
        LBP => "ل.ل.\N{RIGHT-TO-LEFT MARK}",
        LYD => "د.ل.\N{RIGHT-TO-LEFT MARK}",
        MAD => "د.م.\N{RIGHT-TO-LEFT MARK}",
        MRO => "أ.م.\N{RIGHT-TO-LEFT MARK}",
        OMR => "ر.ع.\N{RIGHT-TO-LEFT MARK}",
        PKR => 'ر.ب.',
        QAR => "ر.ق.\N{RIGHT-TO-LEFT MARK}",
        SAR => "ر.س.\N{RIGHT-TO-LEFT MARK}",
        SDD => "د.س.\N{RIGHT-TO-LEFT MARK}",
        SDG => 'ج.س.',
        SSP => 'ج.ج.س.',
        SYP => "ل.س.\N{RIGHT-TO-LEFT MARK}",
        THB => '฿',
        TND => "د.ت.\N{RIGHT-TO-LEFT MARK}",
        TRY => 'ل.ت.',
        XXX => '***',
        YER => "ر.ي.\N{RIGHT-TO-LEFT MARK}",
    },
    'ar-DJ' => {
        DJF => 'Fdj',
    },
    'ar-ER' => {
        ERN => 'Nfk',
    },
    'ar-LB' => {
        SDG => 'SDG',
    },
    'ar-SO' => {
        SOS => 'S',
    },
    'ar-SS' => {
        GBP => 'GB£',
        SSP => '£',
    },
    asa => {
        TZS => 'TSh',
    },
    ast => {
        JPY => '¥',
        THB => '฿',
        USD => '$',
    },
    az => {
        AZN => '₼',
        THB => '฿',
    },
    'az-Cyrl' => {
        AZN => '₼',
    },
    be => {
        BRL => 'BRL',
        BYR => 'р.',
        CAD => 'CAD',
        JPY => '¥',
        NZD => 'NZD',
        RUB => '₽',
        USD => '$',
    },
    bem => {
        ZMW => 'K',
    },
    bez => {
        TZS => 'TSh',
    },
    bg => {
        AUD => 'AUD',
        BGN => 'лв.',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        TWD => 'TWD',
        USD => 'щ.д.',
        VND => 'VND',
        XCD => 'XCD',
    },
    bn => {
        BDT => '৳',
        THB => '฿',
    },
    bo => {
        CNY => '¥',
    },
    'bo-IN' => {
        CNY => 'CN¥',
    },
    br => {
        AUD => '$A',
        BRL => 'BRL',
        CAD => '$CA',
        CNY => 'CNY',
        GBP => '£ RU',
        HKD => '$ HK',
        ILS => 'ILS',
        JPY => 'JPY',
        KRW => 'KRW',
        NZD => '$ ZN',
        TWD => 'TWD',
        USD => '$ SU',
        VND => 'VND',
        XCD => 'XCD',
    },
    bs => {
        AUD => 'AUD',
        BAM => 'KM',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        GBP => 'GBP',
        HKD => 'HKD',
        HRK => 'kn',
        ILS => 'ILS',
        JPY => '¥',
        MXN => 'MXN',
        NZD => 'NZD',
        RSD => 'din.',
        THB => '฿',
        USD => 'USD',
        XCD => 'XCD',
        XPF => 'XPF',
    },
    'bs-Cyrl' => {
        BAM => 'КМ',
        CZK => 'Кч',
        JPY => '¥',
        PLN => 'зл',
        RSD => 'дин.',
        TRY => 'Тл',
    },
    ca => {
        AUD => 'AU$',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => '¥',
        ESP => '₧',
        MXN => 'MXN',
        THB => '฿',
        USD => 'USD',
        XCD => 'XCD',
    },
    'ca-FR' => {
        FRF => 'F',
    },
    ce => {
        RUB => '₽',
    },
    cgg => {
        UGX => 'USh',
    },
    chr => {
        USD => '$',
    },
    cs => {
        AUD => 'AU$',
        CSK => 'Kčs',
        CZK => 'Kč',
        ILS => 'ILS',
        INR => 'INR',
        VND => 'VND',
        XEU => 'ECU',
    },
    cu => {
        RUB => '₽',
    },
    cy => {
        KRW => 'KRW',
        THB => '฿',
    },
    da => {
        AUD => 'AU$',
        DKK => 'kr.',
        THB => '฿',
        USD => '$',
    },
    dav => {
        KES => 'Ksh',
    },
    de => {
        ATS => 'öS',
        AUD => 'AU$',
        BGM => 'BGK',
        BGO => 'BGJ',
        DEM => 'DM',
        JPY => '¥',
        THB => '฿',
        USD => '$',
    },
    'de-CH' => {
        EUR => 'EUR',
    },
    'de-LI' => {
        EUR => 'EUR',
    },
    'de-LU' => {
        LUF => 'F',
    },
    dsb => {
        AUD => 'AUD',
        JPY => '¥',
        PLN => 'zł',
        THB => '฿',
        USD => '$',
    },
    dz => {
        AUD => 'AU$',
        BTN => 'Nu.',
        ILS => 'ILS',
        KRW => 'KR₩',
        THB => 'TH฿',
        XAF => 'XAF',
    },
    ebu => {
        KES => 'Ksh',
    },
    ee => {
        AUD => 'AU$',
        GHS => 'GH₵',
        THB => '฿',
    },
    el => {
        GRD => 'Δρχ',
        THB => '฿',
        USD => '$',
    },
    en => {
        JPY => '¥',
        USD => '$',
    },
    'en-001' => {
        JPY => 'JP¥',
        USD => 'US$',
    },
    'en-AG' => {
        XCD => '$',
    },
    'en-AI' => {
        XCD => '$',
    },
    'en-AU' => {
        AUD => '$',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        EUR => 'EUR',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        SCR => 'Rs',
        TWD => 'TWD',
        USD => 'USD',
        VND => 'VND',
        XAF => 'XAF',
        XCD => 'XCD',
        XOF => 'XOF',
        XPF => 'CFP',
    },
    'en-BB' => {
        BBD => '$',
    },
    'en-BI' => {
        BIF => 'FBu',
    },
    'en-BM' => {
        BMD => '$',
    },
    'en-BS' => {
        BSD => '$',
    },
    'en-BW' => {
        BWP => 'P',
    },
    'en-BZ' => {
        BZD => '$',
    },
    'en-CA' => {
        CAD => '$',
    },
    'en-CC' => {
        AUD => '$',
    },
    'en-CK' => {
        NZD => '$',
    },
    'en-CX' => {
        AUD => '$',
    },
    'en-DK' => {
        DKK => 'kr.',
    },
    'en-DM' => {
        XCD => '$',
    },
    'en-ER' => {
        ERN => 'Nfk',
    },
    'en-FJ' => {
        FJD => '$',
    },
    'en-FK' => {
        FKP => '£',
        GBP => 'GB£',
    },
    'en-GD' => {
        XCD => '$',
    },
    'en-GH' => {
        GHS => 'GH₵',
    },
    'en-GI' => {
        GBP => 'GB£',
        GIP => '£',
    },
    'en-GM' => {
        GMD => 'D',
    },
    'en-GY' => {
        GYD => '$',
    },
    'en-JM' => {
        JMD => '$',
    },
    'en-KE' => {
        KES => 'Ksh',
    },
    'en-KI' => {
        AUD => '$',
    },
    'en-KN' => {
        XCD => '$',
    },
    'en-KY' => {
        KYD => '$',
    },
    'en-LC' => {
        XCD => '$',
    },
    'en-LR' => {
        LRD => '$',
    },
    'en-LS' => {
        ZAR => 'R',
    },
    'en-MG' => {
        MGA => 'Ar',
    },
    'en-MO' => {
        MOP => 'MOP$',
    },
    'en-MS' => {
        XCD => '$',
    },
    'en-MT' => {
        GBP => 'GB£',
    },
    'en-MU' => {
        MUR => 'Rs',
    },
    'en-MW' => {
        MWK => 'MK',
    },
    'en-MY' => {
        MYR => 'RM',
    },
    'en-NA' => {
        NAD => '$',
    },
    'en-NF' => {
        AUD => '$',
    },
    'en-NG' => {
        NGN => '₦',
    },
    'en-NR' => {
        AUD => '$',
    },
    'en-NU' => {
        NZD => '$',
    },
    'en-NZ' => {
        NZD => '$',
    },
    'en-PG' => {
        PGK => 'K',
    },
    'en-PH' => {
        PHP => '₱',
    },
    'en-PK' => {
        PKR => 'Rs',
    },
    'en-PN' => {
        NZD => '$',
    },
    'en-RW' => {
        RWF => 'RF',
    },
    'en-SB' => {
        SBD => '$',
    },
    'en-SC' => {
        SCR => 'SR',
    },
    'en-SE' => {
        SEK => 'kr',
    },
    'en-SG' => {
        SGD => '$',
    },
    'en-SH' => {
        GBP => 'GB£',
        SHP => '£',
    },
    'en-SL' => {
        SLL => 'Le',
    },
    'en-SS' => {
        GBP => 'GB£',
        SSP => '£',
    },
    'en-SX' => {
        ANG => 'NAf.',
    },
    'en-SZ' => {
        SZL => 'E',
    },
    'en-TK' => {
        NZD => '$',
    },
    'en-TO' => {
        TOP => 'T$',
    },
    'en-TT' => {
        TTD => '$',
    },
    'en-TV' => {
        AUD => '$',
    },
    'en-TZ' => {
        TZS => 'TSh',
    },
    'en-UG' => {
        UGX => 'USh',
    },
    'en-VC' => {
        XCD => '$',
    },
    'en-VU' => {
        VUV => 'VT',
    },
    'en-WS' => {
        WST => 'WS$',
    },
    'en-ZA' => {
        ZAR => 'R',
    },
    'en-ZM' => {
        ZMW => 'K',
    },
    es => {
        AUD => 'AUD',
        BRL => 'BRL',
        CNY => 'CNY',
        ESP => '₧',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        THB => '฿',
        TWD => 'TWD',
        USD => '$',
        XAF => 'XAF',
        XCD => 'XCD',
        XOF => 'XOF',
    },
    'es-419' => {
        CAD => 'CAD',
        EUR => 'EUR',
        THB => 'THB',
        USD => 'USD',
        VND => 'VND',
    },
    'es-AR' => {
        ARS => '$',
        USD => 'US$',
    },
    'es-BO' => {
        BOB => 'Bs',
    },
    'es-BR' => {
        BRL => 'R$',
    },
    'es-CL' => {
        CLP => '$',
        USD => 'US$',
    },
    'es-CO' => {
        COP => '$',
        USD => 'US$',
    },
    'es-CR' => {
        CRC => '₡',
    },
    'es-CU' => {
        CUP => '$',
        USD => 'US$',
    },
    'es-DO' => {
        DOP => 'RD$',
        USD => 'US$',
    },
    'es-EC' => {
        USD => '$',
    },
    'es-GQ' => {
        XAF => 'FCFA',
    },
    'es-GT' => {
        GTQ => 'Q',
    },
    'es-HN' => {
        HNL => 'L',
    },
    'es-MX' => {
        AFN => 'Af',
        ANG => 'Naf',
        AOA => 'Kz',
        ARS => '$a',
        AUD => 'AU$',
        AWG => 'Afl.',
        CNY => 'CN¥',
        MXN => '$',
        XPF => 'XPF',
    },
    'es-NI' => {
        NIO => 'C$',
    },
    'es-PA' => {
        PAB => 'B/.',
    },
    'es-PE' => {
        PEN => 'S/.',
    },
    'es-PH' => {
        PHP => '₱',
    },
    'es-PR' => {
        USD => '$',
    },
    'es-PY' => {
        PYG => 'Gs.',
    },
    'es-SV' => {
        USD => '$',
    },
    'es-US' => {
        JPY => '¥',
        USD => '$',
    },
    'es-UY' => {
        USD => 'US$',
        UYU => '$',
    },
    'es-VE' => {
        VEF => 'Bs.',
    },
    et => {
        AUD => 'AU$',
        EEK => 'kr',
        JPY => '¥',
        THB => '฿',
        USD => '$',
    },
    eu => {
        ESP => '₧',
        THB => '฿',
    },
    fa => {
        AFN => '؋',
        CAD => '$CA',
        CNY => '¥CN',
        HKD => '$HK',
        IRR => 'ریال',
        JPY => '¥',
        MXN => '$MX',
        NZD => '$NZ',
        THB => '฿',
        USD => '$',
        XCD => '$EC',
    },
    'ff-GN' => {
        GNF => 'FG',
    },
    'ff-MR' => {
        MRO => 'UM',
    },
    fi => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        FIM => 'mk',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => '¥',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        TWD => 'TWD',
        USD => '$',
        VND => 'VND',
        XCD => 'XCD',
        XPF => 'XPF',
    },
    fil => {
        JPY => '¥',
        PHP => '₱',
        THB => '฿',
        USD => '$',
    },
    fo => {
        DKK => 'kr',
    },
    'fo-DK' => {
        DKK => 'kr.',
    },
    fr => {
        ARS => '$AR',
        AUD => '$AU',
        BEF => 'FB',
        BMD => '$BM',
        BND => '$BN',
        BSD => '$BS',
        BZD => '$BZ',
        CAD => '$CA',
        CLP => '$CL',
        CNY => 'CNY',
        COP => '$CO',
        CYP => '£CY',
        FJD => '$FJ',
        FKP => '£FK',
        FRF => 'F',
        GBP => '£GB',
        GIP => '£GI',
        HKD => 'HKD',
        IEP => '£IE',
        ILP => '£IL',
        ITL => '₤IT',
        JPY => 'JPY',
        LBP => '£LB',
        MTP => '£MT',
        MXN => '$MX',
        NAD => '$NA',
        NZD => '$NZ',
        RHD => '$RH',
        SBD => '$SB',
        SGD => '$SG',
        SRD => '$SR',
        TTD => '$TT',
        TWD => 'TWD',
        USD => '$US',
        UYU => '$UY',
        WST => 'WS$',
        XCD => 'XCD',
        XPF => 'FCFP',
    },
    'fr-BI' => {
        BIF => 'FBu',
    },
    'fr-CA' => {
        ARS => 'ARS',
        AUD => '$ AU',
        BMD => 'BMD',
        BND => 'BND',
        BSD => 'BSD',
        BZD => 'BZD',
        CAD => '$',
        CLP => 'CLP',
        CNY => 'CN¥',
        COP => 'COP',
        FJD => 'FJD',
        FKP => 'FKP',
        GBP => '£',
        GIP => 'GIP',
        HKD => '$ HK',
        ILS => 'ILS',
        JPY => '¥',
        KRW => 'KRW',
        LBP => 'LBP',
        MXN => 'MXN',
        NAD => 'NAD',
        NZD => '$ NZ',
        SBD => 'SBD',
        SGD => '$ SG',
        SRD => 'SRD',
        TTD => 'TTD',
        USD => '$ US',
        UYU => 'UYU',
        VND => 'VND',
        XAF => 'XAF',
        XOF => 'XOF',
        XPF => 'XPF',
    },
    'fr-CD' => {
        CDF => 'FC',
    },
    'fr-DJ' => {
        DJF => 'Fdj',
    },
    'fr-DZ' => {
        DZD => 'DA',
    },
    'fr-GN' => {
        GNF => 'FG',
    },
    'fr-HT' => {
        HTG => 'G',
    },
    'fr-KM' => {
        KMF => 'CF',
    },
    'fr-LU' => {
        FRF => 'FRF',
        LUF => 'F',
    },
    'fr-MG' => {
        MGA => 'Ar',
    },
    'fr-MR' => {
        MRO => 'UM',
    },
    'fr-MU' => {
        MUR => 'Rs',
    },
    'fr-RW' => {
        RWF => 'RF',
    },
    'fr-SC' => {
        SCR => 'SR',
    },
    'fr-SY' => {
        SYP => 'LS',
    },
    'fr-TN' => {
        TND => 'DT',
    },
    'fr-VU' => {
        VUV => 'VT',
    },
    fy => {
        AUD => 'AU$',
        CAD => 'C$',
        FJD => 'FJ$',
        SBD => 'SI$',
        THB => '฿',
        XPF => 'XPF',
    },
    ga => {
        JPY => '¥',
        THB => '฿',
        USD => '$',
    },
    gd => {
        THB => '฿',
        USD => '$',
    },
    gl => {
        AUD => '$A',
        BRL => '$R',
        CAD => '$CA',
        ESP => '₧',
        HKD => '$HK',
        JPY => '¥JP',
        MXN => '$MX',
        THB => '฿',
        TWD => '$NT',
        USD => '$',
    },
    gsw => {
        ATS => 'öS',
        JPY => '¥',
        USD => '$',
    },
    gu => {
        THB => '฿',
    },
    guz => {
        KES => 'Ksh',
    },
    ha => {
        NGN => '₦',
    },
    'ha-GH' => {
        GHS => 'GH₵',
    },
    haw => {
        USD => '$',
    },
    he => {
        ILP => 'ל״י',
        THB => '฿',
        USD => '$',
    },
    hi => {
        THB => '฿',
        USD => '$',
    },
    hr => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        EUR => 'EUR',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        TWD => 'TWD',
        USD => 'USD',
        VND => 'VND',
        XCD => 'XCD',
        XPF => 'XPF',
    },
    'hr-BA' => {
        BAM => 'KM',
    },
    hsb => {
        AUD => 'AUD',
        JPY => '¥',
        PLN => 'zł',
        THB => '฿',
        USD => '$',
    },
    hu => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        EUR => 'EUR',
        GBP => 'GBP',
        HKD => 'HKD',
        HUF => 'Ft',
        ILS => 'ILS',
        INR => 'INR',
        JPY => '¥',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        TWD => 'TWD',
        USD => 'USD',
        VND => 'VND',
        XCD => 'XCD',
    },
    hy => {
        AMD => '֏',
        THB => '฿',
        USD => '$',
    },
    id => {
        AUD => 'AU$',
        IDR => 'Rp',
        INR => 'Rs',
        THB => '฿',
    },
    ig => {
        NGN => '₦',
    },
    ii => {
        CNY => '¥',
    },
    is => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        EUR => 'EUR',
        GBP => 'GBP',
        INR => 'INR',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        TWD => 'TWD',
        USD => 'USD',
        VND => 'VND',
    },
    it => {
        BRL => 'BRL',
        HKD => 'HKD',
        JPY => 'JPY',
        KRW => 'KRW',
        MXN => 'MXN',
        THB => '฿',
        TWD => 'TWD',
    },
    ja => {
        AUD => 'AU$',
        CNY => '元',
        JPY => '￥',
        THB => '฿',
        USD => '$',
    },
    jmc => {
        TZS => 'TSh',
    },
    ka => {
        AUD => 'AUD',
        CNY => 'CNY',
        GEL => '₾',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        NZD => 'NZD',
        VND => 'VND',
    },
    kab => {
        DZD => 'DA',
    },
    kam => {
        KES => 'Ksh',
    },
    kde => {
        TZS => 'TSh',
    },
    kea => {
        AUD => 'AU$',
        CVE => "\N{ZERO WIDTH SPACE}",
        THB => '฿',
    },
    ki => {
        KES => 'Ksh',
    },
    kk => {
        BMD => 'БД',
        CAD => 'КД$',
        KZT => '₸',
        RUB => '₽',
        THB => '฿',
        USD => '$',
    },
    kl => {
        DKK => 'kr.',
    },
    kln => {
        KES => 'Ksh',
    },
    km => {
        KHR => '៛',
        THB => '฿',
        USD => '$',
    },
    kn => {
        THB => '฿',
        USD => '$',
    },
    ko => {
        AUD => 'AU$',
        THB => '฿',
    },
    ksb => {
        TZS => 'TSh',
    },
    ky => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        KGS => 'сом',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        THB => '฿',
        TWD => 'TWD',
        USD => 'USD',
        XCD => 'XCD',
    },
    lag => {
        TZS => 'TSh',
    },
    lb => {
        ATS => 'öS',
        AUD => 'AU$',
        JPY => '¥',
        THB => '฿',
        USD => '$',
    },
    lg => {
        UGX => 'USh',
    },
    lkt => {
        USD => '$',
    },
    ln => {
        CDF => 'FC',
    },
    'ln-AO' => {
        AOA => 'Kz',
    },
    lo => {
        LAK => '₭',
        THB => '฿',
    },
    lt => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        TWD => 'TWD',
        USD => 'USD',
        VND => 'VND',
        XAF => 'XAF',
        XCD => 'XCD',
        XOF => 'XOF',
        XPF => 'XPF',
    },
    lu => {
        CDF => 'FC',
    },
    luo => {
        KES => 'Ksh',
    },
    luy => {
        KES => 'Ksh',
    },
    lv => {
        AUD => 'AU$',
        JPY => '¥',
        LVL => 'Ls',
        THB => '฿',
        USD => '$',
    },
    mas => {
        KES => 'Ksh',
    },
    'mas-TZ' => {
        TZS => 'TSh',
    },
    mer => {
        KES => 'Ksh',
    },
    mfe => {
        MUR => 'Rs',
    },
    mg => {
        MGA => 'Ar',
    },
    mgh => {
        MZN => 'MTn',
    },
    mk => {
        AUD => 'AUD',
        CNY => 'CNY',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        MKD => 'ден',
        NZD => 'NZD',
        TWD => 'TWD',
        VND => 'VND',
    },
    ml => {
        JPY => '¥',
        THB => '฿',
        USD => '$',
    },
    mn => {
        MNT => '₮',
        THB => '฿',
        USD => '$',
    },
    mr => {
        THB => '฿',
        USD => '$',
    },
    ms => {
        CAD => 'CAD',
        MXN => 'MXN',
        MYR => 'RM',
        USD => 'USD',
    },
    'ms-BN' => {
        BND => '$',
    },
    'ms-SG' => {
        SGD => '$',
    },
    my => {
        CRC => 'စီအာစီ',
        MMK => 'K',
        THB => '฿',
    },
    mzn => {
        USD => '$',
    },
    naq => {
        NAD => '$',
    },
    nb => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        MXN => 'MXN',
        NOK => 'kr',
        NZD => 'NZD',
        TWD => 'TWD',
        USD => 'USD',
        VND => 'VND',
        XAF => 'XAF',
        XCD => 'XCD',
        XPF => 'XPF',
    },
    ne => {
        NPR => 'नेरू',
        THB => '฿',
    },
    nl => {
        AUD => 'AU$',
        CAD => 'C$',
        FJD => 'FJ$',
        SBD => 'SI$',
        THB => '฿',
        XPF => 'XPF',
    },
    'nl-AW' => {
        AWG => 'Afl.',
    },
    'nl-BQ' => {
        USD => '$',
    },
    'nl-CW' => {
        ANG => 'NAf.',
    },
    'nl-SR' => {
        SRD => '$',
    },
    'nl-SX' => {
        ANG => 'NAf.',
    },
    nn => {
        NOK => 'kr',
    },
    nus => {
        GBP => 'GB£',
        SSP => '£',
    },
    nyn => {
        UGX => 'USh',
    },
    om => {
        ETB => 'Br',
    },
    'om-KE' => {
        KES => 'Ksh',
    },
    os => {
        GEL => '₾',
        USD => '$',
    },
    'os-RU' => {
        GEL => 'GEL',
        RUB => '₽',
    },
    pa => {
        THB => '฿',
    },
    'pa-Arab' => {
        PKR => 'ر',
    },
    pl => {
        AUD => 'AUD',
        CAD => 'CAD',
        CNY => 'CNY',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        PLN => 'zł',
        TWD => 'TWD',
        USD => 'USD',
        VND => 'VND',
    },
    ps => {
        AFN => '؋',
    },
    pt => {
        AUD => 'AU$',
        PTE => 'Esc.',
        THB => '฿',
    },
    'pt-AO' => {
        AOA => 'Kz',
    },
    'pt-CV' => {
        CVE => "\N{ZERO WIDTH SPACE}",
        PTE => "\N{ZERO WIDTH SPACE}PTE",
    },
    'pt-LU' => {
        LUF => 'F',
    },
    'pt-MO' => {
        MOP => 'MOP$',
    },
    'pt-MZ' => {
        MZN => 'MTn',
    },
    'pt-PT' => {
        PTE => "\N{ZERO WIDTH SPACE}",
    },
    'pt-ST' => {
        STD => 'Db',
    },
    qu => {
        PEN => 'S/.',
    },
    'qu-BO' => {
        BOB => 'Bs',
        PEN => 'PEN',
    },
    'qu-EC' => {
        PEN => 'PEN',
        USD => '$',
    },
    rn => {
        BIF => 'FBu',
    },
    ro => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        EUR => 'EUR',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        TWD => 'TWD',
        USD => 'USD',
        VND => 'VND',
        XCD => 'XCD',
    },
    'ro-MD' => {
        MDL => 'L',
    },
    rof => {
        TZS => 'TSh',
    },
    ru => {
        JPY => '¥',
        RUB => '₽',
        RUR => 'р.',
        THB => '฿',
        TMT => 'ТМТ',
        UAH => '₴',
        USD => '$',
        XXX => 'XXXX',
    },
    'ru-BY' => {
        BYR => 'р.',
        RUR => 'RUR',
    },
    'ru-KG' => {
        KGS => 'сом',
    },
    'ru-KZ' => {
        KZT => '₸',
    },
    'ru-MD' => {
        MDL => 'L',
    },
    rw => {
        RWF => 'RF',
    },
    rwk => {
        TZS => 'TSh',
    },
    sah => {
        RUB => '₽',
    },
    saq => {
        KES => 'Ksh',
    },
    sbp => {
        TZS => 'TSh',
    },
    se => {
        DKK => 'Dkr',
        NOK => 'kr',
        SEK => 'Skr',
        THB => '฿',
    },
    'se-SE' => {
        NOK => 'Nkr',
        SEK => 'kr',
    },
    seh => {
        MZN => 'MTn',
    },
    si => {
        LKR => 'රු.',
        THB => '฿',
        XOF => 'සිෆ්එ',
    },
    sk => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'NIS',
        INR => 'INR',
        JPY => 'JPY',
        KRW => 'KRW',
        NZD => 'NZD',
        TWD => 'TWD',
        USD => 'USD',
        VND => 'VND',
    },
    sl => {
        CAD => 'CAD',
        JPY => '¥',
        THB => '฿',
        USD => '$',
    },
    so => {
        SOS => 'S',
    },
    'so-DJ' => {
        DJF => 'Fdj',
    },
    'so-ET' => {
        ETB => 'Br',
    },
    'so-KE' => {
        KES => 'Ksh',
    },
    sq => {
        ALL => 'Lekë',
        THB => '฿',
    },
    'sq-MK' => {
        MKD => 'den',
    },
    sr => {
        AUD => 'AUD',
        BAM => 'КМ',
        BGN => '[BGN]',
        BYR => '[BYR]',
        JPY => '¥',
        KRW => 'KRW',
        NZD => 'NZD',
        VND => 'VND',
    },
    'sr-Latn' => {
        AUD => 'AUD',
        BAM => 'KM',
        BGN => '[BGN]',
        BYR => '[BYR]',
        JPY => '¥',
        KRW => 'KRW',
        NZD => 'NZD',
        VND => 'VND',
    },
    sv => {
        AUD => 'AUD',
        BBD => 'Bds$',
        BMD => 'BM$',
        BRL => 'BR$',
        BSD => 'BS$',
        BZD => 'BZ$',
        CNY => 'CNY',
        DKK => 'Dkr',
        DOP => 'RD$',
        EEK => 'Ekr',
        EGP => 'EG£',
        GBP => 'GBP',
        HKD => 'HKD',
        INR => 'INR',
        ISK => 'Ikr',
        JMD => 'JM$',
        JPY => 'JPY',
        KRW => 'KRW',
        NOK => 'Nkr',
        NZD => 'NZD',
        SEK => 'kr',
        TWD => 'TWD',
        VND => 'VND',
    },
    sw => {
        KES => 'Ksh',
        THB => '฿',
        TZS => 'TSh',
    },
    'sw-CD' => {
        CDF => 'FC',
    },
    'sw-UG' => {
        UGX => 'USh',
    },
    ta => {
        JPY => '¥',
        THB => '฿',
        USD => '$',
    },
    'ta-LK' => {
        LKR => 'Rs.',
    },
    'ta-MY' => {
        MYR => 'RM',
        SGD => 'S$',
    },
    'ta-SG' => {
        MYR => 'RM',
        SGD => '$',
        USD => 'US$',
    },
    te => {
        THB => '฿',
        USD => '$',
    },
    teo => {
        UGX => 'USh',
    },
    'teo-KE' => {
        KES => 'Ksh',
    },
    th => {
        AUD => 'AU$',
        JPY => '¥',
    },
    ti => {
        ETB => 'Br',
    },
    'ti-ER' => {
        ERN => 'Nfk',
    },
    tk => {
        EUR => 'EUR',
        GBP => 'GBP',
    },
    to => {
        AUD => 'AUD$',
        NZD => 'NZD$',
        TOP => 'T$',
    },
    tr => {
        AUD => 'AU$',
        JPY => '¥',
        THB => '฿',
        TRY => '₺',
        USD => '$',
    },
    ug => {
        CNY => '￥',
        USD => '$',
    },
    uk => {
        AUD => 'AUD',
        BRL => 'BRL',
        CAD => 'CAD',
        CNY => 'CNY',
        EUR => 'EUR',
        GBP => 'GBP',
        HKD => 'HKD',
        ILS => 'ILS',
        INR => 'INR',
        JPY => '¥',
        KRW => 'KRW',
        MXN => 'MXN',
        NZD => 'NZD',
        TWD => 'TWD',
        UAH => '₴',
        UAK => 'крб.',
        USD => 'USD',
        VND => 'VND',
        XCD => 'XCD',
    },
    ur => {
        PKR => 'Rs',
        THB => '฿',
        USD => '$',
    },
    'ur-IN' => {
        PKR => 'PKR',
    },
    uz => {
        UZS => 'soʻm',
    },
    'uz-Arab' => {
        AFN => '؋',
    },
    'uz-Cyrl' => {
        THB => '฿',
        UZS => 'сўм',
    },
    vai => {
        LRD => '$',
    },
    'vai-Latn' => {
        LRD => '$',
    },
    vi => {
        AUD => 'AU$',
        THB => '฿',
    },
    vun => {
        TZS => 'TSh',
    },
    wae => {
        JPY => '¥',
        USD => '$',
    },
    xog => {
        UGX => 'USh',
    },
    yo => {
        NGN => '₦',
    },
    yue => {
        AUD => 'AU$',
        JPY => '¥',
        KRW => '￦',
        TWD => '$',
    },
    zh => {
        AUD => 'AU$',
        CNY => '￥',
        ILR => 'ILS',
        KRW => '￦',
    },
    'zh-Hans-HK' => {
        CNY => 'CN¥',
    },
    'zh-Hans-MO' => {
        CNY => 'CN¥',
        MOP => 'MOP$',
    },
    'zh-Hans-SG' => {
        CNY => 'CN¥',
        SGD => '$',
    },
    'zh-Hant' => {
        AUD => 'AU$',
        JPY => '¥',
        KRW => '￦',
        TWD => '$',
    },
    'zh-Hant-HK' => {
        KRW => '₩',
        TWD => 'NT$',
    },
    'zh-Hant-MO' => {
        MOP => 'MOP$',
    },
    zu => {
        THB => '฿',
        ZAR => 'R',
    },
};

# Supplemental: Currency Fractions
our $CURRENCIES = {
    DEFAULT => {
        digits => 2,
        rounding => 0,
    },
    ADP => {
        digits => 0,
        rounding => 0,
    },
    AFN => {
        digits => 0,
        rounding => 0,
    },
    ALL => {
        digits => 0,
        rounding => 0,
    },
    AMD => {
        digits => 0,
        rounding => 0,
    },
    BHD => {
        digits => 3,
        rounding => 0,
    },
    BIF => {
        digits => 0,
        rounding => 0,
    },
    BYR => {
        digits => 0,
        rounding => 0,
    },
    CAD => {
        digits => 2,
        rounding => 0,
        cash_rounding => 5,
    },
    CHF => {
        digits => 2,
        rounding => 0,
        cash_rounding => 5,
    },
    CLF => {
        digits => 4,
        rounding => 0,
    },
    CLP => {
        digits => 0,
        rounding => 0,
    },
    COP => {
        digits => 0,
        rounding => 0,
    },
    CRC => {
        digits => 0,
        rounding => 0,
    },
    CZK => {
        digits => 2,
        rounding => 0,
        cash_digits => 0,
        cash_rounding => 0,
    },
    DJF => {
        digits => 0,
        rounding => 0,
    },
    ESP => {
        digits => 0,
        rounding => 0,
    },
    GNF => {
        digits => 0,
        rounding => 0,
    },
    GYD => {
        digits => 0,
        rounding => 0,
    },
    HUF => {
        digits => 2,
        rounding => 0,
        cash_digits => 0,
        cash_rounding => 0,
    },
    IDR => {
        digits => 0,
        rounding => 0,
    },
    IQD => {
        digits => 0,
        rounding => 0,
    },
    IRR => {
        digits => 0,
        rounding => 0,
    },
    ISK => {
        digits => 0,
        rounding => 0,
    },
    ITL => {
        digits => 0,
        rounding => 0,
    },
    JOD => {
        digits => 3,
        rounding => 0,
    },
    JPY => {
        digits => 0,
        rounding => 0,
    },
    KMF => {
        digits => 0,
        rounding => 0,
    },
    KPW => {
        digits => 0,
        rounding => 0,
    },
    KRW => {
        digits => 0,
        rounding => 0,
    },
    KWD => {
        digits => 3,
        rounding => 0,
    },
    LAK => {
        digits => 0,
        rounding => 0,
    },
    LBP => {
        digits => 0,
        rounding => 0,
    },
    LUF => {
        digits => 0,
        rounding => 0,
    },
    LYD => {
        digits => 3,
        rounding => 0,
    },
    MGA => {
        digits => 0,
        rounding => 0,
    },
    MGF => {
        digits => 0,
        rounding => 0,
    },
    MMK => {
        digits => 0,
        rounding => 0,
    },
    MNT => {
        digits => 0,
        rounding => 0,
    },
    MRO => {
        digits => 0,
        rounding => 0,
    },
    MUR => {
        digits => 0,
        rounding => 0,
    },
    OMR => {
        digits => 3,
        rounding => 0,
    },
    PKR => {
        digits => 0,
        rounding => 0,
    },
    PYG => {
        digits => 0,
        rounding => 0,
    },
    RSD => {
        digits => 0,
        rounding => 0,
    },
    RWF => {
        digits => 0,
        rounding => 0,
    },
    SLL => {
        digits => 0,
        rounding => 0,
    },
    SOS => {
        digits => 0,
        rounding => 0,
    },
    STD => {
        digits => 0,
        rounding => 0,
    },
    SYP => {
        digits => 0,
        rounding => 0,
    },
    TMM => {
        digits => 0,
        rounding => 0,
    },
    TND => {
        digits => 3,
        rounding => 0,
    },
    TRL => {
        digits => 0,
        rounding => 0,
    },
    TWD => {
        digits => 2,
        rounding => 0,
        cash_digits => 0,
        cash_rounding => 0,
    },
    TZS => {
        digits => 0,
        rounding => 0,
    },
    UGX => {
        digits => 0,
        rounding => 0,
    },
    UYI => {
        digits => 0,
        rounding => 0,
    },
    UZS => {
        digits => 0,
        rounding => 0,
    },
    VND => {
        digits => 0,
        rounding => 0,
    },
    VUV => {
        digits => 0,
        rounding => 0,
    },
    XAF => {
        digits => 0,
        rounding => 0,
    },
    XOF => {
        digits => 0,
        rounding => 0,
    },
    XPF => {
        digits => 0,
        rounding => 0,
    },
    YER => {
        digits => 0,
        rounding => 0,
    },
    ZMK => {
        digits => 0,
        rounding => 0,
    },
    ZWD => {
        digits => 0,
        rounding => 0,
    },
};

1;
