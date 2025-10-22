package Date::Find 0.01;
use 5.020;
use experimental 'signatures';

use utf8; # we store month names in this file

use Exporter 'import';
use Carp 'croak';
our @EXPORT_OK = qw(find_ymd find_all_ymd guess_ymd
                    %date_type %longname
                   );

=head1 NAME

Date::Find - find year, month, day from (filename) strings

=head1 SYNOPSIS

  use 5.020;

  my $info = guess_ymd('statement_20221201.pdf');
  say "$info->{value} - $info->{year} - $info->{month} - $info->{day}";
  # statement_20221201.pdf - 2022 - 12 - 01

  my @dates = guess_ymd(['statement_20221201.pdf',
                         'statement_02.12.2022.pdf',
                         'random.pdf',
                       ], components => 'ym');
  for my $info (@dates) {
      say "$info->{value} - $info->{year} - $info->{month}";
  }
  # statement_20221201.pdf - 2022 - 12 - 00
  # statement_02.12.2022.pdf - 2022 - 12 - 00

  my @dates = guess_ymd(['statement_20221201.pdf',
                         'statement_02.12.2022.pdf',
                         'random.pdf',
                       ], components => 'ym', mode => 'strict');
  for my $info (@dates) {
      say "$info->{value} - $info->{year} - $info->{month}";
  }
  # statement_20221201.pdf - 2022 - 12 - 00
  # statement_02.12.2022.pdf - 2022 - 12 - 00

=cut

our %month_names = (
    # English
    'january'   => 1,
    'february'  => 2,
    'march'     => 3,
    'april'     => 4,
    'may'       => 5,
    'june'      => 6,
    'july'      => 7,
    'august'    => 8,
    'september' => 9,
    'october'   => 10,
    'november'  => 11,
    'december'  => 12,

    # German
    'januar'    => 1,
    'februar'   => 2,
    'maerz'     => 3,
    'märz'      => 3,
    'april'     => 4,
    'mai'       => 5,
    'juni'      => 6,
    'juli'      => 7,
    'august'    => 8,
    'september' => 9,
    'oktober'   => 10,
    'november'  => 11,
    'dezember'  => 12,
);

our $dxy =
    qr/(?<day>[12]\d|3[01]|0?\d)(?:[.]?)\s*/
    . "(?<monthname>(?i)"
    . join( "|",
          map { /^(...)(.*)$/; $2 ? "$1($2)?" : $1  } reverse sort keys %month_names)
    . ")"
    . qr/\s+(?<year>(?:20)\d\d)\b/
    ;

# Februar 27, 2023
our $xdy =
      "(?<monthname>(?i)"
    . join( "|",
          map { /^(...)(.*)$/; $2 ? "$1($2)?" : $1  } reverse sort keys %month_names)
    . ")"
    . qr/\s*(?<day>[12]\d|3[01]|0?\d)(?:[.,]?)\s*/
    . qr/\s+(?<year>(?:20)\d\d)\b/
    ;

our %date_type = (
    ymd => qr/(?<year>(?:20)\d\d)([-]?)(?<month>0\d|1[012])(\2)(?<day>[012]\d|3[01])/,
    dmy => qr/(?<day>[012]\d|3[01])([-.]?)(?<month>0\d|1[012])(\2)(?<year>(?:20)\d\d)/,
    dxy => $dxy,
    xdy => $xdy,
    ym  => qr/(?<year>(?:20)\d\d)([-]?)(?<month>0\d|1[012])/,
    my  => qr/(?<month>0\d|1[012])([-.]?)(?<year>(?:20)\d\d)/,
    y   => [qr/\D(?<year>(?:20)\d\d)\D/, qr/(?<year>(?:20)\d\d)/],
);


our @default_preference = sort { length $b <=> length $a || $b cmp $a } keys %date_type;

# Should we also support hour, minute, second?!
our %longname = (
    'y' => 'year',
    'm' => 'month',
    'x' => 'monthname',
    'd' => 'day',
);

=head2 C<< find_ymd >>


=cut

sub find_ymd( $date_regex, $source, $date_regex_order='ymd' ) {
    if( $source !~ /$date_regex/ ) {
        return;
    }

    my %ymd;
    if( keys %- ) { # we have named captures
        for (keys %longname) {
            $ymd{ $longname{ $_ } } //= $+{ $longname{ $_ }} // $+{ $_ };
        }
    } else {
        my @ymd = split //, $date_regex_order;
        for my $i (0..$#ymd) {
            $ymd{ $longname{ $ymd[$i] }} //= substr( $source, $-[$i+1], $+[$i+1] );
        }
    };

    # map month names to month numbers
    if( $ymd{monthname} ) {

        if( ! exists $month_names{ lc $ymd{ monthname }}) {
            die "Whoops unknown month '$ymd{ monthname }'";
        };

        $ymd{month} = $month_names{ lc( delete $ymd{ monthname })};
    } else {
        delete $ymd{ monthname };
    }

    $ymd{ year } += 2000 if $ymd{ year } < 100;
    for my $n ( values %longname ) {
        next if $n eq 'monthname';

        $ymd{ $n } = sprintf '%02d', $ymd{ $n };
    };

    delete $ymd{ monthname };

    return \%ymd;
}

sub find_all_ymd( $source, %options ) {
    # $options{ preference } //= \@default_preference;
    my %res;
    for my $dt (sort keys %date_type) {
        my @attempts = ref $date_type{ $dt } eq 'ARRAY' ? @{ $date_type{ $dt } } : $date_type{ $dt };
        for my $candidate (@attempts) {
            my $r = find_ymd( $candidate, $source );
            if( $r ) {
                $res{ $dt } = $r;
                last
            }
        }
    }

    #if( $options{ }) {
    #}
    return %res
}

sub guess_date_format( $sources, %options ) {
    $sources = [$sources] unless ref $sources eq 'ARRAY';
    my %res;
    for my $s (@$sources) {
        my %fmts = find_all_ymd( $s );
        if( scalar keys %fmts ) {
            for (keys %fmts) {
                $res{ $_ } //= [];
                push @{$res{$_}}, { value => $s, %{$fmts{ $_ }} };
            }
        } else {
            $res{ 'no_date' } //= [];
            push @{$res{$_}}, { value => $s, date => undef };
        }
    }
    return \%res
}

sub guess_ymd( $sources, %options ) {
    $options{ mode } //= 'lax';
    $options{ preference } //= \@default_preference;

    croak "Need an array of filenames"
        unless defined $sources;
    $sources = [$sources] unless ref $sources eq 'ARRAY';
    my $values = guess_date_format( $sources, %options );

    my $fmt;
    if( $values->{no_date} and @{ $values->{no_date}} and $options{ mode } eq 'strict') {
        # Maybe we don't want croak?!
        croak "Entries without a date found: " . join " ", @{ $values->{no_date} };
    };
    delete $values->{no_date}; # we can't do anything about them

    if( scalar keys %$values == 1 ) {
        # Only one kind of format, so we use that
        ($fmt) = keys %$values;
    } elsif( $options{ components }) {
        # Find all entries that have the wanted components and be done with it
        my $s = join "", sort split //, $options{ components };
        my %res;
        for my $dt (sort { length $b <=> length $a || $a cmp $b } keys %$values) {
            my $comp = join "", sort split //, $dt;
            if( $comp =~ /$s/ ) {
                $res{ $_->{value} } //= $_
                    for @{$values->{$dt}};
            }
        }
        my @res = map { $res{ $_ } ? $res{ $_ } : () } @$sources;
        return wantarray ? @res : $res[0];


    } else {
        (my $max) = sort { @$b <=> @$a } values %$values;
        $max = @$max;

        my %mode = map { $_ => 1 } grep { @{$values->{$_}} == $max } keys %$values;
        my @fmt = grep { $mode{ $_ }} @{ $options{ preference }};
        if( scalar keys %mode != 1 && $options{mode} eq 'strict') {
            croak "Multiple possibilities found, specify one: " . join ",", keys %mode;
        } else {
            $fmt = $fmt[0]
        }
    }
    return wantarray ? @{ $values->{$fmt} } : $values->{$fmt}->[0];
}

1;

=head1 SEE ALSO

L<Date::Extract> - extract dates from more arbitrary text

L<Filename::Timestamp> - extract date and time from filenames, with timezone

=cut
