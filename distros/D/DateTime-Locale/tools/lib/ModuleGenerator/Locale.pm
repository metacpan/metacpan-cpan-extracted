package    # hide from PAUSE
    ModuleGenerator::Locale;

use v5.22;

use strict;
use warnings;
use feature qw( postderef signatures );
use namespace::autoclean;

use DateTime::Locale::Util qw( parse_locale_code );
use JSON::MaybeXS qw( decode_json );
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

has _source_data_root => (
    is       => 'ro',
    isa      => t('Dir'),
    required => 1,
    init_arg => 'source_data_root',
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
    is      => 'ro',
    isa     => t('LaxVersionStr'),
    lazy    => 1,
    builder => '_build_version',
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

sub _build_cldr_json_data($self) {
    my $json = $self->_json_from( $self->_json_file );

    my $json_file_id = $self->_json_file->parent->basename;
    return $json->{main}{$json_file_id};
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
            $cal_root->{eras}{ 'era' . $era_length{$length} }->@{ 0, 1 }
            ];
    }

    return \%data;
}

sub _build_glibc_data ($self) {
    my $parent = $self->_parent_locale;

    unless ( -f $self->_glibc_file ) {
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
    $glibc_code = 'POSIX' if $self->code eq 'root';

    return $self->_source_data_root->child( 'glibc-locales', $glibc_code );
}

sub _extract_glibc_value ( $self, $key, $raw ) {
    my ($val) = $raw =~ /^\Q$key\E\s+"([^"]+?)"/m
        or return;

    $val =~ s/[\\\/]\n//g;
    $val =~ s{//}{/}g;

    $val =~ s/\<U([A-F\d]+)\>/chr(hex($1))/eg;

    return $val;
}

sub _build_version ($self) {
    return $self->_cldr_json_data->{identity}{version}{_cldrVersion};
}

sub _build_json_file ($self) {
    my $code_file = $self->_source_data_root->child(
        qw( cldr-dates-full main ),
        $self->code, 'ca-gregorian.json'
    );
    return $code_file if -f $code_file;

    my $parent_file = $self->_source_data_root->child(
        qw( cldr-dates-full main ),
        $self->_parent_code,
        'ca-gregorian.json'
    );

    unless ( -f $parent_file ) {
        die "Could not find $code_file or $parent_file for locale ",
            $self->code, "\n";
    }

    return $parent_file;
}

sub _build_parent_code ($self) {
    my $explicit_parents = $self->_explicit_parents;

    return $explicit_parents->{ $self->code }
        if $explicit_parents->{ $self->code };

    return
          $self->code =~ /-/    ? $self->code =~ s/-[^-]+$//r
        : $self->code ne 'root' ? 'root'
        :   die 'There is no parent for the root locale!';
}

sub _has_parent_code ($self) {
    return $self->code ne 'root';
}

sub _build_parent_locale ($self) {
    return unless $self->_has_parent_code;
    return ModuleGenerator::Locale->instance(
        code             => $self->_parent_code,
        source_data_root => $self->_source_data_root
    );
}

sub _explicit_parents ($self) {
    state $explicit_parents;
    return $explicit_parents if $explicit_parents;

    my $json = $self->_json_from(
        $self->_source_data_root->child(
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
    my $i = 1;
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

    my $json = $self->_json_from(
        $self->_source_data_root->child(
            qw( cldr-core supplemental weekData.json ))
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
        $self->_source_data_root->child(
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
        $file = $self->_source_data_root->child(
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
