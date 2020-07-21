# vim: ts=4 sw=4 tw=78 et si:
package Algorithm::CheckDigits;

use 5.006;
use strict;
use warnings;
use Carp;
use vars qw($AUTOLOAD);

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CheckDigits ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
          CheckDigits method_descriptions method_list print_methods
          ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( CheckDigits );

use version; our $VERSION = qv('v1.3.3');

my %methods = (
    'upc'                => [ 'Algorithm::CheckDigits::MBase_001',
                              'Universal Product Code, UPC (US, CA)' ],
    'blutbeutel'         => [ 'Algorithm::CheckDigits::MBase_002',
                              'Eurocode, blood bags' ],
    'bzue_de'            => [ 'Algorithm::CheckDigits::MBase_002',
                              'Beleglose Zahlscheinüberweisung, BZÜ (DE)' ],
    'ustid_de'           => [ 'Algorithm::CheckDigits::MBase_002',
                              'Umsatzsteuer-Identifikationsnummer (DE)' ],
    'sici'               => [ 'Algorithm::CheckDigits::MBase_003',
                              'Value Added Tax number, VAT (DE)' ],
    'euronote'           => [ 'Algorithm::CheckDigits::M09_001',
                              'Euro bank notes, EUR' ],
    'amex'               => [ 'Algorithm::CheckDigits::M10_001',
                              'American Express credit cards' ],
    'bahncard'           => [ 'Algorithm::CheckDigits::M10_001',
                              'DB Bahncard (DE)' ],
    'cusip'              => [ 'Algorithm::CheckDigits::M10_001',
        'Committee on Uniform Security Identification Procedures, CUSIP (US)' ],
    'diners'             => [ 'Algorithm::CheckDigits::M10_001',
                              q(Diner's club credit cards) ],
    'discover'           => [ 'Algorithm::CheckDigits::M10_001',
                              'Discover credit cards' ],
    'enroute'            => [ 'Algorithm::CheckDigits::M10_001',
                              'EnRoute credit cards' ],
    'eurocard'           => [ 'Algorithm::CheckDigits::M10_001',
                              'Eurocard credit cards' ],
    'happydigits'        => [ 'Algorithm::CheckDigits::M10_001',
                              'Happy Digits (DE)' ],
    'jcb'                => [ 'Algorithm::CheckDigits::M10_001',
                              'JCB credit cards' ],
    'klubkarstadt'       => [ 'Algorithm::CheckDigits::M10_001',
                              'Klub Karstadt (DE)' ],
    'mastercard'         => [ 'Algorithm::CheckDigits::M10_001',
                              'Mastercard credit cards' ],
    'miles&more'         => [ 'Algorithm::CheckDigits::M10_001',
                              'Miles & More, Lufthansa (DE)' ],
    'visa'               => [ 'Algorithm::CheckDigits::M10_001',
                              'VISA credit cards' ],
    'isin'               => [ 'Algorithm::CheckDigits::M10_001',
                       'International Securities Identifikation Number, ISIN' ],
    'imei'               => [ 'Algorithm::CheckDigits::M10_001',
                      'International Mobile Station Equipment Identity, IMEI' ],
    'imeisv'             => [ 'Algorithm::CheckDigits::M10_001',
'International Mobile Station Equipment Identity and Software Version Number' ],
    'siren'              => [ 'Algorithm::CheckDigits::M10_002',
                              'SIREN (FR)' ],
    'siret'              => [ 'Algorithm::CheckDigits::M10_002',
                              'SIRET (FR)' ],
    'ismn'               => [ 'Algorithm::CheckDigits::M10_003',
                              'International Standard Music Number, ISMN' ],
    'ean'                => [ 'Algorithm::CheckDigits::M10_004',
                              'European Article Number, EAN' ],
    'iln'                => [ 'Algorithm::CheckDigits::M10_004',
                              'Global Location Number, GLN' ],
    'nve'                => [ 'Algorithm::CheckDigits::M10_004',
                              'Nummer der Versandeinheit, NVE, SSCC' ],
    '2aus5'              => [ 'Algorithm::CheckDigits::M10_004',
                              '2 aus 5, 2 of 5, 2/5' ],
    'isbn13'             => [ 'Algorithm::CheckDigits::M10_004',
                              'International Standard Book Number, ISBN13' ],
    'identcode_dp'       => [ 'Algorithm::CheckDigits::M10_005',
                              'Identcode Deutsche Post AG (DE)' ],
    'leitcode_dp'        => [ 'Algorithm::CheckDigits::M10_005',
                              'Leitcode Deutsche Post AG (DE)' ],
    'rentenversicherung' => [ 'Algorithm::CheckDigits::M10_006',
                              'Rentenversicherungsnummer, VSNR (DE)' ],
    'sedol'              => [ 'Algorithm::CheckDigits::M10_008',
                          'Stock Exchange Daily Official List, SEDOL (GB)' ],
    'betriebsnummer'     => [ 'Algorithm::CheckDigits::M10_009',
                              'Betriebsnummer (DE)' ],
    'postcheckkonti'     => [ 'Algorithm::CheckDigits::M10_010',
                              'Postscheckkonti (CH)' ],
    'ups'                => [ 'Algorithm::CheckDigits::M10_011',
                              'United Parcel Service, UPS' ],
    'isbn'               => [ 'Algorithm::CheckDigits::M11_001',
                              'International Standard Book Number, ISBN10' ],
    'issn'               => [ 'Algorithm::CheckDigits::M11_001',
                              'International Standard Serial Number, ISSN' ],
    'ustid_pt'           => [ 'Algorithm::CheckDigits::M11_001',
                              'Umsatzsteuer-Identifikationsnummer (PT)' ],
    'vatrn_pt'           => [ 'Algorithm::CheckDigits::M11_001',
                              'Value Added Tax number, VAT (PT)' ],
    'hkid'               => [ 'Algorithm::CheckDigits::M11_001',
                              'Hong Kong Identity Card, HKID (HK)' ],
    'wagonnr_br'         => [ 'Algorithm::CheckDigits::M11_001',
                              'Codificação dos vagões (BR)' ],
    'nhs_gb'             => [ 'Algorithm::CheckDigits::M11_001',
                              'National Health Service, NHS (GB)' ],
    'vat_sl'             => [ 'Algorithm::CheckDigits::M11_001',
                              'Value Added Tax number, VAT (SL)' ],
    'pzn'                => [ 'Algorithm::CheckDigits::M11_002',
                              'Pharmazentralnummer (DE)' ],
    'pkz'                => [ 'Algorithm::CheckDigits::M11_003',
                              'Personenkennzahl der DDR' ],
    'cpf'                => [ 'Algorithm::CheckDigits::M11_004',
                              'Cadastro de Pessoas Físicas, CPF (BR)' ],
    'titulo_eleitor'     => [ 'Algorithm::CheckDigits::M11_004',
                              'Título Eleitoral (BR)' ],
    'ccc_es'             => [ 'Algorithm::CheckDigits::M11_006',
                              'Código de Cuenta Corriente, CCC (ES)' ],
    'ustid_fi'           => [ 'Algorithm::CheckDigits::M11_007',
                              'Umsatzsteuer-Identifikationsnummer (FI)' ],
    'vatrn_fi'           => [ 'Algorithm::CheckDigits::M11_007',
                              'Value Added Tax number, VAT (FI)' ],
    'ustid_dk'           => [ 'Algorithm::CheckDigits::M11_008',
                              'Umsatzsteuer-Identifikationsnummer (DK)' ],
    'vatrn_dk'           => [ 'Algorithm::CheckDigits::M11_008',
                              'Value Added Tax number, VAT (DK)' ],
    'nric_sg'            => [ 'Algorithm::CheckDigits::M11_009',
                       'National Registration Identity Card, NRIC (SG)' ],
    'ahv_ch'             => [ 'Algorithm::CheckDigits::M11_010',
              'Alters- und Hinterlassenenversicherungsnummer, AHV (CH)' ],
    'ustid_nl'           => [ 'Algorithm::CheckDigits::M11_011',
                              'Umsatzsteuer-Identifikationsnummer (NL)' ],
    'vatrn_nl'           => [ 'Algorithm::CheckDigits::M11_011',
                              'Value Added Tax number, VAT (NL)' ],
    'bwpk_de'            => [ 'Algorithm::CheckDigits::M11_012',
                              'Personenkennummer der Bundeswehr (DE)' ],
    'ustid_gr'           => [ 'Algorithm::CheckDigits::M11_013',
                              'Umsatzsteuer-Identifikationsnummer (GR)' ],
    'vatrn_gr'           => [ 'Algorithm::CheckDigits::M11_013',
                              'Value Added Tax number, VAT (GR)' ],
    'esr5_ch'            => [ 'Algorithm::CheckDigits::M11_015',
                              'Einzahlungsschein mit Referenz, ESR5 (CH)' ],
    'ustid_pl'           => [ 'Algorithm::CheckDigits::M11_016',
                              'Umsatzsteuer-Identifikationsnummer (PL)' ],
    'vatrn_pl'           => [ 'Algorithm::CheckDigits::M11_016',
                              'Value Added Tax number, VAT (PL)' ],
    'nip'                => [ 'Algorithm::CheckDigits::M11_016',
                              'numer identyfikacji podatkowej, NIP' ],
    'ecno'               => [ 'Algorithm::CheckDigits::M11_017',
                    'European Commission number, EC-No (for chemicals)' ],
    'einecs'             => [ 'Algorithm::CheckDigits::M11_017',
'European Inventory of Existing Commercial Chemical Substances, EINECS' ],
    'elincs'             => [ 'Algorithm::CheckDigits::M11_017',
                'European List of Notified Chemical Substances, ELINCS' ],
    'isan'               => [ 'Algorithm::CheckDigits::M16_001',
                      'International Standard Audiovisual Number, ISAN' ],
    'dni_es'             => [ 'Algorithm::CheckDigits::M23_001',
                              'Documento nacional de identidad (ES)' ],
    'ustid_ie'           => [ 'Algorithm::CheckDigits::M23_002',
                              'Umsatzsteuer-Identifikationsnummer (IE)' ],
    'vatrn_ie'           => [ 'Algorithm::CheckDigits::M23_002',
                              'Value Added Tax number, VAT (IE)' ],
    'code_39'            => [ 'Algorithm::CheckDigits::M43_001',
                              'Code39, 3 of 9' ],
    'ustid_lu'           => [ 'Algorithm::CheckDigits::M89_001',
                              'Umsatzsteuer-Identifikationsnummer (LU)' ],
    'vatrn_lu'           => [ 'Algorithm::CheckDigits::M89_001',
                              'Value Added Tax number, VAT (LU)' ],
    'ustid_be'           => [ 'Algorithm::CheckDigits::M97_001',
                              'Umsatzsteuer-Identifikationsnummer (BE)' ],
    'vatrn_be'           => [ 'Algorithm::CheckDigits::M97_001',
                              'Value Added Tax number, VAT (BE)' ],
    'iban'               => [ 'Algorithm::CheckDigits::M97_002',
                              'International Bank Account Number (IBAN)' ],
    'pa_de'              => [ 'Algorithm::CheckDigits::MXX_001',
                              'Personalausweis (DE)' ],
    'aba_rn'             => [ 'Algorithm::CheckDigits::MXX_001',
                     'American Bankers Association routing number (ABA RN)' ],
    'cas'                => [ 'Algorithm::CheckDigits::MXX_002',
                              'Chemical abstract service, CAS' ],
    'dem'                => [ 'Algorithm::CheckDigits::MXX_003',
                              'Deutsche Mark Banknoten, DEM' ],
    'ustid_at'           => [ 'Algorithm::CheckDigits::MXX_004',
                              'Umsatzsteuer-Identifikationsnummer (AT)' ],
    'vatrn_at'           => [ 'Algorithm::CheckDigits::MXX_004',
                              'Value Added Tax number, VAT (AT)' ],
    'esr9_ch'            => [ 'Algorithm::CheckDigits::MXX_005',
                              'Einzahlungsschein mit Referenz, ESR9 (CH)' ],
    'verhoeff'           => [ 'Algorithm::CheckDigits::MXX_006',
                              'Verhoeff scheme' ],
);

sub CheckDigits {
    my $method = shift || '';

    if ( my $pkg = $methods{ lc($method) } ) {
        my $module = $pkg->[0];
        my $file   = $pkg->[0];
        $file =~ s{::}{/}g;
        require "$file.pm";
        return new $module($method);
    }
    else {
        die "Don't know checkdigit algorithm for '$method'!";
    }
}    # CheckDigits()

sub method_list {
    my @methods = ();
    foreach my $method ( sort keys %methods ) {
        push @methods, $method;
    }
    return wantarray ? @methods : \@methods;
}    # method_list()

sub method_descriptions {
    my @meths = @_;
    if ($meths[0] eq 'Algorithm::CheckDigits') {
        # it was called Algorithm::CheckDigits->method_descriptions
        shift @meths;
    }
    if (0 == scalar @meths) {
        @meths = keys %methods;
    }
    my %descr = map { $_ => ($methods{$_}) ? $methods{$_}->[1]
                         :                   'unknown'         } @meths;
    return wantarray ? %descr : \%descr;
} # method_descriptions()

sub plug_in {
    if ('Algorithm::CheckDigits' eq $_[0]) {
        shift;
    }
    my $module = shift ||
       die "you need to specify a module except 'Algorithm::CheckDigits'";
    my $descr  = shift || "algorithm of module $module";
    my $key    = lc shift || 'plalg';
    if (exists $methods{$key}) {
        $key .= ',1';
    }
    while (exists $methods{$key}) {
        $key =~ s/(\d+)$/my $y = $1; ++$y/e;
    }
    $methods{$key} = [ $module, $descr ];
    return $key;
} # plug_in()

sub print_methods {
    foreach my $method ( sort keys %methods ) {
        print "$method => $methods{$method}\n";
    }
}    # print_methods()

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    unless ( $attr =~ /^Algorithm::CheckDigits::[A-Za-z_0-9]*$/ ) {
        croak "$attr is not defined";
    }
    return '';
}    # AUTOLOAD()

sub DESTROY {
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Algorithm::CheckDigits - Perl extension to generate and test check digits

=head1 SYNOPSIS

  perl -MAlgorithm::CheckDigits -e Algorithm::CheckDigits::print_methods

or

  use Algorithm::CheckDigits;
  
  @ml = Algorithm::CheckDigits->method_list();
  %md = Algorithm::CheckDigits->method_descriptions();

  $isbn = CheckDigits('ISBN');

  if ($isbn->is_valid('3-930673-48-7')) {
	# do something
  }

  $cn = $isbn->complete('3-930673-48');     # $cn = '3-930673-48-7'

  $cd = $isbn->checkdigit('3-930673-48-7'); # $cd = '7'

  $bn = $isbn->basenumber('3-930673-48-7'); # $bn = '3-930673-48'

=head1 ABSTRACT

This module provides a number of methods to test and generate check
digits. For more information have a look at the web site
F<www.pruefziffernberechnung.de> (german).

=head1 SUBROUTINES/METHODS

=head2 CheckDigits($method)

Returns an object of an appropriate Algorithm::CheckDigits class for the
given algorithm.

Dies with an error message if called with an unknown algorithm.

See below for the available algorithms. Every object understands the following
methods:

=over 4

=item is_valid($number)

Returns true or false if C<$number> contains/contains no valid check digit.

=item complete($number)

Returns a string representation of C<$number> completed with the appropriate
check digit.

=item checkdigit($number)

Extracts the check digit from C<$number> if C<$number> contains a valid check
digit.

=item basenumber($number)

Extracts the basenumber from C<$number> if C<$number> contains a valid check
digit.

=back

=head2 Algorithm::CheckDigits::plug_in($module, $description, $prefkey)

Register a module that provides the same four methods as above. This function
returns a handle with which the registered module can be instantiated.

The first argument C<$module> is the module to be used for this plugin. This
argument is mandatory. Do not register 'Algorithm::CheckDigits'.

The second argument is a short description of the algorithm. If it is omitted,
the string C<algorithm of module $module> will be taken.

The third argument is the preferred key for this algorithm. The C<plug_in()>
function does not guarantee to register the algorithm with this key. Instead
it returns the key under which the algorithm is registered.

See L</"REGISTERING PLUGINS"> for more information on registering plugins.

=head2 Algorithm::CheckDigits::method_list()

Returns a list of known methods for check digit computation.

=head2 Algorithm::CheckDigits::method_descriptions()

Returns a hash of descriptions for the known methods for check digit
computations. The keys of the hash are the values returned by
C<method_list()>.

=head2 Algorithm::CheckDigits::print_methods()

Returns a list of known methods for check digit computation.

You may use the following to find out which methods your version of
Algorithm::CheckDigits provides and where to look for further
information.

 perl -MAlgorithm::CheckDigits -e Algorithm::CheckDigits::print_methods

=head2 CHECK SUM METHODS

At the moment these methods to compute check digits are provided:
(vatrn - VAT Return Number, in german ustid UmsatzSTeuer-ID)

=over 4

=item euronote

European bank notes, see L<Algorithm::CheckDigits::M09_001>.

=item amex, bahncard, diners, discover, enroute, eurocard, happydigits,
      isin, jcb, klubkarstadt, mastercard, miles&more, visa, imei, imeisv

See L<Algorithm::CheckDigits::M10_001>.

=item siren, siret

See L<Algorithm::CheckDigits::M10_002>.

=item ismn

See L<Algorithm::CheckDigits::M10_003>.

=item ean, iln, isbn13, nve, 2aus5

See L<Algorithm::CheckDigits::M10_004>.

=item identcode_dp, leitcode_dp

See L<Algorithm::CheckDigits::M10_005>.

=item rentenversicherung

See L<Algorithm::CheckDigits::M10_006>.

=item sedol

See L<Algorithm::CheckDigits::M10_008>.

=item betriebsnummer

See L<Algorithm::CheckDigits::M10_009>.

=item postscheckkonti

See L<Algorithm::CheckDigits::M10_010>.

=item ups

See L<Algorithm::CheckDigits::M10_011>.

=item hkid, isbn, issn, nhs_gb, ustid_pt, vat_sl, wagonnr_br

See L<Algorithm::CheckDigits::M11_001>.

=item pzn

See L<Algorithm::CheckDigits::M11_002>.

=item pkz

See L<Algorithm::CheckDigits::M11_003>.

=item cpf, titulo_eleitor

See L<Algorithm::CheckDigits::M11_004>.

=item ccc_es

See L<Algorithm::CheckDigits::M11_006>.

=item ustid_fi, vatrn_fi

See L<Algorithm::CheckDigits::M11_007>.

=item ustid_dk, vatrn_dk

See L<Algorithm::CheckDigits::M11_008>.

=item nric_sg

See L<Algorithm::CheckDigits::M11_009>.

=item ahv_ch

See L<Algorithm::CheckDigits::M11_010>.

=item ustid_nl, vatrn_nl

See L<Algorithm::CheckDigits::M11_011>.

=item bwpk_de

See L<Algorithm::CheckDigits::M11_012>.

=item ustid_gr, vatrn_gr

See L<Algorithm::CheckDigits::M11_013>.

=item esr5_ch

See L<Algorithm::CheckDigits::M11_015>.

=item ustid_pl, vatrn_pl

See L<Algorithm::CheckDigits::M11_016>.

=item ecno, ec-no, einecs, elincs

See L<Algorithm::CheckDigits::M11_017>.

=item isan

See L<Algorithm::CheckDigits::M16_001>.

=item dni_es

See L<Algorithm::CheckDigits::M23_001>.

=item ustid_ie, vatrn_ie

See L<Algorithm::CheckDigits::M23_002>.

=item code_39

See L<Algorithm::CheckDigits::M43_001>.

=item ustid_lu, vatrn_lu

See L<Algorithm::CheckDigits::M89_001>.

=item ustid_be, vatrn_be

See L<Algorithm::CheckDigits::M97_001>.

=item iban

See L<Algorithm::CheckDigits::M97_002>.

=item upc

See L<Algorithm::CheckDigits::MBase_001>.

=item blutbeutel, bzue_de, ustid_de, vatrn_de

See L<Algorithm::CheckDigits::MBase_002>.

=item sici

See L<Algorithm::CheckDigits::MBase_003>.

=item pa_de

See L<Algorithm::CheckDigits::MXX_001>.

=item cas

See L<Algorithm::CheckDigits::MXX_002>.

=item dem

Old german bank notes (DEM), see L<Algorithm::CheckDigits::MXX_003>.

=item ustid_at, vatrn_at

See L<Algorithm::CheckDigits::MXX_004>.

=item esr9_ch

See L<Algorithm::CheckDigits::MXX_005>.

=item verhoeff

Verhoeff scheme, see L<Algorithm::CheckDigits::MXX_006> or
L<Algorithm::Verhoeff>

=back

=head2 EXPORT

This module exports the Function C<CheckDigits()> that is used to create an
instance of a checker with the given algorithm.

=head1 REGISTERING PLUGINS

Brian T. Wightman was the first, asking me to add a plugin registry to
Algorithm::CheckDigits and so I added the function C<plug_in()> that does just
this, registering plug in modules to be used just like the modules in the
distribution of this module.

Providing some means to add additional algorithms without the need to change
the module has the benefit that the user of those additional algorithms may
easily use them with the same interface as the other algorithms without having
to wait for a new version, that may or may not include the wanted algorithm.

But there is a problem: the user must be able to select the new algorithms
like he did with the other ones. And the catch is: since these new algorithms
are developed independently there is no guarantee that no more than one
module applies for the same handle. I could have implemented some simple
strategies like last one wins (the module that registers last for a given
handle is the one that is choosen) or first one wins (the first registered
module is choosen). Instead I went for something more complex to assure that
every module that wants to get registered will be registered and that every
registered module will be accessible by the same handle as long as the program
runs. To make this work C<plug_in()> sees the third argument only as a hint
how the handle should look like, when a module is registered. It returns the
real handle with which the algorithm can be instantiated. That means a
developer of a plugin module cannot make the handle immediately available like
I did for the modules in the distribution. Instead there should be something
like a public variable or function that returns the handle as it came back
from the C<plug_in()> function.

This could go like this in the module:

 package Algorithm::XyZ;

 use Algorithm::CheckDigits;

 our $xyz = Algorithm::CheckDigits::plug_in('Algorithm::XyZ',
                                            'XyZ check digits',
                                            'xyz');

And the user of this algorithm would write something like this:

 use Algorithm::CheckDigits;
 use Algorithm::XyZ;

 my $cd = CheckDigits($Algorithm::XyZ::xyz);

 if ($cd->is_valid($some_number)) {
     # do something
 }

Please have a look at the plugin tests in the test directory (I<t/plugin*.t>)
and the accompanying modules (I<t/PluginLib*.pm>) for example usage. You may
also try to load an additional module with the scripts in I<bin> and
I<cgi-bin> and look for the additional algorithms in the output:

 perl -Ilib -It -MPluginLibA bin/checkdigits.pl list

 perl -Ilib -It -MPluginLibA cgi-bin/checkdigits.cgi

=head2 Namespace

I would like to ask you to use any namespace below or outside but not direct
Algorithm::CheckDigits. That means for instance for the XyZ algorithm,
Algorithm::XyZ would be fine, Algorithm::CheckDigits::Plugin::XyZ or
Algorithm::CheckDigits::X::XyZ would be fine too. But
Algorithm::CheckDigits::XyZ could collide with some future version of the
Algorithm::CheckDigits distribution, so please avoid this namespace.

=head1 SEE ALSO

L<perl>,
F<www.pruefziffernberechnung.de>.

=head1 BUGS AND LIMITATIONS

The function C<plug_in()> dies if you try to register the module
'Algorithm::CheckDigits'.

Please report any bugs or feature requests to
C<bug-algorithm-checkdigits@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Mathias Weidner, C<< mamawe@cpan.org >>

=head1 THANKS

Petri Oksanen made me aware that CheckDigits('IMEI') would invoke no test at
all since there was no entry for this in the methods hash.

Brian T. Wightman made me think about and implement the plugin interface.

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2013 by Mathias Weidner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic>.

=cut
