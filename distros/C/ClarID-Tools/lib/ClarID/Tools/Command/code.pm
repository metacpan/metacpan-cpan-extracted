package ClarID::Tools::Command::code;
use strict;
use warnings;
use feature qw(say);
use ClarID::Tools;
use ClarID::Tools::Util qw(load_yaml_file load_json_file);
use Moo;
use MooX::Options
  auto_help        => 1,
  version          => $ClarID::Tools::VERSION,
  usage            => 'pod',
  config_from_hash => {};
use Text::CSV_XS;
use Carp                   qw(croak);
use Types::Standard        qw(Str Int Enum HashRef Undef ArrayRef);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use IO::Compress::Gzip     qw(gzip   $GzipError);
use JSON::XS               qw(decode_json);
use File::Spec::Functions  qw(catdir catfile);

# Tell App::Cmd this is a command
use App::Cmd::Setup -command;
use namespace::autoclean;

# Set development mode
use constant DEVEL_MODE => 0;

# CLI options
# NB: Invalid parameter values (e.g., --format=foo) trigger App::Cmd usage/help
# This hides the detailed Types::Standard error
# Fix by overriding usage_error/options_usage
#
# Example (Types::Standard):
# perl -Ilib -MClarID::Tools::Command::code -we \
# 'ClarID::Tools::Command::code->new(format=>"stube", action=>"encode", entity=>"biosample")'
#
# Value "stube" did not pass type constraint "Enum["human","stub"]" (in $args->{"format"}) at -e line 1
#    "Enum["human","stub"]" requires that the value is equal to "human" or "stub"
option entity => (
    is     => 'ro',
    format => 's',
    isa    => Enum [qw/biosample subject biospecimen individual/],
    coerce => sub {
        return 'biosample' if $_[0] eq 'biospecimen';
        return 'subject'   if $_[0] eq 'individual';
        return $_[0];
    },
    doc =>
'biosample | subject (accepts synonyms: biospecimen -> biosample; individual -> subject)',
    required => 1,
);
option format => (
    is       => 'ro',
    format   => 's',
    isa      => Enum [qw/human stub/],
    doc      => 'human | stub',
    required => 1,
);
option action => (
    is       => 'ro',
    format   => 's',
    isa      => Enum [qw/encode decode/],
    doc      => 'encode | decode',
    required => 1,
);
option codebook => (
    is     => 'ro',
    format => 's',
    isa    => HashRef,
    coerce => sub {
        my $cb = load_yaml_file( $_[0] );
        _apply_defaults($cb);
        return $cb;
    },
    doc     => 'path to codebook.yaml',
    default =>
      sub { catfile( $ClarID::Tools::share_dir, 'clarid-codebook.yaml' ) },
    required => 1,
);
option infile => (
    is     => 'ro',
    format => 's',
    isa    => Undef | Str,
    doc    => 'bulk input CSV/TSV',
);
option outfile => (
    is     => 'ro',
    format => 's',
    isa    => Undef | Str,
    doc    => 'bulk output file',
);
option sep => (
    is      => 'ro',
    format  => 's',
    isa     => Str,
    default => sub { ',' },
    doc     => 'separator',
);
option icd10_map => (
    is      => 'ro',
    format  => 's',
    isa     => Str,
    default => sub { catfile( $ClarID::Tools::share_dir, 'icd10.json' ) },
    doc     => 'path to ICD-10 map JSON',
);
option with_condition_name => (
    is      => 'ro',
    is_flag => 1,
    doc     => 'append human-readable condition_name on decode',
);
option subject_id_base62_width => (
    is      => 'ro',
    format  => 'i',
    default => sub { 3 },
    doc     => 'number of Base-62 characters to use for subject ID stubs',
);
option subject_id_pad_length => (
    is      => 'ro',
    format  => 'i',
    default => sub { 5 },
    doc     =>
      'decimal padding width for subject IDs in biosample/subject human format',
);
option clar_id => (
    is     => 'ro',
    format => 's',
    isa    => Undef | Str,
    doc    => 'ID to decode (use --clar_id or --stub_id)',
    short  => 'stub_id',
);

# Always load the ICD-10 order map at startup (JSON::XS parses ~70K entries in ~100 ms on modern hardware), simplifying stub logic.
# This one-time cost (~0.1 s, ~10 MB RAM) is negligible compared to the complexity of conditional or lazy loading.
option icd10_order => (
    is      => 'ro',
    format  => 's',
    isa     => HashRef,
    coerce  => \&load_json_file,
    default => sub { catfile( $ClarID::Tools::share_dir, 'icd10_order.json' ) },
    doc     => 'path to icd10_order.json',
);

has icd10_by_order => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_icd10_by_order',
);

option max_conditions => (
    is      => 'ro',
    format  => 'i',
    isa     => Int,
    default => sub { 10 },
    doc     => 'maximum number of ICD-10 codes allowed',
);

# biosample fields
option project =>
  ( is => 'ro', format => 's', isa => Undef | Str, doc => 'project key' );
option species =>
  ( is => 'ro', format => 's', isa => Undef | Str, doc => 'species key' );
option tissue =>
  ( is => 'ro', format => 's', isa => Undef | Str, doc => 'tissue key' );
option sample_type => (
    is     => 'ro',
    format => 's',
    isa    => Undef | Str,
    doc    => 'sample_type key'
);
option assay =>
  ( is => 'ro', format => 's', isa => Undef | Str, doc => 'assay key' );
option timepoint =>
  ( is => 'ro', format => 's', isa => Undef | Str, doc => 'timepoint' );
option duration => (
    is     => 'ro',
    format => 's',
    isa    => Undef | Str,
    doc    => 'duration: P<digits><D|W|M|Y> or P0N (Not Available)'
);
option batch =>
  ( is => 'ro', format => 's', isa => Undef | Int, doc => 'batch' );
option replicate => (
    is     => 'ro',
    format => 'i',
    isa    => Undef | Int,
    doc    => 'replicate number'
);

# subject fields
option study =>
  ( is => 'ro', format => 's', isa => Undef | Str, doc => 'study' );
option type => ( is => 'ro', format => 's', isa => Undef | Str, doc => 'type' );
option sex  => ( is => 'ro', format => 's', isa => Undef | Str, doc => 'sex' );
option age_group =>
  ( is => 'ro', format => 's', isa => Undef | Str, doc => 'age_group' );

# Biosample + subject
option subject_id =>
  ( is => 'ro', format => 'i', isa => Undef | Int, doc => 'subject_id' );
option condition => (
    is     => 'ro',
    format => 's',
    isa    => Undef | Str,
    doc    => 'comma-separated ICD-10 codes (e.g. C22.0,C18.1)'
);

# declare once, reuse everywhere:
my %FIELDS = (
    biosample => {
        encode => [
            qw(
              project species subject_id tissue sample_type assay
              condition timepoint duration batch replicate
            )
        ],
        decode => [
            qw(
              project species subject_id tissue sample_type assay
              condition timepoint duration batch replicate
            )
        ],
    },
    subject => {
        encode => [
            qw(
              study subject_id type condition sex age_group
            )
        ],
        decode => [
            qw(
              study subject_id type condition sex age_group
            )
        ],
    },
);

sub _encode_fields {
    my $self = shift;
    my $e    = $self->entity;
    Carp::croak "Unknown entity '$e'" unless exists $FIELDS{$e};
    return @{ $FIELDS{$e}{encode} };
}

sub _decode_fields {
    my $self = shift;
    my $e    = $self->entity;
    Carp::croak "Unknown entity '$e'" unless exists $FIELDS{$e};
    return @{ $FIELDS{$e}{decode} };
}

# Validate required options
sub BUILD {
    my $self = shift;

    # If we're in bulk mode, skip ALL of the single-record checks,
    # including the CLI --condition parsing.
    return if defined $self->infile;

    # Only from here on is single-record mode…

    # 1) Ensure --with-condition-name only on decode
    if ( $self->with_condition_name && $self->action ne 'decode' ) {
        croak "--with-condition-name only makes sense when --action decode";
    }

    # 2) Single-record encode: parse & validate the CLI --condition
    if ( $self->action eq 'encode' ) {

        # split into individual codes (profiled on Aug-09-25)
        my @conds = split /\s*,\s*/, ( $self->condition // '' );
        croak "--condition must not be empty" unless @conds;

        # enforce max
        if ( @conds > $self->max_conditions ) {
            croak sprintf
              "You passed %d conditions but max is %d",
              scalar(@conds), $self->max_conditions;
        }

        # pull regex from your codebook
        my $pat_cfg =
          $self->codebook->{entities}{ $self->entity }{condition_pattern}
          or croak "No condition_pattern defined in your codebook";
        my $re = $pat_cfg->{regex}
          or croak "condition_pattern has no regex";

        # validate each
        for my $c (@conds) {
            croak "Invalid condition '$c'"
              unless $c =~ /^$re$/;
        }

        # stash for the encoder
        $self->{_conds} = \@conds;

        # 3) Now enforce the usual “required field” checks
        for my $field ( $self->_encode_fields ) {
            next if $field eq 'batch'     && !defined $self->batch;
            next if $field eq 'replicate' && !defined $self->replicate;
            croak "--$field is required for single-record encode"
              unless defined $self->$field;
        }
    }
    elsif ( $self->action eq 'decode' ) {

        # 4) Single-record decode needs a clar_id
        croak "--clar_id is required for decode"
          unless defined $self->clar_id;
    }
}

# lazy load
sub _build_icd10_by_order {
    my $self = shift;

    # force-load the order hash if not done yet
    my $ord_hash = $self->icd10_order;
    my @by;
    $by[ $ord_hash->{$_} ] = $_ for keys %$ord_hash;
    return \@by;
}

# Main dispatch
sub execute {
    my $self = shift;

    # lazy load ICD-10 map if requested
    my $code2name;
    if ( $self->action eq 'decode' && $self->with_condition_name ) {
        croak "ICD-10 map not found at '" . $self->icd10_map . "'"
          unless -e $self->icd10_map;
        open my $jh, '<', $self->icd10_map or croak $!;
        local $/;
        my $jtxt = <$jh>;
        close $jh;
        $code2name = decode_json($jtxt);
    }

    # bulk vs single-record
    my ( $in_fh, $out_fh );
    if ( defined( my $infile = $self->infile ) ) {

        # Input handle (auto‐gunzip for .gz)
        if ( $infile =~ /\.gz$/ ) {
            $in_fh = IO::Uncompress::Gunzip->new($infile)
              or croak "gunzip failed on '$infile': $GunzipError";
        }
        else {
            open my $fh_in, '<', $infile
              or croak "Could not open '$infile': $!";
            $in_fh = $fh_in;
        }

        # Output handle (auto‐gzip for .gz, else file or STDOUT)
        if ( defined $self->outfile ) {
            if ( $self->outfile =~ /\.gz$/ ) {
                $out_fh = IO::Compress::Gzip->new( $self->outfile )
                  or croak "gzip failed on '$self->outfile': $GzipError";
            }
            else {
                open my $fh_out, '>', $self->outfile
                  or croak "Could not open '$self->outfile' for writing: $!";
                $out_fh = $fh_out;
            }
        }
        else {
            $out_fh = *STDOUT;
        }

        # Delegate to bulk processor
        return $self->_run_bulk( $in_fh, $self->sep, $out_fh, $code2name );
    }

    # single-record mode — unwrap either top-level or entities-wrapped codebook
    my $full = $self->codebook;

    # if the YAML has an "entities:" wrapper, drill into it; otherwise assume old style
    my $root =
      exists $full->{entities}
      ? $full->{entities}
      : $full;
    my $cb = $root->{ $self->entity }
      or croak "No codebook for '" . $self->entity . "' in your YAML";
    if ( $self->action eq 'encode' ) {
        my @vals = map { $self->$_ } $self->_encode_fields;
        my $meth = sprintf '_encode_%s_%s', $self->format, $self->entity;
        say $self->$meth( $cb, @vals );
    }
    else {
        my $meth = sprintf '_decode_%s_%s', $self->format, $self->entity;
        my $res  = $self->$meth( $cb, $self->clar_id );

        # Print each field in order
        say "$_: $res->{$_}" for $self->_decode_fields;

        # Optionally append human-readable condition_name
        if ( $self->with_condition_name ) {

            # split whatever separator you're using in $res->{condition}
            my @keys = split /[+;]/, $res->{condition};

            # normalize to dot‐free lookup key and fetch each name
            my @names = map {
                ( my $clean = $_ ) =~ s/\W//g;
                $code2name->{$clean} // ''
            } @keys;

            # join multiple names with semicolons
            say "condition_name: " . join( ';', @names );
        }
    }
}

# Bulk processing for single or multiple records
sub _run_bulk {
    my ( $self, $in_fh, $sep, $out_fh, $code2name ) = @_;
    $sep ||= ',';

    # set up CSV parser
    my $csv = Text::CSV_XS->new( { sep_char => $sep } );

    # read header row and set column names
    my $hdr = $csv->getline($in_fh)
      or croak "Failed to read header";
    $csv->column_names(@$hdr);

    # unwrap entity wrapper in the codebook for bulk mode
    my $full = $self->codebook;
    my $root = exists $full->{entities} ? $full->{entities} : $full;
    my $cb   = $root->{ $self->entity }
      or croak "No codebook for '" . $self->entity . "'";

    # write output header
    if ( $self->action eq 'encode' ) {
        my $label = $self->format eq 'stub' ? 'stub_id' : 'clar_id';
        say $out_fh join( $sep, ( @$hdr, $label ) );
    }
    else {
        my @cols = ( @$hdr, $self->_decode_fields );
        push @cols, 'condition_name' if $self->with_condition_name;
        say $out_fh join( $sep, @cols );
    }

    # process each row
    while ( my $row = $csv->getline_hr($in_fh) ) {

        if ( $self->action eq 'encode' ) {

            # ——— per-row multi‐condition support (CSV uses ';') ———
            my @conds = split /\s*;\s*/, $row->{condition} // '';
            croak "Missing or empty condition in row" unless @conds;
            if ( @conds > $self->max_conditions ) {
                croak sprintf
                  "You passed %d conditions but max is %d",
                  scalar(@conds), $self->max_conditions;
            }

            # validate each against the codebook regex
            my $pat_cfg = $cb->{condition_pattern}
              or croak "No condition_pattern in codebook";
            my $re = $pat_cfg->{regex}
              or croak "condition_pattern has no regex";
            for my $c (@conds) {
                croak "Invalid condition '$c'"
                  unless $c =~ /^$re$/;
            }

            # stash for the encoder
            $self->{_conds} = \@conds;

            my @args = map { $row->{$_} } $self->_encode_fields;
            my $meth = sprintf '_encode_%s_%s', $self->format, $self->entity;
            my $out  = $self->$meth( $cb, @args );
            say $out_fh join( $sep, ( map { $row->{$_} // '' } @$hdr ), $out );
        }
        else {
            # enforce column based on --format
            my ( $meth, $id_col );
            if ( $self->format eq 'human' ) {
                $meth   = sprintf '_decode_human_%s', $self->entity;
                $id_col = 'clar_id';
            }
            else {    # format eq 'stub'
                $meth   = sprintf '_decode_stub_%s', $self->entity;
                $id_col = 'stub_id';
            }

            croak "Missing $id_col in input row"
              unless defined $row->{$id_col};

            my $res = $self->$meth( $cb, $row->{$id_col} );

            my @out = map { $res->{$_} // '' } $self->_decode_fields;
            if ( $self->with_condition_name && $code2name ) {
                my @codes = split /[+;]/, $res->{condition};
                my @names = map {
                    ( my $c = $_ ) =~ s/\W//g;
                    $code2name->{$c} // ''
                } @codes;
                push @out, join( ';', @names );
            }

            say $out_fh join( $sep, ( map { $row->{$_} // '' } @$hdr ), @out );
        }
    }

    return;
}

sub _validate_field {
    my ( $fmap, $f, $v ) = @_;
    croak "Invalid $f '$v'" unless defined $v && exists $fmap->{$v};
}

# Cache compiled regex + placeholder counts per pattern config
sub _prep_pattern {
    my ( $pcfg, $mode ) = @_;
    $pcfg->{_re} ||= qr/^(?:$pcfg->{regex})$/;

    my $fmt =
      $mode eq 'human'
      ? ( $pcfg->{code_format} // '%s' )
      : ( $pcfg->{stub_format} // '%s' );

    my $need_key = $mode eq 'human' ? '_need_human' : '_need_stub';
    $pcfg->{$need_key} //= do {
        ( my $t = $fmt ) =~ s/%%//g;    # ignore literal %%
        scalar( () = $t =~ /%/g )       # count % directives
    };

    return ( $pcfg->{_re}, $fmt, $pcfg->{$need_key} );
}

# Generic parser (grab captures; safe for alternation like P0N)
sub _parse_field {
    my ( $val, $map, $pcfg, $mode, $field ) = @_;

    croak "Missing value for $field" unless defined $val;
    croak "No pattern for $field"    unless $pcfg && $pcfg->{regex};

    my ( $re, $fmt, $need ) = _prep_pattern( $pcfg, $mode );
    croak "Invalid $field '$val'" unless $val =~ $re;

    my @caps = grep { defined } ( $val =~ $re );    # drop undef from alternation
    splice @caps, $need if @caps > $need;           # never pass extra args

    return $need ? sprintf( $fmt, @caps ? @caps : ($val) ) : $fmt;
}

# Static-or-pattern parser (uses codebook map first, then pattern)
sub _parse_from_codebook {
    my ( $val, $map, $pcfg, $mode ) = @_;

    # 1) static map entry (e.g., tokens)
    if ( $map && ref $map eq 'HASH' && exists $map->{$val} ) {
        my $k = $mode eq 'human' ? 'code' : 'stub_code';
        return $map->{$val}{$k} if defined $map->{$val}{$k};
    }

    # 2) require a value
    croak "Missing value for field" unless defined $val;

    # 3) pattern path (captures-aware) or raw fallback
    if ( $pcfg && $pcfg->{regex} ) {
        my ( $re, $fmt, $need ) = _prep_pattern( $pcfg, $mode );
        croak "Invalid value '$val' for field" unless $val =~ $re;

        my @caps = grep { defined } ( $val =~ $re );
        splice @caps, $need if @caps > $need;

        # for stub mode, if no captures, normalize raw by stripping non-word
        if ( !@caps && $need == 1 && $mode eq 'stub' ) {
            ( my $raw = $val ) =~ s/\W//g;
            return sprintf( $fmt, $raw );
        }

        return @caps ? sprintf( $fmt, @caps ) : sprintf( $fmt, $val );
    }

    return $val;
}

#----------------------------------------------------------------
# Human biosample encoder
#----------------------------------------------------------------
# Human biosample encoder
sub _encode_human_biosample {
    my (
        $self, $cb, $pr_raw, $sp, $sid, $ti, $st,
        $as,   $co, $tp,     $du, $ba,  $re
    ) = @_;

    # normalize project key
    my $pr = $pr_raw;
    unless ( exists $cb->{project}{$pr} ) {
        ( my $alt = $pr_raw ) =~ tr/-/_/;
        $pr = $alt if exists $cb->{project}{$alt};
    }
    croak "Invalid project '$pr_raw'" unless exists $cb->{project}{$pr};

    # basic field validation
    _validate_field( $cb->{project},     'project',     $pr );
    _validate_field( $cb->{species},     'species',     $sp );
    _validate_field( $cb->{tissue},      'tissue',      $ti );
    _validate_field( $cb->{sample_type}, 'sample_type', $st );
    _validate_field( $cb->{assay},       'assay',       $as );

    # subject_id
    my $pad = $self->subject_id_pad_length;
    croak "Invalid pad length '$pad'" unless $pad =~ /^\d+$/ && $pad > 0;
    my $max = 10**$pad - 1;
    croak "Bad subject_id '$sid' (0-$max)"
      unless $sid =~ /^\d+$/ && $sid >= 0 && $sid <= $max;

    # ------ multi‐condition support ------
    my @conds = @{ delete $self->{_conds} };    # pull in the validated list
    my @human = map {
        _parse_from_codebook( $_, $cb->{condition}, $cb->{condition_pattern},
            'human' )
    } @conds;
    my $cond_code = join '+', @human;

    # -------------------------------------
    # timepoint (strict codebook lookup)
    _validate_field( $cb->{timepoint}, 'timepoint', $tp );
    my $pt_code = $cb->{timepoint}{$tp}{code};

    # duration (pattern-drivem only)
    my $dur_code =
      _parse_field( $du, undef, $cb->{duration_pattern}, 'human', 'duration' );

    # batch (pattern-driven only)
    my $batch_code =
      defined $ba
      ? _parse_field( $ba, undef, $cb->{batch_pattern}, 'human', 'batch' )
      : ();

    # replicate (pattern-driven only)
    my $rep_code =
      defined $re
      ? _parse_field( $re, undef, $cb->{replicate_pattern}, 'human',
        'replicate' )
      : ();

    # assemble
    my @parts = (
        $cb->{project}{$pr}{code},     $cb->{species}{$sp}{code},
        sprintf( "%0${pad}d", $sid ),  $cb->{tissue}{$ti}{code},
        $cb->{sample_type}{$st}{code}, $cb->{assay}{$as}{code},
        $cond_code,                    $pt_code,
        $dur_code,
    );
    push @parts, $batch_code if defined $batch_code;
    push @parts, $rep_code   if defined $rep_code;

    return join( '-', @parts );
}

# Human biosample decoder
sub _decode_human_biosample {
    my ( $self, $cb, $id ) = @_;
    my @p = split /-/, $id;
    croak "Bad biosample ID" unless @p >= 9;
    my ( $prc, $sc, $sid, $tc, $stc, $ac, $cn, $ptc, $du, @rest ) = @p;

    my ($project) =
      grep { $cb->{project}{$_}{code} eq $prc } keys %{ $cb->{project} };
    croak "Unknown project code '$prc'" unless defined $project;
    my ($species) =
      grep { $cb->{species}{$_}{code} eq $sc } keys %{ $cb->{species} };
    croak "Unknown species code '$sc'" unless defined $species;
    my ($tissue) =
      grep { $cb->{tissue}{$_}{code} eq $tc } keys %{ $cb->{tissue} };
    croak "Unknown tissue code '$tc'" unless defined $tissue;
    my ($stype) = grep { $cb->{sample_type}{$_}{code} eq $stc }
      keys %{ $cb->{sample_type} };
    croak "Unknown sample_type code '$stc'" unless defined $stype;
    my ($assay) = grep { $cb->{assay}{$_}{code} eq $ac } keys %{ $cb->{assay} };
    croak "Unknown assay code '$ac'" unless defined $assay;

    # parse subject_id using dynamic pad length
    my $pad = $self->subject_id_pad_length;
    croak "Invalid pad length '$pad'" unless $pad =~ /^\d+$/ && $pad > 0;
    croak "Bad subject_id in ID '$sid'"
      unless $sid =~ /^\d{$pad}$/;
    my $subject_id = int($sid);

    # Extract batch and replicate (just the integer)
    my ( $batch, $replicate );
    if (@rest) {

        # last element R## -> replicate
        if ( $rest[-1] =~ /^R(\d{2})$/ ) {
            $replicate = int $1;
            pop @rest;
        }

        # now maybe B## -> batch
        if ( @rest && $rest[-1] =~ /^B(\d{2})$/ ) {
            $batch = int $1;
            pop @rest;
        }
    }

    # timepoint decode (strict codebook reverse lookup)
    my ($timepoint) =
      grep { $cb->{timepoint}{$_}{code} eq $ptc } keys %{ $cb->{timepoint} };
    croak "Unknown timepoint code '$ptc'" unless defined $timepoint;

    # condition decode (allow multiple codes separated by '+')
    my @parts = split /\+/, $cn;
    my @norm;
    for my $code (@parts) {

        # if it exists verbatim, use it
        if ( exists $cb->{condition}{$code} ) {
            push @norm, $code;
        }
        else {
            # insert dot after 3rd char if missing
            if ( $code !~ /\./ && length($code) > 3 ) {
                $code = substr( $code, 0, 3 ) . '.' . substr( $code, 3 );
            }
            push @norm, $code;
        }
    }

    # join with semicolons for human readability
    my $condition = join ';', @norm;

    # ensure we don't get warnings when printing
    $batch     = '' unless defined $batch;
    $replicate = '' unless defined $replicate;

    return {
        project     => $project,
        species     => $species,
        subject_id  => $subject_id,
        tissue      => $tissue,
        sample_type => $stype,
        assay       => $assay,
        condition   => $condition,
        timepoint   => $timepoint,
        duration    => $du,
        batch       => $batch,
        replicate   => $replicate,
    };
}

#----------------------------------------------------------------
# Stub biosample encoder
#----------------------------------------------------------------
sub _encode_stub_biosample {
    my ( $self, $cb, $pr, $sp, $sid, $ti, $st, $as, $co, $tp, $du, $ba, $re ) =
      @_;

    # 1) static validations
    _validate_field( $cb->{project},     'project',     $pr );
    _validate_field( $cb->{species},     'species',     $sp );
    _validate_field( $cb->{tissue},      'tissue',      $ti );
    _validate_field( $cb->{sample_type}, 'sample_type', $st );
    _validate_field( $cb->{assay},       'assay',       $as );

    # 2) subject_id -> stub
    my $w = $self->subject_id_base62_width;
    croak "Invalid stub width '$w'" unless $w =~ /^\d+$/ && $w > 0;
    croak "Bad subject_id '$sid' (0–" . ( 62**$w - 1 ) . ")"
      unless defined $sid && $sid =~ /^\d+$/ && $sid <= 62**$w - 1;
    my $sid_stub = $self->_subject_id_to_stub( $sid, $w );

    # 3) pull in previously-parsed conditions (bulk) or split the raw string
    my $conds_aref = delete $self->{_conds};
    my @conds =
        $conds_aref
      ? @$conds_aref
      : split /\s*[+,;]\s*/, ( defined $co ? $co : '' );
    croak "No conditions provided" unless @conds;
    croak sprintf "You passed %d conditions but max is %d",
      scalar(@conds), $self->max_conditions
      if @conds > $self->max_conditions;

    # 4) map each ICD-10 -> 3-char stub
    my @stubs = map {
        ( my $c = $_ ) =~ s/\.//g;    # strip dots
        croak "Unknown ICD-10 '$_'"
          unless exists $self->icd10_order->{$c};
        $self->_subject_id_to_stub( $self->icd10_order->{$c}, 3 )
    } @conds;
    my $cond_stub    = join '', @stubs;
    my $count_prefix = sprintf( "%02d", scalar @stubs );    # << count added

    # 5) timepoint stub (strict codebook lookup)
    _validate_field( $cb->{timepoint}, 'timepoint', $tp );
    my $tp_stub = $cb->{timepoint}{$tp}{stub_code};

    # 6) duration stub (pattern-driven only)
    my $du_stub =
      _parse_field( $du, undef, $cb->{duration_pattern}, 'stub', 'duration' );

    # 7) batch & replicate (optional)
    my $ba_stub =
      defined $ba
      ? _parse_field( $ba, undef, $cb->{batch_pattern}, 'stub', 'batch' )
      : '';
    my $re_stub =
      defined $re
      ? _parse_field( $re, undef, $cb->{replicate_pattern}, 'stub',
        'replicate' )
      : '';

    # 8) assemble and return
    return join '', (
        $cb->{project}{$pr}{stub_code},     $cb->{species}{$sp}{stub_code},
        $sid_stub,                          $cb->{tissue}{$ti}{stub_code},
        $cb->{sample_type}{$st}{stub_code}, $cb->{assay}{$as}{stub_code},
        $cond_stub,                         $count_prefix,                    # << here
        $tp_stub,                           $du_stub,
        $ba_stub,                           $re_stub,
    );
}

# Stub biosample decoder
sub _decode_stub_biosample {
    my ( $self, $cb, $id ) = @_;
    croak "Bad stub ID" unless defined $id && length $id;

    # Use codebook-driven tail peel for replicate & batch
    my $repl_fmt  = $cb->{replicate_pattern}{stub_format} // '%02d';
    my $batch_fmt = $cb->{batch_pattern}{stub_format}     // '%02d';

    # 1) strip off replicate using stub_format (e.g. 'R%02d' or '%02d')
    my $replicate = _strip_tail_using_fmt( \$id, $repl_fmt );

    # 2) strip off batch using stub_format
    my $batch = _strip_tail_using_fmt( \$id, $batch_fmt );

    # Legacy fallback for old (unprefixed) stubs: peel bare 2 digits if still present
    if ( !defined $replicate && $id =~ s/(\d{2})$// ) { $replicate = 0 + $1 }
    if ( !defined $batch     && $id =~ s/(\d{2})$// ) { $batch     = 0 + $1 }

    # 3) strip off duration: allow D/W/M/Y or 0N
    croak "Bad stub ID (duration)" unless $id =~ s/(\d+)([DWMYN])$//;
    my ( $d_num, $d_unit ) = ( $1, $2 );
    croak "Invalid duration unit 'N' with non-zero"
      if $d_unit eq 'N' && $d_num != 0;
    my $duration = 'P' . $d_num . $d_unit;

    # 4) strip off timepoint (variable-length stub_code from codebook)
    my %tp_by =
      map { $cb->{timepoint}{$_}{stub_code} => $_ } keys %{ $cb->{timepoint} };
    my $timepoint;
    for my $stub ( sort { length($b) <=> length($a) } keys %tp_by ) {
        if ( $id =~ s/\Q$stub\E$// ) { $timepoint = $tp_by{$stub}; last }
    }
    croak "Unknown timepoint stub at end of ID" unless defined $timepoint;

    # 4b) peel 2-digit condition COUNT (immediately before timepoint)
    croak "Missing condition count" unless $id =~ s/(\d{2})$//;
    my $cond_count = int $1;
    croak "Invalid condition count '$cond_count'" unless $cond_count > 0;

    # now $id is the head: project + species + sid + tissue + sample_type + assay + COND_SEGMENT
    my $head = $id;

    # 5) project (match longest stub_code at start)
    my %proj_by = map { $cb->{project}{$_}{stub_code} => $_ }
      keys %{ $cb->{project} };
    my ($project);
    for my $stub ( sort { length($b) <=> length($a) } keys %proj_by ) {
        if ( $head =~ s/^\Q$stub\E// ) { $project = $proj_by{$stub}; last }
    }
    croak "Unknown project stub" unless defined $project;

    # 6) species (always 2 chars)
    my $spec_stub = substr( $head, 0, 2 );
    substr( $head, 0, 2 ) = '';
    my %sp_by = map { $cb->{species}{$_}{stub_code} => $_ }
      keys %{ $cb->{species} };
    croak "Unknown species stub '$spec_stub'" unless exists $sp_by{$spec_stub};
    my $species = $sp_by{$spec_stub};

    # 7) subject_id (base-62 width)
    my $w = $self->subject_id_base62_width;
    croak "Bad stub width" unless $w =~ /^\d+$/ && $w > 0;
    my $sid_stub = substr( $head, 0, $w );
    substr( $head, 0, $w ) = '';
    my $subject_id = $self->_stub_to_subject_id($sid_stub);

    # 8) tissue (match longest)
    my %ti_by = map { $cb->{tissue}{$_}{stub_code} => $_ }
      keys %{ $cb->{tissue} };
    my $tissue;
    for my $stub ( sort { length($b) <=> length($a) } keys %ti_by ) {
        if ( $head =~ s/^\Q$stub\E// ) { $tissue = $ti_by{$stub}; last }
    }
    croak "Unknown tissue stub '$head'" unless defined $tissue;

    # 9) sample_type (match longest)
    my %st_by = map { $cb->{sample_type}{$_}{stub_code} => $_ }
      keys %{ $cb->{sample_type} };
    my $stype;
    for my $stub ( sort { length($b) <=> length($a) } keys %st_by ) {
        if ( $head =~ s/^\Q$stub\E// ) { $stype = $st_by{$stub}; last }
    }
    croak "Unknown sample_type stub" unless defined $stype;

    # 10) assay (match longest)
    my %as_by = map { $cb->{assay}{$_}{stub_code} => $_ }
      keys %{ $cb->{assay} };
    my $assay;
    for my $stub ( sort { length($b) <=> length($a) } keys %as_by ) {
        if ( $head =~ s/^\Q$stub\E// ) { $assay = $as_by{$stub}; last }
    }
    croak "Unknown assay stub" unless defined $assay;

    # 11) remaining $head must be exactly cond_count * 3 chars (ICD ordinals stubs)
    croak "Bad condition stub length" unless length($head) % 3 == 0;
    my @c_stubs = $head =~ /(.{3})/g;
    croak "Condition count mismatch (have "
      . scalar(@c_stubs)
      . ", expected $cond_count)"
      unless @c_stubs == $cond_count;

    my @conds = map {
        my $ord = $self->_stub_to_subject_id($_);
        croak "Invalid condition ordinal '$ord'"
          unless $ord >= 1 && $ord < @{ $self->icd10_by_order };
        _format_icd10( $self->icd10_by_order->[$ord] );
    } @c_stubs;

    my $condition = join ';', @conds;

    if (DEVEL_MODE) {
        say "DEBUG biosample cond_count = $cond_count";
        say "DEBUG biosample cond_stubs = [" . join( ',', @c_stubs ) . "]";
    }

    return {
        project     => $project,
        species     => $species,
        subject_id  => $subject_id,
        tissue      => $tissue,
        sample_type => $stype,
        assay       => $assay,
        condition   => $condition,    # ';' joined
        timepoint   => $timepoint,
        duration    => $duration,
        batch       => $batch     // '',
        replicate   => $replicate // '',
    };
}

# Human-mode subject encoder
sub _encode_human_subject {
    my (
        $self, $cb,
        $study,                       # study
        $sid,                         # subject_id
        $ty,                          # type
        $co,                          # raw condition string
        $sx,                          # sex
        $ag                           # age_group
    ) = @_;

    # 1) Validate type, sex & age_group
    _validate_field( $cb->{type},      'type',      $ty );
    _validate_field( $cb->{sex},       'sex',       $sx );
    _validate_field( $cb->{age_group}, 'age_group', $ag );

    # 2) Pad subject_id
    my $pad = $self->subject_id_pad_length;
    croak "Invalid pad length '$pad'"
      unless $pad =~ /^\d+$/ && $pad > 0;
    my $max = 10**$pad - 1;
    croak "Bad subject_id '$sid' (must be 0-$max)"
      unless defined $sid && $sid =~ /^\d+$/ && $sid <= $max;
    $study =~ tr/-/_/;    # normalize study key

    # 3) Split & validate multiple ICD-10 codes
    my @conds = split /\s*[+,;]\s*/, ( defined $co ? $co : '' );
    croak "No conditions provided" unless @conds;
    for my $c (@conds) {
        my $pat_cfg = $cb->{condition_pattern}
          or croak "No condition_pattern in codebook";
        croak "Invalid condition '$c'"
          unless $c =~ /^$pat_cfg->{regex}$/;
    }

    # 4) Re-join with '+' for the final code
    my $cond_code = join '+', @conds;

    # 5) Assemble the ID
    return join( '-',
        $study,
        sprintf( "%0${pad}d", $sid ),
        $cb->{type}{$ty}{code},
        $cond_code,
        $cb->{sex}{$sx}{code},
        $cb->{age_group}{$ag}{code},
    );
}

# Human-mode subject decoder
sub _decode_human_subject {
    my ( $self, $cb, $id ) = @_;

    my @p = split /-/, $id;
    croak "Bad subject ID" unless @p == 6;
    my ( $study, $sid, $type_c, $co, $sex_c, $ag_code ) = @p;

    my ($ag_key) = grep { $cb->{age_group}{$_}{code} eq $ag_code }
      keys %{ $cb->{age_group} };
    croak "Unknown age_group code '$ag_code'" unless defined $ag_key;

    return {
        study      => $study,
        type       => $type_c,
        sex        => $sex_c,
        age_group  => $ag_key,
        condition  => $co,
        subject_id => int($sid),
    };
}

# Stub-mode subject encoder (with 2-digit condition count prefix)
# Stub-mode subject **encoder**, with COUNT just before sex
sub _encode_stub_subject {
    my (
        $self, $cb,
        $study,         # study key
        $subject_id,    # integer
        $type,          # type key
        $condition,     # comma-separated ICD list
        $sex,           # sex key
        $age_group      # age_group key
    ) = @_;

    # study stub
    my $study_stub = $cb->{study}{$study}{stub_code} // $study;

    # validate & get stubs for type/sex/age_group
    croak "Unknown type '$type'" unless exists $cb->{type}{$type};
    croak "Unknown sex '$sex'"   unless exists $cb->{sex}{$sex};
    croak "Unknown age_group '$age_group'"
      unless exists $cb->{age_group}{$age_group};
    my $type_stub      = $cb->{type}{$type}{stub_code};
    my $sex_stub       = $cb->{sex}{$sex}{stub_code};
    my $age_group_stub = $cb->{age_group}{$age_group}{stub_code};

    # subject_id -> base-62
    my $w = $self->subject_id_base62_width;
    croak "Invalid stub width '$w'" unless $w =~ /^\d+$/ && $w > 0;
    my $sid_stub = $self->_subject_id_to_stub( $subject_id, $w );

    # split and encode ICDs
    my @conds = split /\s*,\s*/, $condition;
    croak "No conditions provided" unless @conds;
    croak "Too many conditions" if @conds > 99;
    my @cond_stubs = map {
        ( my $c = $_ ) =~ s/\.//g;
        croak "Unknown ICD-10 '$_'" unless exists $self->icd10_order->{$c};
        $self->_subject_id_to_stub( $self->icd10_order->{$c}, 3 )
    } @conds;

    # build count + conds string
    my $count_prefix = sprintf( "%02d", scalar @cond_stubs );
    my $conds_part   = join "", @cond_stubs;

    # final: STUDY + SID + TYPE + CONDS + COUNT + SEX + AGE
    return join "",
      (
        $study_stub,   $sid_stub, $type_stub, $conds_part,
        $count_prefix, $sex_stub, $age_group_stub,
      );
}

# Stub-mode subject **decoder**, reading backwards with COUNT before sex
sub _decode_stub_subject {
    my ( $self, $cb, $stub ) = @_;

    # 1) sanity on base-62 width
    my $w = $self->subject_id_base62_width;
    croak "Invalid stub length '$w'"
      unless defined $w && $w =~ /^\d+$/ && $w > 0;

    # 2) reverse the entire stub
    my $rev = reverse $stub;

    # 3) pull off age_group (2 chars) + sex (1 char)
    my $rev_age = substr( $rev, 0, 2 );
    my $rev_sex = substr( $rev, 2, 1 );
    my $rest    = substr( $rev, 3 );

    # 4) next two chars are the **reversed** condition count
    croak "Bad condition count in stub" unless length($rest) >= 2;
    my $count_rev = substr( $rest, 0, 2 );

    # restore correct order, parse as integer
    my $cond_count = int reverse $count_rev;
    croak "Invalid condition count '$cond_count'" unless $cond_count > 0;
    $rest = substr( $rest, 2 );

    # 5) peel off exactly cond_count * 3 chars for all condition stubs
    my $conds_len = $cond_count * 3;
    croak "Bad condition stub length"
      unless length($rest) >= $conds_len;
    my $rev_conds_rev = substr( $rest, 0, $conds_len );
    $rest = substr( $rest, $conds_len );

    # 6) next is the type stub (1 char)
    croak "Missing type stub" unless length($rest) >= 1;
    my $rev_type = substr( $rest, 0, 1 );
    $rest = substr( $rest, 1 );

    # 7) then the subject_id stub (width $w)
    croak "Missing subject_id stub" unless length($rest) >= $w;
    my $rev_id_rev = substr( $rest, 0, $w );
    $rest = substr( $rest, $w );

    # 8) and whatever remains is the study stub
    my $rev_study_rev = $rest;

    # 9) DEBUG dumps
    if (DEVEL_MODE) {
        say "DEBUG rev            = '$rev'";
        say "DEBUG rev_age        = '$rev_age'";
        say "DEBUG rev_sex        = '$rev_sex'";
        say "DEBUG count_rev      = '"
          . ( reverse $count_rev )
          . "' -> cond_count=$cond_count";
        say "DEBUG rev_conds_rev  = '$rev_conds_rev'";
        say "DEBUG rev_type       = '$rev_type'";
        say "DEBUG rev_id_rev     = '$rev_id_rev'";
        say "DEBUG rev_study_rev  = '$rev_study_rev'";
    }

    # 10) reverse back simple fields
    my $age_s    = reverse $rev_age;         # stub for age_group
    my $sex_s    = reverse $rev_sex;         # stub for sex
    my $type_s   = reverse $rev_type;        # stub for type
    my $sid_stub = reverse $rev_id_rev;      # base62 subject_id
    my $study    = reverse $rev_study_rev;

    # 11) decode subject_id
    my $subject_id = $self->_stub_to_subject_id($sid_stub);

    # 12) map back type, sex, and age_group via codebook
    my ($type) =
      grep { $cb->{type}{$_}{stub_code} eq $type_s } keys %{ $cb->{type} };
    croak "Unknown type stub '$type_s'" unless defined $type;

    my ($sex_key) =
      grep { $cb->{sex}{$_}{stub_code} eq $sex_s } keys %{ $cb->{sex} };
    croak "Unknown sex stub '$sex_s'" unless defined $sex_key;

    my ($age_group_key) = grep { $cb->{age_group}{$_}{stub_code} eq $age_s }
      keys %{ $cb->{age_group} };
    croak "Unknown age_group stub '$age_s'" unless defined $age_group_key;

    # 13) split condition segment into reversed 3-char chunks
    my @rev_chunks = $rev_conds_rev =~ /(.{3})/g;
    croak "Condition stub parsing mismatch"
      unless @rev_chunks == $cond_count;

    # *** restore original left-to-right order ***
    @rev_chunks = reverse @rev_chunks;

    # 14) reverse each back, then decode ordinal -> ICD-10
    my @conds = map {
        my $stub3 = reverse $_;                            # un-reverse it
        my $ord   = $self->_stub_to_subject_id($stub3);    # base62 -> ordinal
        croak "Invalid condition ordinal '$ord'"
          unless $ord >= 1 && $ord < @{ $self->icd10_by_order };
        _format_icd10( $self->icd10_by_order->[$ord] );
    } @rev_chunks;

    # 15) assemble final hash
    return {
        study      => $study,
        subject_id => $subject_id,
        type       => $type,
        condition  => join( ';', @conds ),
        sex        => $sex_key,
        age_group  => $age_group_key,        # <-- now mapped via codebook
    };
}

# ------------------------------------------------------------------------
# Helper functions for subject_id ↔ stub conversion
#
# _subject_id_to_stub($id, $width):
#   - Converts a non-negative integer $id into a fixed-width base‑62 string.
#   - Pads with '0' on the left to exactly $width characters.
#
# _stub_to_subject_id($stub):
#   - Parses a base‑62 string $stub back into the original integer.
#   - Validates characters against the 0-9, A-Z, a-z alphabet.
#
# These allow you to shrink a 5‑digit decimal ID into 3 base‑62 chars in stub mode,
# and recover the original integer when decoding.
# ------------------------------------------------------------------------

# Base‑62 alphabet
my @BASE62     = ( '0' .. '9', 'A' .. 'Z', 'a' .. 'z' );
my %BASE62_REV = map { $BASE62[$_] => $_ } 0 .. $#BASE62;

# ------------------------------------------------------------------------
# Convert a non‑negative integer into a fixed-width base‑62 stub
#   $id    : integer subject ID (>=0)
#   $width : desired stub length (default 3)
# Returns a $width-char string in [0-9A-Za-z], zero-padded on the left.
# ------------------------------------------------------------------------
sub _subject_id_to_stub {
    my ( $self, $id, $width ) = @_;
    $width ||= 3;    # default stub length

    croak "Bad subject_id '$id'"
      unless defined $id && $id =~ /^\d+$/ && $id >= 0;

    return '0' x $width if $id == 0;    # special‑case zero

    my $s   = '';
    my $num = $id;
    while ( $num > 0 ) {

        # prepend the next base‑62 digit
        $s   = $BASE62[ $num % 62 ] . $s;
        $num = int( $num / 62 );
    }

    # left‑pad with '0' to exactly $width chars
    return substr( ( '0' x $width ) . $s, -$width );
}

# Convert a base‑62 string back to an integer
sub _stub_to_subject_id {
    my ( $self, $stub ) = @_;
    croak "Bad stub '$stub'"
      unless defined $stub && $stub =~ /^[0-9A-Za-z]+$/;
    my $id = 0;
    for my $char ( split //, $stub ) {
        croak "Invalid base62 char '$char'" unless exists $BASE62_REV{$char};
        $id = $id * 62 + $BASE62_REV{$char};
    }
    return $id;
}

# Private helper: if an ICD‑10 code has no dot but is >3 chars,
# stick a dot after the third character.
sub _format_icd10 {
    my ($code) = @_;
    return $code if $code =~ /\./ || length($code) <= 3;
    return substr( $code, 0, 3 ) . '.' . substr( $code, 3 );
}

sub _apply_defaults {
    my ($doc)    = @_;
    my $ents     = $doc->{entities} or return;
    my $defaults = delete $ents->{_defaults} || {};

    for my $entity (qw/biosample subject/) {
        next unless my $cat = $ents->{$entity};
        for my $slot ( grep { ref $cat->{$_} eq 'HASH' } keys %$cat ) {
            my $map = $cat->{$slot};

            # skip the default‐holder itself
            next if $slot eq '_defaults';

            # for each of your two default keys, only add if missing:
            # NB: 'age_group' already has its own so it is skipped here
            for my $k ( keys %$defaults ) {
                $map->{$k} //= { %{ $defaults->{$k} } };
            }
        }
    }

    warn
"!  Note: injected global 'Unknown' + 'Not Available' defaults into each category\n"
      if DEVEL_MODE;
}

# Turn a stub_format like 'R%02d' or '%02d' into a tail regex with one capture
sub _fmt_to_tail_regex {
    my ($fmt) = @_;
    my $re = quotemeta($fmt);            # escape literal chars
    $re =~ s/\\%0?(\d+)d/(\\d{$1})/g;    # %02d -> (\d{2}), %3d -> (\d{3})
    return qr/$re$/;                     # anchor at end
}

# Try to strip a value from the *end* of a string using stub_format
# Returns the captured integer or undef if no match; modifies $$sref
sub _strip_tail_using_fmt {
    my ( $sref, $fmt ) = @_;
    my $re = _fmt_to_tail_regex($fmt);
    if ( $$sref =~ s/$re// ) { return 0 + $1 }
    return undef;
}

1;

