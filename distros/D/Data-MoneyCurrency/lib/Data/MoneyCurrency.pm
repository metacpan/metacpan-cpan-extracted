# ABSTRACT: Get information for different currencies
package Data::MoneyCurrency;
$Data::MoneyCurrency::VERSION = '0.23';
use strict;
use warnings;
use utf8;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_currency get_currencies_for_country);

use Carp;
use Cpanel::JSON::XS;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::ShareDir qw(dist_dir);
use Types::Serialiser;

my $confdir = dist_dir('Data-MoneyCurrency');
my $rh_currency_for_country = {};


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
    }

    if (!$rh_currency_iso->{$currency_abbreviation}) {
        return;
    }

    # Shallow copy everytime deliberately, so that the caller can mutate the
    # return value if wished, without affecting rh_currency_iso
    my $rv = {};
    for my $key (keys %{$rh_currency_iso->{$currency_abbreviation}}) {
        my $value = $rh_currency_iso->{$currency_abbreviation}{$key};
        if (   Cpanel::JSON::XS::is_bool($value)
            or Types::Serialiser::is_bool($value))
        {
            $value = $value ? 1 : 0;
        }
        $rv->{$key} = $value;
    }
    return $rv;
}

my $rh_currencies_for_country = {
    ad   => ['eur'],
    ae   => ['aed'],
    af   => ['afn'],
    ag   => ['xcd'],
    ai   => ['xcd'],
    al   => ['all'],
    am   => ['amd'],
    an   => ['ang'],
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
    bg   => ['bgn'],
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
    cw   => ['ang'],
    cx   => ['aud'],
    cy   => ['eur'],
    cz   => ['czk'],
    de   => ['eur'],
    dj   => ['djf'],
    dk   => ['dkk'],
    dm   => ['xcd'],
    do   => ['dop'],
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
    hr   => ['hrk'],
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
    sl   => ['sll'],
    sm   => ['eur'],
    sn   => ['xof'],
    so   => ['sos'],
    sr   => ['srd'],
    ss   => ['ssp'],
    st   => ['std'],
    sv   => ['usd', 'btc'],
    sx   => ['ang'],
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
    xk   => ['eur'],
    ye   => ['yer'],
    yt   => ['eur'],
    za   => ['zar'],
    zm   => ['zmk']
};


sub get_currencies_for_country {
    croak "get_currencies_for_country received no arguments" if (scalar(@_) == 0);
    croak "get_currencies_for_country received more than one argument" if (scalar(@_) > 1);

    my $country = lc($_[0]);

    # Return shallow copy to avoid mutating $rh_currencies_for_country
    if (my $rv = $rh_currencies_for_country->{$country}){
        return [@$rv];
    }
    return;
}


1; # End of Data::MoneyCurrency

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MoneyCurrency - Get information for different currencies

=head1 VERSION

version 0.23

=head1 SYNOPSIS

Get currency information for different currencies.

    use Data::MoneyCurrency qw(get_currency);

    my $currency = get_currency(currency => 'usd');
    # $currency = {
    #    # ...
    # }
    my $currency = get_currency(country => 'fr');
    # $currency = {
    #   # ...
    # }

This uses some data found in the Ruby library
L<money|https://github.com/RubyMoney/money/tree/main/config>, but it has no
dependency on it, the relevant data files are already included.

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 get_currency

Takes hash of arguments, and returns a reference to hash containing information
about that currency (character strings), or undef if the currency or the
country is not recognised. Pass either 'currency' or 'country' as the only key
of the hash of arguments, with the currency code or the ISO 3166-2 alpha-2
country code respectively.

    my $currency = get_currency(currency => 'usd');
    # $currency = {
    #    # ...
    # }
    my $currency = get_currency(country => 'fr');
    # $currency = {
    #   # ...
    # }

=head2 get_currencies_for_country

Takes one argument, a country code in ISO 3166-1 alpha-2 format, and returns a
reference to an array of strings that are currency codes.

    my $rv = get_currencies_for_country('fr');
    # $rv = ["eur"];

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

This software is copyright (c) 2022 by OpenCage GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
