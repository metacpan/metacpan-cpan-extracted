package Data::MoneyCurrency;

use 5.006;
use strict;
use warnings;
use utf8;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_currency get_currencies_for_country);

use File::ShareDir qw(dist_file);
use JSON qw(decode_json);
use Types::Serialiser;
use Carp;
use Data::Dumper;

my $rh_currency_for_country = {};

=encoding utf8

=head1 NAME

Data::MoneyCurrency - Get currency information for different currencies

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


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

This uses some data found in in the Ruby library
L<money|https://github.com/RubyMoney/money/tree/master/config>, but it has no
dependency on it, the relevant data files are already included.

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 get_currency

Takes hash of arguments, and returns a reference to hash containing information
about that currency (character strings), or undef if the currency or the
country is not recognised. Pass either 'currency' or 'country' as the only key
of the hash of arguments, with the currency code or the ISO 3166-2 country code
respectively.

    my $currency = get_currency(currency => 'usd');
    # $currency = {
    #    # ...
    # }
    my $currency = get_currency(country => 'fr');
    # $currency = {
    #   # ...
    # }

=cut

my $rh_currency_iso; # contains character strings

sub get_currency {
    croak "get_currency received no arguments" if @_ == 0;
    my %args = @_;

    croak "get_currency cannot accept both currency and country" if $args{currency} && $args{country};
    
    my $currency_abbreviation = lc(delete($args{currency}) || "");
    my $country = lc(delete($args{country}) || "");
    croak "get_currency only accepts currency or country as args" if keys(%args) > 0;
    if (! $currency_abbreviation) {
        if ($country) {
            my $ra_currencies = get_currencies_for_country($country);
            if (! $ra_currencies) {
                return;
            } elsif (@$ra_currencies > 1) {
                croak "More than one currency known for country '$country'";
            }
            $currency_abbreviation = $ra_currencies->[0];
        }
        else {
            croak "Expected one of currency or country to be specified";
        }
    }

    if (! defined($rh_currency_iso)) {
        my $path = dist_file('Data-MoneyCurrency', 'currency_iso.json');
        open my $fh, "<:raw", $path or die $!;
        my $octet_contents = join "", readline($fh);
        close $fh or die $!;
        $rh_currency_iso = decode_json($octet_contents);
    }

    if (! $rh_currency_iso->{$currency_abbreviation}) {
        return;
    }

    # Shallow copy everytime deliberately, so that the caller can mutate the
    # return value if wished, without affecting rh_currency_iso
    my $rv = {};
    for my $key (keys %{ $rh_currency_iso->{$currency_abbreviation} }) {
        my $value = $rh_currency_iso->{$currency_abbreviation}{$key};
        if (JSON::is_bool($value) or Types::Serialiser::is_bool($value)) {
            $value = $value ? 1 : 0;
        }
        $rv->{$key} = $value;
    }
    return $rv;
}

my $rh_currencies_for_country = {
    ae => ['aed'],
    af => ['afn'],
    ag => ['xcd'],
    ai => ['xcd'],
    al => ['all'],
    am => ['amd'],
    an => ['ang'],
    ao => ['aoa'],
    ar => ['ars'],
    at => ['eur'],
    au => ['aud'],
    aw => ['awg'],
    az => ['azn'],
    ba => ['bam'],
    bb => ['bbd'],
    bd => ['bdt'],
    be => ['eur'],
    bf => ['xof'],
    bg => ['bgn'],
    bh => ['bhd'],
    bi => ['bif'],
    bm => ['bmd'],
    bn => ['bnd'],
    bo => ['bob'],
    br => ['brl'],
    bs => ['bsd'],
    bt => ['btn'],
    bw => ['bwp'],
    by => [ 'byn', 'byr' ],
    bz => ['bzd'],
    ca => ['cad'],
    cd => ['cdf'],
    cf => ['xaf'],
    cg => ['xaf'],
    ch => ['chf'],
    ci => ['xof'],
    cl => [ 'clf', 'clp' ],
    cm => ['xaf'],
    cn => ['cny'],
    co => ['cop'],
    cr => ['crc'],
    cu => [ 'cuc', 'cup' ],
    cv => ['cve'],
    cy => ['eur'],
    cz => ['czk'],
    de => ['eur'],
    dj => ['djf'],
    dk => ['dkk'],
    dm => ['xcd'],
    do => ['dop'],
    dy => ['xof'],
    dz => ['dzd'],
    ee => ['eur'],
    eg => ['egp'],
    er => ['ern'],
    es => ['eur'],
    et => ['etb'],
    fi => ['eur'],
    fj => ['fjd'],
    fk => ['fkp'],
    fr => ['eur'],
    ga => ['xaf'],
    gb => ['gbp'],
    gd => ['xcd'],
    ge => ['gel'],
    gh => ['ghs'],
    gi => ['gip'],
    gm => ['gmd'],
    gn => ['gnf'],
    gq => ['xaf'],
    gr => ['eur'],
    gt => ['gtq'],
    gw => ['xof'],
    gy => ['gyd'],
    hk => ['hkd'],
    hn => ['hnl'],
    hr => ['hrk'],
    ht => ['htg'],
    hu => ['huf'],
    id => ['idr'],
    ie => ['eur'],
    il => ['ils'],
    in => ['inr'],
    iq => ['iqd'],
    ir => ['irr'],
    is => ['isk'],
    it => ['eur'],
    jm => ['jmd'],
    jo => ['jod'],
    jp => ['jpy'],
    ke => ['kes'],
    kg => ['kgs'],
    kh => ['khr'],
    km => ['kmf'],
    kn => ['xcd'],
    kp => ['kpw'],
    kr => ['krw'],
    kw => ['kwd'],
    ky => ['kyd'],
    kz => ['kzt'],
    la => ['lak'],
    lb => ['lbp'],
    lc => ['xcd'],
    lk => ['lkr'],
    lr => ['lrd'],
    ls => ['lsl'],
    lt => ['ltl'],
    lu => ['eur'],
    lv => ['eur'],
    ly => ['lyd'],
    ma => ['mad'],
    md => ['mdl'],
    mg => ['mga'],
    mk => ['mkd'],
    ml => ['xof'],
    mm => ['mmk'],
    mn => ['mnt'],
    mo => ['mop'],
    mr => ['mro'],
    ms => ['xcd'],
    mt => ['eur'],
    mu => ['mur'],
    mv => ['mvr'],
    mw => ['mwk'],
    mx => ['mxn'],
    my => ['myr'],
    mz => ['mzn'],
    na => ['nad'],
    nc => ['xpf'],
    ne => ['xof'],
    ng => ['ngn'],
    ni => ['nio'],
    nl => ['eur'],
    no => ['nok'],
    np => ['npr'],
    nz => ['nzd'],
    om => ['omr'],
    pa => ['pab'],
    pe => ['pen'],
    pf => ['xpf'],
    pg => ['pgk'],
    ph => ['php'],
    pk => ['pkr'],
    pl => ['pln'],
    pt => ['eur'],
    py => ['pyg'],
    qa => ['qar'],
    ro => ['ron'],
    rs => ['rsd'],
    ru => ['rub'],
    rw => ['rwf'],
    sa => ['sar'],
    sb => ['sbd'],
    sc => ['scr'],
    sd => ['sdg'],
    se => ['sek'],
    sg => ['sgd'],
    sh => ['shp'],
    si => ['eur'],
    sk => ['eur'],
    sl => ['sll'],
    sn => ['xof'],
    so => ['sos'],
    sr => ['srd'],
    ss => ['ssp'],
    st => ['std'],
    sv => ['svc'],
    sy => ['syp'],
    sz => ['szl'],
    tg => ['xof'],
    th => ['thb'],
    tj => ['tjs'],
    tm => ['tmt'],
    tn => ['tnd'],
    to => ['top'],
    tr => ['try'],
    tt => ['ttd'],
    tw => ['twd'],
    tz => ['tzs'],
    ua => ['uah'],
    ug => ['ugx'],
    us => ['usd'],
    uy => ['uyu'],
    uz => ['uzs'],
    vc => ['xcd'],
    ve => ['vef'],
    vn => ['vnd'],
    vu => ['vuv'],
    wf => ['xpf'],
    ws => ['wst'],
    xc => ['xcd'],
    ye => ['yer'],
    za => ['zar'],
    zm => ['zmk']
};

=head2 get_currencies_for_country

Takes one argument, a country code in ISO 3166-1 format, and returns a
reference to an array of strings that are currency codes.

    my $rv = get_currencies_for_country('fr');
    # $rv = ["eur"];

=cut

sub get_currencies_for_country {
    croak "get_currency received no arguments" if @_ == 0;
    croak "get_currency received more than one argument" if @_ > 1;
    my $country = lc($_[0]);

    # Return shallow copy to avoid mutating $rh_currencies_for_country
    my $rv = $rh_currencies_for_country->{$country};
    if ($rv) {
        return [@$rv];
    }
    return;
}

=head1 AUTHOR

David D Lowe, C<< <daviddlowe.flimm at gmail.com> >>

=head1 BUGS


Please report any bugs or feature requests through the web interface at
L<https://github.com/Flimm/perl5-Data-MoneyCurrency/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::MoneyCurrency

You can also look for information at:

=over 4

=item * Meta CPAN

L<https://metacpan.org/pod/Data::MoneyCurrency>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This is licensed under the MIT license, and includes code from the
RubyMoney/Money module, which is also licensed under the MIT license.

=cut

1; # End of Data::MoneyCurrency
