# ABSTRACT: Get information for different currencies
package Data::MoneyCurrency;
$Data::MoneyCurrency::VERSION = '0.32';
use strict;
use warnings;
use utf8;

use Ex::Op;
our @EXPORT_OK = qw(get_currency get_currencies_for_country);

use Carp;
use Cpanel::JSON::XS;
use File::ShareDir qw(dist_dir);
use Types::Serialiser;

my $confdir = dist_dir('Data-MoneyCurrency');
my $rh_currency_for_country = {};


my $rh_currencies_for_country = {
    ad   => ['eur'],
    ae   => ['aed'],
    af   => ['afn'],
    ag   => ['xcd'],
    ai   => ['xcd'],
    al   => ['all'],
    am   => ['amd'],
    an   => ['xcg'],
    ao   => ['aoa'],
    ar   => ['ars'],
    as   => ['usd'],
    at   => ['eur'],
    au   => ['aud'],
    aw   => ['awg'],
    ax   => ['eur'],
    az   => ['azn'],
    ba   => ['bam'],
    bb   => ['bbd'],
    bd   => ['bdt'],
    be   => ['eur'],
    bf   => ['xof'],
    bg   => ['eur'],
    bh   => ['bhd'],
    bi   => ['bif'],
    bj   => ['xof'],
    bl   => ['eur'],
    bm   => ['bmd'],
    bn   => ['bnd'],
    bo   => ['bob'],
    bq   => ['usd'],
    br   => ['brl'],
    bs   => ['bsd'],
    bt   => ['btn'],
    bw   => ['bwp'],
    by   => ['byn'],
    bv   => ['nok'],
    bz   => ['bzd'],
    ca   => ['cad'],
    cc   => ['aud'],
    cd   => ['cdf'],
    cf   => ['xaf'],
    cg   => ['xaf'],
    ch   => ['chf'],
    ci   => ['xof'],
    ck   => ['nzd'],
    cl   => ['clp'],
    cm   => ['xaf'],
    cn   => ['cny'],
    co   => ['cop'],
    cr   => ['crc'],
    cu   => ['cuc', 'cup'],
    cv   => ['cve'],
    cw   => ['xcg'],
    cx   => ['aud'],
    cy   => ['eur'],
    cz   => ['czk'],
    de   => ['eur'],
    dj   => ['djf'],
    dk   => ['dkk'],
    dm   => ['xcd'],
    'do' => ['dop'],
    dy   => ['xof'],
    dz   => ['dzd'],
    ec   => ['usd'],
    ee   => ['eur'],
    eg   => ['egp'],
    eh   => ['mad'],
    er   => ['ern'],
    es   => ['eur'],
    et   => ['etb'],
    fi   => ['eur'],
    fj   => ['fjd'],
    fk   => ['fkp'],
    fm   => ['usd'],
    fo   => ['dkk'],
    fr   => ['eur'],
    ga   => ['xaf'],
    gb   => ['gbp'],
    gd   => ['xcd'],
    ge   => ['gel'],
    gf   => ['eur'],
    gg   => ['gbp', 'ggp'],
    gh   => ['ghs'],
    gi   => ['gip'],
    gl   => ['dkk'],
    gm   => ['gmd'],
    gn   => ['gnf'],
    gp   => ['eur'],
    gq   => ['xaf'],
    gr   => ['eur'],
    gs   => ['fkp'],
    gt   => ['gtq'],
    gu   => ['usd'],
    gw   => ['xof'],
    gy   => ['gyd'],
    hk   => ['hkd'],
    hm   => ['aud'],
    hn   => ['hnl'],
    hr   => ['eur'],
    ht   => ['htg'],
    hu   => ['huf'],
    id   => ['idr'],
    ie   => ['eur'],
    il   => ['ils'],
    im   => ['imp', 'gbp'],
    in   => ['inr'],
    io   => ['gbp'],
    iq   => ['iqd'],
    ir   => ['irr'],
    is   => ['isk'],
    it   => ['eur'],
    je   => ['gbp', 'jep'],
    jm   => ['jmd'],
    jo   => ['jod'],
    jp   => ['jpy'],
    ke   => ['kes'],
    kg   => ['kgs'],
    kh   => ['khr'],
    ki   => ['aud'],
    km   => ['kmf'],
    kn   => ['xcd'],
    kp   => ['kpw'],
    kr   => ['krw'],
    kw   => ['kwd'],
    ky   => ['kyd'],
    kz   => ['kzt'],
    la   => ['lak'],
    lb   => ['lbp'],
    lc   => ['xcd'],
    li   => ['chf'],
    lk   => ['lkr'],
    lr   => ['lrd'],
    ls   => ['lsl'],
    lt   => ['eur'],
    lu   => ['eur'],
    lv   => ['eur'],
    ly   => ['lyd'],
    ma   => ['mad'],
    mc   => ['eur'],
    md   => ['mdl'],
    me   => ['eur'],
    mf   => ['eur'],
    mg   => ['mga'],
    mh   => ['usd'],
    mk   => ['mkd'],
    ml   => ['xof'],
    mm   => ['mmk'],
    mn   => ['mnt'],
    mo   => ['mop'],
    mq   => ['eur'],
    mr   => ['mro'],
    ms   => ['xcd'],
    mt   => ['eur'],
    mu   => ['mur'],
    mv   => ['mvr'],
    mw   => ['mwk'],
    mx   => ['mxn'],
    'my' => ['myr'],
    mz   => ['mzn'],
    na   => ['nad'],
    nc   => ['xpf'],
    ne   => ['xof'],
    nf   => ['aud'],
    ng   => ['ngn'],
    ni   => ['nio'],
    nl   => ['eur'],
    no   => ['nok'],
    np   => ['npr'],
    nr   => ['aud'],
    nu   => ['nzd'],
    nz   => ['nzd'],
    om   => ['omr'],
    pa   => ['usd', 'pab'],
    pe   => ['pen'],
    pf   => ['xpf'],
    pg   => ['pgk'],
    ph   => ['php'],
    pk   => ['pkr'],
    pl   => ['pln'],
    pm   => ['eur', 'cad'],
    pn   => ['nzd'],
    pr   => ['usd'],
    ps   => ['ils', 'jod'],
    pt   => ['eur'],
    pw   => ['usd'],
    py   => ['pyg'],
    qa   => ['qar'],
    re   => ['eur'],
    ro   => ['ron'],
    rs   => ['rsd'],
    ru   => ['rub'],
    rw   => ['rwf'],
    sa   => ['sar'],
    sb   => ['sbd'],
    sc   => ['scr'],
    sd   => ['sdg'],
    se   => ['sek'],
    sg   => ['sgd'],
    sh   => ['shp'],
    si   => ['eur'],
    sj   => ['nok'],
    sk   => ['eur'],
    sl   => ['sle'],
    sm   => ['eur'],
    sn   => ['xof'],
    so   => ['sos'],
    sr   => ['srd'],
    ss   => ['ssp'],
    st   => ['std'],
    sv   => ['usd', 'btc'],
    sx   => ['xcg'],
    sy   => ['syp'],
    sz   => ['szl'],
    tc   => ['usd'],
    td   => ['xof'],
    tf   => ['eur'],
    tg   => ['xof'],
    th   => ['thb'],
    tj   => ['tjs'],
    tk   => ['nzd'],
    tl   => ['usd'],
    tm   => ['tmt'],
    tn   => ['tnd'],
    to   => ['top'],
    tr   => ['try'],
    tt   => ['ttd'],
    tv   => ['aud'],
    tw   => ['twd'],
    tz   => ['tzs'],
    ua   => ['uah'],
    ug   => ['ugx'],
    um   => ['usd'],
    us   => ['usd'],
    uy   => ['uyu'],
    uz   => ['uzs'],
    va   => ['eur'],
    vc   => ['xcd'],
    ve   => ['ves'],
    vg   => ['usd'],
    vi   => ['usd'],
    vn   => ['vnd'],
    vu   => ['vuv'],
    wf   => ['xpf'],
    ws   => ['wst'],
    xc   => ['eur'],    
    xk   => ['eur'],
    ye   => ['yer'],
    yt   => ['eur'],
    za   => ['zar'],
    zm   => ['zmk'],
    zw   => ['zwg'],
};


op get_currencies_for_country ($country) {
    croak "get_currencies_for_country received no arguments" if !defined $country;

    $country = lc $country;

    # Return shallow copy to avoid mutating $rh_currencies_for_country
    if (my $rv = $rh_currencies_for_country->{$country}){
        return [@$rv];
    }
    return;
}

my $rh_currency_iso; # contains character strings

sub get_currency {
    croak "get_currency received no arguments" if @_ == 0;

    my %args = @_;

    croak "get_currency cannot accept both currency and country"
        if $args{currency} && $args{country};

    my $currency_abbreviation = lc(delete($args{currency}) || "");
    my $country               = lc(delete($args{country})  || "");

    croak "get_currency only accepts currency OR country as args"
        if keys(%args) > 0;

    if (!$currency_abbreviation) {
        if ($country) {
            my $ra_currencies = get_currencies_for_country($country);
            if (!$ra_currencies) {
                return;
            } elsif (@$ra_currencies > 1) {
                croak "More than one currency known for country '$country'";
            }
            $currency_abbreviation = $ra_currencies->[0];
        } else {
            croak "Expected one of currency or country to be specified";
        }
    }

    if (!defined($rh_currency_iso)) {
        # need to read the conf files

        # first the iso file
        my $iso_path = $confdir . '/currency_iso.json';
        open my $fh, "<:raw", $iso_path or die $!;
        my $octet_contents = join "", readline($fh);
        close $fh or die $!;
        $rh_currency_iso = decode_json($octet_contents);

        # now the non_iso
        my $non_iso_path = $confdir . '/currency_non_iso.json';
        open $fh, "<:raw", $non_iso_path or die $!;
        $octet_contents = join "", readline($fh);
        close $fh or die $!;
        my $rh_non_iso = decode_json($octet_contents);
        foreach my $nic (keys %$rh_non_iso){
            $rh_currency_iso->{$nic} = $rh_non_iso->{$nic};
        }

        # Pre-process JSON booleans into Perl 1/0 once at load time
        for my $currency (values %$rh_currency_iso) {
            for my $key (keys %$currency) {
                my $value = $currency->{$key};
                if (   Cpanel::JSON::XS::is_bool($value)
                    or Types::Serialiser::is_bool($value))
                {
                    $currency->{$key} = $value ? 1 : 0;
                }
            }
        }
    }

    if (!$rh_currency_iso->{$currency_abbreviation}) {
        return;
    }

    # Shallow copy everytime deliberately, so that the caller can mutate the
    # return value if wished, without affecting rh_currency_iso
    return { %{$rh_currency_iso->{$currency_abbreviation}} };
}


1; # End of Data::MoneyCurrency

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MoneyCurrency - Get information for different currencies

=head1 VERSION

version 0.32

=head1 SYNOPSIS

    use Data::MoneyCurrency qw(get_currency get_currencies_for_country);

    my $currency = get_currency(currency => 'usd');
    # $currency = {
    #     alternate_symbols    => ['US$'],
    #     decimal_mark         => '.',
    #     disambiguate_symbol  => 'US$',
    #     html_entity          => '$',
    #     iso_code             => 'USD',
    #     iso_numeric          => '840',
    #     name                 => 'United States Dollar',
    #     priority             => 1,
    #     smallest_denomination => 1,
    #     subunit              => 'Cent',
    #     subunit_to_unit      => 100,
    #     symbol               => '$',
    #     symbol_first         => 1,
    #     thousands_separator  => ',',
    # }

    my $currency = get_currency(country => 'fr');
    # $currency contains the hash for EUR

    my $currencies = get_currencies_for_country('cu');
    # $currencies = ['cuc', 'cup']

=head1 DESCRIPTION

Data::MoneyCurrency provides currency data lookup by ISO 4217 currency code or
ISO 3166-1 alpha-2 country code.  It covers all ISO 4217 currencies plus
select non-ISO currencies (e.g. BTC) and 250+ countries and territories.

The currency data is sourced from the Ruby
L<Money|https://github.com/RubyMoney/money/tree/main/config> library but is
maintained independently.  The relevant data files are already included in this
distribution, so there is no dependency on Ruby.

=head1 EXPORT

Nothing is exported by default.  The following functions are available for
export:

    use Data::MoneyCurrency qw(get_currency get_currencies_for_country);

=head1 SUBROUTINES/METHODS

=head2 get_currency

    my $currency = get_currency(currency => 'USD');
    my $currency = get_currency(country  => 'fr');

Takes a hash of arguments with exactly one key — either C<currency> (an
ISO 4217 currency code such as C<usd>) or C<country> (an ISO 3166-1 alpha-2
country code such as C<fr>).  Input is case-insensitive.

Returns a hashref containing currency information, or C<undef> if the
currency or country is not recognised.  The returned hash contains the
following keys:

=over 4

=item C<iso_code> — ISO 4217 currency code (e.g. C<USD>)

=item C<iso_numeric> — ISO 4217 numeric code (e.g. C<840>)

=item C<name> — full currency name (e.g. C<United States Dollar>)

=item C<symbol> — currency symbol (e.g. C<$>)

=item C<alternate_symbols> — arrayref of alternate symbols (e.g. C<['US$']>)

=item C<disambiguate_symbol> — symbol used when disambiguation is needed

=item C<html_entity> — HTML entity for the symbol

=item C<subunit> — name of the fractional unit (e.g. C<Cent>)

=item C<subunit_to_unit> — number of subunits per unit (e.g. C<100>)

=item C<symbol_first> — C<1> if the symbol precedes the amount, C<0> otherwise

=item C<decimal_mark> — character used as the decimal separator

=item C<thousands_separator> — character used as the thousands separator

=item C<smallest_denomination> — smallest amount of cash in circulation (in subunits)

=item C<priority> — relative priority for display ordering

=back

Croaks if called with no arguments, with both C<currency> and C<country>, or
with unrecognised keys.

When using C<country> for a country that has multiple currencies (e.g. Cuba),
the function croaks.  Use L</get_currencies_for_country> to retrieve the full
list first.

=head2 get_currencies_for_country

    my $currencies = get_currencies_for_country('cu');
    # $currencies = ['cuc', 'cup']

    my $currencies = get_currencies_for_country('fr');
    # $currencies = ['eur']

Takes a single argument — an ISO 3166-1 alpha-2 country code (case-insensitive)
— and returns an arrayref of lowercase currency code strings.  Returns C<undef>
if the country is not recognised.

Croaks if called with no arguments or an undefined argument. Any arguments
after the first are ignored.

=head1 SEE ALSO

=over 4

=item * L<Ruby Money|https://github.com/RubyMoney/money> — the source of the currency data

=item * L<ISO 4217|https://en.wikipedia.org/wiki/ISO_4217> — the standard for currency codes

=item * L<ISO 3166-1 alpha-2|https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2> — the standard for country codes

=back

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/OpenCageData/perl5-Data-MoneyCurrency>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::MoneyCurrency

You can also look for information at:

=over 4

=item * Meta CPAN

L<https://metacpan.org/pod/Data::MoneyCurrency>

=back

=head1 ACKNOWLEDGEMENTS

Original version by David D Lowe (FLIMM)

=head1 AUTHOR

edf <cpan@opencagedata.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by OpenCage GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
