package Config::INI::RefVars;
use 5.010;
use strict;
use warnings;
use feature ":5.10";

use Carp;
use Config;
use Cwd qw(abs_path);
use File::Spec::Functions qw(catdir catfile file_name_is_absolute splitpath);
use Config::INI::RefVars::Builtins;

our $VERSION = '1.04';

use constant DFLT_TOCOPY_SECTION => "__TOCOPY__";
use constant FLD_KEY_PREFIX      => __PACKAGE__ . ' __ ';

use constant {
              EXPANDED          => FLD_KEY_PREFIX . 'EXPANDED',
              CMNT_VL           => FLD_KEY_PREFIX . 'CMNT_VL',
              TOCOPY_SECTION    => FLD_KEY_PREFIX . 'TOCOPY_SECTION',
              CURR_TOCP_SECTION => FLD_KEY_PREFIX . 'CURR_TOCP_SECTION',
              TOCOPY_VARS       => FLD_KEY_PREFIX . 'TOCOPY_VARS',
              NOT_TOCOPY        => FLD_KEY_PREFIX . 'NOT_TOCOPY',
              SECTIONS          => FLD_KEY_PREFIX . 'SECTIONS',
              SECTIONS_H        => FLD_KEY_PREFIX . 'SECTIONS_H',
              SRC_NAME          => FLD_KEY_PREFIX . 'SRC_NAME',
              VARIABLES         => FLD_KEY_PREFIX . 'VARIABLES',
              FUNCTIONS         => FLD_KEY_PREFIX . 'FUNCTIONS',
              GLOBAL_VARS       => FLD_KEY_PREFIX . 'GLOBAL_VARS',
              GLOBAL_MODE       => FLD_KEY_PREFIX . 'GLOBAL_MODE',
              VREF_RE           => FLD_KEY_PREFIX . 'VREF_RE',
              SEPARATOR         => FLD_KEY_PREFIX . 'SEPARATOR',
              BACKUP            => FLD_KEY_PREFIX . 'BACKUP',
              VARNAME_CHK_RE    => FLD_KEY_PREFIX . 'VARNAME_CHK_RE',
              DISPATCH_TABLE    => FLD_KEY_PREFIX . 'DISPATCH_TABLE',
             };

my %Globals = ('=:'       => catdir("", ""),
               '=::'      => $Config{path_sep},
               '=VERSION' => $VERSION,
               '=devnull' => File::Spec::Functions::devnull(),
               '=rootdir' => File::Spec::Functions::rootdir(),
               '=tmpdir'  => File::Spec::Functions::tmpdir(),
              );

# Match punctuation chars, but not the underscores.
my $Modifier_Char = '[^_[:^punct:]]';

my ($_look_up, $_x_var_name, $_expand_vars, $_user_function_call, $_function_body, $_parse_ini);

my $_dispatch_sub = sub {
  my ($self, $name) = @_;

  my $dispatch = $self->{+DISPATCH_TABLE}
    or croak("Internal error: dispatch table is not initialized");

  my $sub = $dispatch->{$name}
    or croak("unknown function '$name'");

  return $sub;
};

my $_split_dispatch_spec = sub {
  my ($self, $spec) = @_;

  $spec =~ s/^\s+//;
  $spec =~ s/\s+$//;

  croak("empty function call") if $spec eq "";

  my @parts;
  my $buf = "";
  my $level = 0;

  foreach my $token (split(/(\$\(|\))/, $spec)) {
    if ($token eq '$(') {
      ++$level;
      $buf .= $token;
    }
    elsif ($token eq ')') {
      croak("unterminated variable reference") if !$level;
      --$level;
      $buf .= $token;
    }
    else {
      foreach my $subtok (split(/(,)/, $token)) {
        if ($subtok eq ',' && !$level) {
          push(@parts, $buf);
          $buf = "";
        }
        else {
          $buf .= $subtok;
        }
      }
    }
  }
  croak("unterminated variable reference") if $level;

  push(@parts, $buf);

  my $name = shift(@parts) // "";
  $name =~ s/^\s+//;
  $name =~ s/\s+$//;
  croak("empty function name") if $name eq "";

  @parts = map {
    s/^\s+//;
    s/\s+$//;
    $_;
  } @parts;

  return ($name, @parts);
};


my $_dispatch_call = sub {
  my ($self, $curr_sect, $spec, $seen) = @_;

  my ($name, @args) = $self->$_split_dispatch_spec($spec);
  @args = map { $self->$_expand_vars($curr_sect, undef, $_, $seen, 1) } @args;

  my $sub = $self->$_dispatch_sub($name);
  return $sub->(@args) // "";
};


$_function_body = sub {
  my ($self, $curr_sect, $name) = @_;
  my $functions = $self->{+FUNCTIONS} // {};

  if ($name =~ $self->{+VREF_RE}) {
    my ($section, $basename) = ($1, $2);
    return (exists($functions->{$section}) && exists($functions->{$section}{$basename})) ?
      ($section, $basename, $functions->{$section}{$basename}) : ();
  }
  return ($curr_sect, $name, $functions->{$curr_sect}{$name})
    if exists($functions->{$curr_sect}) && exists($functions->{$curr_sect}{$name});

  my $tocopy_section = $self->{+TOCOPY_SECTION};
  return ($tocopy_section, $name, $functions->{$tocopy_section}{$name})
    if ($curr_sect ne $tocopy_section
        && exists($functions->{$tocopy_section})
        && exists($functions->{$tocopy_section}{$name}));
  return;
};


$_user_function_call = sub {
  my ($self, $curr_sect, $spec, $seen) = @_;

  my ($name, @args) = $self->$_split_dispatch_spec($spec);
  @args = map { $self->$_expand_vars($curr_sect, undef, $_, $seen, 1) } @args;

  my ($func_section, $func_name, $body) = $self->$_function_body($curr_sect, $name);

  if (!defined($body)) {
    croak("unknown function '$name'") if $name =~ $self->{+VREF_RE};
    return $self->$_dispatch_sub($name)->(@args) // "";
  }

  my $x_func_name = "[$func_section]#=$func_name";

  croak("recursive function '$x_func_name' calls itself") if exists($seen->{$x_func_name});

  $seen->{$x_func_name} = undef;

  my $variables = $self->{+VARIABLES};
  my $sect_vars = $variables->{$curr_sect} //= {};
  my (%had_arg, %old_arg, %param);

  for my $i (1 .. @args) {
    $param{$i} = $args[$i - 1];
  }

  while ($body =~ /\$\((\d+)\)/g) {
    $param{$1} //= "";
  }

  foreach my $arg (keys(%param)) {
    $had_arg{$arg} = exists($sect_vars->{$arg});
    $old_arg{$arg} = $sect_vars->{$arg} if $had_arg{$arg};
    $sect_vars->{$arg} = $param{$arg};
  }
  my $result;
  eval { $result = $self->$_expand_vars($curr_sect, undef, $body, $seen, 1); 1; } or die($@);

  foreach my $arg (keys(%param)) {
    if ($had_arg{$arg}) {
      $sect_vars->{$arg} = $old_arg{$arg};
    }
    else {
      delete($sect_vars->{$arg});
    }
  }
  delete($seen->{$x_func_name});
  return $result;
};


my $_check_tocopy_vars = sub {
  my ($self, $tocopy_vars, $set) = @_;

  croak("'tocopy_vars': expected HASH ref") if ref($tocopy_vars) ne 'HASH';
  $tocopy_vars = { %$tocopy_vars };

  while (my ($var, $value) = each(%$tocopy_vars)) {
    croak("'tocopy_vars': value of '$var' is a ref, expected scalar") if ref($value);
    if (!defined($value)) {
      carp("'tocopy_vars': value '$var' is undef - treated as empty string");
      $tocopy_vars->{$var} = "";
    }
    croak("'tocopy_vars': variable '$var': name is not permitted")
      if ($var =~ /^\s*$/ || $var =~ /^[[=;]/);
  }
  $self->{+TOCOPY_VARS} = {%$tocopy_vars} if $set;
  return $tocopy_vars;
};


my $_check_not_tocopy = sub {
  my ($self, $not_tocopy, $set) = @_;
  my $ref = ref($not_tocopy);
  if ($ref eq 'ARRAY') {
    foreach my $v (@$not_tocopy) {
      croak("'not_tocopy': undefined value in array") if !defined($v);
      croak("'not_tocopy': unexpected ref value in array") if ref($v);
    }
    $not_tocopy = {map {$_ => undef} @$not_tocopy};
  }
  elsif ($ref eq 'HASH') {
    $not_tocopy = %{$not_tocopy};
  }
  else {
    croak("'not_tocopy': unexpected type: must be ARRAY or HASH ref");
  }
  $self->{+NOT_TOCOPY} = $not_tocopy if $set;
  return $not_tocopy;
};


sub new {
  my ($class, %args) = @_;

  state $allowed_keys = { map { $_ => undef } qw(builtins
                                                 cmnt_vl
                                                 global_mode
                                                 not_tocopy
                                                 separator
                                                 tocopy_section
                                                 tocopy_vars
                                                 varname_chk_re
                                               )};

  _check_args(\%args, $allowed_keys);

  my $builtins = delete($args{builtins}) // {};
  croak("builtins must be a hash reference") if ref($builtins) ne 'HASH';
  my $dispatch = Config::INI::RefVars::Builtins::default_dispatch_table();
  foreach my $name (keys(%$builtins)) {
    croak("builtin '$name' is not a CODE reference") if ref($builtins->{$name}) ne 'CODE';
    $dispatch->{$name} = $builtins->{$name};
  }
  my $self = {
              +DISPATCH_TABLE() => $dispatch,
             };

  croak("'tocopy_section': must not be a reference") if ref($args{tocopy_section});

  if (exists($args{separator})) {
    state $allowed_sep_chars = "#!%&',./:~\\";
    my $sep = $args{separator};
    croak("'separator': unexpected ref type, must be a scalar") if ref($sep);
    croak("'separator': invalid value. Allowed chars: $allowed_sep_chars")
      if $sep !~ m{^[\Q$allowed_sep_chars\E]+$};
    $self->{+SEPARATOR} = $sep;
    $self->{+VREF_RE}   = qr/^(.*?)(?:\Q$sep\E)(.*)$/;
  }
  else {
    $self->{+VREF_RE} = qr/^\[\s*(.*?)\s*\](.*)$/;
  }
  $self->{+CMNT_VL}        = $args{cmnt_vl};
  $self->{+TOCOPY_SECTION} = $args{tocopy_section} // DFLT_TOCOPY_SECTION;
  $self->$_check_tocopy_vars($args{tocopy_vars}, 1) if exists($args{tocopy_vars});
  $self->$_check_not_tocopy($args{not_tocopy}, 1)   if exists($args{not_tocopy});

  $self->{+GLOBAL_MODE} = !!$args{global_mode};

  if (exists($args{varname_chk_re})) {
    croak("'varname_chk_re': must be a compiled regex")
      if ref($args{varname_chk_re}) ne 'Regexp';
    $self->{+VARNAME_CHK_RE} = $args{varname_chk_re};
  }
  return bless($self, $class);
}


my $_expand_value = sub { return $_[0]->$_expand_vars($_[1], undef, $_[2]); };

#
# We assume that this is called when the target section is still empty and if
# tocopy vars exist.
#
my $_cp_tocopy_vars = sub {
  my ($self, $to_sect_name) = @_;

  my $comm_sec   = $self->{+VARIABLES}{$self->{+TOCOPY_SECTION}} // die("no tocopy vars");
  my $not_tocopy = $self->{+NOT_TOCOPY};
  my $to_sec     = $self->{+VARIABLES}{$to_sect_name} //= {};
  my $expanded   = $self->{+EXPANDED};

  foreach my $comm_var (keys(%$comm_sec)) {
    next if exists($not_tocopy->{$comm_var});
    $to_sec->{$comm_var} = $comm_sec->{$comm_var};
    my $comm_x_var_name = "[" . $self->{+TOCOPY_SECTION} . "]$comm_var";
    $expanded->{"[$to_sect_name]$comm_var"} = undef
      if exists($expanded->{$comm_x_var_name});
  }
};


my $_read_ini_file = sub {
  my ($path) = @_;

  open(my $fh, '<', $path) or croak("'$path': cannot open file: $!");
  my @lines = <$fh>;
  close($fh) or croak("'$path': cannot close file: $!");

  return \@lines;
};


$_parse_ini = sub {
  my ($self, $src, $curr_section, $include_stack, $src_dir, $src_name) = @_;

  croak("Internal error: argument is not an ARRAY ref") if ref($src) ne 'ARRAY';

  $src_name //= $self->{+SRC_NAME};
  $src_dir  //= '.';
  $include_stack //= {};

  my $cmnt_vl     = $self->{+CMNT_VL};
  my $sections    = $self->{+SECTIONS};
  my $sections_h  = $self->{+SECTIONS_H};
  my $expanded    = $self->{+EXPANDED};
  my $variables   = $self->{+VARIABLES};
  my $functions   = $self->{+FUNCTIONS};
  my $tocopy_sec  = $self->{+TOCOPY_SECTION};
  my $tocopy_vars = $variables->{$tocopy_sec}; # hash key need not to exist!
  my $global_mode = $self->{+GLOBAL_MODE};
  my $vnm_chk_re  = $self->{+VARNAME_CHK_RE};

  my $tocopy_sec_declared;

  my $i;                        # index in for() loop
  my $_fatal = sub { croak("'$src_name': ", $_[0], " at line ", $i + 1); };

  my $_include_file = sub {
    my ($include) = @_;

    $include =~ s/^\s+//;
    $include =~ s/\s+$//;
    $_fatal->("missing file name in include directive") if $include eq "";

    $include = $self->$_expand_vars(defined($curr_section) ? $curr_section : $tocopy_sec,
                                    undef,
                                    $include,
                                    undef,
                                    1,
                                   );

    my $path = file_name_is_absolute($include) ? $include : catfile($src_dir, $include);

    my $abs_path = abs_path($path) or $_fatal->("'$include': cannot resolve include file");

    $_fatal->("'$include': recursive include") if exists($include_stack->{$abs_path});

    local $include_stack->{$abs_path} = undef;

    my ($vol, $dirs) = splitpath($abs_path);
    my $inc_dir = catdir(length($vol // "") ? $vol : (), $dirs);

    my ($inc_tocopy_declared, $inc_curr_section) =
      $self->$_parse_ini($_read_ini_file->($abs_path),
                         $curr_section,
                         $include_stack,
                         $inc_dir,
                         $abs_path,
                        );

    $tocopy_sec_declared ||= $inc_tocopy_declared;
    $curr_section = $inc_curr_section if defined($inc_curr_section);
  };

  my $set_curr_section = sub {
    $curr_section = shift;
    if ($curr_section eq $tocopy_sec) {
      $_fatal->("tocopy section '$tocopy_sec' must be first section") if @$sections;
      $tocopy_vars = $variables->{$tocopy_sec} = {} if !$tocopy_vars;
      $functions->{$tocopy_sec} //= {};
      $tocopy_sec_declared = 1;
    }
    elsif ($tocopy_vars && !$global_mode) {
      $self->$_cp_tocopy_vars($curr_section);
    }
    else {
      $variables->{$curr_section} = {};
    }
    $functions->{$curr_section} //= {};

    $_fatal->("'$curr_section': duplicate header") if exists($sections_h->{$curr_section});
    $sections_h->{$curr_section} = @$sections; # Index!
    push(@$sections, $curr_section);
  };

  for ($i = 0; $i < @$src; ++$i) {
    my $line = $src->[$i];
    $line =~ s/\s+$//;
    next if $line eq "";

    if ($line =~ /^=include(?:\s+(.+))?\z/) {
      $_include_file->($1 // "");
      next;
    }

    if (index($line, ";!") == 0 || index($line, "=") == 0) {
      $_fatal->("directives are not yet supported");
    }

    $line =~ s/^\s+//;
    next if $line eq "" || $line =~ /^[;#]/;

    # section header
    if (index($line, "[") == 0) {
      $line =~ s/\s*[#;][^\]]*$//;
      $line =~ /^\[\s*(.*?)\s*\]$/ or $_fatal->("invalid section header");
      $set_curr_section->($1);
      next;
    }

    # var = val
    $line =~ s/\s+;.*$// if $cmnt_vl;
    $set_curr_section->($tocopy_sec) if !defined($curr_section);

    $line =~ /^(.*?)\s*($Modifier_Char*?)=(?:\s*)(.*)/
      or $_fatal->("neither section header nor key definition");

    my ($var_name, $modifier, $value) = ($1, $2, $3);

    if ($modifier =~ s/\\\z//) {
      while ($value =~ s/\\\z//) {
        last if $i + 1 >= @$src;
        my $next_line = $src->[++$i];
        $next_line =~ s/\s+$//;

        if (index($next_line, "=") == 0) {
          $_fatal->("directive in line continuation");
        }
        $value .= $next_line;
      }
    }
    if ($vnm_chk_re) {
      croak("'$var_name': var name does not match varname_chk_re") if $var_name !~ $vnm_chk_re;
    }

    my $x_var_name = $self->$_x_var_name($curr_section, $var_name);
    my $exp_flag   = exists($expanded->{$x_var_name});

    $_fatal->("empty variable name") if $var_name eq "";

    my $sect_vars = $variables->{$curr_section} //= {};
    my $sect_funcs = $functions->{$curr_section} //= {};

    if ($modifier eq '#') {
      $sect_funcs->{$var_name} = $value;
    }
    elsif ($modifier eq "") {
      delete $expanded->{$x_var_name} if $exp_flag;
      $sect_vars->{$var_name} = $value;
    }
    elsif ($modifier eq '?') {
      $sect_vars->{$var_name} = $value if !exists($sect_vars->{$var_name});
    }
    elsif ($modifier eq '??') {
      $sect_vars->{$var_name} = $value
        if (!exists($sect_vars->{$var_name}) || $sect_vars->{$var_name} eq "");
    }
    elsif ($modifier eq '+') {
      if (exists($sect_vars->{$var_name})) {
        $sect_vars->{$var_name} .= " "
          . ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value);
      }
      else {
        $sect_vars->{$var_name} = $value;
      }
    }
    elsif ($modifier eq '.') {
      $sect_vars->{$var_name} = ($sect_vars->{$var_name} // "")
        . ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value);
    }
    elsif ($modifier eq ':') {
      delete $expanded->{$x_var_name} if $exp_flag;
      $sect_vars->{$var_name} = $self->$_expand_vars($curr_section, $var_name, $value, undef, 1);
    }
    elsif ($modifier eq '+>') {
      if (exists($sect_vars->{$var_name})) {
        $sect_vars->{$var_name} =
          ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value)
          . ' ' . $sect_vars->{$var_name};
      }
      else {
        $sect_vars->{$var_name} = $value;
      }
    }
    elsif ($modifier eq '.>') {
      $sect_vars->{$var_name} = ($exp_flag ? $self->$_expand_value($curr_section, $value) : $value)
        . ($sect_vars->{$var_name} // "");
    }
    else {
      $_fatal->("'$modifier': unsupported modifier");
    }
  }
  return ($tocopy_sec_declared, $curr_section);
};


sub parse_ini {
  my $self = shift;
  my %args = (cleanup => 1, @_);

  state $allowed_keys = {
    map { $_ => undef } qw(cleanup src src_name tocopy_section tocopy_vars not_tocopy)
  };
  state $dflt_src_name = "INI data";

  _check_args(\%args, $allowed_keys);

  foreach my $scalar_arg (qw(tocopy_section src_name)) {
    croak("'$scalar_arg': must not be a reference") if ref($args{$scalar_arg});
  }

  delete $self->{+SRC_NAME} if exists($self->{+SRC_NAME});
  $self->{+SRC_NAME} = $args{src_name} if exists($args{src_name});

  my ($cleanup, $src, $tocopy_section, $tocopy_vars, $not_tocopy)
    = @args{qw(cleanup src tocopy_section tocopy_vars not_tocopy)};

  croak("'src': missing mandatory argument") if !defined($src);

  my $backup = $self->{+BACKUP} //= {};

  if (defined($tocopy_section)) {
    $backup->{tocopy_section} = $self->{+TOCOPY_SECTION};
    $self->{+TOCOPY_SECTION}  = $tocopy_section;
  }
  else {
    $tocopy_section = $self->{+TOCOPY_SECTION};
  }

  $self->{+CURR_TOCP_SECTION} = $tocopy_section;
  $Globals{'=TO_CP_SEC'}      = $tocopy_section;

  if ($tocopy_vars) {
    $backup->{tocopy_vars} = $self->{+TOCOPY_VARS};
    $self->$_check_tocopy_vars($tocopy_vars, 1);
  }

  if ($not_tocopy) {
    $backup->{not_tocopy} = $self->{+NOT_TOCOPY};
    $self->$_check_not_tocopy($not_tocopy, 1);
  }

  $self->{+SECTIONS}   = [];
  $self->{+SECTIONS_H} = {};
  $self->{+EXPANDED}   = {};
  $self->{+VARIABLES}  = {
    $tocopy_section => ($self->{+TOCOPY_VARS} ? {%{$self->{+TOCOPY_VARS}}} : {})
  };
  $self->{+FUNCTIONS} = {};

  my $global_vars     = $self->{+GLOBAL_VARS} = {%Globals};
  my $variables       = $self->{+VARIABLES};
  my $tocopy_sec_vars = $variables->{$tocopy_section};

  if (my $ref_src = ref($src)) {
    $self->{+SRC_NAME} = $dflt_src_name if !exists($self->{+SRC_NAME});

    if ($ref_src eq 'ARRAY') {
      $src = [@$src];
      foreach my $entry (@$src) {
        croak("'src': unexpected ref type in array") if ref($entry);
        if (!defined($entry)) {
          carp("'src': undef entry - treated as empty string");
          $entry = "";
        }
      }
    }
    else {
      croak("'src': $ref_src: ref type not allowed");
    }
  }
  else {
    if (index($src, "\n") < 0) {
      my $path = $src;
      my $abs_path = abs_path($path) or croak("'$path': cannot resolve file name");
      $src = $_read_ini_file->($abs_path);
      $self->{+SRC_NAME} = $path if !exists($self->{+SRC_NAME});

      my ($vol, $dirs, $file) = splitpath($abs_path);
      @{$global_vars}{'=INIfile', '=INIdir'} = ($file,
                                                catdir(length($vol // "") ? $vol : (), $dirs),
                                               );
    }
    else {
      $src = [split(/\n/, $src)];
      $self->{+SRC_NAME} = $dflt_src_name if !exists($self->{+SRC_NAME});
    }
  }

  $global_vars->{'=srcname'} = $self->{+SRC_NAME};

  my $src_dir = '.';
  my $include_stack = {};

  if (!ref($args{src}) && index($args{src}, "\n") < 0) {
    my $abs_path = abs_path($args{src})
      or croak("'$args{src}': cannot resolve file name");
    $include_stack->{$abs_path} = undef;
    my ($vol, $dirs) = splitpath($abs_path);
    $src_dir = catdir(length($vol // "") ? $vol : (), $dirs);
  }

  my ($tocopy_sec_declared, undef) = $self->$_parse_ini($src,
                                                        undef,
                                                        $include_stack,
                                                        $src_dir,
                                                        $self->{+SRC_NAME},
                                                       );

  my @sections = ((exists($self->{+SECTIONS_H}{$tocopy_section}) ? () : $tocopy_section),
                  @{$self->{+SECTIONS}},
                 );

  foreach my $section (@sections) {
    my $sec_vars = $variables->{$section};

    foreach my $variable (keys(%$sec_vars)) {
      my $value = $sec_vars->{$variable};
      $sec_vars->{$variable} = $self->$_expand_vars($section, $variable, $value);
    }
  }

  if ($cleanup) {
    foreach my $section (keys(%$variables)) {
      my $sec_vars = $variables->{$section};
      foreach my $var (keys(%$sec_vars)) {
        delete $sec_vars->{$var} if index($var, '=') >= 0;
      }
    }

    delete $variables->{$self->{+TOCOPY_SECTION}} if (!$tocopy_sec_declared && !%$tocopy_sec_vars);
  }
  else {
    if ($self->{+GLOBAL_MODE}) {
      foreach my $section (keys(%$variables)) {
        my $sec_vars = $variables->{$section};
        $sec_vars->{'='} = $section;
      }
      @{$tocopy_sec_vars}{keys(%$global_vars)} = values(%$global_vars);
    }
    else {
      foreach my $section (keys(%$variables)) {
        my $sec_vars = $variables->{$section};
        $sec_vars->{'='} = $section;
        @{$sec_vars}{keys(%$global_vars)} = values(%$global_vars);
      }
    }
  }

  $self->{+TOCOPY_SECTION} = $backup->{tocopy_section} if exists($backup->{tocopy_section});
  $self->{+TOCOPY_VARS}    = $backup->{tocopy_vars}    if exists($backup->{tocopy_vars});
  $self->{+NOT_TOCOPY}     = $backup->{not_tocopy}     if exists($backup->{not_tocopy});
  $backup = {};

  return $self;
}


sub current_tocopy_section { $_[0]->{+CURR_TOCP_SECTION} }
sub tocopy_section         { $_[0]->{+TOCOPY_SECTION} }
sub global_mode            { $_[0]->{+GLOBAL_MODE} }

sub sections {
  return defined($_[0]->{+SECTIONS}) ? [@{$_[0]->{+SECTIONS}}] : undef;
}

sub sections_h {
  return defined($_[0]->{+SECTIONS_H}) ? +{ %{$_[0]->{+SECTIONS_H}} } : undef;
}

sub separator { $_[0]->{+SEPARATOR} }
sub src_name  { $_[0]->{+SRC_NAME} }


sub variables {
  my $vars = $_[0]->{+VARIABLES} // return undef;
  return { map { $_ => {%{$vars->{$_}}} } keys(%$vars) };
}


$_look_up = sub {
  my ($self, $curr_sect, $variable) = @_;
  my $matched = $variable =~ $self->{+VREF_RE};
  my ($v_section, $v_basename) = $matched ? ($1, $2) : ($curr_sect, $variable);
  my $v_value;
  my $variables      = $self->{+VARIABLES};
  my $tocopy_section = $self->{+TOCOPY_SECTION};
  if (!exists($variables->{$v_section})) {
    $v_value = "";
  }
  elsif (exists($variables->{$v_section}{$v_basename})) {
    $v_value = $variables->{$v_section}{$v_basename};
  }
  elsif ($v_basename !~ /\S/) {
    $v_value = $v_basename;
  }
  elsif ($v_basename eq '=') {
    $v_value = $v_section;
  }
  elsif ($v_basename =~ /^=(?:ENV|env):\s*(.*)$/) {
    $v_value = $ENV{$1} // "";
  }
  elsif ($v_basename =~ /^=CONFIG:\s*(.*)$/) {
    $v_value = $Config{$1} // "";
  }
  elsif (exists($self->{+GLOBAL_VARS}{$v_basename})) {
    $v_value = $self->{+GLOBAL_VARS}{$v_basename};
  }
  elsif ($self->{+GLOBAL_MODE} && exists($variables->{$tocopy_section}{$v_basename})) {
    if (!$matched
        && $curr_sect ne $tocopy_section
        && exists($self->{+NOT_TOCOPY}{$v_basename})
       ) {
      $v_value = "";
    }
    else {
      $v_value = $variables->{$tocopy_section}{$v_basename};
    }
  }
  else {
    $v_value = "";
  }
  die("Internal error") if !defined($v_value);
  return wantarray ? ($v_section, $v_basename, $v_value) : $v_value;
};


# Extended name of a variable definition
$_x_var_name = sub {
  my ($self, $curr_sect, $variable) = @_;

  return ($variable, "[$curr_sect]$variable");
};


$_expand_vars = sub {
  my ($self, $curr_sect, $variable, $value, $seen, $not_seen) = @_;
  my $top = !$seen;
  my @result = ("");
  my @raw = ("");
  my $level = 0;
  my $x_variable_name;

  if (defined($variable)) {
    ((my $var_basename), $x_variable_name) = $self->$_x_var_name($curr_sect, $variable);

    if (exists($self->{+EXPANDED}{$x_variable_name})) {
      return $self->{+VARIABLES}{$curr_sect}{$variable};
    }
    if ($var_basename =~ /^=(?:ENV|CONFIG):/) {
      return $self->$_look_up($curr_sect, $variable);
    }

    croak("recursive variable '$x_variable_name' references itself")
      if exists($seen->{$x_variable_name});

    $seen->{$x_variable_name} = undef if !$not_seen;
  }

  foreach my $token (split(/(\$\(|\))/, $value)) {
    if ($token eq '$(') {
      ++$level;
      $raw[$level - 1] .= '$(' if $level > 1;
    }
    elsif ($token eq ')' && $level) {
      my $raw_expr = $raw[$level];

      if ($result[$level] eq '==') {
        $result[$level - 1] .= $variable;
      }
      elsif ($raw_expr =~ /^\s*=#\s*(.*)$/s) {
        $result[$level - 1] .= $self->$_user_function_call($curr_sect, $1, $seen);
      }
      elsif ($raw_expr =~ /^\s*=&\s*(.*)$/s) {
        $result[$level - 1] .= $self->$_dispatch_call($curr_sect, $1, $seen);
      }
      else {
        my ($ref_section, $ref_variable, $ref_value) =
          $self->$_look_up($curr_sect, $result[$level]);
        $result[$level - 1] .= $self->$_expand_vars(
                                                    $ref_section,
                                                    $ref_variable,
                                                    $ref_value,
                                                    $seen,
                                                   );
      }
      $raw[$level - 1] .= $raw_expr . ')';
      pop(@result);
      pop(@raw);
      --$level;
    }
    else {
      $result[$level] .= $token;
      $raw[$level]    .= $token;
    }
  }

  croak("'$x_variable_name': unterminated variable reference") if $level;
  $value = $result[0];
  if ($x_variable_name) {
    $self->{+EXPANDED}{$x_variable_name} = undef if $top;
    delete $seen->{$x_variable_name};
  }
  return $value;
};


#
# This is a function, not a method!
#
sub _check_args {
  my ($args, $allowed_args) = @_;
  foreach my $key (keys(%$args)) {
    croak("'$key': unsupported argument") if !exists($allowed_args->{$key});
  }
  delete @{$args}{ grep { !defined($args->{$_}) } keys(%$args) };
}


1; # End of Config::INI::RefVars


__END__


=pod


=head1 NAME

Config::INI::RefVars - INI file reader with variable references and function calls


=head1 VERSION

Version 1.04

=head1 SYNOPSIS

  use Config::INI::RefVars;

  my $cfg = Config::INI::RefVars->new();
  $cfg->parse_ini(src => 'config.ini');
  my $vars = $cfg->variables;
  print $vars->{database}{host}, "\n";


=head1 QUICK EXAMPLE

Suppose F<config.ini> contains

  root = /usr/local

  [paths]
  bin = $(root)/bin
  lib = $(root)/lib
  cfg = $(=& catfile, $(lib), config.ini)

  [copy]
  cfg = $([paths]cfg)

Then

  my $cfg = Config::INI::RefVars->new();

  $cfg->parse_ini(src => 'config.ini');

  my $vars = $cfg->variables;

produces

  {
    '__TOCOPY__' => {
      root => '/usr/local',
    },
    paths => {
      root => '/usr/local',
      bin  => '/usr/local/bin',
      lib  => '/usr/local/lib',
      cfg  => '/usr/local/lib/config.ini',
    },
    copy => {
      root => '/usr/local',
      cfg  => '/usr/local/lib/config.ini',
    },
  }


=head1 DESCRIPTION

=head2 INTRODUCTION

C<Config::INI::RefVars> extends the traditional INI format with variable
references, function calls, include directives, line continuations, and
additional assignment operators. All references are resolved while parsing, so
the resulting data structure contains only plain Perl scalars.

The minimum Perl version required to use this module is C<v5.10.1>.


=head2 OVERVIEW

A line in an INI file should normally not start with an C<=> or the sequence
C<;!>. These are reserved for extensions (e.g. C<=include>). Otherwise the
parser throws a "Directives are not yet supported" exception. Apart from these
special cases, the following rules apply:

=over

=item *

Spaces at the beginning and end of each line are ignored.

=item *

If the first non-white character of a line is a C<;> or a C<#>, then the line
is a comment line.

=item *

Comments can also be specified to the right of a section declaration (in this
case, the comment must not contain closing square brackets).

=item *

In a section header, spaces to the right of the opening square
bracket and to the left of the closing square bracket are ignored, i.e. a
section name always begins and ends with a non-white character. B<But>: As a
special case, the name of a section heading can be an empty character string.

=item *

Section name must be unique.

=item *

The order of the sections is retained: The C<sections> method returns an array
of sections in the order in which they appear in the INI file.

=item *

There are several assignment operators, not just C<=>. The other assignment
operators have one or more punctuation characters to the left of the C<=>
symbol.

=item *

Spaces around the assignment operator are usually ignored, but may be needed
as separators in some cases.

=item *

If you want to define a variable whose name ends with an punctuation character other
than an underscore, there must be at least one space between the variable name
and the assignment operator.

=item *

The name of a user-defined variable cannot be empty. Furthermore, it cannot
begin with any of the characters C<;>, or C<[>. Obviously, it also cannot contain a
C<=> at all (but see constructor variable C<tocopy_vars>).

=item *

The sequence C<$(...)> is used to reference INI variables or environment
variables.

=item *

The sequence C<$(=& ...)> is used to call built-in functions.

=item *

The sequence C<$(=# ...)> is used to call user-defined functions.

=item *

There is no escape character.

=item *

The source to be parsed (argument C<src> of the method C<parse_ini>) does not
have to be a file, but can also be a string or an array.

=back

You will find further details in the following sections.


=head2 SECTIONS

A section begins with a section header:

  [section]

A line contains a section heading if the first non-blank character is a C<[>
and the last non-blank character is a C<]>. The character string in between is
the name of the section, whereby spaces to the right of C<[> and to the left
of C<]> are ignored.

   [   The name of the section   ]

This sets the section name to C<The name of the section>.

As a special case, C<[]> or C<[ ]> are permitted, which results in a section
name that is just an empty string.

Section names must be unique.

An INI file does not have to start with a section header, it can also start
with variable definitions. In this case, the variables are added to the
I<tocopy> section (default name: C<__TOCOPY__>). You can explicitly specify
the I<tocopy> section heading, but then this must be the first active line in
your INI file.


=head2 ASSIGNMENT OPERATORS

=head3 Overview

There are several assignment operators, the basic one is the C<=>, the others
are formed by a C<=> preceded by one or more punctuation characters. Thus, if
you want to define a variable whose name ends with an punctuation character,
there must be at least one space between the variable name and the assignment
operator.

B<Note>: Since the use of the underscore in identifiers is so common, it is
not treated as a punctuation character here.

=head3 List of Assignment Operators

=over

=item C<=>

The standard assignment operator. Note: A second assignment to the same
variable simply overwrites the first.

=item C<?=>

Works like the corresponding operator of GNU Make: the assignment is only
executed if the variable is not yet defined.

=item C<??=>

This works similarly to the C<?=> operator: the assignment is only executed if
the variable is not yet defined or if its current, non-expanded value is an
empty string.

This allows you to set a default value for an environment variable:

   env_var:=$(=ENV:ENV_VAR)
   env_var??=the default

If the environment variable C<ENV_VAR> is not defined or is empty, then
C<env_var> has the value C<the default>. This would not work with
C<?=>. Please note that you must also use the C<:=> operator for the
assignment!


=item C<:=>

Works like the corresponding operator of GNU Make: all references to other
variables are expanded when the variable is defined. See section L</"REFERENCING VARIABLES">

=item C<.=>

The right-hand side is appended to the value of the variable. If the variable
is not yet defined, this does the same as a simple C<=>.

Example:

  var=abc
  var.=123

Now C<var> has the value C<abc123>.

=item C<+=>

The right-hand side is appended to the value of the variable, separated by a
space. If the right-hand side is empty, a space is appended. If the variable
is not yet defined, this has the same effect as a simple C<=>.

Example:

   var=abc
   var+=123

Now C<var> has the value C<abc 123>.

B<Note:> The semantics of the C<+=> operator are intentionally based on GNU
Make up to version 4.2.1. Consequently, an assignment such as

  foo =
  foo +=

appends a single space rather than an empty string. GNU Make changed this
behavior in version 4.3.


=item C<< .>= >>

The right-hand side is placed in front of the value of the variable. If the
variable is not yet defined, this has the same effect as a simple C<=>.

Example:

  var=abc
  var.>=123

Now C<var> has the value C<123abc>.

=item C<< +>= >>

The right-hand side is placed in front the value of the variable, separated by
a space. If the right-hand side is empty, a space is placed in front of the
variable value. If the variable is not yet defined, this has the same effect
as a simple C<=>.

Example:

  var=abc
  var+>=123

Now C<var> has the value C<123 abc>.

=item C<#=>

Defines a function. See L</User-defined Functions>

=item C<\=>, C<:\=>, etc

See L<LINE CONTINUATION>.

=back


=head2 LINE CONTINUATION

By default, the value assigned in an assignment statement ends at the first
non-space character on the same line. However, this module also supports line
continuations by modifying the assignment operators.

To enable line continuation, place a backslash immediately before the
assignment operator. This works with all assignment operators, for example
C<\=>, C<:\=>, C<+\=>, etc.  The backslash must appear immediately before the
equals sign.

If a line containing such a modified assignment operator ends with a
backslash, the trailing backslash is removed and the following physical line
is appended. This process is repeated until a line no longer ends with a
backslash or the end of the file is reached.

Spaces following a backslash are always ignored, because spaces at the end of
a line are removed before parsing.

B<Note:> The backslash preceding the assignment operator is only a marker to enable
line continuation and is not part of the operator itself.

Examples:

  long_line \= foo\
    bar\
    baz

is equivalent to

  long_line = foo  bar  baz

Likewise,

  text :\= Hello,\
  world!

is equivalent to

  text := Hello,world!

Assignments without a backslash before the assignment operator never use
line continuation, even if their value ends with a backslash.

  normal = foo\
  bar = baz

Here, the variable C<normal> has the value C<foo\>, and the variable C<bar>
has the value C<baz>.

B<Note:> To avoid ambiguity, the first character of a continuous line must not
be "=". This

  v\=abcd\
  =

will cause a C<directive in line continuation> error, but this will work:


  v\=abcd\
   =

This works because of the space before the C<=>, the result would be C<abcd =>.

This would work, too:

  v\=abcd\
  $()=

The result would be C<abcd=>.


=head2 INCLUDE FILES

An INI file may include another INI file by using the C<=include>
directive:

  =include common.ini

The file name may contain variable references:

  config_dir = config

  =include $(config_dir)/common.ini

If the specified file name is relative, it is interpreted relative to the
directory containing the current INI file. Absolute file names may also be
used.

An included file is processed exactly as if its contents had been inserted
at the position of the C<=include> directive. Consequently, the current
section is preserved across file boundaries. If the included file changes
the current section, parsing continues in that section after the include.

The same file may be included multiple times. However, recursive includes
are detected and reported as an error.

Examples:

  [general]

  =include common.ini

  name = example

If F<common.ini> contains

  version = 1.0

the resulting input is equivalent to

  [general]

  version = 1.0

  name = example

Likewise,

  [first]

  =include other.ini

  value = x

where F<other.ini> contains

  [second]

  other = y

is equivalent to

  [first]

  [second]

  other = y

  value = x

Line continuation never crosses file boundaries. In particular, a directive
must not appear where a continuation line is expected.


=head2 REFERENCING VARIABLES

=head3 Basic Referencing

The referencing of variables is similar but not identical to that in B<make>,
you use C<$(I<VARIABLE>)>. Example:

   a=hello
   b=world
   c=$(a) $(b)

Variable C<c> has the value C<hello world>. As with B<make>, lazy evaluation
is used, i.e. you would achieve exactly the same result with this:

   c=$(a) $(b)
   a=hello
   b=world

But the following would result in C<c> containing only one space:

   c:=$(a) $(b)
   a=hello
   b=world

Unlike in B<make>, the round brackets cannot be omitted for variables with
only one letter!

You can nest variable references:

   foo=the foo value
   var 1=fo
   var 2=o
   bar=$($(var 1)$(var 2))

Now the variable C<bar> has the value C<the foo value>.

A reference to a non-existent variable is always expanded to an empty
character string.

If you need a literal C<$(...)> sequence, e.g. C<$(FOO)>, as part of a
variable value, you can write:

   var = $$()(FOO)

This results in the variable C<var> having the value C<$(FOO)>. It works
because C<$()> always expands to an empty string (see section L</"PREDEFINED
VARIABLES">).

Recursive references are not possible, an attempt to do so leads to a fatal
error. However, you can do the following with the C<:=> assignment:

   a=omethin
   a:=s$(a)g

C<a> has the value C<something>. However, due to the way C<:=> works, this is
not really a recursive reference.

=head3 Referencing Variables of other Sections

By default, you can reference a variable in another section by writing the
name of the section in square brackets, followed by the name of the variable:

   [sec A]
   foo=Referencing a variable from section: $([sec B]bar)

   [sec B]
   bar=Referenced!

You can switch to a different notation by specifying the constructor argument
C<separator>.

A more complex example:

   [A]
   a var = 1234567

   [B]
   b var = a var
   nested = $([$([C]c var)]$(b var))

   [C]
   c var = A

Variable C<nested> in section C<B> has the value C<1234567>:

=over

=item

C<$([C]c var)> expands to C<A>,

=item

C<$(b var)> expands to C<a var>,

=item

We therefore have C<$([A]a var)> which leads to C<1234567>.

=back


=head2 PREDEFINED VARIABLES

=head3 Variables related to Section and Variable Names

=over

=item C<=>

C<$(=)> expands to the name of the current section.

=item C<==>

C<$(==)> expands to the name of the variable that is currently being defined.
Think of this as a pseudo-variable, something like $([SECTION]==) always
results in an empty string.

=back

Example:

   [A]
   foo=variable $(==) of section $(=)
   ref=Reference to foo of section B: $([B]foo)

   [B]
   foo=variable $(==) of section $(=)
   bar=$(foo)

The hash returned by the C<variables> method is then:

   {
     'A' => {
             'foo' => 'variable foo of section A',
             'ref' => 'Reference to foo of section B: variable foo of section B'
            },
     'B' => {
             'foo' => 'variable foo of section B'
             'bar' => 'variable foo of section B',
            }
   }


=head3 Variables related to the Source

=over

=item C<=srcname>

Name of the INI source. If the source is a file, this corresponds to the value
that you have passed to C<parse_ini> via the C<src> argument, otherwise it is
set to "INI data". The value can be overwritten with the argument C<src_name>.

=item C<=INIdir>, C<=INIfile>

Directory (absolute path) and file name of the INI file. These variables are
only present if the source is a file, otherwise they are not defined.

=back

=head3 Variables related to the OS

=over

=item C<=:>

The directory separator, C<\> on Windows, C</> on Linux.  Note: This is not
always sufficient to create a path, e.g. on VMS.

=item C<=::>

Path separator, which is used in the environment variable C<PATH>, for
example.

=back


=head3 Space Variables

C<$()> always expands to an empty string, C<$(E<nbsp>)>, C<$(E<nbsp>E<nbsp>)>
with any number of spaces within the parens expand to exactly these spaces. So
there are several ways to define variables with heading or trailing spaces:

   foo = abc   $()
   bar = $(   )abc

The value of C<foo> has three spaces at the end, the value of C<bar> has three
spaces at the beginning. A special use case for C<$()> is the avoidance of
unwanted variable expansion:

   var=hello!
   x=$(var)
   y=$$()(var)

With these settings, C<x> has the value C<Hello!>, but C<y> has the value
C<$(var)>.

=head3 Other Variables

=over

=item C<=TO_CP_SEC>

Name of the I<tocopy> section, see L</"THE I<TOCOPY> SECTION">.

=item C<=VERSION>

Version of the C<Config::INI::RefVars> module.

=item C<=devnull>

A string representation of the null device (result of function
C<devnull> from L<File::Spec::Functions>).

=item C<=rootdir>

A string representation of the root directory (result of function
C<rootdir> from L<File::Spec::Functions>).

=item C<=tmpdir>

A string representation of the first writable directory from a list of
possible temporary directories, or the current directory if no writable
temporary directories are found (result of function
C<tmpdir> from L<File::Spec::Functions>).

=back


=head3 Custom predefined Variables

Currently, custom predefined variables are not supported. But you can do
something very similar, see argument C<tocopy_vars> (of C<new> and
C<parse_ini>), see also L</"THE I<TOCOPY> SECTION">. With this argument you
can also define variables whose names contain a C<=>, which is obviously
impossible in an INI file.


=head3 Predefined Variables in resulting Hash

By default, all variables whose names contain a C<=> are removed from the
resulting hash. This means that the variables discussed above are not normally
included in the result. This behavior can be changed with the C<parse_ini>
argument C<cleanup>. The variable C<==> can of course not be included in the
result. Similarly, C<$(=ENV:...)>, C<$(=env:...)>, and C<$(=CONFIG:...)> are
never included in the result.


=head2 ACCESSING ENVIRONMENT AND CONFIG VARIABLES

You can access environment variables with this C<$(=ENV:...)> or this
C<$(=env:...)> notation. Example:

   path = $(=ENV:PATH)

C<path> now contains the content of your environment variable C<PATH>.

The results of C<$(=ENV:...)> and C<$(=env:...)> are almost always the
same. The difference is that the parser always leaves the value of
C<$(=ENV:...)> unchanged, but tries to expand the value of C<$(=env:...)>.
For example, let's assume you have an environment variable C<FOO> with the
value C<$(var)> and you write this in your INI file:

   var=hello!
   x=$(=ENV:FOO)
   y=$(=env:FOO)

This results in C<x> having the value C<$(var)>, while C<y> has the value C<hello!>.

You can access configuration variables of Perl's L<Config> module with this C<$(=CONFIG:...)> notation. Example:

  the archlib=$(=CONFIG:archlib)

This gives the variable C<the archlib> the value of C<$Config{archlib}>.

You can write something like C<$([SEC]=ENV:FOO)>; this yields the same result
as C<$(=ENV:FOO)>, provided that C<[SEC]> exists, and an empty string if
C<[SEC]> does not exist. The same applies, of course, to C<$([SEC]=env:FOO)>
and C<$([SEC]=CONFIG:FOO)>.

Note: In contrast to C<$(=ENV:...)>, there is no lower-case counterpart to
C<$(=CONFIG:...)>, as this would not make sense.


=head2 THE I<TOCOPY> SECTION

=head3 Default Behavior

If specified, the method C<parse_ini> copies the variables of the I<tocopy>
section (default name: C<__TOCOPY__>) to any other section when the INI file
is read (default, this behavior can be changed by the constructor argument
C<global_mode>).  For example this

   [__TOCOPY__]
   some var=some value
   section info=$(=)

   [A]

   [B]

is exactly the same as this:

   [__TOCOPY__]
   some var=some
   section info=$(=)

   [A]
   some var=some
   section info=$(=)

   [B]
   some var=some
   section info=$(=)

Of course, you can change or overwrite a variable copied from the C<tocopy>
section locally within a section at any time without any side effects. In this
case, you can access the original value as follows:

   $([__TOCOPY__]some var)

or - more generally - like this:

   $([$(=TO_CP_SEC)]some var)

You can exclude variables with the argument C<not_tocopy> from copying
(methods C<new> and C<parse_ini>), but there is currently no notation to do
this in the INI file.

The I<tocopy section> is optional. If it is specified, it must be the first
section. By default, its name is C<__TOCOPY__>, this can be changed with the
argument C<tocopy_section> (methods C<new> and C<parse_ini>). You can omit the
C<[__TOCOPY__]> header and simply start your INI file with variable
definitions. These then simply become the I<tocopy section>. So this:

  [__TOCOPY__]
  a=this
  b=that

  [sec]
  x=y

is exactly the same as this:

  a=this
  b=that

  [sec]
  x=y

You can also add I<tocopy> variables via the argument C<tocopy_vars> (methods
C<new> and C<parse_ini>), these are treated as if they were at the very
beginning of the C<tocopy> section.


=head3 Global Mode

If you specify the constructor argument C<global_mode> with a I<true> value,
the variables of the I<tocopy> section are not copied, but behave like global
variables. Variables that you specify with the argument C<not_tocopy> are not
treated as global.

Consequently, there is almost no difference in the referencing of variables if
you use the global mode. The advantage of this mode is that you do not clutter
your sections with unwanted variables.

Example:

   [__TOCOPY__]
   a=this
   b=that

   [sec]
   x=y

This would lead to this result by default:

   {
     __TOCOPY__ => {a => 'this', b => 'that'},
     sec        => {a => 'this', b => 'that', x => 'y'}
   }

But in global mode the result is:

   {
     __TOCOPY__ => {a => 'this', b => 'that'},
     sec        => {x => 'y'}
   }

To create a local copy of a global variable, use the assignment operator C<:=>
instead of a simple C<=>, since the latter can sometimes lead to undesirable
results (see example below).

B<NOTE:>
In some special cases, variables have different values in standard mode than in global mode.
Example:

   section=$(=)
   x=GLOBAL
   x_val=$(x)

   [local-sec]
   var_1 := $(section)
   var_2 = $(section)

   x=LOCAL

   x_1 := $(x_val)
   x_2 = $(x_val)

By default, you will get:

   {
     '__TOCOPY__' => {
                      'section' => '__TOCOPY__',
                      'x' => 'GLOBAL',
                      'x_val' => 'GLOBAL'
                     },
     'local-sec' => {
                     'section' => 'local-sec',
                     'var_1' => 'local-sec',
                     'var_2' => 'local-sec',
                     'x' => 'LOCAL',
                     'x_1' => 'LOCAL',
                     'x_2' => 'LOCAL',
                     'x_val' => 'LOCAL'
                    }
   }

But in global mode, the result is:

   {
     '__TOCOPY__' => {
                      'section' => '__TOCOPY__',
                      'x' => 'GLOBAL',
                      'x_val' => 'GLOBAL'
                     },
     'local-sec' => {
                     'var_1' => 'local-sec',
                     'var_2' => '__TOCOPY__',
                     'x' => 'LOCAL',
                     'x_1' => 'LOCAL',
                     'x_2' => 'GLOBAL'
               }
   }

Note the different values for C<var_2> and C<x_2>.  When the assignment C<x_1
:= $(x_val)> is reached, the right-hand side is evaluated immediately, so that
C<$(x_val)> becomes C<$(x)>, which in turn leads to C<LOCAL>, since the
definition of C<x> in C<[local-sec]> shadows the global C<x>.

In contrast, the value of C<x_2> is evaluated after the file has been
completely read. This value is C<$(x_val)> and the variable C<x_val> was in
turn previously evaluated in the global section and has the value C<GLOBAL>,
which then becomes the value of C<x_2>.

In standard mode, C<x_val=$(x)> is copied to C<[local-sec]> and C<x_2> is
given the value C<LOCAL> due to the local definition of C<x>.

A corresponding explanation applies to the different values of C<var_2>.


=head2 FUNCTION CALLS

In addition to variable references, function calls may be used in
expanded values.

There are two kinds of function calls:

=over

=item * Built-in functions

  value = $(=& func, arg1, arg2, ...)

=item * User-defined functions

  value = $(=# func, arg1, arg2, ...)

=back

Function calls are evaluated during variable expansion. Arguments may
contain variable references and nested function calls.

Arguments are split before argument expansion, similar to GNU Make's
C<$(call ...)> function. Therefore commas introduced by later expansion
do not create additional arguments.

Example:

  [paths]
  comma = ,

  dir = $(=& catdir, foo, bar$(comma)baz)

The second argument is expanded to C<bar,baz>, so the result becomes:

  foo/bar,baz

rather than:

  foo/bar/baz

=head3 Built-in Functions

Built-in functions are called with C<$(=& ...)>.

Example:

  [paths]
  root = /usr/local
  bin  = $(=& catdir, $(root), bin)

Result:

  /usr/local/bin

The built-in functions are provided by L<Config::INI::RefVars::Builtins>.

Function names are not expanded. Only function arguments are subject to
variable expansion.

Thus,

  path = $(=& catdir, foo, bar)

is valid, whereas

  fn1 = cat
  fn2 = dir
  path = $(=& $(fn1)$(fn2), foo, bar)

attempts to call a function literally named C<$(fn1)$(fn2)> and therefore
fails.

Additional built-in functions can be registered via constructor argument
C<builtins>, see also L</Evaluating Arithmetic Expressions>.

=head3 User-defined Functions

User-defined functions are defined with the C<#=> assignment operator.

Example:

  greet #= Hello $(1)!
  pair  #= $(1):$(2)

  [sec]
  msg1 = $(=# greet, World)
  msg2 = $(=# pair, foo, bar)

Result:

  msg1 = Hello World!
  msg2 = foo:bar

Function parameters are available as numeric variables:

  $(1)
  $(2)
  $(3)

Missing parameters expand to the empty string.

Example:

  triple #= $(1):$(2):$(3)

  [sec]
  x = $(=# triple, a, b)

Result:

  x = a:b:

B<Note:> These numeric variables are always local within the function. They
never overwrite a numeric variable defined outside the function, and a numeric
variable defined outside the function is not visible within the function.


=head3 Function Lookup

User-defined functions are searched similarly to variables.

For an unqualified call:

  $(=# func, arg1, arg2)

the resolver searches:

=over

=item *

the current section

=item *

the I<tocopy> section

=item *

the built-in function dispatcher

=back

Thus, a user-defined function can override a built-in function for C<$(=#
...)> calls. The built-in function remains available via C<$(=& ...)>.

Example:

  concat #= user:$(1):$(2)

  [sec]
  x = $(=# concat, a, b)
  y = $(=& concat, a, b)

Result:

  x = user:a:b
  y = ab

=head3 Qualified Function Calls

A function from a specific section can be called explicitly:

  value = $(=# [section]func, arg1, arg2)

This is analogous to qualified variable references:

  value = $([section]var)

Example:

  fmt #= GLOBAL:$(1)

  [sec]
  fmt = not relevant
  fmt #= LOCAL:$(1)

  x = $(=# fmt, test)
  y = $(=# [__TOCOPY__]fmt, test)

Result:

  x = LOCAL:test
  y = GLOBAL:test

A qualified function call does not fall back to a built-in function if the
specified section does not contain such a function.

B<Note:> the function name is interpreted literally and is not subject to variable
expansion. Variable references are expanded only in the function arguments.

Thus,

  myfunc #= myfunc:$(1)
  fn1 = my
  fn2 = func
  result = $(=# $(fn1)$(fn2), foo)

attempts to call a function literally named C<$(fn1)$(fn2)> and therefore
fails.


=head3 Function Scope

Function bodies are expanded in the caller's scope.

Example:

  fmt #= $(1):$(var)
  var = GLOBAL

  [sec]
  var = LOCAL
  x = $(=# fmt, test)

Result:

  x = test:LOCAL

A qualified variable reference may be used to force access to a variable from
a specific section:

  fmt #= $(1):$([__TOCOPY__]var)

Functions and variables use separate namespaces. Therefore this is valid:

  foo = value
  foo #= function:$(1)

The variable C<foo> is referenced with C<$(foo)>, while the function C<foo> is
called with C<$(=# foo, ...)>.

=head3 Recursion

Recursive user-defined function calls are detected and cause a fatal error.

Example:

  recurse #= $(=# recurse)

  [sec]
  x = $(=# recurse)

Produces an error similar to:

  recursive function '[__TOCOPY__]#=recurse' calls itself


=head2 COMMENTS

As said, if the first non-white character of a line is a C<;> or a C<#>, then the line
is a comment line.

   # This is a comment
   ; This is also a comment
       ;! a comment, but: avoid ";!" at the very beginning of a line!
   var = value ; this is not a comment but part of the value.

Avoid C<;!> at the very beginning of a line, otherwise you will get an
error. The reason for this is that this sequence is reserved for future
extensions. However, you can use it if you precede it with spaces.

You cannot append a comment to the right of a variable definition, as your
comment would otherwise become part of the variable value. But you can append
a comment to the right of a header declaration:

   [section]  ; My fancy section

B<Attention>: if you do this, the comment must not contain a C<]> character!


=head2 METHODS

=head3 new

The constructor takes the following optional named arguments:

=over

=item C<builtins>

Optional. Argument for registering additional built-in functions.

Example:

  my $cfg = Config::INI::RefVars->new(
                      builtins => {
                                     _uc => sub {
                                       return uc($_[0] // "");
                                     },
                                     _sprintf => sub {
                                       my $fmt = shift // return "";
                                       my $result;
                                       eval { $result = sprintf($fmt, @_); 1; } or
                                         die("_sprintf: $@\n");
                                       return $result;
                                   },
                                  });

The keys of the hash reference specify the function names. The values
must be code references.

Built-in functions are invoked using the C<$(=& ...)> syntax:

  upper  = $(=& _uc,hello)
  string = $(=& _sprintf, <%s:%d>, a string, 27)

The callback receives the expanded function arguments in C<@_>. The
callback's return value becomes the result of the function call.

If a user-defined built-in has the same name as one of the predefined
built-in functions, the user-defined implementation takes precedence.

Exceptions thrown by a callback are propagated to the caller and abort
parsing in the same way as errors raised by the predefined built-in
functions.

B<Naming convention>: User-defined built-in functions may use any name,
including the names of predefined built-in functions. If a user-defined
built-in has the same name as a predefined one, the user-defined
implementation takes precedence.

To avoid accidental name clashes with future versions of this module,
applications are encouraged to use function names containing at least
one underscore (C<_>).

This module guarantees that no predefined built-in function, present or
future, will contain an underscore in its name.

Examples:

  project_root
  is_release_build
  my_concat
  cfg_dir

Using such names ensures that future versions of
C<Config::INI::RefVars> cannot introduce a conflicting predefined
built-in function.


=item C<cmnt_vl>

Optional, a boolean value. If this value is set to I<true>, comments are
permitted in variable lines. The comment character is a semicolon preceded by
one or more spaces.

Example:

   [section]
   var 1=val 1 ; comment
   var 2=val 2  ; ;  ; comment
   var 3=val 3; no comment
   var 4=val 4 $(); no comment

After parsing, the C<variables> method returns:

   section => {'var 1' => 'val 1',
               'var 2' => 'val 2',
               'var 3' => 'val 3; no comment',
               'var 4' => 'val 4 ; no comment',
              }

Default is I<false> (C<undef>).


=item C<global_mode>

Optional, a boolean. Changes handling of the I<tocopy> section, see section
L</"Global Mode">. See also the accessor method of the same name.

=item C<not_tocopy>

Optional, a reference to a hash or an array of strings. The hash keys or array
entries specify a list of variables that should not be copied from the
I<tocopy> section to the other sections. It does not matter whether these
variables actually occur in the I<tocopy> section or not.

Default is C<undef>.

=item C<separator>

Optional, a string. If specified, an alternative notation can be used for
referencing variables in another section. Example:

   my $obj = Config::INI::RefVars->new(separator => '::');

Then you can write:

    [A]
    y=27

    [B]
    a var=$(A::y)

This gives the variable C<a var> the value C<27>.

The following characters are permitted for C<separator>:

   #!%&',./:~\

See also the accessor method of the same name.

=item C<tocopy_section>

Optional, a string. Specifies a different name for the I<tocopy>
section. Default is C<__TOCOPY__>. See accessor C<tocopy_section>.

=item C<tocopy_vars>

Optional, a hash reference. If specified, its keys become variables of the
I<tocopy> section, the hash values become the corresponding variable values. This
allows you to specify variables that you cannot specify in the INI file,
e.g. variables with a C<=> in the name.

Keys with C<=>, C<[> or C<;> as the first character are not permitted.

Default is C<undef>.

=item C<varname_chk_re>

Optional, a compiled regex. If specified, each variable name defined in the
INI source must match this regex.

Example:

   my $obj = Config::INI::RefVars->new(varname_chk_re => qr/^[A-Z]/);
   my $src = <<'EOT';
      [the section]
      A=the value
      xYZ=123
      Z1=z2
      Y=
   EOT
  $obj->parse_ini(src => $src);

This will result in an exception with the message C<'xYZ': var name does not
match varname_chk_re>.

=back


=head3 current_tocopy_section

Returns the name of the section I<tocopy> that was used the last time
C<parse_ini> was called. Please note that the section does not have to be
present in the data.

See also method C<tocopy_section>.


=head3 global_mode

Returns a boolean value indicating whether the global mode is activated or
not. See constructor argument of the same name, see also section L</"Global
Mode">.

=head3 parse_ini

Parses an INI source. The method takes the following optional arguments:

=over

=item C<src>

Mandatory, a string or an array reference. This specifies the source to
parse. If it is a character string that does not contain a newline character,
it is treated as the name of an INI file. Otherwise, its content is parsed
directly.

=item C<cleanup>

Optional, a boolean. If this value is set to I<false>, variables with a C<=>
in their name are not removed from the resulting hash that is returned by the
C<variables> method. But in global mode, most of this variables will not be
contained, see section L</"Global Mode">.

Default is 1 (I<true)>

=item C<tocopy_section>

Optional, a string. Specifies a different name for the I<tocopy> section for
this run only. The previous value is restored before the method
returns. Default is the string returned by accessor C<tocopy_section>.

See constructor argument of the same name.

=item C<tocopy_vars>

Optional, overwrites the corresponding setting saved in the object for this
run only. The previous setting is restored before the method returns.

See constructor argument of the same name.

=item C<not_tocopy>

Optional, overwrites the corresponding setting saved in the object for this
run only. The previous setting is restored before the method returns.

See constructor argument of the same name.

=item C<src_name>

Optional, overwrites the corresponding setting saved in the object for this
run only. The previous setting is restored before the method returns.

See constructor argument of the same name, see also the accessor of the same
name.

=back


=head3 sections

Returns a reference to an array of section names from the INI source, in the
order in which they appear there.

=head3 sections_h

Returns a reference to a hash whose keys are the section names from the INI
source, the values are the corresponding indices in the array returned by
C<sections>.


=head3 separator

Returns the value that was passed to the constructor via the argument of the
same name, or C<undef> .


=head3 src_name

Returns the name of the INI source (file name that you have passed to
C<parse_ini> via the argument C<src>, or the one that you have passed via the
argument C<src_name>, or "C<INI data>", see section L</"Variables in relation
to the source">.


=head3 tocopy_section

Returns the name of the I<tocopy> section that will be used as the default for
the next call to C<parse_ini>.

See also method C<current_tocopy_section>.


=head3 variables

Returns a reference to a hash of hashes. The keys are the section names, each
value is the corresponding hash of variables (key: variable name, value:
variable value). By default, variables with a C<=> in their name are not
included; this can be changed with the C<cleanup> argument.


=head2 PITFALLS

=head3 Method C<sections> vs. C<sections_h>


In most cases, the keys in the hash returned by C<variables> are the same as
the keys in the hash returned by the C<sections_h> method and the entries in
the array returned by the C<sections> method. In special cases, however, there
may be a difference with regard to the I<tocopy> section. Example:

   [A]
   a=1

   [B]
   b=2

If you parse this INI source like this:

  my $obj = Config::INI::RefVars->new();
  $obj->parse_ini(src => $src, tocopy_vars => {'foo' => 'xyz'});

then the C<variables> method returns this:

  {
    'A' => {
            'a' => '1',
            'foo' => 'xyz'
           },
    'B' => {
            'b' => '2',
            'foo' => 'xyz'
           },
    '__TOCOPY__' => {
                     'foo' => 'xyz'
                    }
  }

but C<sections_h> returns

   { 'A' => '0',
     'B' => '1' }

and C<sections> returns

   ['A', 'B']

No C<__TOCOPY__>. The reason for this is that the return values of
C<sections_h> and C<sections> refer to what is contained in the source, and in
this case C<__TOCOPY__> is not contained in the source, but comes from a
method argument.

=head3 Separator in Variable Names

   my $cfg = Config::INI::RefVars->new(separator => "/");

   my $ini =<<'INI';
    [FOO]
    var=abcde

    [BAR]
    FOO/var=my var in section BAR
    a=$(FOO/var)
    b=$(BAR/FOO/var)
   INI

By specifying the C<separator> argument, qualified variable references use
the form C<$(SECTION/VARIABLE)>.

Section C<[BAR]> defines a variable named C<FOO/var>. This is a valid
variable name, even though it contains the configured separator.

The resulting data structure is:

   {
      'FOO' => {
                 'var' => 'abcde'
               },
      'BAR' => {
                 'b' => 'my var in section BAR',
                 'a' => 'abcde',
                 'FOO/var' => 'my var in section BAR'
               }
   }

In this case, C<FOO/var> can only be referenced in the qualified form.


=head3 Regular Expressions: Groups

Currently, there is no access to the contents of capturing groups. However,
you may still want to use non-capturing groups. In this case, be aware that
you cannot use them directly in the regular expression, since the closing
parenthesis will confuse the parser. Therefore, the following will not work:

  [WRONG]
  a = $(=& m, bb, ^(?:a|b)b$)

Instead, use a helper variable, e.g.:

  [RIGHT]
  regex = (?:a|b)b
  a = $(=& m, bb, ^$(regex)$)


=head2 EXAMPLES

=head3 Reading DHCP Server INI files


You can parse INI files as described here L<$(section\name) syntax for INI
file
variables|https://www.dhcpserver.de/cms/ini_file_reference/special/sectionname-syntax-for-ini-file-variables/>
as follows:

   my $obj = Config::INI::RefVars->new(separator      => "\\",
                                       cmnt_vl        => 1,
                                       tocopy_section => 'Settings',
                                       global_mode    => 1);
   my $src = <<'EOT';
     [Settings]
     BaseDir="d:\dhcpsrv" ; dhcpsrv.exe resides here
     IPBIND_1=192.168.17.2
     IPPOOL_1=$(Settings\IPBIND_1)-50
     AssociateBindsToPools=1
     Trace=1
     TraceFile="$(BaseDir)\dhcptrc.txt" ; trace file

     [DNS-Settings]
     EnableDNS=1

     [General]
     SUBNETMASK=255.255.255.0
     DNS_1=$(IPBIND_1)

     [TFTP-Settings]
     EnableTFTP=1
     Root="$(BaseDir)\wwwroot" ; use wwwroot for http and tftp

     [HTTP-Settings]
     EnableHTTP=1
     Root="$(BaseDir)\wwwroot" ; use wwwroot for http and tftp
   EOT
   $obj->parse_ini(src => $src);


=head3 Evaluating Arithmetic Expressions

There is no built-in arithmetic. However, if you need to evaluate arithmetic
expressions in your INI file, it is simple to add such a feature, e.g.:

  use strict;
  use warnings;

  use Config::INI::RefVars;
  use Math::Expression::Evaluator;

  my $cfg = Config::INI::RefVars->new(
    builtins => {
      my_calculator => sub {
        die("my_calculator: needs exactly 1 arg") unless @_ == 1;

        my $m = Math::Expression::Evaluator->new;
        my $result;

        eval { $result = $m->parse($_[0])->val(); 1 }
          or die("my_calculator: $@");

        return $result;
      },
    },
  );

  my $ini = <<'INI';
  [sec]
  val = 3
  result = $(=& my_calculator, 2 + $(val))
  INI

  print($cfg->parse_ini(src => $ini)->variables->{sec}{result}, "\n");

This will print C<5>.


=head1 ERROR HANDLING

Most parsing and expansion errors are reported by throwing an exception.

Examples include:

=over

=item *

syntax errors

=item *

undefined variables

=item *

unknown functions

=item *

recursive variable references

=item *

recursive function calls

=back

If C<parse_ini()> dies, the object may be left in an inconsistent state.

Applications should treat the object as unusable after a parsing error and
create a new object before attempting another parse operation.


=head1 SEE ALSO

L<$(section\name) syntax for INI file variables|https://www.dhcpserver.de/cms/ini_file_reference/special/sectionname-syntax-for-ini-file-variables/>

This one allows also referencing variables: L<Config::IOD::Reader>.

Other modules handling INI files:

L<Config::INI>,
L<Config::INI::Tiny>,
L<Config::IniFiles>,
L<Config::Tiny> and many more.

Remark: the built-in functions are provided by
L<Config::INI::RefVars::Builtins>.


=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-config-ini-accvars at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-INI-RefVars>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::INI::RefVars


You can also look for information at:

=over 4

=item * GitHub Issue (preferred for issues)

L<https://github.com/AAHAZRED/perl-Config-INI-RefVars/issues>

=item * RT: CPAN's request tracker (you may report bugs also here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-INI-RefVars>

=item * Search CPAN

L<https://metacpan.org/release/Config-INI-RefVars>

=item * GitHub Repository

L<https://github.com/AAHAZRED/perl-Config-INI-RefVars>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut
