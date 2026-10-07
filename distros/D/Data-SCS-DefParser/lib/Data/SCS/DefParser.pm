use v5.36;
use Object::Pad 0.805;

class Data::SCS::DefParser 0.12
  :strict(params);

use Archive::SCS 1.06;
use Archive::SCS::GameDir;
use Carp qw(croak);
use Path::Tiny qw(path);
use Scalar::Util ();

our $cargo = 0;
our $tidy = 1;

# The list of directories or archives to mount.
field @mounts :reader;

# The data source to use (game name, game/sii directory, array reference
# of mountable paths, Archive::SCS instance).
field $mount :param;

# The list of def file names to parse.
field @filenames = (
  "def/country.sii",
  "def/city.sii",
  "def/company.sii",
);

field $archive;
field %archive_has_entry;
field @company_files;

ADJUST :params ( :$parse = undef ) {
  if (defined $parse) {
    @filenames = ref $parse eq 'ARRAY' ? $parse->@* : $parse;
    @filenames or croak '"parse" cannot be an empty array';
  }
  if (ref $mount eq 'ARRAY') {
    @mounts = $mount->@*;
    @mounts or croak '"mount" cannot be an empty array';
  }
  elsif ($mount isa Archive::SCS) {
    $archive = $mount;
  }
  elsif (defined $mount) {
    $self->init_def($mount);
  }
  else {
    croak '"mount" cannot be undef';
  }
}


sub trim :prototype($) {
  my $str = shift;
  $str =~ s/^\s+//s;
  $str =~ s/\s+$//s;
  return $str;
}


sub parse_block {
  my $data = shift;
  my ($pre, $in) = $data =~ m/^([^\{]*)\{(.*)\}/s;
  return (trim $pre, trim $in);
}


method lines_from_file ($context, $contents) {
  my @input = grep {length $_} map {trim $_} split m/\n/, $contents;
  my @lines;
  while (my $line = shift @input) {
    if (my ($inc) = $line =~ m/\A\@include\s+"(.+?)"\z/) {
      # include file
      my $file = path("/$context")->parent->relative("/")->child($inc);
      $file = substr $inc, 1 if $inc =~ m|\A/|;
      if (! $archive_has_entry{$file}) {
        $archive_has_entry{$file} = eval { $archive->read_entry($file); 1 };
        $archive_has_entry{$file} or croak
          sprintf "Couldn't find file '%s' (referenced by '%s') in: %s",
          $file, $context, join ", ", @mounts;
      }
      utf8::decode my $entry = $archive->read_entry($file);
      unshift @input, $self->lines_from_file($file, $entry);
      next;
    }
    push @lines, $line;
  }
  return @lines;
}


method parse_sii ($file) {
  utf8::decode my $sii = $archive->read_entry($file);
  my ($magic, $unit) = parse_block $sii;
  $magic =~ m/^ \N{ BYTE ORDER MARK }? SiiNunit $/x or die
    sprintf "Expected SiiNunit, found '%s' in %s", $magic, $file;
  my @lines = $self->lines_from_file($file, $unit);
  @lines = map {trim $_} map {
    s{/\* .*? \*/}{}gx;
    m{/\*|\*/} and die "Multi-line comments unimplemented";
    # clip comments
    s{#.*$|//.*$}{}r;
  } @lines;
  @lines = grep {$_} map {trim $_} map {
    # make sure { and } stand by their own on a line
    my @line = ($_);
    while ($line[$#line] =~ m/^(.*?)([\{\}])(.*)/) {
      pop @line;
      push @line, $1, $2, $3;
    }
    @line;
  } @lines;
  return @lines;
}


sub parse_sui_data_value {
  my $value = shift;
  if ( $value =~ m/^&([0-9A-Fa-f]{8})$/ ) {  # IEEE 754 binary32 float
    return 'Inf' if lc $1 eq '7f7fffff';  # max finite value / no data marker
    return sprintf '%.9g', unpack 'f', pack 'h8', scalar reverse $1;
    # 9 significant digits are sufficient to represent any 32-bit float.
  }
  if ( $value =~ m/^\(([^()]+)\)$/ ) {
    return join ', ', map { parse_sui_data_value( trim $_ ) } split m/,/, $1;
  }
  if ( $value =~ m/^"( ([^"]|\\")+ )"$/x ) {
    my $str = $1 =~ s{ \\x( [0-9A-Fa-f]{2} ) }{ chr hex $1 }egrx;
    $str =~ s{\\"}{"}g;
    utf8::decode $str;
    return $str;
  }
  if ( $value =~ m/^0x( [0-9A-Fa-f]{6,8} )$/x ) {
    return $1;
  }
  if ( $value eq 'true' ) {
    no warnings 'experimental::builtin';
    return builtin::true;
  }
  if ( $value eq 'false' ) {
    no warnings 'experimental::builtin';
    return builtin::false;
  }
  if ( Scalar::Util::looks_like_number $value ) {
    return 0 + $value;
  }
  if ( $value =~ m/^(\S+)$/ ) {
    return $1;
  }
  die "Unknown value format: '$value'";
}


sub parse_sui_data {
  my ($ats_data, $key, @raw) = @_;
  my $data = {};
  # parse key and insert data
  my ($type, $path) = $key =~ m/^(\S+)\s*:\s+(\S+)$/;
  if ($tidy) {
    # skip currently useless clutter
    return if $type eq 'license_plate_data';
  }
  # parse block contents
  for (@raw) {
    if ($tidy) {
      # skip currently useless clutter
      next if /city_name_localized/ || /sort_name/ || /time_zone/;
      next if /city_pin_scale_factor/;
      next if /map_._offsets/ || /license_plate/;
      next if $type eq 'prefab_model' && (/model_desc/ || /semaphore_profile/ || /use_semaphores/ || /gps_avoid/ || /use_perlin/ || /detail_veg_max_distance/ || /traffic_rules_input/ || /traffic_rules_output/ || /invisible/ || /category/ || /tweak_detail_vegetation/);
      next if $type eq 'prefab_model' && (/dynamic_lod_/ || /corner\d/);  # code dies for these; not sure why
    }
    if (/(\w+)\s*:\s*(.+)$/) {
      $data->{$1} = parse_sui_data_value $2;
      next;
    }
    if (/(\w+)\[(\d*)\]\s*:\s*(.+)$/) {
      # init array, overwriting scalar array size if present
      $data->{$1} = [] unless ref $data->{$1};
      if (length $2) {
        $data->{$1}[0+$2] = parse_sui_data_value $3;
      }
      else {
        push @{$data->{$1}}, parse_sui_data_value $3;
      }
      next;
    }
    die "Unkown data format: '$_'";
  }
  #$data->{_raw} = [@raw];
  #$data->{_key_raw} = $key;
  #$data->{_type} = $type;
  if ($path =~ m/^[\.\w]+$/) {
    my $hashpath = $path =~ s/\./'}{'/gr;
    $hashpath =~ s/^\'}/_$type'}/;
    eval "\$ats_data->{'$hashpath'} = \$data";
  }
  else {
    die "Unimplemented path '$path'";
  }
}


sub parse_sui_blocks {
  my ($ats_data, @lines) = @_;
  my $block = 0;
  my @raw;
  my $key;
  for my $i (0..$#lines) {
    0 <= $block <= 1 or die $block;
    if ($lines[$i] eq '{') {
      $block++;
      $key = $lines[$i-1];
      @raw = ();
      next;
    }
    if ($lines[$i] eq '}') {
      parse_sui_data $ats_data, $key, @raw;
      $key = undef;
      $block--;
      next;
    }
    if ($block && $lines[$i] !~ m/"/ && $lines[$i] =~ m/:/) {  # parse Reforma one-liners
      push @raw, split m/(?<=[a-z])\s+/, $lines[$i];
      next;
    }
    if ($block) {
      push @raw, $lines[$i];
      next;
    }
  }
}


method init_def ($source) {
  my $is_path = $source isa Path::Tiny || $source =~ m|/|;
  if ( $is_path && path($source)->realpath->is_dir ) {
    @mounts = sort map { "$_" } path( $source )->children( qr/^def|^dlc_/ );

    # ATS_DB originally expected def.scs to be extracted directly into the
    # source dir. In this legacy case, the source dir must be mounted first.
    my $def_dir = "$source/def";
    if ( path($def_dir)->is_dir && ! path($def_dir)->child('def')->is_dir ) {
      @mounts = ( $source, grep { $_ ne $def_dir } @mounts );
    }
  }
  else {  # $source is abstract, e.g. 'ATS'
    my $gamedir = Archive::SCS::GameDir->new(game => $source);
    @mounts = grep { /^def|^dlc_/ } $gamedir->archives;

    if ( $gamedir->game =~ m/^A/i ) {
      # The DLC file names for ATS are well-known; limiting the mounts
      # to essentially the ones suggested by country.sii saves a bunch of time.
      # Using only the DLC file list for this would be unreliable unless you
      # always run the latest game version and always get all DLC immediately.
      my %countries = Data::SCS::DefParser->new(
        mount => $gamedir->mounted('def.scs'),
        parse => 'def/country.sii',
      )->raw_data->{country}{data}->%*;
      my %mount;
      $mount{$_}++ for (
        'def.scs',
        'dlc_kenworth_t680.scs',
        'dlc_peterbilt_579.scs',
        'dlc_westernstar_49x.scs',
        'dlc_arizona.scs',
        'dlc_nevada.scs',
        map { lc sprintf 'dlc_%s.scs', $_->{country_code} } values %countries,
      );
      @mounts = grep { $mount{$_} } $gamedir->archives;
    }

    @mounts = map { $gamedir->path->child($_)->stringify } @mounts;
  }
}


method sii_files () {
  my @files = grep $archive_has_entry{$_}, @filenames;
  for my $path (@mounts) {
    # Include files from DLCs, with file names containing the DLC archive name.
    my $dlc_name = path($path)->basename =~ s/\.scs$//r;
    push @files, grep $archive_has_entry{$_}, map { s/\.sii$/.$dlc_name.sii/r } @filenames;
  }
  return sort @files;
}


method data () {
  my $ats_data = $self->raw_data;
  $self->company_cargo($ats_data) if $cargo;
  $self->company_city($ats_data);
  ats_db_company_filter($ats_data) if $tidy;
  return $ats_data;
}


method raw_data () {
  if (@mounts) {
    $archive = Archive::SCS->new;
    $archive->mount($_) for @mounts;
  }
  undef %archive_has_entry;
  $archive_has_entry{$_} = 1 for my @archive_files = $archive->list_files;
  @company_files = grep { m|^/?def/company/| } @archive_files;

  my $ats_data = {};
  parse_sui_blocks $ats_data, $self->parse_sii($_) for $self->sii_files;
  return $ats_data;
}


method company_cargo ($ats_data) {
  # read company in/out cargo data
  for my $company (sort keys $ats_data->{company}{permanent}->%*) {
    my (@in_files, @out_files);
    @in_files = grep { m|/$company/in/[^/]+\.sii$| } @company_files;
    my $in_data = {};
    parse_sui_blocks $in_data, map { $self->parse_sii($_) } @in_files;
    my @in_cargo = map {
      $in_data->{_cargo_def}{$_}{cargo} =~ s/^cargo\.//r;
    } sort keys $in_data->{_cargo_def}->%*;
    @out_files = grep { m|/$company/out/[^/]+\.sii$| } @company_files;
    my $out_data = {};
    parse_sui_blocks $out_data, map { $self->parse_sii($_) } @out_files;
    my @out_cargo = map {
      $out_data->{_cargo_def}{$_}{cargo} =~ s/^cargo\.//r;
    } sort keys $out_data->{_cargo_def}->%*;
    if ($cargo) {
      $ats_data->{company}{permanent}{$company}{in_cargo} = \@in_cargo;
      $ats_data->{company}{permanent}{$company}{out_cargo} = \@out_cargo;
    }
  }
}


method company_city ($ats_data) {
  # relate city data and company data
  for my $company (sort keys $ats_data->{company}{permanent}->%*) {
    my @editor_files;
    @editor_files = grep { m|/$company/editor/[^/]+\.sii$| } @company_files;
    my @lines = ();
    push @lines, $self->parse_sii($_) for @editor_files;
    my $company_data = {};
    parse_sui_blocks $company_data, @lines;
    my @company_defs = map {
      $company_data->{_company_def}{$_}
    } sort keys $company_data->{_company_def}->%*;
    push $ats_data->{company}{permanent}{$company}{company_def}->@*, @company_defs;
  }
}


sub ats_db_company_filter {
  my $ats_data = shift;

  # fix data errors (leftovers from earlier versions etc.)
  delete $ats_data->{company}{permanent}{mcs_con_sit};  # Mud Creek slide

  # remove prefab data, except for that of company depots
  return unless $ats_data->{prefab} && $ats_data->{company}{permanent}->%*;
  my %prefabs;
  for my $company (sort keys $ats_data->{company}{permanent}->%*) {
    $prefabs{$_->{prefab}}++ for $ats_data->{company}{permanent}{$company}{company_def}->@*;
  }
  $ats_data->{prefab}{$_}{_count} = $prefabs{$_} for sort keys %prefabs;
  for my $prefab (sort keys $ats_data->{prefab}->%*) {
    delete $ats_data->{prefab}{$prefab} unless $prefabs{$prefab};
  }
}


method all_locations ($companies = {}, $data = $self->data) {
  # get a list of every company location as an array of hashrefs
  # (allows for very simple filtering code)
  my %branch_company;
  for my $company (keys $companies->%*) {
    for my $branch ($companies->{$company}{branches}->@*) {
      $branch_company{$branch} = $company;
    }
  }
  my @locs;
  for my $branch (sort keys $data->{company}{permanent}->%*) {
    push @locs, map {
      branch  => $branch,
      company => $branch_company{$branch},
      country => lc $data->{city}{ lc $_->{city} }{country},
      city    => lc $_->{city},
      prefab  => lc $_->{prefab},
    }, $data->{company}{permanent}{$branch}{company_def}->@*;
  }
  return sort { $a->{city} cmp $b->{city} } @locs;
}


1;

=head1 NAME

Data::SCS::DefParser - Parse SCS def SII files

=head1 SYNOPSIS

  my $game_data = Data::SCS::DefParser->new(
    mount => ( $game_name or $dir_path or [@scs_files] ),
    parse => ( $def_file or [@def_files] ),
  )->raw_data;

  # Example: Write out a YAML representation of definitions;
  # omitting "parse" will default to city and company files.
  use YAML::Tiny;
  my $ats = Data::SCS::DefParser->new( mount => 'ATS' )->data;
  YAML::Tiny->new( $ats )->write( 'ats.yml' );

  # Example: List city tokens from the Texas DLC; the correct
  # def name city.dlc_tx.sii will be automatically determined.
  say for ( sort keys Data::SCS::DefParser->new(
    mount => ['dlc_tx.scs'],
    parse => ['def/city.sii'],
  )->data->{city}->%* );

=head1 DESCRIPTION

This software is a Perl module to parse units contained in SII
definition files (plain text variant). SII files are used by the
L<ATS|https://americantrucksimulator.com> and
L<ETS2|https://eurotrucksimulator2.com> simulator games.

What I originally needed was a quick solution to read basic city and
company data. Instead of creating a generic SII parser, I ended up just
throwing regular expressions at the problem until I got what I wanted.
The result turned out to be capable of parsing many other def files as
well to some extent, although it might not be very reliable. That said,
it's served me well in practice for many years without needing too
much maintenance. Which is good, since that quick-and-dirty approach
let readability suffer.

The code is structured around the expectation that the game files
have already been extracted to the file system, and have been
limited to just the files you want to parse. While you I<can>
easily point the parser to the full game installation thanks to
L<Archive::SCS>, doing so is comparatively slow. Fixing that would
be a bit of a redesign and I don't think I'll bother with it.

=head1 METHODS

=head2 all_locations

  @locs = $parser->all_locations($companies);
  @locs = $parser->all_locations($companies, $data);

Obtain an array of all company locations in the parsed game data.

Company locations (sometimes called "depots") are instances of
placed company prefabs in the game world which are an active part
of the economy simulation; in other words, they are the places
where you can either pick up or drop off cargo. The returned array
contains one item for each company location looking like this:

  {
    branch  => 'dg_wd_hrv',   # company game token: Deepgrove logging site
    company => 'deepgrove'    # unique ID, chosen by you (see below)
    country => 'montana',     # game token for Montana
    city    => 'thompson_f',  # game token for Thompson Falls
    prefab  => 'd_wd_hrv1',   # game token for Deepgrove logging site prefab
  }

The game treats functionally distinct parts of what appears to be a
single company in the game world as a separate company each internally.
This module refers to such distinct parts as "company branches".

For example, the forestry company Deepgrove has locations that
are logging sites and some locations that are sawmills.
These location types are implemented as separate companies by the
game engine, but they both use the same player-visible branding
and are clearly meant to be a single company semantically.

The C<$companies> hash ref is expected to have one entry for each
such semantic company, with the hash key being a unique ID for
that company. You can pick any truthy string as the ID, it's
simply fed back to you as C<company> in the method return value.
The entry value is another hash ref that has a C<branches>
entry, which is an array ref of game company tokens that should
be treated as belonging to the respective semantic company.

  $companies = {
    'deepgrove' => {   # unique ID for Deepgrove, chosen by you
      branches => [
        'dg_wd_hrv',   # game token for Deepgrove logging site
        'dg_wd_saw',   # game token for Deepgrove sawmill
        'dg_wd_saw1',  # game token for Deepgrove sawmill variant
      ],
    },
    ...
  };

The optional C<$data> attribute is simply the output of L</data>,
which you can pass in to avoid having to parse files more than
once.

See F<example/all_locations.pl> in this dist for how to create the
companies hash from the game files, and use that data to produce
a table of all company locations in the game.

=head2 data

  $data    = $parser->data;

  %city    = $data->{city}{ $city_token }->%*;
  %company = $data->{company}{permanent}{ $company_token }->%*;
  %country = $data->{country}{data}{ $country_token }->%*;

Returns a hash ref of parsed game data. This method is primarily
designed to retrieve basic city and company data, which can be
accessed like shown above. Depending on which archive entries
you decide to parse, additional data may be returned in the same
format as described for the L</raw_data> method.

Some munging is performed to make the game data easier to use.
For example, company_def editor entries are inserted into a
company's "permanent" tree to keep them nice and organized:

  @cm_min_str_locations
    = $data->{company}{permanent}{cm_min_str}{company_def}->@*;

Additionally, this method performs cleanup steps that remove data
not considered relevant when focusing on cities and companies.
The exact behavior of these cleanup steps is subject to change.
See also L</GLOBALS> below. Unless you're specifically interested
in city and company data, you should probably use L</raw_data>
instead.

The parsed data is currently not cached, which means each call to
this method will parse all files again. This may change in a future
version. Until then, you should cache the returned hash locally.

See F<example/dump.pl> in this dist for how to use this method to
write city/company data to a file in a common data exchange format
like YAML or JSON.

=head2 new

  $parser = Data::SCS::DefParser->new( mount => ... );

Creates a new L<Data::SCS::DefParser> object. Available parameters:

=over

=item mount

The game data archives to consider when parsing. Mandatory.

Can be an array reference with pathnames of archives to mount.
Archives are mounted using L<Archive::SCS>.

If given the pathname of a directory instead, the parser will
behave as if an array ref had been given which contains all children
of that directory whose names start with C<def> or C<dlc_>.
This is legacy behavior and shouldn't be relied upon.

If given the string C<'ATS'>, the parser will try to mount
C<def.scs> and all map DLC relevant for your currently
installed version of ATS. The same I<should> happen for
C<'ETS2'>, but that is known to be unreliable at present.
The full game names may be used as aliases. The behavior
if given other strings is currently unspecified.

Additionally, the C<mount> parameter accepts an L<Archive::SCS>
object, but this currently results in unintended behavior and
shouldn't be relied upon.

=item parse

The list of archive entries to parse and return data for.
Can either be an array reference of pathnames or a single pathname.
Optional. When not given, this parameter defaults to:

  parse => [qw(
    def/country.sii
    def/city.sii
    def/company.sii
  )]

=back

=head2 raw_data

  local $Data::SCS::DefParser::tidy = 0;
  $data = $parser->raw_data;

Parses the game data and returns a hash reference with the
result. Hash keys for named units will be unit name components.
For unnamed units, keys will be unit class names with a prefixed
underscore. The entry pathname is currently not recorded
(but this may change because it can be relevant).

The data output format is still evolving. There is already some
code that depends on it, so radical changes are somewhat unlikely.
But if you use this parser for your own projects, it would still
be wise to let the author know about that, so that your needs
can be taken into consideration for future development.

This method is currently affected by the tidy feature.
This is unintended and will probably be fixed eventually.
As a workaround, you can disable tidy explicitly if needed.

=head1 GLOBALS

=over

=item $Data::SCS::DefParser::cargo

Controls whether C<data()> will populate cargo in/out attributes
for companies. This is disabled by default.

=item $Data::SCS::DefParser::tidy

Controls whether C<data()> will run certain cleanup steps, such as
removing unit attributes that were considered "currently useless
clutter" at the time this feature was first implemented. This is
enabled by default. The exact behavior is subject to change.

This variable currently enables some of the cleanup steps for
C<raw_data()>, too. This is unintended and will probably be fixed
eventually. Once C<raw_data()> is fixed, this variable will likely
no longer have any effect on C<data()>, either. The parser will
then simply always run cleanup for C<data()> and never do so for
C<raw_data()>.

=back

=head1 SEE ALSO

=over

=item * L<https://modding.scssoft.com/wiki/Documentation/Engine/Game_data>

=item * L<https://modding.scssoft.com/wiki/Documentation/Engine/Units>

=back

=head1 AUTHOR

L<nautofon|https://github.com/nautofon>

=head1 COPYRIGHT

This software is copyright (c) 2026 by nautofon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
