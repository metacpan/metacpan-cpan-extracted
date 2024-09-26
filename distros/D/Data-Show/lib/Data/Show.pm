package Data::Show;

=encoding utf-8
=cut

use 5.010;
use strict;
use warnings;
use utf8;
use PPR;

our $VERSION = '0.004000';

# Be a ninja...
our @CARP_NOT;

# Useful pieces of information...
my $IS_UTF8_TERM;  BEGIN { $IS_UTF8_TERM  = grep {$_ && /utf-8/i} @ENV{qw<LC_ALL LC_TYPE LANG>}; }
my $IS_LIGHT_BG;   BEGIN { $IS_LIGHT_BG   = ($ENV{COLORFGBG} // q{}) =~ m{\A 0;15 \z}x;          }
my $CAN_ANSICOLOR; BEGIN { $CAN_ANSICOLOR = eval { require Term::ANSIColor; 1 } ? 1 : 0;         }

# Various defaults...
my $MAXWIDTH;               BEGIN { $MAXWIDTH  = 78;                                                  }
my $INITIAL_DEFAULT_PLUGIN; BEGIN { $INITIAL_DEFAULT_PLUGIN = 'Data::Show::Plugin::Data::Pretty';     }
my $FINAL_CANDIDATE_PLUGIN; BEGIN { $FINAL_CANDIDATE_PLUGIN = 'Data::Show::Plugin';                   }
my $DEFAULT_TARGET;         BEGIN { $DEFAULT_TARGET         = \*STDERR;                               }
my $RC_FILE_NAME;           BEGIN { $RC_FILE_NAME           = '.datashow';                            }
my @PLUGIN_API;             BEGIN { @PLUGIN_API = qw< stringify format >;    }
my @ARGUMENT_DEFAULTS;      BEGIN { @ARGUMENT_DEFAULTS = (
                                      to         => $DEFAULT_TARGET,
                                      with       => $INITIAL_DEFAULT_PLUGIN,
                                      as         => 'show',
                                      fallback   => q{},
                                      warnings   => 'off',
                                      termwidth  => $MAXWIDTH,

                                      grid       => 'off',
                                      style      => 'auto',

                                                   # DARK BACKGROUND    LIGHT BACKGROUND
                                      showstyle  => 'bold bright_cyan , bold bright_blue',
                                      datastyle  =>       'bold white ,       bold black',
                                      codestyle  =>             'cyan ,             blue',
                                      filestyle  =>             'blue ,              red',
                                      linestyle  =>             'blue ,              red',
                                      gridstyle  =>             'blue ,              red',
                                    );
                            }
my %GRID; BEGIN {
    @GRID{split //,                   q{┏┯┓┗┷┛━┃┠─┬┴┨│} }
        = split //, ( $IS_UTF8_TERM ? q{┏┯┓┗┷┛━┃┠─┬┴┨│}
                                    : q{ _ |_|_||---|:}
        );
}


# Useful regexes...
my $OWS;         BEGIN { $OWS         = qr{ (?: \s++ | \# [^\n]*+ )*+ }x;               }
my $IDENT;       BEGIN { $IDENT       = qr{ [^\W\d]\w* (?: :: [^\W\d]\w* )* | [_\W] }x; }
my $COLOUR_CHAR; BEGIN { $COLOUR_CHAR = qr{ (?: \e[^m]*m )*  [^\n]  (?: \e[^m]*m )* }x; }
my $VALID_ARG;   BEGIN { $VALID_ARG   = qr{ \A (?: to        | with      | fallback
                                                 | base      | warnings  | as
                                                 | style     | grid      | termwidth
                                                 | datastyle | filestyle | linestyle
                                                 | codestyle | showstyle | gridstyle
                                               ) \z }x; }

# Track lexically scoped output targets and styles...
my @OUTPUT_FH;
my @STYLE;

# Export the module's API, or that of a plugin (as requested)...
sub import {
    # Track load context...
    my ($package, $file, $line) = _get_context();

    # Remove the module name from the argument list...
    shift @_;

    # Handle the special case of a 'base' argument (by adding it as the caller's base class)...
    if (@_ > 0 && $_[0] eq 'base') {
        die "If 'base' is specified, it must be the only argument at $file line $line\n" if @_ > 2;
        no strict 'refs';
        push @{caller().'::ISA'}, _load_plugin( $_[1] // 'Data::Show::Plugin', $file, $line, 'warn' );
        return;
    }

    # Check for missing named args and improve the usual warning for that problem...
    die "No value specified for named argument '$_[-1]' at $file line $line\n"
        if @_ % 2 != 0;

    # Unpack args (including defaults from config file)....
    state $defaults_ref = _load_defaults($file, $line);
    my %opt = (%{$defaults_ref}, @_);

    # Punish invalid arguments...
    _validate_args(\%opt, "at $file line $line", "named argument");

    # Any 'to' arg must be a filehandle, filename, or scalar ref (and open it if necessary)...
    $opt{to} = _open_target( $opt{to} // $DEFAULT_TARGET, $file, $line, $opt{warnings} ne 'off' );

    # Unpack fallback arguments into an arrayref...
    $opt{fallback} = [ split m{ \s*,\s* }x, $opt{fallback} ];

    # Resolve style options according to terminal background (i.e. dark or light)
    for my $option (@opt{ grep /\A.+style\z/, keys %opt}) {
        $option = [split /\s*,\s*/, $option]->[$IS_LIGHT_BG ? -1 : 0];
    }

    # Install Data::Show::Plugin base class as well...
    $INC{'Data/Show/Plugin.pm'} = $INC{'Data/Show.pm'};

    # Track lexical options...
    $^H{'Data::Show/with'}       = _load_plugin( $opt{with}, $file, $line,
                                                 $opt{warnings} ne 'off', $opt{fallback} );
    $^H{'Data::Show/termwidth'}  = $opt{termwidth};
    $^H{'Data::Show/to'}         = @OUTPUT_FH;
    $^H{'Data::Show/style'}      = @STYLE;
    my $existing_as              = $^H{'Data::Show/as'} // '(?!)';
    $^H{'Data::Show/as'}         = "$existing_as|$opt{as}";
    push @OUTPUT_FH, $opt{to};
    push @STYLE,     { add_grid => $opt{grid},
                       mode     => $opt{style},
                       map { m/(.+)style/ ? ($1 => $opt{$_}) : () } keys %opt
                     };

    # Install the function...
    no strict 'refs';
    *{caller() . '::' . $opt{as}} = \&show;
}

# A "no Data::Show" turns show() into a no-op...
sub unimport {
    # Track disabling lexically...
    $^H{'Data::Show/noshow'} = 1;

    # Install the function...
    no strict 'refs';
    *{caller() . '::show'} = \&show;
}

sub _validate_args {
    my ($opt_ref, $where, $what) = @_;

    # Collect and report non-valid arguments...
    my @unknown_args = grep { !m{$VALID_ARG} } keys %{$opt_ref};
    die "Unknown $what" . (@unknown_args == 1 ? '' : 's') . " $where:\n",
        join q{}, map { "    $_\n" } @unknown_args
            if @unknown_args;

    # By the time we're validating, we shouldn't see a 'base' option...
    return if !exists $opt_ref->{base};
    die $what eq 'named argument' ? "If 'base' is specified, it must be the only argument $where\n"
                                  : "Can't specify 'base' as a $what $where\n"
}

# Ensure output filehandles are valid (or fall back to the default)...
sub _open_target {
    my ($target, $file, $line, $warnings) = @_;

    # Track already opened targets, and reuse them...
    state %already_open;
    return $already_open{$target} if $already_open{$target};

    # Handle stringy filenames and in-memory targets...
    my $to_type = ref($target);
    if (!$to_type && ref(\$target) ne 'GLOB' || $to_type eq 'SCALAR') {
        if (open my $fh, '>', $target) {
            return ($already_open{$target} = $fh);
        }
        else {
            warn "Could not open named 'to' argument for output at $file line $line\n"
                if $warnings;
            return ($already_open{$target} = $DEFAULT_TARGET);
        }
    }

    # Handle filehandle-y targets...
    elsif (_is_writeable($target)) {
        return ($already_open{$target} = $target);
    }
    else {
        warn "Named 'to' argument is not a writeable target at $file line $line\n"
            if $warnings;
        return ($already_open{$target} = $DEFAULT_TARGET);
    }
}

# -w is not reliable, so do this instead...
sub _is_writeable {
    return eval { no warnings; print {$_[0]} q{} };
}


# Extract call context, adjusting for evals...
sub _get_context {
    # Start in the current caller's caller...
    my ($package, $file, $line, $hints_ref) = (caller(1))[0..2,10];

    # Keep looking up as long as next caller is a string eval...
    if ($file =~ m{\A \( eval \s+ \d+ \)}x) {
        for my $uplevel (2..1_000_000) {
            my ($uppackage, $upfile, $upline) = caller($uplevel);
            $upfile =~ s{.*/}{};
            $file .= ", at $upfile line $upline";
            last if $upfile !~ m{\A \( eval \s+ \d+ \)}x;
        }
    }

    return ($package, $file, $line, $hints_ref);
}

# Strip repeated arguments from return list...
sub _uniq {
    my %seen;
    return grep {!$seen{$_}++} @_;
}

# Load requested plugin (or fall back on a safe default)...
my %STANDARD_PLUGIN;   # (Populated below)
sub _load_plugin {
    my ($plugin, $file, $line, $warnings, $fallback_ref) = @_;

    # Build initial fallback list...
    my @fallbacks = _uniq( @{ $fallback_ref // [] } );

    # Remember and normalize the original plugin requested (even after we start falling back)...
    my $starting_plugin = $plugin;
    if ($starting_plugin !~ m{ \A Data::Show::Plugin \b }x) {
        $starting_plugin = "Data::Show::Plugin::$plugin";
    }

    # Track outcomes...
    my @failed_loads;
    state %loaded;

    # Loop to accommodate fallbacks (if required)...
    CANDIDATE:
    while (1) {
        # Normalize plugin name under the Data::Show::Plugin:: hierarchy...
        if ($plugin !~ m{ \A Data::Show::Plugin \b }x) {
            $plugin = "Data::Show::Plugin::$plugin";
        }

        # Only load (or try to load) each plugin once (if already loaded, just return its name)...
        last CANDIDATE if exists $loaded{$plugin};

        # Handle standard plugins...
        if (my $standard = $STANDARD_PLUGIN{$plugin}) {

            # Validate the plugin's preconditions...
            for my $requirement (@{$standard->{requires}}) {

                # If plugin can't be used, fall back to the next best alternative (if any)...
                if (!eval "require $requirement; 1") {
                    warn "$plugin requires $requirement, which could not be loaded.\n"
                        if $warnings;
                    push @failed_loads, $plugin;
                    if ($plugin = shift(@fallbacks) // $standard->{fallback}) {
                        next CANDIDATE;
                    }
                    else {
                        $plugin = $FINAL_CANDIDATE_PLUGIN;
                        last CANDIDATE;
                    }
                }
            }

            # Instantiate the plugin class, inserting the plugin-specific source code...
            eval qq{
                package $plugin;
                BEGIN { our \@ISA = 'Data::Show::Plugin'; }
                $standard->{source};
                1;
            } or die "Internal error: $@";   # This can never happen! ;-)

            # And we're done...
            last CANDIDATE;
        }

        # Otherwise, if we can load the (non-standard) module then we're also done...
        elsif (_load_external_plugin($plugin, $warnings)) {
            last CANDIDATE;
        }

        # Otherwise, fall back to a specified alternative, or else try the standard fallback(s)...
        else {
            warn "Could not install $plugin at $file line $line\n"
                if $warnings;
            push @failed_loads, $plugin;
            $plugin = shift(@fallbacks) // $INITIAL_DEFAULT_PLUGIN;
            next CANDIDATE;
        }
    }

    # Report substitution-on-failure (if any)...
    warn "Used $plugin in place of $starting_plugin at $file line $line\n"
        if $warnings && $plugin ne $starting_plugin;

    # Remember the outcome(s) to speed things up next time...
    $loaded{$_} = $plugin for $plugin, @failed_loads;

    return $plugin;
}

# Load or otherwise verify the availability of a non-standard plugin...
sub _load_external_plugin {
    my ($plugin, $warnings) = @_;

    # Load it (or fail silently)...
    eval "require $plugin";

    # Are all the essential methods present in the plugin class???
    my @missing_methods = grep { !$plugin->can($_) } @PLUGIN_API;
    warn "Requested plugin class $plugin does not provide the following essential methods:\n",
         (map { "   $_()" } @missing_methods), "\n"
            if $warnings && @missing_methods;

    # Succeed if all the essential methods are available...
    return !@missing_methods;
}

# Locate and process config file(s) and/or environment variable, if any...
sub _load_defaults {
    my ($file, $line) = @_;

    # Build up defaults, starting with the built-in defaults...
    my %defaults = @ARGUMENT_DEFAULTS;

    # Overwrite previous defaults with any readable global or local config file(s)...
    for my $config_file (grep {-r} "$ENV{HOME}/$RC_FILE_NAME", "./$RC_FILE_NAME") {
        %defaults = ( %defaults, _load_config($config_file) );
    }

    return \%defaults;
}

sub _load_config {
    my ($filename) = @_;

    # Grab contents of file...
    open my $fh, '<:utf8', $filename or return;
    local $/;
    my $config = readline($fh) // return;

    # Remove empty lines (including comment lines)...
    $config =~ s{ ^ \s* (?: \# [^\n]* )? (?:\n|\z) }{}gxms;

    # Extract keys and values of each option...
    my %opt = $config =~ m{ ^ \h* ([^:=]*?) \h* [:=] \h* ([^\n]*) (?:\n|\z) }gxms;

    # Convert a "*NAME" string to the corresponding named filehandle...
    if (exists $opt{to} && $opt{to} =~ m{ \A \* (.*) }x) {
        no strict 'refs';
        no warnings 'once';
        $opt{to} = \*{$1};
    }

    # Validate config...
    _validate_args(\%opt, "in $filename", "configuration option");

    return %opt;
}

# The whole point of the module...
sub show {
    # Find the various contexts of this call...
    my ($package, $file, $line, $hints_ref) = _get_context();
    my $call_context = wantarray();

    # Skip almost everything if "no Data::Show"...
    if (!$hints_ref->{'Data::Show/noshow'}) {

        # Identify current lexically-scoped config (should already have been loaded by import())...
        my $plugin_class = $hints_ref->{'Data::Show/with'} // $FINAL_CANDIDATE_PLUGIN;
        my %style        = %{ $STYLE[ $hints_ref->{'Data::Show/style'} ] };
        my $termwidth    = $hints_ref->{'Data::Show/termwidth'};

        # Warn about side-effects of multi-arg calls to show() in scalar context...
        if (defined $call_context && !$call_context && @_ > 1) {
            warn "Call to show() may not be not transparent at $file line $line\n";
        }

        # Serialize Contextual::Return objects (can break some dumpers in the Data::Dump family)...
        my @data = map { ref() =~ m{\AContextual::Return::Value}
                    ? do {my $v = $_->Contextual::Return::DUMP(); $v =~ s[\}\n][\},\n]gxms; eval $v; }
                    : $_
                    } @_;

        # Extract the originating source line(s)...
        my ($pre_source, $source, $post_source, $startline)
            = _get_source($file, $line, $hints_ref->{'Data::Show/as'});

        # What kind of data is it???
        my $is_single_hash = _data_is_single_hash($source, \@data, $hints_ref->{'Data::Show/as'});
        my $is_single_arg  = @data == 1;

        # Stringify the data...
        my $data = $plugin_class->stringify( $is_single_hash ? {@data}
                                           : $is_single_arg  ? $data[0]
                                           :                   \@data
                                           );

        # Some stringifiers add an (unwanted) empty first line, so remove it...
        $data =~ s{ \A \h* \n }{}xms;

        # Change delimters of any stringified arguments that were passed to the stringifier via refs...
        if    ($is_single_hash)  { $data =~ s{ \A (\s*) \{ (.*) \} (\s*) \z }{$1($2)$3}xms; }
        elsif (!$is_single_arg)  { $data =~ s{ \A (\s*) \[ (.*) \] (\s*) \z }{$1($2)$3}xms; }

        # Where are we printing to???
        my $fh = exists $hints_ref->{'Data::Show/to'} ? $OUTPUT_FH[$hints_ref->{'Data::Show/to'}]
                                                      : $DEFAULT_TARGET;

        # Disable styling if not outputting to a terminal or if styling is unavailable...
        if (!-t $fh || $style{mode} eq 'auto' && !$CAN_ANSICOLOR) {
            $style{mode} = 'off'
        }

        # Show the data with its context header (with style!)...
        no warnings 'utf8';
        print {$fh}
            $plugin_class->format(
                $file, $startline, $pre_source, $source, $post_source, $data, \%style, $termwidth,
            );
    }

    # Return the entire argument list if possible, otherwise simulate scalar context...
    return @_ if $call_context;
    return $_[0];
}

# Return the source code at a given file and line...
sub _get_source {
    my ($file, $line, $subname) = @_;

    # Optimize look-up via a cache...
    state %source_cache;

    # Load the entire source of requested file...
    if (!$source_cache{$file}) {
        # Load the source of an eval()...
        if ($file =~ m{\A \( eval \s+ \d+ \)}x) {
            $source_cache{$file} = (caller(2))[6];
        }

        # Otherwise, read in the source from the file...
        elsif (open my $filehandle, '<', $file) {
            $source_cache{$file} = do { local $/, readline($filehandle) };
        }

        else {
            # Otherwise, see if it's a #line trick in the main file...
            if (!defined $source_cache{$0} && open my $selfhandle, '<', $0) {
                $source_cache{$0} = do { local $/, readline($selfhandle) };
            }

            $source_cache{$file} = $source_cache{$0};
            $source_cache{$file} =~ s{ \A .*? ^ \# \h* line \h+ (\d+) \h+ \Q$file\E \h* \n }
                                     { "\n" x ($1-1) }xmse
                or $source_cache{$file} = q{};
            $source_cache{$file} =~ s{ \A .*? ^ \# \h* line \h+ (\d+) \h+ [^\n]* \n .* }{}xms;
        }
    }

    # This pattern detects when we have a complete show() call...
    state %SHOW_PATTERN_FOR;
    my $SHOW_PATTERN  = $SHOW_PATTERN_FOR{$subname}
                    //= qr{ (?<pre>  [^\n]*?  )
                            (?>
                                (?<call>  \b(?:$subname)\b (?&PerlOWS) (?&PerlParenthesesList) )
                                (?<post>  [^\n]* )
                            |
                                (?<call>  \b(?:$subname)\b (?&PerlOWS) (?&PerlCommaList)       )
                                (?> (?<post>       (?&PerlOWS)  (?: ; | \Z )  )
                                |   (?<post>)  (?= (?&PerlOWS) \}  )
                                )
                            )
                            $PPR::GRAMMAR
                        }xms;

    # Locate the call in the source code (allowing for inaccuracies in caller() line results)...
    use re 'eval';
    our $prelim_lines; local $prelim_lines = $line-1;
    my $found = $source_cache{$file} =~ m{
        \A
        (?<showlines>
            (?<prelines>  (?: [^\n]* \n ){0,$prelim_lines}? (?&PerlOWS) )
            (?> $SHOW_PATTERN )
        )
        (??{ ($+{showlines} =~ tr/\n//) >= $prelim_lines ? q{} : '(?!)' })
    }xms;
    my %cap = %+;

    # Extract source code of call (the else should only very rarely need to be invoked)...
    if ($found) {
        return @cap{qw<pre call post>}, 1 + ($+{prelines} =~ tr/\n//);
    }
    else {
        return q{}, [0, split /\n/, $source_cache{$file}]->[$line], q{}, $line;
    }

}

# Attempt to detect a show() argument list that consists of a single hash...
sub _data_is_single_hash {
    my ($context, $data_ref, $subname) = @_;
    $context //= q{};

    # What does a single hash arg look like???
    state %SINGLE_HASH_FOR;
    my $SINGLE_HASH = $SINGLE_HASH_FOR{$subname}
                  //= qr{  \b(?:$subname) (?&PerlOWS)
                           (?:                (?&PerlVariableHash)
                             | \( (?&PerlOWS) (?&PerlVariableHash) (?&PerlOWS) \)
                           )
                           (?&PerlOWS) \z
                           $PPR::GRAMMAR
                        }x;

    # Must be only one argument (plus the invocant) and must look like a single hash...
    return @{$data_ref} % 2 == 0 && $context =~ $SINGLE_HASH;
}


# Base class for plugins...
package Data::Show::Plugin;

# When imported, make the imported plugin a base class of the importing class...
sub import {
    my ($package) = @_;
    no strict 'refs';
    @{caller().'::ISA'}  = $package;
}

# Visually distinguish the context string and data...
sub format {
    my ($class, $file, $line, $pre_source, $source, $post_source, $data, $style, $termwidth) = @_;
    $_ //= q{} for $pre_source, $source, $post_source;

    # Track previous file context between calls...
    state $prevfile = q{};
    my $is_new_context = $file ne $prevfile;
    $prevfile = $file;

    # Compute line numbering width...
    my $line_num_len = length( $line + ($pre_source . $source . $post_source) =~ tr/\n// );
    my $data_box_len = $termwidth - 4;
    my $code_box_len = $data_box_len - $line_num_len - 1;

    # ASCII-only decoration if explicitly requested, or if Term::ANSIcolor is unavailable...
    my $decorate_data    = $style->{mode} eq 'context'
                        || $style->{mode} eq 'off'     ? \&_monochrome : \&_polychrome;
    my $decorate_context = $style->{mode} eq 'off'     ? \&_monochrome : \&_polychrome;

    # Set up grid components (if requested)...
    my ($gridhead, $gridtail, $gridfsep, $gridcsep, $gridside, $gridline, $gridplus) = (q{}) x 7;
    my $padding = q{ } x $data_box_len;

    if ($style->{add_grid} ne 'off') {
        #                           $is_new_context    !$is_new_context
        # Top line of grid:         ┏━━━━━━━━━━━━━┓    ┏━━━┯━━━━━━━━━━┓
        $gridhead = $GRID{'┏'} . ($GRID{'━'} x ($termwidth-2)) . $GRID{'┓'} . "\n";
        substr($gridhead, $line_num_len+1, 1) = $GRID{'┯'} if !$is_new_context;

        # Post-filename separator:  ┠───┬─────────┨    <not used>
        $gridfsep = $GRID{'┠'} . ($GRID{'─'} x ($termwidth-2)) . $GRID{'┨'} . "\n";
        substr($gridfsep, $line_num_len+1, 1) = $GRID{'┬'};

        # Post-code separator:      ┠───┴─────────┨    ┠───┴─────────┨
        $gridcsep = $GRID{'┠'} . ($GRID{'─'} x ($termwidth-2)) . $GRID{'┨'} . "\n";
        substr($gridcsep, $line_num_len+1, 1) = $GRID{'┴'};

        # Bottom line of grid:      ┗━━━━━━━━━━━━━┛    ┗━━━━━━━━━━━━━┛
        $gridtail = $GRID{'┗'} . ($GRID{'━'} x ($termwidth-2)) . $GRID{'┛'} . "\n";

        # Verticals of grid...
        $gridside = $GRID{'┃'};
        $gridplus = $GRID{'┃'} . q{ };
        $gridline = $GRID{'│'};

        # Decorate them all in the same style...
        for my $border ($gridhead, $gridtail, $gridfsep, $gridcsep, $gridside, $gridplus, $gridline) {
            $border = $decorate_context->($border, $style->{grid});
        }
    }

    # Style the source code...
    $source = join("\n", map {$decorate_context->($_, $style->{code})} split "\n", $pre_source)
            . join("\n", map {$decorate_context->($_, $style->{show})} split "\n", $source)
            . join("\n", map {$decorate_context->($_, $style->{code})} split "\n", $post_source);
    $source =~ s{ ^ }{  }gxms;

    # Install the line numbers and grid/format each source line...
    $source = join "\n",
              map {
                  $style->{add_grid} eq 'off'
                        ?                    m{ [^\n]* }xms
                        : ($_ . $padding) =~ m{ $COLOUR_CHAR {$code_box_len} }xms;
                  $gridside
                . $decorate_context->( sprintf('%*d', $line_num_len, $line++), $style->{line} )
                . $gridline . q{ } . $& . q{ } . $gridside
              }
              split "\n", $source;

    # Trim, grid, and format each data line...
    $data = join "\n",
            map {
                  $style->{add_grid} eq 'off' ? m{ [^\n]* }xms
                                              : ($_ . $padding) =~ m{ $COLOUR_CHAR {$data_box_len} }xms;
                  $gridplus . $decorate_data->( $&, $style->{data} ) . q{ } . $gridside
            }
            split "\n", $data;

    # Delineate source lines and data lines if no better styling has been specified...
    if (!$CAN_ANSICOLOR && $style->{add_grid} eq 'off') {
        $file   =~ s{ ^ }{### }gxms;
        $source =~ s{ ^ }{### }gxms;
        $data   =~ s{ ^ }{>>> }gxms;
    }

    return $gridhead
         . ($is_new_context
                ? do {
                       $style->{add_grid} eq 'off'
                           ? $file =~ m{ [^\n]* }xms
                           : ($file . $padding) =~ m{ $COLOUR_CHAR {$data_box_len} }xms;
                       $gridplus
                     . $decorate_context->( $&, $style->{file} )
                     . q{ } . $gridside . "\n"
                     . $gridfsep
                     }
                : q{}
           )
         . "$source\n"
         . $gridcsep
         . "$data\n"
         . $gridtail
         . "\n";
}


# Utility functions...

sub _monochrome { $_[0] }

sub _polychrome { &Term::ANSIColor::colored }

sub _antichrome { &Term::ANSIColor::colorstrip }

sub _max {
    my ($x, $y) = @_;
    return $x > $y ? $x : $y;
}

# Convert the data to a printable form (using Data::Dumper)...
sub stringify {
    my ($class, $data) = @_;

    # Choose conservative defaults (derive a subclass to change these)...
    use Data::Dumper 'Dumper';
    no warnings 'once';
    local $Data::Dumper::Deparse  = 0;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Deepcopy = 1;
    local $Data::Dumper::Terse    = 1;

    # Convert data to a string representation...
    my $stringification = Dumper($data);

    # Remove the annoying "$VAR1 = ", and realign subsequent indented lines...
#    $stringification =~ s{ ^ .{8} }{}gxms;

    # Remove the annoying trailing ';'...
    $stringification =~ s{ ; (\s*) \z }{$1}gxms;

    return $stringification;
}


# Template for constructing standard plugins...
my $NULL_FORMATTER; BEGIN { $NULL_FORMATTER = q{
    sub format {
       my ($class, $data) = @_;
       $data =~ s{\s*\z}{};
       return "$data\n\n";
    }
}}
sub _build_plugin {
    # (SHOUTY parameters get interpolated, mousy prarameters don't)...
    my ($NAME, $FALLBACK, $DUMP, $no_formatting) = @_;

    # Handle non-formatting plugins, and optimize argument look-up...
    my $FORMATTER = $no_formatting ? $NULL_FORMATTER : q{};
    my $DATA      = '$_[1]';

    return
        "Data::Show::Plugin::$NAME" => {
            requires => [$NAME],
            fallback => $FALLBACK,
            source   => qq{
                $FORMATTER
                sub stringify {
                    use $NAME q{$DUMP};
                    return (eval { $DUMP($DATA) }
                            // '<$NAME cannot show a ' . lc(ref($DATA)) . " reference>\n")
                         . "\n";
                }
            },
        };
}

# Initialize the data needed to instantiate the built-in plugins on-demand...
BEGIN {
    %STANDARD_PLUGIN = (

        #              DUMPER MODULE              FALLBACK        DUMP FUNC   VARIATIONS
        _build_plugin( 'Data::Dmp'             => 'Data::Pretty', 'dmp'                      ),
        _build_plugin( 'Data::Dump'            => 'Data::Dumper', 'pp',                      ),
        _build_plugin( 'Data::Dump::Color'     => 'Data::Dump',   'pp',       'preformatted' ),
        _build_plugin( 'Data::Dumper::Compact' => 'Data::Dump',   'ddc'                      ),
        _build_plugin( 'Data::Dumper::Concise' => 'Data::Dumper', 'Dumper'                   ),
        _build_plugin( 'Data::Dumper::Table'   => 'Dumpvalue',    'Tabulate'                 ),
        _build_plugin( 'Data::Pretty'          => 'Data::Dump',   'pp',                      ),
        _build_plugin( 'Data::TreeDumper'      => 'Dumpvalue',    'DumpTree'                 ),
        _build_plugin( 'YAML'                  => 'YAML::Tiny',   'Dump'                     ),
        _build_plugin( 'YAML::PP'              => 'YAML::Tiny',   'Dump'                     ),
        _build_plugin( 'YAML::Tiny'            => 'Dumpvalue',    'Dump'                     ),
        _build_plugin( 'YAML::Tiny::Color'     => 'YAML::Tiny',   'Dump',     'preformatted' ),

        "Data::Show::Plugin::Data::Dumper" => {
            requires => ['Data::Dumper'],
            fallback => 'DumpValue',
            source   => q{},  # ...because Data::Show::Plugin base class already uses Data::Dumper
        },

        'Data::Show::Plugin::Data::Printer' => {
            requires => ['Data::Printer'],
            fallback => 'Dumpvalue',
            source => qq{
                sub stringify {
                    use Data::Printer;
                    return np(\$_[1], colored=>$CAN_ANSICOLOR) . "\n";
                }
            },
        },

        'Data::Show::Plugin::Dumpvalue' => {
            requires => ['Dumpvalue'],
            source => q{
                sub stringify {
                    my ($class, $data) = @_;

                    # Create a singleton Dumpvalue object to do the stringification...
                    use Dumpvalue;
                    state $DUMPER = Dumpvalue->new(subdump=>1, globPrint=>1);

                    # Dumpvalue only dumps to STDOUT, so co-opt that filehandle to capture the output...
                    open +(local *STDOUT), '>', \\my $dump;

                    # Stringify the data to the captured STDOUT...
                    $DUMPER->dumpValue($data);

                    # Return the intercepted stringification...
                    return $dump;
                }
            },
        },

        # This plugin restores the previous (pre-version-0.003) output format for the module...
        'Data::Show::Plugin::Legacy' => {
            requires => ['Data::Dump', 'PPR', 'List::Util'],
            fallback => 'Data::Dump',
            source => q{
                sub format {
                    my ($class, $file, $line,
                        $pre_source, $source, $post_source,
                        $data, $style, $termwidth) = @_;

                    use List::Util 'max';

                    # Configuration for layout of representation...
                    state $DEFAULT_INDENT = 4;
                    state $MAX_DESC       = 30;
                    state $MAX_FILENAME   = 20;
                    state $TITLE_POS      = 3;

                    # Extract description of arglist from source...
                    $source =~ s{\\A show \b \\s*}{}x;
                    $source =~ s{\\s+}{ }gx;
                    $source =~ s{\\A \\( (.*) \\) \\Z}{$1}x;
                    if (length($source) > $MAX_DESC) {
                        $source = substr($source,0,$MAX_DESC-3) . q{...};
                    }

                    # Trim filename and format context info and description...
                    $file =~ s{.*[/\\\\]}{}xms;
                    if (length($file) > $MAX_FILENAME) {
                        $file =~ s/ (_[^\\W_]) [^\\W_]* /$1/gxms;
                    }
                    if (length($file) > $MAX_FILENAME) {
                        $file =~ s/\\A (.{1,8}) .*? (.{1,8}) \\Z/$1...$2/gxms;
                    }
                    my $context = "[ '$file', line $line ]";

                    # Insert title into header...
                    my $header = '=' x $termwidth;
                    substr($header, $TITLE_POS, length($source)+6) = "(  $source  )";
                    substr($header, -(length($context)+$TITLE_POS), length($context)) = $context;

                    # Indent data...
                    $data =~ s{^}{    }gxms;

                    # Assemble and send off...
                    return "$header\\n\\n$data\\n\\n";
                }

                # Original stringifier was Data::Dump...
                sub stringify {
                    use Data::Dump 'pp';
                    return pp($_[1]);
                }
            },
        },
    );
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Data::Show - Dump data structures with name and point-of-origin information


=head1 VERSION

This document describes Data::Show version 0.004000


=head1 SYNOPSIS

    use Data::Show;

    show %foo;
    show @bar;
    show (
        @bar,
        $baz,
    );
    show $baz;
    show $ref;
    show @bar[do{1..2;}];
    show 2*3;
    show 'a+b';
    show 100 * sqrt length $baz;
    show $foo{q[;{{{]};


=head1 DESCRIPTION

This module provides a simple wrapper around various data-dumping modules.

A call to C<show()> data-dumps its arguments, prefaced
by a context string that reports the arguments and the
file and line from which C<show()> was called.

For example, the code in the L<SYNOPSIS> might produce something like
the following:

    ### try_SYNOPSIS.pl
    ### 16:     show %foo;
    >>>
    >>> ( f => 1, o => 2 )

    ### 17:     show @bar;
    >>>
    >>> qw( 3 . 1 4 1 5 )

    ### 18:     show (
    ### 19:         @bar,
    ### 20:         $baz,
    ### 21:     );
    >>>
    >>> (3, ".", 1, 4, 1, 5, "baz value")

    ### 22:     show $baz;
    >>>
    >>> "baz value"

    ### 23:     show $ref;
    >>>
    >>> {
    >>>     a => [1, 2, 3],
    >>>     h => { x => 1, y => 2, z => 3 },
    >>>     s => \"scalar",
    >>> }

    ### 24:     show @bar[do{1..2;}];
    >>>
    >>> qw( . 1 )

    ### 25:     show 2*3;
    >>>
    >>> 6

    ### 26:     show 'a+b';
    >>>
    >>> "a+b"

    ### 27:     show 100 * sqrt length $baz;
    >>>
    >>> 300

    ### 28:     show $foo{q[;{{{]};
    >>>
    >>> undef

If you have Term::ANSIColor installed, you get an even cleaner dump
with the context, source code, and dumped values distinguished in
distinct, accessible, and configurable colours.


=head1 INTERFACE

    use Data::Show;

Loading the module without arguments exports a single C<show()> subroutine that
dumps its argument(s) to C<STDERR>, using either the C<Data::Pretty> module, or
else C<Data::Dump>, or else C<Data::Dumper>, or else C<Dumpvalue> (whichever is
first available, in that order - see L<"Fallbacks">).

The C<show()> subroutine is the only subroutine provided by the module.
It is always exported.

C<show()> can be called with any number of arguments and data-dumps them
all with a suitable header indicating the arguments, and the file
and line from which C<show()> was called.

C<show()> returns its own argument(s), which allows you to place it
in the middle of a larger expression to check an intermediate value
(see L<"Inlined dumps">).



=head2 Changing the module used to dump data

    use Data::Show with => 'MODULE::NAME';

If you pass a C<'with'> argument when loading the module,
it exports the single C<show()> subroutine that dumps its argument(s)
to C<STDERR> using the specified dumper plugin. For example:

    use Data::Show  with => 'Data::Printer';

    use Data::Show  with => 'Data::Dmp';

    use Data::Show  with => 'Legacy';

    use Data::Show  with => 'My::Own::Dumper';

If the requested module is not available (i.e. can't be loaded),
then a fallback (see L<"Fallbacks">) is used instead.

See L<"Plugins"> for details of how to specify any of the standard plugins,
and how to create and name your own plugins.


=head2 Specifying a fallback dumper

    use Data::Show fallback => 'MODULE::NAME';

You can specify a fallback plugin to be used if the requested (or default)
dumper plugin cannot be loaded. This fallback will be used any time the
requested plugin cannot be located, or fails to load, or does not supply
the necessary dumping methods. The specified fallback represents the
I<starting point> for the standard fallback process. See L<"Fallbacks">.


=head2 Changing the destination to which data is dumped

    use Data::Show to => TARGET_SPECIFIER;

Loading the module with a C<'to'> argument exports the single C<show()> subroutine
that dumps its argument(s) to the specified target (rather than to C<STDERR>).
The specified target can be a filename, an already-opened filehandle, or a
variable reference. For example:

    use Data::Show  to => \*STDOUT;

    use Data::Show  to => \$capture_variable;

    use Data::Show  to => 'some_file_name';


=head2 Exporting C<show()> under another name...

    use Data::Show as => 'explicate';

The module always exports a single C<show()> subroutine, but C<show()>
is an extremely generic name, which could easily already be used in
some other way in the code you are debugging.

So the module can export C<show()> under another name, by loading it
with the C<'as'> option, passing the desired alternative name as a string.


=head2 Specifying the output width

    use Data::Show termwidth => 78;

Loading the module with a C<'termwidth'> argument sets the maximum
width value that will be passed to plugins when they are asked to dump data.
The default maximum is 78 columns, but using this option that maximum can
be reset to any desired positive integer value.

Note that plugins are always free to disregard the maximum terminal width they
are passed, and will often do so in the interest of showing the dumped data fully.
However, the built-in plugins that support L<grid output | "Requesting grid output">
will always constrain their output grids to the requested terminal width.


=head2 Silencing warnings

The module produces a number of L<compile-time warnings | "DIAGNOSTICS">,
most of which can be silenced, by loading it with the C<'warnings'> option,
as follows:

    use Data::Show warnings  => 'off';

Note that if the option is specified with I<any> value except C<'off'>,
then warnings will remain enabled. Specifically, passing a false value
for C<'warnings'> does B<not> turn off warnings. If you need to control
warnings via a boolean value (say in the variable C<$ENV{WARNINGS}>),
use something like:

    use Data::Show warnings => ($ENV{WARNINGS} ? 'on' : 'off');


=head2 Requesting grid output

    use Data::Show grid  => 'on';   # Or any other true value except 'off'

Normally, the context and data information produced as the output
of the C<show()> subroutine are distinguished by prefixes or by colour/styling.
However, you can also request that the context and data are placed in a grid,
to more clearly distinguish the module's output from the program's regular output.

When requested, the grid is generated automatically,
using either ASCII punctuation characters:

     _______________________________
    |20:   show (                   |
    |21:      \@bar,                |
    |22:       $baz,                |
    |23:   );                       |
    |-------------------------------|
    | ( ['b', 'a', 'r'], 'baz' )    |
    |_______________________________|

...or (if the the module can determine that the terminal supports UTF8 output),
using Unicode box-drawing elements:

    ┏━━┯━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    ┃19│   show (                   ┃
    ┃20│      \@bar,                ┃
    ┃21│       $baz,                ┃
    ┃22│   );                       ┃
    ┠──┴────────────────────────────┨
    ┃ ( ['b', 'a', 'r'], 'baz' )    ┃
    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

The choice to use Unicode is made by examining the C<$ENV{LC_ALL}>, C<$ENV{LC_TYPE}>,
and C<$ENV{LANG}> environment variables. If any of them are set to a value that
includes the strings C<'utf-8'> or C<'UTF-8'>, then the terminal is assumed to be
Unicode capable.

You can also explicitly turn grid output off
(if, for example, it was turned on by default in
L<your F<.datashow> file|"CONFIGURATION AND ENVIRONMENT">):

    use Data::Show grid  => 'off';


=head2 Specifying the output style

The module allows you to configure every aspect of the styling of its output
(including whether or not it the output has any styling). Normally, the module
determines automatically whether colour output is appropriate or possible,
by checking for the availability of the L<Term::ANSIColor> module. If that module
can be loaded, it is used to style the output; if not, the output is unstyled.

However, you can explicitly disable output styling (regardless of the availability
of L<Term::ANSIColor>) by passing the appropriate C<'style'> option when the module
is loaded:

    use Data::Show style => 'off';

You can also turn off styling of just the data dump (leaving the context information styled)
with:

    use Data::Show style => 'context';

If you wish to explicitly request the default automatic styling (for example, to override
an option specified in the F<.datashow> file), you can do so with:

    use Data::Show style => 'auto';

In addition to controlling whether styling is used at all, you can also specify exactly
what styling is used for each component of the output, using the various C<'...style'>
options. Each option takes a string value containing either two L<Term::ANSIColor>
style specifications, separated by a comma (the first of which is used for terminals with dark
backgrounds, and the second of which is used for terminals with light
backgrounds):

    use Data::Show
    #   COMPONENT    FOR DARK BG     FOR LIGHT BG
    #   =========    ===========     ============
        datastyle => 'bold white ,   bold black',
        showstyle =>  'bold cyan ,    bold blue',
        codestyle =>       'cyan ,         blue',
        filestyle =>       'blue ,          red',
        linestyle =>       'blue ,          red',
        gridstyle =>       'blue ,          red';

Alternatively any of these options can be specified with a single string
containing only B<one> L<Term::ANSIColor> style specification
(which is then used for both light- and dark-background terminals):

    use Data::Show
    #   COMPONENT    FOR ALL BGS
    #   =========    ===========
        datastyle => 'bold red',
        showstyle => 'bold green',
        codestyle => 'green',
        filestyle => 'cyan',
        linestyle => 'cyan',
        gridstyle => 'blue';

You can specify as many or as few of these options as you wish,
and mix any number of single- and light/dark values in a single call.

The effect of each option is as follows:

=over

=item C<datastyle>

The style in which the dumped data is output
S<(default: C<'bold white, bold black'>)>

=item C<showstyle>

The style in which the show statement itself is output (and highlighted)
as part of the context information
S<(default: C<'bold bright_cyan, bold bright_blue'>)>

=item C<codestyle>

The style in which any other ambient source code is output
(and typically de-emphasized) as part of the context information
S<(default: C<'cyan, blue'>)>

=item C<filestyle>

The style in which filenames are output as part of the context information
S<(default: C<'blue, red'>)>

=item C<linestyle>

The style in which line numbers are output as part of the context information
S<(default: C<'blue, red'>)>

=item C<gridstyle>

The style in which gridlines are drawn
S<(default: C<'blue, red'>)>

=back


=head2 Lexically disabling C<show()>

During a debugging session it can be useful to turn off the data dumping behaviour
of the C<show()> subroutine, without having to comment out, or remove, every call to it
throughout the source code.

If you load the module with C<no> instead of C<use>:

    no Data::Show;

...then the dumping behaviour of C<show()> is disabled within the rest of the lexical
scope. So, if you anticipate needing to continue debugging at a later stage,
you can set up a series of calls to C<show()> and then "turn them off"
without actually having to remove them immediately.

Of course, those calls still impose a slight overhead on your code so you should
still actually remove the calls to C<show()> from your source, once you are confident
that you have genuinely finished debugging it.


=head2 Plugins

Because most dumper modules have distinct and incompatible interfaces,
the Data::Show module uses object-oriented wrapper classes to convert
each dumper module into a compatible API. This also makes it easy to
integrate other modules you may wish to use as dumpers for Data::Show.

Wrapper classes are automatically generated for the following core or CPAN dumper modules:

    Data::Dmp
    Data::Dump
    Data::Dump::Compact
    Data::Dumper
    Data::Dumper::Color
    Data::Dumper::Concise
    Data::Dumper::Table
    Data::Pretty
    Data::Printer
    Data::TreeDumper
    Dumpvalue
    YAML
    YAML::PP
    YAML::Tiny
    YAML::Tiny::Color

But you can also write your own plugin wrapper classes to allow Data::Show
to make use of other dumper modules.

Each wrapper class must be declared with a name beginning C<Data::Show::Plugin::>,
where the convention is that the rest of the wrapper's name is the name of the
dumper module it's wrapping. For example:

    Data::Show::Plugin::Data::Dumper
    Data::Show::Plugin::Data::Dump
    Data::Show::Plugin::YAML
    Data::Show::Plugin::My::Own::Dumper

Each such wrapper class must provide two methods: C<stringify()> and C<format()>.
Both methods should expect to be called on the class itself (i.e. as I<common> methods),
rather than on an actual object (i.e. not as I<instance> methods).

The C<stringify()> method expects a single argument: a data value or reference
that is to be stringified. The C<stringify()> method is expected to return a
single string representing that data in some way.

For example:

    # Create a plugin to allow Data::Show to dump using the Data::Dumper module...
    package Data::Show::Plugin::Data::Dumper;

    sub stringify ($class, $data) {
        use Data::Dumper 'Dumper';
        return Dumper($data) =~ s{ ; (\s*) \z }{$1}xr;
    }

When creating plugin you can, of course, use the new Perl OO syntax instead:

    class Data::Show::Plugin::Data::Printer;

    method stringify ($data) {
        use Data::Printer;
        return np($data, colored=>1) . "\n";
    }

The second method that a plugin must provide is C<format()>.
It is passed nine arguments:

    $file          # The name of the file from which show() was called
    $line          # The line at which show() was called
    $pre_source    # Any source code on that line before the call to show()
    $source,       # The source code of the call to show()
    $post_source   # Any source code on the same line after the call to show()
    $data          # The already-stringified data to be shown
    $style         # A hash containing the various style configuration values
    $termwidth     # The maximum terminal width nominated by the user

The C<format()> method is expected to use this information to return
a single formatted string (possibly including terminal escape codes)
that will then be output as the result of the call to C<show()>.

For example:

    class Data::Show::Plugin::Legacy;

    method format ($class, $file, $line, $pre, $source, $post, $data, $style, $termwidth) {

        # Extract description of arglist from source...
        $source =~ s{\\A show \b \\s*}{}x;
        $source =~ s{\\s+}{ }gx;
        $source =~ s{\\A \\( (.*) \\) \\Z}{$1}x;

        # Trim filename and format context info and description...
        $file =~ s{.*[/\\\\]}{}xms;
        my $context = "[ '$file', line $line ]";

        # Insert title into header...
        my $header = '=' x $termwidth;
        substr($header, $TITLE_POS, length($source)+6) = "(  $source  )";
        substr($header, -(length($context)+$TITLE_POS), length($context)) = $context;

        # Indent data...
        $data =~ s{^}{    }gxms;

        # Assemble and send off...
        return "$header\\n\\n$data\\n\\n";
    }

Note that, if you are generally happy with the output formatting that Data::Show provides
by default, it is not necessary to write your own C<format()> method when creating a new plugin;
you can choose to simply inherit the default one:

    class Data::Show::Plugin::My::Own::Dumper;

    use Data::Show 'base';     # Inherit format() from Data::Show::Plugin

    method stringify ($data) {
        use My::Own::Dumper;
        return My::Own::Dumper->new->dump($data);
    }

...or, if you want legacy Data::Show formatting for your new plugin:

    class Data::Show::Plugin::My::Own::Dumper::Legacy;

    use Data::Show base => 'Data::Show::Plugin::Legacy';   # Inherit legacy format()

    method stringify ($data) {
        use My::Own::Dumper;
        return My::Own::Dumper->new->dump($data);
    }

When the Data::Show module is loaded with the single argument C<'base'>:

    use Data::Show  'base';

...it causes the current class to inherit the root plugin base class,
C<Data::Show::Plugin>.

Alternatively, when Data::Show is loaded with a named C<base> argument pair:

    use Data::Show  base => 'Data::Show::Plugin::Whatever';

...it causes the current class to inherit the specified base class
(loading or autogenerating that base class, if necessary).


=head2 Modifying existing plugins

The object-oriented nature of the plugin mechanism also makes it easy to
modify the dumping or formatting behaviour of an existing plugin.

For example, if you wanted to change the default behaviour of the builtin
plugin for L<Data::Printer>, so that it no longer shows tainting or colours,
and so that it indents by eight columns instead of four, then you could
create a derived plugin class and override its C<stringify()> method:

    class Data::Show::Plugin::Data::Printer::Custom;

    # Inherit from the existing standard plugin...
    use Data::Show base => 'Data::Show::Plugin::Data::Printer';

    # Change the stringification behaviour...
    method stringify ($data) {
        use Data::Printer;
        return np($data, show_tainted=>0, colored=>0, indent=>8, ) . "\n";
    }

    # and thereafter...

    use Data::Show  with => 'Data::Printer::Custom';


=head2 Fallbacks

In addition to allowing the user to
L<explicitly specify a fallback option | "Specifying a fallback dumper">,
the module maintains an internal hierarchy of dumpers it can fall back on
if the requested dumper (or the default dumper) is not able to be loaded:

                            Data::Dmp   Legacy
                             \______  ______/
                                    \/
          Data::Dumper::Color   Data::Pretty   Data::Dump::Compact
           \________________________  __________________________/
                                    \/
        Data::Dumper::Concise   Data::Dump   YAML   YAML::PP   YAML::Tiny::Color
         \______________  ______________/     \____________  _________________/
                        \/                                 \/
    Data::Printer  Data::Dumper  Data::Dumper::Table  YAML::Tiny  Data::TreeDumper
     \____________________________________  ____________________________________/
                                          \/
                                      Dumpvalue

The idea is that when a specific dumper module is requested (or defaulted to)
but cannot be loaded, the module will follow the arrows downwards through the preceding diagram,
trying each alternative dumper module on that path through the tree.

So, for example, if the user requests L<Data::Dmp> as their dumper, but it is not
available, then the module will try L<Data::Pretty>, then L<Data::Dump>, then
L<Data::Dumper>, then L<Dumpvalue>, accepting the first fallback it can load.
Note that both L<Data::Dumper> and L<Dumpvalue> are core modules, so they should
always be available in any standard Perl installation.


=head1 DIAGNOSTICS

=over

=item C<< Unknown named arguments: <ARGNAMES> >>

You loaded the module and passed a named argument with a name other than
C<as>, C<to>, C<with>, C<fallback>, C<warnings>, C<termwidth>, C<grid>,
C<style>, C<showstyle>, C<datastyle>, C<codestyle>, C<filestyle>,
C<linestyle>, or C<gridstyle>.

Did you misspell one of those?


=item C<< No value specified for named argument <ARGNAME> >>

You loaded the module and passed a named option (C<'with'>, C<'to'>, C<'warnings'>, etc.)
but you didn't provide a value for that name. For example:

    use Data::Show 'warnings';

If you really intended to specify that named argument with
an undefined value, specify the C<undef> explicitly:

    use Data::Show 'warnings' => undef;

Although, because passing C<undef> actually leaves the warnings on,
in this particular example the user probably meant:

    use Data::Show 'warnings' => 'off';


=item C<< Unknown configuration options: <CONFIGNAMES> >>

You specified a configuration option in a F<.datashow> file
with a name other than:
C<as>, C<to>, C<with>, C<fallback>, C<warnings>, C<termwidth>, C<grid>,
C<style>, C<showstyle>, C<datastyle>, C<codestyle>, C<filestyle>,
C<linestyle>, or C<gridstyle>.

Did you misspell one of those?


=item C<< Can't specify 'base' as a configuration option in <CONFIGFILE> >>

It doesn't make sense to specify C<'base'> in your F<.datashow> configuration file.
A C<'base'> specification causes the current class to inherit a plugin
class. But there's no current class in a configuration file, so specifying
a C<'base'> value is pointless there (and probably indicate a misunderstanding
of the C<'base'> option).

Just remove the configuration option from your F<.datashow> file.


=item C<< If 'base' is specified, it must be the only argument >>

The C<'base'> named argument causes the current class to inherit a specified plugin
class. It does not export or configure C<show()>, so any other arguments are
pointless (and probably indicate a misunderstanding of the C<'base'> option).

Remove any other named arguments from the C<use Data::Show> call.


=item C<< Could not open named 'to' argument for output >>

You specified a filename as an alternative output target,
via a named C<'to'> argument, but the specified file could not
be opened for output. For example:

    use Data::Show to => "";

Check whether the filename is legal on your filesystem, and also
whether the target directory, and any existing version of the file,
are both writeable.


=item C<< Named 'to' argument is not a writeable target >>

You specified a filehandle as an alternative output target,
but the filehandle was not writeable.

Check whether the filehandle you passed is actually open,
and then whether it is open for output.


=item C<< <PLUGIN> requires <MODULE>, which could not be loaded >>

You requested a built-in plugin, but that plugin requires a module
that could not be loaded.

Either install the required support module, or load Data::Show with:

    use Data::Show warnings => 'off';

...to silence this warning and quietly use a fallback module instead.


=item C<< Could not load <PLUGIN> >>

You requested a non-built-in plugin, but that plugin
could not be loaded.

Check that the name of the requested plugin is correctly spelled,
and that the plugin is actually installed somewhere in the current
C<@INC> path.

If you can't install the module, you can silence this warning
and default to a fallback dumper with:

    use Data::Show warnings => 'off';


=item C<< Requested plugin class does not provide the following essential methods >>

You specified a non-builtin plugin, which was found and loaded, but which did
not provide both of the two required methods for dumping information:
C<stringify()> and C<format()>.

See L<"Plugins"> for an explanation of why these two methods are required,
and how they work.

To ignore this warning and proceed to a fallback dumper module instead:

    use Data::Show warnings => 'off';

=item C<< Used <FALLBACK> in place of <PLUGIN> >>

You requested a plugin that could not be loaded,
so the best available fallback was used instead.

You would have also received one or more of the three preceding
diagnostics. Consult their entries for suggestions on silencing
this warning.


=item C<< Call to show() may not be not transparent >>

The call to C<show()> has been inserted into a scalar context,
but was passed two or more arguments to dump. This can change
the behaviour of the surrounding code. For example, consider
the following statements:

    my @list = (
        abs  $x,
        exp  $y,
        sqrt $z,
    );

    sub foo ($angle) {
        return cos $angle,
               sin $angle;
    }

If we add interstitial C<show()> calls, as follows:

    my @list = (
        abs  show $x,
        exp  show $y,
        sqrt show $z,
    );

    sub foo ($angle) {
        return cos show $angle,
               sin show $angle;
    }

...then the addition of the C<show()> calls actually changes
the final contents of C<@list>, and also changes the return
value of C<foo()> in scalar contexts.

This issue (and warning) never occurs in list or void contexts,
and can generally be avoided in scalar contexts, by explicitly
parenthesizing each call to C<show()>, as follows:

    my @list = (
        abs  show($x),
        exp  show($y),
        sqrt show($z),
    );

    sub foo ($angle) {
        return cos show($angle),
               sin show($angle);
    }

Note that this approach also ensures that the various intermediate
calls to C<show()> occur in a more predictable sequence.


=item C<< <MODULE> cannot show a <TYPE> reference >>

The stringification module used by your selected plugin
was unable to stringify the particular data passed to C<show()>.

This may be due to a bug or limitation in the stringification module itself,
or it may be because the target output format does not support rendering
certain Perl datatypes. For example, C<YAML::Tiny> deliberately supports
only a subset of the full YAML output format and cannot represent references
to scalars or C<qr> regexes. So C<Data::Show::Plugin::YAML::Tiny>
cannot stringify those two data types.

To be shown the particular data, choose another C<Data::Show> plugin instead.
For example, try C<Data::Show::Plugin::YAML> instead of C<Data::Show::Plugin::YAML::Tiny>.


=item C<< Internal error: <DESCRIPTION> >>

Congratulations! You found a bug in this module.
Please consider reporting it to the maintainer,
who will be extremely grateful to you.

=back


=head1 CONFIGURATION AND ENVIRONMENT

You can change the default values for the C<'with'>, C<'to'>, C<'warnings'>,
and all other options to a C<use Data::Show;> by specifying either
a local or a global configuration file.

If a C<use Data::Show> call does not specify an explicit C<'with'> or C<'to'>,
the module looks first for a F<.datashow> file in the current directory,
and then for a F<.datashow> file in the home directory.

The contents of each of these configuration files must be a series of
S<I<key>C<:>I<value>> pairs (in the typical INI format).
The keys can be any valid named argument that can be
passed to a C<use Data::Show> import, except C<'base'>.
As in many other INI config files, you can use C<=> instead of C<:>
if you prefer, and any line that starts with a C<#> is ignored as a comment.

So, for example, you could change the global default plugin (for example, from
C<Data::Pretty> to C<Data::Printer>), and change the default output destination
(from STDERR to the file F<datashow.log> in the current directory), and change
the default styling of output (to something slightly more subtle because you
have an ANSI-256 colour terminal), by creating a F<~/.datashow> file containing
the following lines:

    # Change default dumper...
    with: Data::Printer

    # Change default output target...
    to: ./datashow.log

    # Change the styling...
    showstyle: bold italic ansi75
    codestyle:      italic ansi246
    filestyle: bold italic ansi27
    linestyle: bold italic ansi27
    gridstyle:             ansi27
    datastyle: bold        white

See the file F<sample.datashow> in the module's distribution for a full example
of a potential F<.datashow> configuration file, in which all the configuration
values happen to be the default values for those options (i.e. installing
F<sample.datashow> as your F<.datashow> should have no effect on the module,
if you're loading it without named arguments).

=head1 DEPENDENCIES

This module only works under Perl 5.10 and later.

The module requires the PPR module.

It will also require any non-core module that is itself required
by a plugin you select.

However, the requested non-core module is not actually I<required>;
if it cannot be loaded, the plugin request will be ignored and
L<a fallback|"Fallbacks"> will be used instead.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

The module uses a complex PPR-based regex to parse out the call context from the source.
Hence it is subject to the usual limitations of this approach
(namely, that it may very occasionally get the argument list wrong).

Also, because the module uses the PPR module, it will not work under Perl v5.20
(due to bugs in the regex engine under that version of Perl).

No other bugs have been reported.

Please report any bugs or feature requests to
C<bug-data-show@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010-2024, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
