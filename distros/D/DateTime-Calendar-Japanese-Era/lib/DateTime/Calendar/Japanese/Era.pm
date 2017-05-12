# $Id: /mirror/datetime/DateTime-Calendar-Japanese-Era/trunk/lib/DateTime/Calendar/Japanese/Era.pm 69495 2008-08-24T15:54:28.230984Z lestrrat  $
#
# Copyright (c) 2004-2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package DateTime::Calendar::Japanese::Era;
use strict;
use warnings;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use DateTime;
use DateTime::Infinite;
use Encode ();
use Exporter qw(import);
use File::ShareDir;
use Params::Validate();
use YAML ();
use constant NORTH_REGIME => 1;
use constant SOUTH_REGIME => 2;

use constant SOUTH_REGIME_START => DateTime->new(
    year => 1331, 
    month => 11, 
    day => 7, 
    time_zone => 'Asia/Tokyo'
);
use constant SOUTH_REGIME_END => DateTime->new(
    year => 1392, 
    month => 11, 
    day => 27,
    time_zone => 'Asia/Tokyo'
);
our $VERSION = '0.08003';
our @EXPORT_OK = qw(SOUTH_REGIME NORTH_REGIME);

__PACKAGE__->mk_accessors($_) for qw(id name start end);

__PACKAGE__->mk_classdata(MainDataFile =>
    File::ShareDir::dist_file('DateTime-Calendar-Japanese-Era', 'eras.yaml')
);
__PACKAGE__->mk_classdata(SouthRegimeDataFile =>
    File::ShareDir::dist_file('DateTime-Calendar-Japanese-Era', 'south-eras.yaml')
);

my(%ERAS_BY_ID, %ERAS_BY_NAME, @ERAS_BY_CENTURY, @SOUTH_REGIME_ERAS);

my %NewValidate = (
    id => { type => Params::Validate::SCALAR() },
    name => { type => Params::Validate::SCALAR() },
    start => { isa => 'DateTime' },
    end => { isa => 'DateTime' },
);

sub new
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, \%NewValidate);
    $class->SUPER::new({ %args });
}

sub clone
{
    my $self = shift;
    return ref($self)->new(
        id    => $self->id,
        name  => $self->name,
        start => $self->start->clone,
        end   => $self->end->clone
    );
}

sub lookup_by_id
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, {
        id => { type => Params::Validate::SCALAR() }
    });

    return exists $ERAS_BY_ID{ $args{id} } ?
        $ERAS_BY_ID{ $args{id} }->clone : ();
}

sub lookup_by_name
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, {
        name => { type => Params::Validate::SCALAR() },
        encoding => { optional => 1 },
    });
    my $name = $args{encoding} ?
        Encode::decode($args{encoding}, $args{name}) : $args{name};

    return exists $ERAS_BY_NAME{ $name } ?
         $ERAS_BY_NAME{ $name }->clone : ();
}

sub lookup_by_date
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, {
        datetime => { can => 'utc_rd_values' },
        regime   => { type => Params::Validate::SCALAR(), default => NORTH_REGIME }
    } );

    my $dt_utc = DateTime->from_object(object => $args{datetime});
#    $dt_utc->set_time_zone('UTC');

    my @candidates;
    if ($args{regime} == SOUTH_REGIME && $dt_utc >= SOUTH_REGIME_START && $dt_utc <= SOUTH_REGIME_END) {
        @candidates = @SOUTH_REGIME_ERAS;
    } else {
        my $century = int($dt_utc->year() / 100);
        my $r = $century >= $#ERAS_BY_CENTURY ?
            $ERAS_BY_CENTURY[$#ERAS_BY_CENTURY] :
            $ERAS_BY_CENTURY[$century];
        if (! defined($r) ) {
            return;
        }
        @candidates = @$r;
    }

    foreach my $era (@candidates) {
        if ($era->start <= $dt_utc && $era->end > $dt_utc) {
            return $era->clone;
        }
    }
    return;
}

sub register_era
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, {
        object => { isa => __PACKAGE__, optional => 1 },
        id     => { type => Params::Validate::SCALAR(), optional => 1 },
        name   => { type => Params::Validate::SCALAR(), optional => 1 },
        start  => { isa => 'DateTime', optional => 1 },
        end    => { isa => 'DateTime', optional => 1 },
    });

    my $era = delete $args{object};
    if (!exists $args{object}) {
        $era = __PACKAGE__->new(%args);
    }

    if (exists $ERAS_BY_ID{ $era->id }) {
        Carp::croak("Era with id = " . $era->id() . " already exists!");
    }
    $ERAS_BY_ID{ $era->id } = $era;

    $ERAS_BY_NAME{ $era->name } = $era;

    my $start_century = int($era->start->year() / 100);
    my $end_century   = int($era->end->year() / 100);

    $ERAS_BY_CENTURY[ $start_century ] ||= [];
    push @{ $ERAS_BY_CENTURY[ $start_century ] }, $era;

    if ($start_century != $end_century && $end_century !~ /^-?inf/) {
        $ERAS_BY_CENTURY[ $end_century ] ||= [];
        push @{ $ERAS_BY_CENTURY[ $end_century ] }, $era;
    }
}

sub registered
{
    return values (%ERAS_BY_ID);
}

sub load_from_file
{
    my($class, $file, $opts) = @_;

    my $ID    = 0;
    my $NAME  = 1;
    my $START = 2;
    my $END   = 3;
    my @eras = @{ YAML::LoadFile($file) };
    foreach my $idx (0..$#eras) {
        my $this_era = $eras[$idx];
        my $start_date = DateTime->new(
            year      => $this_era->[$START]->[0],
            month     => $this_era->[$START]->[1],
            day       => $this_era->[$START]->[2],
            time_zone => 'Asia/Tokyo'
        );

        my $end_date;
        if ($idx == $#eras) {
            $end_date = DateTime::Infinite::Future->new();
        } else {
            my $next_era = $eras[$idx + 1];
            if ($this_era->[$END]) {
                $end_date = DateTime->new(
                    year      => $this_era->[$END]->[0],
                    month     => $this_era->[$END]->[1],
                    day       => $this_era->[$END]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            } else {
                $end_date = DateTime->new(
                    year      => $next_era->[$START]->[0],
                    month     => $next_era->[$START]->[1],
                    day       => $next_era->[$START]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            }
        }

        # we create the dates in Asia/Tokyo time, but for calculation
        # we really want them to be in UTC.
#        $start_date->set_time_zone('UTC');
#        $end_date->set_time_zone('UTC');

        if ( $opts->{is_south_regime} ) {
            push @SOUTH_REGIME_ERAS, __PACKAGE__->new(
                id => $this_era->[$ID],
                name => $this_era->[$NAME],
                start => $start_date, 
                end => $end_date, 
            );
        } else {
            __PACKAGE__->register_era(
                id    => $this_era->[$ID],
                name  => $this_era->[$NAME],
                start => $start_date,
                end   => $end_date
            );
        }
        push @EXPORT_OK, $this_era->[$ID];
        constant->import( $this_era->[$ID], $this_era->[$ID]);
    }
}


{
    __PACKAGE__->load_from_file( __PACKAGE__->MainDataFile );
    __PACKAGE__->load_from_file( __PACKAGE__->SouthRegimeDataFile, { is_south_regime => 1 });
}

1;

__DATA__

__END__

=encoding utf-8

=head1 NAME

DateTime::Calendar::Japanese::Era - DateTime Extension for Japanese Eras

=head1 SYNOPSIS

  use DateTime::Calendar::Japanese::Era;
  my $era = DateTime::Calendar::Japanese::Era->lookup_by_date(
    datetime => DateTime->new(year => 1990)
  );
  my $era = DateTime::Calendar::Japanese::Era->lookup_by_id(
    id => HEISEI_ERA
  );
  my $era = DateTime::Calendar::Japanese::Era->lookup_by_name(
    name => "平成"
  );

  my $era = DateTime::Calendar::Japanese::Era->new(
    id => ...,
    start => ...,
    end   => ...
  );

  $era->id;
  $era->start;
  $era->end;

=head1 DESCRIPTION

Japan traditionally used an "era" system since 645 to denote the year. For
example, 2006 is "Heisei 18".

The era system is loosely tied to the reign of an emperor: in modern days
(since the Meiji era) eras can only be renewed when a new emperor succeeds his
predecessor. Until then new eras were proclaimed for various reasons,
including the succession of the shogunate during the Tokugawa shogunate.

=head1 NORTH AND SOUTH REGIMES

During the 60 years between 1331 and 1392, there were two regimes in Japan
claiming to be the rightful successor to the imperial throne. During this
period of time, there were two sets of eras in use.

This module by default uses eras from the North regime, but you can get the
South regime's eras if you explicitly specify it:

  use DateTime::Calendar::Japanese::Era qw(SOUTH_REGIME);
  my $dt = DateTime->new( year => 1342 );
  $era = DateTime::Calendar::Japanese::Era->lookup_by_date(
    datetime => $dt,
    regime   => SOUTH_REGIME
  );

=head1 METHODS

=head2 new

=head2 id

=head2 name

=head2 start

=head2 end

=head2 clone

=head1 FUNCTIONS

=head2 register_era

Registers a new era object in the lookup table.

=head2 registered

Returns all eras that are registered.

=head2 lookup_by_id

  $heisei = DateTime::Calendar::Japanese::Era->lookup_by_id(
    id => HEISEI
  );

Returns the era associated with the given era id. The IDs are provided by
DateTime::Calendar::Japanese::Era as constants.

=head2 lookup_by_name

  $heisei = DateTime::Calendar::Japanese::Era->lookup_by_name(
    name     => '平成',
  );

Returns the era associated with the given era name. By default UTF-8 is
assumed for the name parameter. You can override this by specifying the
'encoding' parameter.

=head2 lookup_by_date

  my $dt = DateTime->new(year => 1990);
  $heisei = DateTime::Calendar::Japanese::Era->lookup_by_date(
     datetime => $dt
  );

Returns the era associate with the given date. 

=head2 load_from_file

Loads era definitions from the specified file. For internal use only

=head1 CONSANTS

Below are the list of era IDs that are known to this module:

  TAIKA
  HAKUCHI
  SHUCHOU
  TAIHOU
  KEIUN
  WADOU
  REIKI
  YOUROU
  JINKI
  TENPYOU
  TENPYOUKANPOU
  TENPYOUSHOUHOU
  TENPYOUJOUJI
  TENPYOUJINGO
  JINGOKEIUN
  HOUKI
  TENNOU
  ENRYAKU
  DAIDOU
  KOUNIN
  TENCHOU
  JOUWA
  KASHOU
  NINJU
  SAIKOU
  TENNAN
  JOUGAN
  GANGYOU
  NINNA
  KANPYOU
  SHOUTAI
  ENGI
  ENCHOU
  SHOUHEI
  TENGYOU
  TENRYAKU
  TENTOKU
  OUWA
  KOUHOU
  ANNA
  TENROKU
  TENNEN
  JOUGEN1
  TENGEN
  EIKAN
  KANNA
  EIEN
  EISO
  SHOURYAKU
  CHOUTOKU
  CHOUHOU
  KANKOU
  CHOUWA
  KANNIN
  JIAN
  MANJU
  CHOUGEN
  CHOURYAKU
  CHOUKYU
  KANTOKU
  EISHOU1
  TENGI
  KOUHEI
  JIRYAKU
  ENKYUU
  JOUHOU
  JOURYAKU
  EIHOU
  OUTOKU
  KANJI
  KAHOU
  EICHOU
  JOUTOKU
  KOUWA
  CHOUJI
  KAJOU
  TENNIN
  TENNEI
  EIKYU
  GENNEI
  HOUAN
  TENJI
  DAIJI
  TENSHOU1
  CHOUSHOU
  HOUEN
  EIJI
  KOUJI1
  TENNYOU
  KYUAN
  NINPEI
  KYUJU
  HOUGEN
  HEIJI
  EIRYAKU
  OUHOU
  CHOUKAN
  EIMAN
  NINNAN
  KAOU
  SHOUAN1
  ANGEN
  JISHOU
  YOUWA
  JUEI
  GENRYAKU
  BUNJI
  KENKYU
  SHOUJI
  KENNIN
  GENKYU
  KENNEI
  JOUGEN2
  KENRYAKU
  KENPOU
  JOUKYU
  JOUOU1
  GENNIN
  KAROKU
  ANTEI
  KANKI
  JOUEI
  TENPUKU
  BUNRYAKU
  KATEI
  RYAKUNIN
  ENNOU
  NINJI
  KANGEN
  HOUJI
  KENCHOU
  KOUGEN
  SHOUKA
  SHOUGEN
  BUNNOU
  KOUCHOU
  BUNNEI
  KENJI
  KOUAN1
  SHOUOU
  EININ
  SHOUAN2
  KENGEN
  KAGEN
  TOKUJI
  ENKYOU1
  OUCHOU
  SHOUWA1
  BUNPOU
  GENNOU
  GENKOU
  SHOUCHU
  KARYAKU
  GENTOKU
  SHOUKEI
  RYAKUOU
  KOUEI
  JOUWA1
  KANNOU
  BUNNNA
  ENBUN
  KOUAN2
  JOUJI
  OUAN
  EIWA
  KOURYAKU
  EITOKU
  SHITOKU
  KAKEI
  KOUOU
  MEITOKU
  OUEI
  SHOUCHOU
  EIKYOU
  KAKITSU
  BUNNAN
  HOUTOKU
  KYOUTOKU
  KOUSHOU
  CHOUROKU
  KANSHOU
  BUNSHOU
  OUNIN
  BUNMEI
  CHOUKYOU
  ENTOKU
  MEIOU
  BUNKI
  EISHOU2
  DAIEI
  KYOUROKU
  TENBUN
  KOUJI2
  EIROKU
  GENKI
  TENSHOU2
  BUNROKU
  KEICHOU
  GENNA
  KANNEI
  SHOUHOU
  KEIAN
  JOUOU2
  MEIREKI
  MANJI
  KANBUN
  ENPOU
  TENNA
  JOUKYOU
  GENROKU
  HOUEI
  SHOUTOKU
  KYOUHO
  GENBUN
  KANPOU
  ENKYOU2
  KANNEN
  HOUREKI
  MEIWA
  ANNEI
  TENMEI
  KANSEI
  KYOUWA
  BUNKA
  BUNSEI
  TENPOU
  KOUKA
  KAEI
  ANSEI
  MANNEI
  BUNKYU
  GENJI
  KEIOU
  MEIJI
  TAISHO
  SHOUWA2
  HEISEI

These are the eras from the South regime during 1331-1392

  S_GENKOU
  S_KENMU
  S_EIGEN
  S_KOUKOKU
  S_SHOUHEI
  S_KENTOKU
  S_BUNCHU
  S_TENJU
  S_KOUWA
  S_GENCHU

=head1 AUTHOR

Copyright (c) 2004-2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

