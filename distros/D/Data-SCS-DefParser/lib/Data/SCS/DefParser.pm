use v5.36;
use Object::Pad 0.805;

class Data::SCS::DefParser 0.10
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


method include_file ($file) {
  $archive_has_entry{$file} or croak
    sprintf "Couldn't find file '%s' in: %s", $file, join ", ", @mounts;
  my $inc = $archive->read_entry($file);
  utf8::decode($inc);
  my @inc = grep {$_} map {trim $_} split m/\n/, $inc;
  return @inc;
}


method parse_sii ($file) {
  utf8::decode my $sii = $archive->read_entry($file);
  my ($magic, $unit) = parse_block $sii;
  $magic =~ m/^ \N{ BYTE ORDER MARK }? SiiNunit $/x or die
    sprintf "Expected SiiNunit, found '%s' in %s", $magic, $file;
  my @input = grep {$_} map {trim $_} split m/\n/, $unit;
  my @lines;
  while (my $line = shift @input) {
    if (my ($inc) = $line =~ m/^\@include\s+"([^"]+)"$/) {
      my $inc_path = path("/$file")->parent->relative("/")->child($inc);
      unshift @input, $self->include_file($inc_path);
      next;
    }
    push @lines, $line;
  }
  @lines = map {trim $_} map {
    s{/\* .*? \*/}{}gx;
    m{/\*|\*/} and die "Multi-line comments unimplemented";
    # clip comments
    s{#.*$|//.*$}{}r;
  } @lines;
  @lines = grep {$_} map {trim $_} map {
    # make sure { and } stand by their own on a line
    my @line = ($_);
    while ($line[$#line] =~ m/^([^\{]+)([\{\}])(.*)/) {
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
  if ( $value =~ m/^"([^"]+)"$/ ) {
    my $str = $1 =~ s{ \\x( [0-9A-Fa-f]{2} ) }{ chr hex $1 }egrx;
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
      # to just the needed ones saves a bunch of time.
      @mounts = sort +(
        'dlc_kenworth_t680.scs',
        'dlc_peterbilt_579.scs',
        'dlc_westernstar_49x.scs',
        'dlc_arizona.scs',
        'dlc_nevada.scs',
        grep { /^def|^dlc_[a-z]{2}\.scs$/ } @mounts,
      );
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
  parse_sui_blocks $ats_data, map { $self->parse_sii($_) } $self->sii_files;
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


1;
