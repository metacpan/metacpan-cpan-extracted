package    # hide from PAUSE
    ModuleGenerator::Locale;

use v5.22;

use strict;
use warnings;
use feature qw( postderef signatures );
use namespace::autoclean;

use Carp                   qw( confess );
use DateTime::Locale::Util qw( parse_locale_code );
use JSON::MaybeXS          qw( decode_json );
use List::AllUtils         qw( any first );
use Specio::Declare;
use Specio::Library::Builtins;
use Specio::Library::Perl 0.42;
use Specio::Library::Path::Tiny;

use Moose;

## no critic (TestingAndDebugging::ProhibitNoWarnings)
no warnings qw( experimental::postderef experimental::signatures );
## use critic

has code => (
    is       => 'ro',
    isa      => t('Str'),
    required => 1,
);

has _glibc_root => (
    is       => 'ro',
    isa      => t('Dir'),
    required => 1,
    init_arg => 'glibc_root',
);

has _cldr_root => (
    is       => 'ro',
    isa      => t('Dir'),
    required => 1,
    init_arg => 'cldr_root',
);

has _parent_code => (
    is      => 'ro',
    isa     => t('Str'),
    lazy    => 1,
    builder => '_build_parent_code',
);

has _parent_locale => (
    is      => 'ro',
    isa     => t( 'Maybe', of => object_isa_type('ModuleGenerator::Locale') ),
    lazy    => 1,
    builder => '_build_parent_locale',
);

has _json_file => (
    is      => 'ro',
    isa     => t('File'),
    lazy    => 1,
    builder => '_build_json_file',
);

has _glibc_file => (
    is      => 'ro',
    isa     => t('Path'),
    lazy    => 1,
    builder => '_build_glibc_file',
);

has _glibc_data => (
    is      => 'ro',
    isa     => t('HashRef'),
    lazy    => 1,
    builder => '_build_glibc_data',
);

has _parsed_code => (
    is      => 'ro',
    isa     => t( 'HashRef', of => t( 'Maybe', of => t('Str') ) ),
    lazy    => 1,
    builder => '_build_parsed_code',
);

has language_code => (
    is      => 'ro',
    isa     => t('Str'),
    lazy    => 1,
    default => sub ($self) { $self->_parsed_code->{language} },
);

has script_code => (
    is      => 'ro',
    isa     => t( 'Maybe', of => t('Str') ),
    lazy    => 1,
    default => sub ($self) { $self->_parsed_code->{script} },
);

has territory_code => (
    is      => 'ro',
    isa     => t( 'Maybe', of => t('Str') ),
    lazy    => 1,
    default => sub ($self) { $self->_parsed_code->{territory} },
);

has variant_code => (
    is      => 'ro',
    isa     => t( 'Maybe', of => t('Str') ),
    lazy    => 1,
    default => sub ($self) { $self->_parsed_code->{variant} },
);

has en_name => (
    is      => 'ro',
    isa     => t('Str'),
    lazy    => 1,
    builder => '_build_en_name',
);

has native_name => (
    is      => 'ro',
    isa     => t('Str'),
    lazy    => 1,
    builder => '_build_native_name',
);

for my $lang (qw( en native )) {
    for my $part (qw( language territory script variant )) {
        my $attr = q{_} . $lang . q{_} . $part;
        has $attr => (
            is      => 'ro',
            isa     => t( 'Maybe', of => t('Str') ),
            lazy    => 1,
            builder => '_build' . $attr,
        );
    }
}

has _cldr_json_data => (
    is      => 'ro',
    isa     => t('HashRef'),
    lazy    => 1,
    builder => '_build_cldr_json_data',
);

has _first_day_of_week => (
    is      => 'ro',
    isa     => t('Int'),
    lazy    => 1,
    builder => '_build_first_day_of_week',
);

has version => (
    is       => 'ro',
    isa      => t('LaxVersionStr'),
    required => 1,
);

has data_hash => (
    is      => 'ro',
    isa     => t('HashRef'),
    lazy    => 1,
    builder => '_build_data_hash',
);

{
    my %Cache;

    sub instance ( $class, %p ) {
        return $Cache{ $p{code} } //= $class->new(%p);
    }
}

## no critic (ValuesAndExpressions::ProhibitFiletest_f)

sub source_files ($self) {
    return grep {-f} $self->_json_file, $self->_glibc_file;
}

sub _build_cldr_json_data ($self) {
    my $json = $self->_json_from( $self->_json_file );

    my $json_file_id = $self->_json_file->parent->basename;
    my $cldr         = $json->{main}{$json_file_id};

    # https://unicode-org.atlassian.net/browse/CLDR-14361
    if (   $self->code =~ /^sd-Deva/
        && $cldr->{dates}{calendars}{gregorian}{quarters}{format}{narrow}{4}
        == 1 ) {

        $cldr->{dates}{calendars}{gregorian}{quarters}{format}{narrow}{4} = 4;
    }

    return $cldr;
}

sub _build_data_hash ($self) {
    my $cal_root = $self->_cldr_json_data->{dates}{calendars}{gregorian};

    my %data = (
        ## no critic (ValuesAndExpressions::ProhibitCommaSeparatedStatements)
        am_pm_abbreviated =>
            [ $cal_root->{dayPeriods}{format}{abbreviated}->@{ 'am', 'pm' } ],
        available_formats => $cal_root->{dateTimeFormats}{availableFormats},
        code              => $self->code,
        first_day_of_week => $self->_first_day_of_week,
        version           => $self->version,
        $self->_glibc_data->%*,
    );

    for my $thing (qw( name language script territory variant )) {
        for my $type (qw( en native )) {
            my $meth
                = ( $thing eq 'name' ? q{} : q{_} ) . $type . q{_} . $thing;
            my $key = join q{_}, ( ( $type eq 'en' ? () : $type ), $thing );
            $data{$key} = $self->$meth;
        }
    }

    for my $thing (qw( date time dateTime )) {
        for my $length (qw( full long medium short )) {
            my $val = $cal_root->{ $thing . 'Formats' }{$length};
            $data{ lc $thing . q{_format_} . $length }
                = ref $val ? $val->{_value} : $val;
        }
    }

    my %ordering = (
        day     => [qw( mon tue wed thu fri sat sun )],
        month   => [ 1 .. 12 ],
        quarter => [ 1 .. 4 ],
    );

    my @lengths = qw( abbreviated narrow wide );
    for my $thing (qw( day month quarter )) {
        for my $type (qw( format stand-alone )) {
            for my $length (@lengths) {
                my $key = join q{_}, $thing, ( $type =~ s/-/_/gr ), $length;
                $data{$key}
                    = [ $cal_root->{ $thing . 's' }{$type}{$length}
                        ->@{ $ordering{$thing}->@* } ];
            }
        }
    }

    my %era_length = (
        narrow      => 'Narrow',
        abbreviated => 'Abbr',
        wide        => 'Names',
    );
    for my $length (@lengths) {
        ## no critic (ValuesAndExpressions::ProhibitCommaSeparatedStatements)
        $data{ 'era_' . $length }
            = [
            $cal_root->{eras}{ 'era' . $era_length{$length} }->@{ 0, 1 } ];
    }

    $data{day_of_month_format_abbreviated} = $self->_days_of_month(
        $cal_root->{dayOfMonths}{format}{abbreviated} );

    return \%data;
}

# We compute all 31 strings here so that the runtime code doesn't need to know how to evaluate CLDR
# plural rules. Most locales have no dayOfMonths data, in which case each day is just the number,
# which is what the root locale's "{0}" pattern produces.
sub _days_of_month ( $self, $patterns ) {
    return [ 1 .. 31 ] unless $patterns;

    my $rules = $self->_ordinal_rules;

    my @days;
    for my $day ( 1 .. 31 ) {
        my $category = first { _plural_rule_matches( $rules->{$_}, $day ) }
            grep { $_ ne 'other' && $patterns->{$_} } keys $rules->%*;
        my $pattern = $patterns->{ $category // 'other' };
        push @days, $pattern =~ s/\{0\}/$day/r;
    }

    return \@days;
}

sub _ordinal_rules ($self) {
    my $all = $self->_all_ordinal_rules;

    my $code = $self->code;
    while (1) {
        return $all->{$code} if $all->{$code};
        last                 if $code eq 'und';
        $code = $self->_parent_of_code($code);
    }

    confess 'Could not find ordinal plural rules for ' . $self->code;
}

sub _all_ordinal_rules ($self) {
    state $all_ordinal_rules;
    return $all_ordinal_rules if $all_ordinal_rules;

    my $json
        = $self->_json_from(
        $self->_cldr_root->child(qw( cldr-core supplemental ordinals.json ))
        );

    my %rules;
    my $raw = $json->{supplemental}{'plurals-type-ordinal'};
    for my $code ( keys $raw->%* ) {
        for my $key ( keys $raw->{$code}->%* ) {
            my ($category) = $key =~ /^pluralRule-count-(.+)$/
                or confess "Unexpected ordinal rule key: $key";

            # The part after the "@" is just sample values.
            my ($condition) = split /\@/, $raw->{$code}{$key};
            $rules{$code}{$category} = $condition =~ s/^\s+|\s+$//gr;
        }
    }

    return $all_ordinal_rules = \%rules;
}

# This only handles the subset of the plural rule syntax that applies to a positive integer, which
# is all we need for days of the month. See
# https://www.unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules for the full syntax.
sub _plural_rule_matches ( $condition, $n ) {
    return 1 unless length $condition;

    # For an integer the visible fraction digits operands are all 0 and the integer digits operand
    # is the number itself.
    my %operands = (
        n => $n,
        i => $n,
        map { $_ => 0 } qw( v w f t c e ),
    );

    for my $or ( split /\s+or\s+/, $condition ) {
        my $all = 1;
        for my $relation ( split /\s+and\s+/, $or ) {
            my ( $operand, $mod, $op, $ranges )
                = $relation
                =~ /^([nivwftce])\s*(?:%\s*(\d+))?\s*(!?=)\s*([\d.,\s]+)$/
                or confess "Cannot parse plural rule relation: $relation";

            my $val = $operands{$operand};
            $val %= $mod if defined $mod;

            my $in_range = any {
                my ( $min, $max ) = split /\.\./;
                $max //= $min;
                $val >= $min && $val <= $max;
                }
                map {s/\s+//gr} split /,/, $ranges;

            if ( $op eq '=' ? !$in_range : $in_range ) {
                $all = 0;
                last;
            }
        }

        return 1 if $all;
    }

    return 0;
}

sub _build_glibc_data ($self) {
    my $parent = $self->_parent_locale;

    unless ( -f $self->_glibc_file ) {
        confess sprintf(
            'No glibc data for %s and it has no parent',
            $self->code
        ) unless $parent;
        return $parent->_glibc_data;
    }

    my $raw = $self->_glibc_file->slurp_raw;

    return {
        glibc_datetime_format =>
            $self->_extract_glibc_value( 'd_t_fmt', $raw )
            // $parent->_glibc_data->{glibc_datetime_format},
        glibc_date_format => $self->_extract_glibc_value( 'd_fmt', $raw )
            // $parent->_glibc_data->{glibc_date_format},
        glibc_date_1_format => $self->_extract_glibc_value( 'date_fmt', $raw )
            // $parent->_glibc_data->{glibc_date_1_format},
        glibc_time_format => $self->_extract_glibc_value( 't_fmt', $raw )
            // $parent->_glibc_data->{glibc_time_format},
        glibc_time_12_format =>
            $self->_extract_glibc_value( 't_fmt_ampm', $raw )
            // $parent->_glibc_data->{glibc_time_12_format},
    };
}

sub _build_glibc_file ($self) {
    my $glibc_code = join '_', grep {defined} $self->language_code,
        $self->territory_code;
    if ( my $script = $self->_en_script ) {
        $glibc_code .= '@' . lc $script;
    }

    # This ensures some sort of sanish fallback
    $glibc_code = 'POSIX' if $self->code eq 'und';

    return $self->_glibc_root->child($glibc_code);
}

sub _extract_glibc_value ( $self, $key, $raw ) {
    my ($val) = $raw =~ /^\Q$key\E\s+"([^"]+?)"/m
        or return;

    $val =~ s/[\\\/]\n//g;
    $val =~ s{//}{/}g;

    $val =~ s/\<U([A-F\d]+)\>/chr(hex($1))/eg;

    return $val;
}

sub _build_json_file ($self) {
    my $code_file = $self->_gregorian_file_for_code( $self->code );
    return $code_file if -f $code_file;

    my $parent_file = $self->_gregorian_file_for_code( $self->_parent_code );
    unless ( -f $parent_file ) {
        confess "Could not find $code_file or $parent_file for locale ",
            $self->code, "\n";
    }

    return $parent_file;
}

sub _build_parent_code ($self) {
    my $code = $self->code;
    while ( $code = $self->_parent_of_code($code) ) {
        my $parent_file = $self->_gregorian_file_for_code($code);
        return $code if -f $parent_file;
    }

    # This is impossible because we should always be able to find und as a
    # parent.
    confess 'Impossible! Could not find a parent!';
}

sub _parent_of_code ( $self, $code ) {
    my $explicit_parents = $self->_explicit_parents;

    return $explicit_parents->{$code}
        if $explicit_parents->{$code};

    return
          $code =~ /-/   ? $code =~ s/-[^-]+$//r
        : $code ne 'und' ? 'und'
        :                  confess 'There is no parent for the und locale!';
}

sub _gregorian_file_for_code ( $self, $code ) {
    return $self->_cldr_root->child(
        qw( cldr-dates-full main ),
        $code,
        'ca-gregorian.json'
    );
}

sub _build_parent_locale ($self) {
    return unless $self->_has_parent_code;
    return ModuleGenerator::Locale->instance(
        code       => $self->_parent_code,
        cldr_root  => $self->_cldr_root,
        glibc_root => $self->_glibc_root,
        version    => $self->version,
    );
}

sub _has_parent_code ($self) {
    return $self->code ne 'und';
}

sub _explicit_parents ($self) {
    state $explicit_parents;
    return $explicit_parents if $explicit_parents;

    my $json = $self->_json_from(
        $self->_cldr_root->child(
            qw( cldr-core supplemental parentLocales.json ))
    );

    return $explicit_parents
        = $json->{supplemental}{parentLocales}{parentLocale};
}

sub _build_parsed_code ($self) {
    my %parsed = parse_locale_code( $self->code );
    return \%parsed;
}

{
    my $i    = 1;
    my %days = map { $_ => $i++ } qw( mon tue wed thu fri sat sun );

    sub _build_first_day_of_week {
        my $self = shift;

        my $terr = $self->territory_code;
        return 1 unless defined $terr;

        my $index = $self->_first_day_of_week_index;
        return $index->{$terr} ? $days{ $index->{$terr} } : 1;
    }
}

sub _first_day_of_week_index ($self) {
    state $first_day_of_week_index;
    return $first_day_of_week_index if $first_day_of_week_index;

    my $json
        = $self->_json_from(
        $self->_cldr_root->child(qw( cldr-core supplemental weekData.json ))
        );

    return $first_day_of_week_index
        = $json->{supplemental}{weekData}{firstDay};
}

sub _build_en_name ($self) {
    return join q{ }, grep {defined} $self->_en_language,
        $self->_en_territory, $self->_en_script, $self->_en_variant;
}

sub _build_en_language ($self) {
    return unless $self->language_code;
    return $self->_en_languages_data->{ $self->language_code };
}

sub _build_en_territory ($self) {
    return unless $self->territory_code;
    return $self->_en_territories_data->{ $self->territory_code };
}

sub _build_en_script ($self) {
    return unless $self->script_code;
    return $self->_en_scripts_data->{ $self->script_code };
}

sub _build_en_variant ($self) {
    return unless $self->variant_code;
    return $self->_en_variants_data->{ $self->variant_code };
}

sub _en_languages_data ($self) {
    state $en_languages_data;
    return $en_languages_data //= $self->_populate_en_lookup('languages');
}

sub _en_territories_data ($self) {
    state $en_territories_data;
    return $en_territories_data //= $self->_populate_en_lookup('territories');
}

sub _en_scripts_data ($self) {
    state $en_scripts_data;
    return $en_scripts_data //= $self->_populate_en_lookup('scripts');
}

sub _en_variants_data ($self) {
    state $en_variants_data;
    return $en_variants_data //= $self->_populate_en_lookup('variants');
}

sub _populate_en_lookup ( $self, $type ) {
    my $json = $self->_json_from(
        $self->_cldr_root->child(
            qw( cldr-localenames-full main en ), $type . '.json'
        )
    );
    return $json->{main}{en}{localeDisplayNames}{$type};
}

sub _build_native_name ($self) {
    return join q{ }, grep {defined} $self->_native_language,
        $self->_native_territory, $self->_native_script,
        $self->_native_variant;
}

sub _build_native_language ($self) {
    return unless $self->language_code;
    return $self->_native_lookup('languages')->{ $self->language_code };
}

sub _build_native_territory ($self) {
    return unless $self->territory_code;
    return $self->_native_lookup('territories')->{ $self->territory_code };
}

sub _build_native_script ($self) {
    return unless $self->script_code;
    return $self->_native_lookup('scripts')->{ $self->script_code };
}

sub _build_native_variant ($self) {
    return unless $self->variant_code;
    return $self->_native_lookup('variants')->{ $self->variant_code };
}

sub _native_lookup ( $self, $type ) {
    my $file;
    my $locale = $self;
    while ($locale) {
        $file = $self->_cldr_root->child(
            qw( cldr-localenames-full main  ),
            $locale->code, $type . '.json'
        );

        last if -f $file;
        $locale = $locale->_parent_locale;
    }
    return {} unless -f $file;

    my $json = $self->_json_from($file);
    return $json->{main}{ $locale->code }{localeDisplayNames}{$type};
}

sub _json_from ( $self, $file ) {
    return decode_json( $file->slurp_raw );
}

__PACKAGE__->meta->make_immutable;

1;
