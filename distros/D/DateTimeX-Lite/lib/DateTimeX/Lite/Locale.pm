# $Id: Locale.pm 30361 2009-02-20 08:13:39Z tokuhirom $

package DateTimeX::Lite::Locale;
use strict;
use warnings;
use File::ShareDir qw(dist_file);
use File::Spec;
use Carp ();

our %CachedLocales;
our %Aliases;

{
    my $db = dist_file('DateTimeX-Lite', 'DateTimeX/Lite/Locale/Aliases.dat');
    my $aliases = do $db
        or die "cannot load alias database";
    %Aliases = %$aliases;
}

sub _load_locale {
    my $name = shift;

    # XXX - original comment as follows:
    # Support RFC 3066 language tags, which use '-' instead of '_'
    $name =~ tr/-/_/;

    # Strip off charset for LC_* ids : en_GB.UTF-8 etc
    $name =~ s/\..*$//;

    my $original = $name;
    while (exists $Aliases{$name}) {
        $name = $Aliases{$name};
    }

    my ($language, $script, $territory, $variant ) = _parse_id($name);

    my @guesses;

    if ( defined $script )
    {
        my $guess = join '_', lc $language, ucfirst lc $script;

        push @guesses, $guess;

        $guess .= '_' . uc $territory if defined $territory;

        # version with script comes first
        unshift @guesses, $guess;
    }

    if ( defined $variant )
    {
        push @guesses,
            join '_', lc $language, uc $territory, uc $variant;
    }

    if ( defined $territory )
    {
        push @guesses,
            join '_', lc $language, uc $territory;
    }

    push @guesses, lc $language;

    foreach my $id (@guesses) {
        my $h;
        $h = do "DateTimeX/Lite/Locale/$id.dat";
        if (! $@ && $h) {
            $h->{id} = $original if $original ne $name;
            return $h;
        }
    }
    return ();
}

sub load {
    my ($class, $name) = @_;

    return $CachedLocales{$name} if $CachedLocales{$name};

    my $conf = _load_locale($name);
    if (! $conf) {
        Carp::croak("Invalid locale name or id: locale $name not found");
    }
    return $CachedLocales{$name} = $class->new(%$conf);
}

use List::MoreUtils ();

BEGIN
{
    foreach my $field ( qw( id en_complete_name native_complete_name
                            en_language en_script en_territory en_variant
                            native_language native_script native_territory native_variant
                          )
                      )
    {
        # remove leading 'en_' for method name
        (my $meth_name = $field) =~ s/^en_//;

        # also remove 'complete_'
        $meth_name =~ s/complete_//;

        no strict 'refs';
        *{$meth_name} = sub { $_[0]->{$field} } }
}

sub new
{
    my $class = shift;

    # By making the default format lengths part of the object's hash
    # key, it allows them to be settable.
    my $self = bless { @_,
        default_date_format_length => 'medium',
        default_time_format_length => 'medium',
    }, $class;

    $self->{native_language} = $self->{en_language}
        unless exists $self->{native_language};
    
    my @en_pieces;
    my @native_pieces;
    foreach my $p ( qw( language script territory variant ) )
    {
        push @en_pieces, $self->{"en_$p"} if exists $self->{"en_$p"};
        push @native_pieces, $self->{"native_$p"} if exists $self->{"native_$p"};
    }

    $self->{en_complete_name} = join ' ', @en_pieces;
    $self->{native_complete_name} = join ' ', @native_pieces;

    return $self;
}

sub language_id  { ( DateTimeX::Lite::Locale::_parse_id( $_[0]->id ) )[0] }
sub script_id    { ( DateTimeX::Lite::Locale::_parse_id( $_[0]->id ) )[1] }
sub territory_id { ( DateTimeX::Lite::Locale::_parse_id( $_[0]->id ) )[2] }
sub variant_id   { ( DateTimeX::Lite::Locale::_parse_id( $_[0]->id ) )[3] }
sub _parse_id
{
    $_[0] =~ /([a-z]+)               # id
              (?: _([A-Z][a-z]+) )?  # script - Title Case - optional
              (?: _([A-Z]+) )?       # territory - ALL CAPS - optional
              (?: _([A-Z]+) )?       # variant - ALL CAPS - optional
             /x;

    return $1, $2, $3, $4;
}


my @FormatLengths = qw( short medium long full );

sub date_format_default {
    my $default = $_[0]->default_date_format_length();
    if (! $default) {
        die sprintf("DateTimeX::Lite::Locale %s did not return a proper value from default_date_format_length()", $_[0]->{id});
    }
    my $meth = "date_format_$default";
    $_[0]->$meth();
}

sub date_formats
{
    return
        { map { my $meth = 'date_format_' . $_;
                $_ => $_[0]->$meth() } @FormatLengths }
}

sub time_format_default
{
    my $default = $_[0]->default_time_format_length();
    if (! $default) {
        die sprintf("DateTimeX::Lite::Locale %s did not return a proper value from default_time_format_length()", $_[0]->{name});
    }
    my $meth = "time_format_$default";
    $_[0]->$meth();
}

sub time_formats
{
    return
        { map { my $meth = 'time_format_' . $_;
                $_ => $_[0]->$meth() } @FormatLengths }
}

sub format_for
{
    my $self = shift;
    my $for  = shift;

    my $meth = '_format_for_' . $for;

    return unless $self->can($meth);

    return $self->$meth();
}

sub available_formats
{
    my $self = shift;

    # The various parens seem to be necessary to force uniq() to see
    # the caller's list context. Go figure.
    my @uniq = List::MoreUtils::uniq( map { keys %{ $_->_available_formats() || {} } }
                                      Class::ISA::self_and_super_path( ref $self )
    );

    # Doing the sort in the same expression doesn't work under 5.6.x.
    return sort @uniq;
}

# Just needed for the above method.
sub _available_formats { }

sub default_date_format_length { $_[0]->{default_date_format_length} }

sub set_default_date_format_length
{
    my ($self, $l) = @_;
    die unless $l =~ /^(?:full|long|medium|short)$/i;

    $self->{default_date_format_length} = lc $l;
}

sub default_time_format_length { $_[0]->{default_time_format_length} }

sub set_default_time_format_length
{
    my ($self, $l) = @_;
    die unless $l =~ /^(?:full|long|medium|short)$/i;

    $self->{default_time_format_length} = lc $l;
}

for my $length ( qw( full long medium short ) )
{
    my $key = 'datetime_format_' . $length;

    my $sub =
        sub { my $self = shift;

              return $self->{$key} if exists $self->{$key};

              my $date_meth = 'date_format_' . $length;
              my $time_meth = 'time_format_' . $length;

              return $self->{$key} = $self->_make_datetime_format( $date_meth, $time_meth );
            };

    no strict 'refs';
    *{$key} = $sub;
}

sub datetime_format_default
{
    my $self = shift;

    my $date_meth = 'date_format_' . $self->default_date_format_length();
    my $time_meth = 'time_format_' . $self->default_time_format_length();

    return $self->_make_datetime_format( $date_meth, $time_meth );
}

sub _make_datetime_format
{
    my $self      = shift;
    my $date_meth = shift;
    my $time_meth = shift;

    my $dt_format = $self->datetime_format();

    my $time = $self->$time_meth();
    my $date = $self->$date_meth();

    $dt_format =~ s/\{0\}/$time/g;
    $dt_format =~ s/\{1\}/$date/g;

    return $dt_format;
}

sub prefers_24_hour_time
{
    my $self = shift;

    return $self->{prefers_24_hour_time}
        if exists $self->{prefers_24_hour_time};

    $self->{prefers_24_hour_time} =
        $self->time_format_short() =~ /h|K/ ? 0 : 1;
}

sub date_before_time
{
    my $self = shift;

    my $dt_format = $self->datetime_format();

    return $dt_format =~ /\{1\}.*\{0\}/ ? 1 : 0;
}

sub date_parts_order
{
    my $self = shift;

    my $short = $self->date_format_short();

    $short =~ tr{dmyDMY}{}cd;
    $short =~ tr{dmyDMY}{dmydmy}s;

    return $short;
}

sub full_date_format   { $_[0]->_convert_to_strftime( $_[0]->date_format_full() ) }
sub long_date_format   { $_[0]->_convert_to_strftime( $_[0]->date_format_long() ) }
sub medium_date_format { $_[0]->_convert_to_strftime( $_[0]->date_format_medium() ) }
sub short_date_format  { $_[0]->_convert_to_strftime( $_[0]->date_format_short() ) }
sub default_date_format { $_[0]->_convert_to_strftime( $_[0]->date_format_default() ) }

sub full_time_format   { $_[0]->_convert_to_strftime( $_[0]->time_format_full() ) }
sub long_time_format   { $_[0]->_convert_to_strftime( $_[0]->time_format_long() ) }
sub medium_time_format { $_[0]->_convert_to_strftime( $_[0]->time_format_medium() ) }
sub short_time_format  { $_[0]->_convert_to_strftime( $_[0]->time_format_short() ) }
sub default_time_format { $_[0]->_convert_to_strftime( $_[0]->time_format_default() ) }

sub full_datetime_format   { $_[0]->_convert_to_strftime( $_[0]->datetime_format_full() ) }
sub long_datetime_format   { $_[0]->_convert_to_strftime( $_[0]->datetime_format_long() ) }
sub medium_datetime_format { $_[0]->_convert_to_strftime( $_[0]->datetime_format_medium() ) }
sub short_datetime_format  { $_[0]->_convert_to_strftime( $_[0]->datetime_format_short() ) }
sub default_datetime_format { $_[0]->_convert_to_strftime( $_[0]->datetime_format_default() ) }

# Older versions of DateTime.pm will not pass in the $cldr_ok flag, so
# we will give them the converted-to-strftime pattern (bugs and all).
sub _convert_to_strftime
{
    my $self    = shift;
    my $pattern = shift;
    my $cldr_ok = shift;

    return $pattern if $cldr_ok;

    return $self->{_converted_patterns}{$pattern}
        if exists $self->{_converted_patterns}{$pattern};

    return $self->{_converted_patterns}{$pattern} = $self->_cldr_to_strftime($pattern);
}

{
    my @JavaPatterns =
        ( qr/G/     => '{era}',
          qr/yyyy/  => '{ce_year}',
          qr/y/     => 'y',
          qr/u/     => 'Y',
          qr/MMMM/  => 'B',
          qr/MMM/   => 'b',
          qr/MM/    => 'm',
          qr/M/     => '{month}',
          qr/dd/    => 'd',
          qr/d/     => '{day}',
          qr/hh/    => 'l',
          qr/h/     => '{hour_12}',
          qr/HH/    => 'H',
          qr/H/     => '{hour}',
          qr/mm/    => 'M',
          qr/m/     => '{minute}',
          qr/ss/    => 'S',
          qr/s/     => '{second}',
          qr/S/     => 'N',
          qr/EEEE/  => 'A',
          qr/E/     => 'a',
          qr/D/     => 'j',
          qr/F/     => '{weekday_of_month}',
          qr/w/     => 'V',
          qr/W/     => '{week_month}',
          qr/a/     => 'p',
          qr/k/     => '{hour_1}',
          qr/K/     => '{hour_12_0}',
          qr/z/     => '{time_zone_long_name}',
        );

    sub _cldr_to_strftime
    {
        shift;
        my $simple = shift;

        $simple =~
            s/(G+|y+|u+|M+|d+|h+|H+|m+|s+|S+|E+|D+|F+|w+|W+|a+|k+|K+|z+)|'((?:[^']|'')*)'/
                $2 ? _stringify($2) : $1 ? _convert($1) : "'"/eg;

        return $simple;
    }

    sub _convert
    {
        my $simple = shift;

        for ( my $x = 0; $x < @JavaPatterns; $x += 2 )
        {
            return '%' . $JavaPatterns[ $x + 1 ] if $simple =~ /$JavaPatterns[$x]/;
        }

        die "**Dont know $simple***";
    }

    sub _stringify
    {
        my $string = shift;

        $string =~ s/%(?:[^%])/%%/g;
        $string =~ s/\'\'/\'/g;

        return $string;
    }
}

foreach my $field (qw(
am_pm_abbreviated
date_format_full
date_format_long
date_format_medium
date_format_short
datetime_format
day_format_abbreviated
day_format_narrow
day_format_wide
day_stand_alone_abbreviated
day_stand_alone_narrow
day_stand_alone_wide
era_abbreviated
era_narrow
era_wide
first_day_of_week
month_format_abbreviated
month_format_narrow
month_format_wide
month_stand_alone_abbreviated
month_stand_alone_narrow
month_stand_alone_wide
quarter_format_abbreviated
quarter_format_narrow
quarter_format_wide
quarter_stand_alone_abbreviated
quarter_stand_alone_narrow
quarter_stand_alone_wide
time_format_full
time_format_long
time_format_medium
time_format_short
_format_for_Hm
_format_for_Hms
_format_for_M
_format_for_MEd
_format_for_MMM
_format_for_MMMEd
_format_for_MMMMEd
_format_for_MMMMd
_format_for_MMMd
_format_for_MMdd
_format_for_Md
_format_for_d
_format_for_hm
_format_for_ms
_format_for_y
_format_for_yM
_format_for_yMEd
_format_for_yMMM
_format_for_yMMMEd
_format_for_yMMMM
_format_for_yQ
_format_for_yQQQ
_format_for_yyMMM
_format_for_yyyyMM
_format_for_yyyyMMMM
)) {
    no strict 'refs';
    *{$field} = sub { 
        my $v = $_[0]->{$field};
        # XXX - This SUCKS. I need to fix up update-locale.pl to return
        # the value from the other aliases method
        if (defined $v && $v =~ /^alias:([^:]+)$/) {
            return $_[0]->$1;
        }
        return $v;
    }
}

sub month_name { $_[0]->month_format_wide()->[ $_[1]->month - 1 ] }
sub month_abbreviation { $_[0]->month_format_abbreviated()->[ $_[1]->month - 1 ] }
sub day_name { $_[0]->day_format_wide()->[ $_[1]->day_of_week - 1 ] }
sub day_abbreviation { $_[0]->day_format_abbreviated->[ $_[1]->day_of_week - 1 ] }


sub add_aliases {
    my $self = shift;
    my $aliases = ref $_[0] ? $_[0] : {@_};

    while ( my ( $alias, $id ) = each %$aliases )
    {
        die "Can't alias an id to itself"
            if $alias eq $id;

        # check for overwrite?

        my %seen = ( $alias => 1, $id => 1 );
        my $copy = $id;
        while ( $copy = $Aliases{$copy} )
        {
            die "Creating an alias from $alias to $id would create a loop.\n"
                if $seen{$copy};

            $seen{$copy} = 1;
        }
        $Aliases{$alias} = $id;
    }
}

sub remove_alias {
    my ($self, $id) = @_;
    delete $CachedLocales{$id};
    delete $Aliases{$id};
}


1;

__END__

=head1 NAME

DateTimeX::Lite::Locale - Locale

=head1 CAVEATS

=over 4

=item ids() is not implemented

=item names() is not implemented

=item backwards compatible loading (by language) is not implemented

=back

=cut
