package Business::ID::VehiclePlate;

use 5.010001;
use warnings;
use strict;

use DateTime;
use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-05'; # DATE
our $DIST = 'Business-ID-VehiclePlate'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(parse_idn_vehicle_plate_number);

# source data: devdata/prefixes.csv
our %prefixes = (
  A  => {
          iso_prov_codes => "ID-BT",
          region => "Banten",
          summary => "Banten, Cilegon, Serang, Pandeglang, Lebak, Tangerang",
        },
  AA => {
          iso_prov_codes => "ID-JT",
          region => "Jawa Tengah",
          summary => "Magelang, Purworejo, Temanggung, Kebumen, Wonosobo",
        },
  AB => {
          iso_prov_codes => "ID-YO",
          region => "DIY",
          summary => "Yogyakarta, Bantul, Gunung Kidul, Sleman, Kulon Progo",
        },
  AD => {
          iso_prov_codes => "ID-JT",
          region => "Jawa Tengah",
          summary => "Surakarta, Sukoharjo, Boyolali, Klaten, Karanganyar, Sragen, Wonogiri",
        },
  AE => {
          iso_prov_codes => "ID-JI",
          region => "Jawa Timur",
          summary => "Madiun, Ngawi, Ponorogo, Magetan, Pacitan",
        },
  AG => {
          iso_prov_codes => "ID-JI",
          region => "Jawa Timur",
          summary => "Kediri, Blitar, Nganjuk, Tulungagung, Trenggalek",
        },
  B  => {
          iso_prov_codes => "ID-JK,ID-JB",
          region => "DKI",
          summary => "Jakarta, Depok, Bekasi",
        },
  BA => {
          iso_prov_codes => "ID-SB",
          region => "Sumatera",
          summary => "Sumatera Barat",
        },
  BB => {
          iso_prov_codes => "ID-SU",
          region => "Sumatera",
          summary => "Sumatera Utara bagian barat",
        },
  BD => { iso_prov_codes => "ID-BE", region => "Sumatera", summary => "Bengkulu" },
  BE => { iso_prov_codes => "ID-LA", region => "Sumatera", summary => "Lampung" },
  BG => {
          iso_prov_codes => "ID-SS",
          region => "Sumatera",
          summary => "Sumatera Selatan",
        },
  BH => { iso_prov_codes => "ID-JA", region => "Sumatera", summary => "Jambi" },
  BK => {
          iso_prov_codes => "ID-SU",
          region => "Sumatera",
          summary => "Sumatera Utara bagian timur",
        },
  BL => { iso_prov_codes => "ID-AC", region => "Sumatera", summary => "Aceh" },
  BM => { iso_prov_codes => "ID-RI", region => "Sumatera", summary => "Riau" },
  BN => {
          iso_prov_codes => "ID-BB",
          region => "Sumatera",
          summary => "Bangka-Belitung",
        },
  BP => {
          iso_prov_codes => "ID-KR",
          region => "Sumatera",
          summary => "Kepulauan Riau",
        },
  D  => { iso_prov_codes => "ID-JB", region => "Jawa Barat", summary => "Bandung" },
  DA => {
          iso_prov_codes => "ID-KS",
          region => "Kalimantan",
          summary => "Banjarmasin",
        },
  DB => {
          iso_prov_codes => "ID-SA",
          region => "Sulawesi",
          summary => "Manado, Bolaang Mongondow, Minahasa, Bitung",
        },
  DC => {
          iso_prov_codes => "ID-SR",
          region => "Sulawesi",
          summary => "Majumu, Polewari Mandar, Majene",
        },
  DD => {
          iso_prov_codes => "ID-SN",
          region => "Sulawesi",
          summary => "Makassar, Takalar, Giwa, Bantaeng",
        },
  DE => {
          iso_prov_codes => "ID-MA",
          region => "Maluku & Papua",
          summary => "Maluku, Serang, Ambon, Tual",
        },
  DG => {
          iso_prov_codes => "ID-MU",
          region => "Maluku & Papua",
          summary => "Ternate, Halmahera, Tidore, Murotai",
        },
  DH => {
          iso_prov_codes => "ID-NT",
          region => "Bali & NT",
          summary => "Pulau Timor, Kupang",
        },
  DK => { iso_prov_codes => "ID-BA", region => "Bali & NT", summary => "Bali" },
  DL => {
          iso_prov_codes => "ID-SA",
          region => "Sulawesi",
          summary => "Sahinge, Sitaro, Talaud",
        },
  DM => {
          iso_prov_codes => "ID-GO",
          region => "Sulawesi",
          summary => "Gorontalo, Bone Bolango",
        },
  DN => {
          iso_prov_codes => "ID-ST",
          region => "Sulawesi",
          summary => "Donggala, Palu, Poso",
        },
  DR => {
          iso_prov_codes => "ID-NB",
          region => "Bali & NT",
          summary => "Pulau Lombok, Mataram",
        },
  DT => {
          iso_prov_codes => "ID-SG",
          region => "Sulawesi",
          summary => "Kolaka, Konawe, Wakatobi, Buton, Kendari",
        },
  E  => {
          iso_prov_codes => "ID-JB",
          region => "Jawa Barat",
          summary => "Cirebon, Majalengka, Indramayu, Kuningan",
        },
  EA => {
          iso_prov_codes => "ID-NB",
          region => "Bali & NT",
          summary => "Pulau Sumbawa",
        },
  EB => {
          iso_prov_codes => "ID-NT",
          region => "Bali & NT",
          summary => "Pulau Flores",
        },
  ED => {
          iso_prov_codes => "ID-NT",
          region => "Bali & NT",
          summary => "Pulau Sumba",
        },
  F  => {
          iso_prov_codes => "ID-JB",
          region => "Jawa Barat",
          summary => "Bogor, Cianjur,\nSukabumi",
        },
  G  => {
          iso_prov_codes => "ID-JT",
          region => "Jawa Tengah",
          summary => "Pekalongan, Pemalang, Batang, Tegal, Brebes",
        },
  H  => {
          iso_prov_codes => "ID-JT",
          region => "Jawa Tengah",
          summary => "Semarang, Kendal, Salatiga, Demak",
        },
  K  => {
          iso_prov_codes => "ID-JT",
          region => "Jawa Tengah",
          summary => "Pati, Jepara, Kudus, Blora, Rembang, Grombogan",
        },
  KB => {
          iso_prov_codes => "ID-KB",
          region => "Kalimantan",
          summary => "Singkawang, Pontianak",
        },
  KH => {
          iso_prov_codes => "ID-KT",
          region => "Kalimantan",
          summary => "Palangkaraya, Kotawaringin, Barito",
        },
  KT => {
          iso_prov_codes => "ID-KI",
          region => "Kalimantan",
          summary => "Balikpapan, Kutai Kartanegara, Samarinda, Bontang, Kutai",
        },
  KU => {
          iso_prov_codes => "ID-KU",
          region => "Kalimantan",
          summary => "Kalimantan Utara",
        },
  L  => {
          iso_prov_codes => "ID-JI",
          region => "Jawa Timur",
          summary => "Surabaya",
        },
  M  => { iso_prov_codes => "ID-JI", region => "Jawa Timur", summary => "Madura" },
  N  => {
          iso_prov_codes => "ID-JI",
          region => "Jawa Timur",
          summary => "Malang, Pasuruan, Probolinggo, Lumajang",
        },
  P  => {
          iso_prov_codes => "ID-JI",
          region => "Jawa Timur",
          summary => "Bondowoso, Jember, Situbondo, Banyuwangi",
        },
  PA => {
          iso_prov_codes => "ID-PA",
          region => "Maluku & Papua",
          summary => "Jayapura, Merauke, Mimika, Paniai",
        },
  PB => {
          iso_prov_codes => "ID-PB",
          region => "Maluku & Papua",
          summary => "Papua Barat",
        },
  R  => {
          iso_prov_codes => "ID-JT",
          region => "Jawa Tengah",
          summary => "Banyumas, Purbalingga, Cilacap, Banjarnegara",
        },
  S  => {
          iso_prov_codes => "ID-JI",
          region => "Jawa Timur",
          summary => "Bojonegoro, Tuban, Mojokerto, Lamongan, Jombang",
        },
  T  => {
          iso_prov_codes => "ID-JB",
          region => "Jawa Barat",
          summary => "Purwakarta, Karawang, Subang",
        },
  W  => {
          iso_prov_codes => "ID-JI",
          region => "Jawa Timur",
          summary => "Gresik, Sidoarjo",
        },
  Z  => {
          iso_prov_codes => "ID-JB",
          region => "Jawa Barat",
          summary => "Garut, Sumedang, Tasikmalaya, Pangandaran, Ciamis, Banjar",
        },
);

our %SPEC;

$SPEC{parse_idn_vehicle_plate_number} = {
    v => 1.1,
    summary => 'Parse Indonesian vehicle plate number',
    args => {
        number => {
            summary => 'Input to be parsed',
            schema => 'str*',
            pos => 0,
            req => 1,
        },
    },
};
sub parse_idn_vehicle_plate_number {
    my %args = @_;

    defined(my $num = $args{number})
        or return [400, "Please specify number"];
    $num = uc $num;
    my $res = {};

    $num =~ s/\s+//g;

    return [400, "Missing area prefix (1-2 letters)"] unless $num =~ s/\A([A-Z]{1,2})//;
    my $prefix = $1;
    $res->{prefix} = $prefix;
    if (my $area = $prefixes{ $prefix }) {
        $res->{ind_prefix_area} = $area->{summary};
        $res->{prefix_iso_prov_codes}  = $area->{iso_prov_codes};
    } else {
        return [400, "Unknown area prefix: $prefix"];
    }

    return [400, "Missing main number (1-4 digits after prefix)"] unless $num =~ s/\A(\d{1,4})//;
    my $main = $1;
    $res->{main} = $main;
    if ($main < 1) {
        return [400, "Main number cannot be 0"];
    } elsif ($main < 2000) {
        $res->{ind_main_vehicle_type} = 'Kendaraan penumpang (1-1999)';
    } elsif ($main < 7000) {
        $res->{ind_main_vehicle_type} = 'Sepeda motor (2000-6999)';
    } elsif ($main < 8000) {
        $res->{ind_main_vehicle_type} = 'Bus (7000-7999)';
    } else {
        $res->{ind_main_vehicle_type} = 'Kendaraan beban atau pengangkut (8000-9999)';
    }

    # XXX check whether main number is a pretty number

    my $suffix = "";
  GET_SUFFIX: {
        last unless $num =~ s/\A([A-Z]{1,3})//;
        $suffix = $1;
    }
    $res->{suffix} = $suffix;

  CHECK_RF_SUFFIX: {
        last unless $suffix =~ /\ARF(.)\z/;
        my $s = $1;
        $res->{ind_suffix_vehicle_type} = 'Staf pemerintahan (RF)';
        if ($s eq 'S') {
            $res->{ind_suffix_rf_type} = 'Sekretariat Negara (S)';
        } elsif ($s =~ /\A[OHQ]\z/) {
            $res->{ind_suffix_rf_type} = 'Pejabat eselon II (O/H/Q)';
            $res->{ind_suffix_rf_type} .= ' (Kemenhan)' if $s eq 'H';
        } elsif ($s eq 'P') {
            $res->{ind_suffix_rf_type} = 'Polri (P)';
        } elsif ($s eq 'D') {
            $res->{ind_suffix_rf_type} = 'TNI AD (D)';
        } elsif ($s eq 'L') {
            $res->{ind_suffix_rf_type} = 'TNI AL (L)';
        } elsif ($s eq 'U') {
            $res->{ind_suffix_rf_type} = 'TNI AU (U)';
        } else {
            $res->{ind_suffix_rf_type} = "Tidak dikenal ($s)"
        }
    }

    if ($prefix eq 'B') {
      CHECK_JAKARTA_SUFFIX1: {
            my $s = substr($suffix, 0, 1);
            if ($s eq 'B') {
                $res->{suffix1_city} = "Jakarta Barat (B)";
            } elsif ($s eq 'P') {
                $res->{suffix1_city} = "Jakarta Pusat (P)";
            } elsif ($s eq 'S') {
                $res->{suffix1_city} = "Jakarta Selatan (S)";
            } elsif ($s eq 'T') {
                $res->{suffix1_city} = "Jakarta Timue (T)";
            } elsif ($s eq 'U') {
                $res->{suffix1_city} = "Jakarta Utara & Kepulauan Seribu (U)";
            } else {
                $res->{suffix1_city} = "Unknown ($s)";
            }
        }
      CHECK_JAKARTA_SUFFIX2: {
            last unless length($suffix) >= 2;
            my $s = substr($suffix, 1, 1);
            if ($s eq 'A') {
                $res->{ind_suffix1_vehicle_type} = "Sedan/pickup (A)";
            } elsif ($s eq 'D') {
                $res->{ind_suffix1_vehicle_type} = "Truk (D)";
            } elsif ($s eq 'F') {
                $res->{ind_suffix1_vehicle_type} = "Minibus/hatchback/city (F)";
            } elsif ($s eq 'J') {
                $res->{ind_suffix1_vehicle_type} = "Jip/SUV (J)";
            } elsif ($s eq 'Q') {
                $res->{ind_suffix1_vehicle_type} = "Kendaraan staf pemerintah (Q)";
            } elsif ($s eq 'T') {
                $res->{ind_suffix1_vehicle_type} = "Taksi (T)";
            } elsif ($s eq 'U') {
                $res->{ind_suffix1_vehicle_type} = "Kendaraan staf pemerintah (U)";
            } elsif ($s eq 'V') {
                $res->{ind_suffix1_vehicle_type} = "Minibus(V)";
            } else {
                $res->{ind_suffix1_vehicle_type} = "Tidak dikenal ($s)";
            }
        }
    }

    return [400, "Extraneous bits after suffix: $num"] if length $num;

    [200, "OK", $res];
}

1;
# ABSTRACT: Parse Indonesian vehicle plate number

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::ID::VehiclePlate - Parse Indonesian vehicle plate number

=head1 VERSION

This document describes version 0.002 of Business::ID::VehiclePlate (from Perl distribution Business-ID-VehiclePlate), released on 2024-08-05.

=head1 SYNOPSIS

 use Business::ID::VehiclePlate qw(parse_idn_vehicle_plate_number);

 my $res = parse_idn_vehicle_plate_number(number => "B 1234 SJW");

=head1 DESCRIPTION

Keywords: vehicle plate number, registered plate number

=head1 FUNCTIONS


=head2 parse_idn_vehicle_plate_number

Usage:

 parse_idn_vehicle_plate_number(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse Indonesian vehicle plate number.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<number>* => I<str>

Input to be parsed.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Business-ID-VehiclePlate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Business-ID-VehiclePlate>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-ID-VehiclePlate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
