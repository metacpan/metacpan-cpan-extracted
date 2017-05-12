package Config::Properties::Commons;

#######################
# LOAD MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

use 5.008_001;
use Encode qw();
use File::Spec qw();
use Text::Wrap qw();
use Cwd qw(abs_path);
use List::Util qw(max);
use File::Basename qw(dirname);
use File::Slurp qw(read_file write_file);
use String::Util qw(no_space fullchomp hascontent trim);
use Params::Validate qw(validate_with validate_pos :types);

#######################
# VERSION
#######################
our $VERSION = '1.0.1';

#######################
# CONSTRUCTOR
#######################
sub new {
    my ( $class, @args ) = @_;

    # Bless object
    my $self = {
        _options      => {},
        _seen_files   => {},
        _current_file => {
            name => '',
            base => '',
        },
        _properties => {},
    };
    bless $self, $class;

    # Process Options
    my %options = %{ $self->_set_options(@args) };
    $self->{_options} = {%options};

    # Get default properties
    $self->{_properties} = $options{defaults};

    # Short-circuit _load_ if a filename is defined
    if ( defined $options{load_file} ) {
        $self->load( $options{load_file} );
    }

    # Return object
  return $self;
} ## end sub new

#######################
# PUBLIC METHODS
#######################

# =====================
# LOAD
# =====================
sub load {
    my ( $self, $from, @args ) = @_;
    croak "File name/handle to load from is not provided"
      unless defined $from;

    # Process Options
    my %options = %{ $self->_set_options(@args) };

    unless ( ref $from ) {

        # Not a reference. _should_ be a file

        my $file = $from;

        # Check file
        $file = abs_path($file);
        croak "File $file does not exist!" unless ( $file and -f $file );

        # Set current file
        $self->{_current_file}->{name} = $file;
        $self->{_current_file}->{base} = dirname($file);

        # Process file?
      return 1
          if ( $options{cache_files} and $self->{_seen_files}->{$file} );

        # Mark as seen
        $self->{_seen_files}->{$file} = 1;
    } ## end unless ( ref $from )

    # Read file
    my @lines = read_file(
        $from,
        binmode => ':utf8',
        chomp   => 1,
    );

    # Load properties
    $self->_load(
        {
            lines   => \@lines,
            options => \%options,
        }
    );

  return 1;
} ## end sub load

# =====================
# GET/SET PROPERTY
# =====================
sub get_property {
    my ( $self, $key ) = @_;
  return unless exists $self->{_properties}->{$key};
  return $self->{_properties}->{$key};
} ## end sub get_property


sub require_property {
    my ( $self, $key ) = @_;
    croak "Property for $key is not set"
      unless exists $self->{_properties}->{$key};
  return $self->get_property($key);
} ## end sub require_property


sub add_property {
    my ( $self, @args )   = @_;
    my ( $key,  $values ) = validate_pos(
        @args, {
            type => SCALAR,
        }, {
            type => SCALAR | ARRAYREF,
        },
    );

    my @new_values;
    my $save      = undef;
    my $old_value = $self->get_property($key);
    @new_values = ref($values) ? @{$values} : ($values);

    if ( defined $old_value ) {
        $save
          = [ ( ref($old_value) ? @{$old_value} : $old_value ), @new_values ];
    } ## end if ( defined $old_value)
    else {
        if ( $self->{_options}->{force_value_arrayref} ) {
            $save = [@new_values];
        }
        else {
            if   ( scalar(@new_values) > 1 ) { $save = [@new_values]; }
            else                             { $save = $new_values[0]; }
        } ## end else [ if ( $self->{_options}...)]
    } ## end else [ if ( defined $old_value)]

  return unless defined $save;
    $self->{_properties}->{$key} = $save;
  return 1;
} ## end sub add_property

# =====================
# QUERY PROPERTIES
# =====================
sub properties {
    my ( $self, $prefix, $sep ) = @_;

    my %props;
    my %_props = %{ $self->{_properties} };

    if ( defined $prefix ) {
        $sep = '.' unless defined $sep;
        $prefix .= ${sep};
        foreach my $_prop ( grep { /^${prefix}/x } keys %_props ) {
            my $_p = $_prop;
            $_p =~ s{^${prefix}}{}gx;
            $props{$_p} = $_props{$_prop};
        } ## end foreach my $_prop ( grep { ...})
    } ## end if ( defined $prefix )
    else {
        %props = %_props;
    }

  return %props if wantarray;
  return {%props};
} ## end sub properties


sub property_names {
    my ( $self, $prefix ) = @_;
    my %props   = $self->properties();
    my $_sorter = $self->{_options}->{save_sorter};
    my @names   = sort $_sorter keys %props;
    if ( defined $prefix ) {
        @names = grep { /^${prefix}/x } @names;
    }
  return @names;
} ## end sub property_names


sub is_empty {
    my ($self) = @_;
    my @keys = $self->property_names();
  return if scalar(@keys);
  return 1;
} ## end sub is_empty


sub has_property {
    my ( $self, @args ) = @_;
    my $val = $self->get_property(@args);
  return 1 if defined $val;
  return;
} ## end sub has_property

# =====================
# CLEAR/DELETE PROPERTY
# =====================
sub delete_property {
    my ( $self, $key ) = @_;
  return unless ( defined $key and hascontent($key) );

  return 1 unless exists $self->{_properties}->{$key};
    delete $self->{_properties}->{$key};
  return 1;
} ## end sub delete_property


sub clear_properties {
    my ($self) = @_;
    $self->{_properties} = {};
    $self->{_seen_files} = {};
  return 1;
} ## end sub clear_properties


sub reset_property {
    my ( $self, @args ) = @_;
    $self->delete_property(@args) or return;
    $self->add_property(@args)    or return;
  return 1;
} ## end sub reset_property

# =====================
# SAVE PROPERTIES
# =====================
sub save_to_string {
    my ( $self, @args ) = @_;

    # Process Options
    my %options = %{ $self->_set_options(@args) };

    # Get string to save
    my $save_string = $self->_save(
        {
            options => \%options,
        }
    );

  return $save_string;
} ## end sub save_to_string


sub save {
    my ( $self, $to, @args ) = @_;
  return unless defined $to;

    # Get a string dump
    my $str = $self->save_to_string(@args);

    # Write to file/handle
    write_file(
        $to, {
            binmode => ':utf8',
        },
        Encode::encode_utf8($str)
    );

    # Done
  return 1;
} ## end sub save

# =====================
# FILES PROCESSED
# =====================
sub get_files_loaded {
    my ($self) = @_;
    my @files = sort { lc $a cmp lc $b } keys %{ $self->{_seen_files} };
  return @files;
} ## end sub get_files_loaded

#######################
# METHOD ALIASES
#######################

## no critic (ArgUnpacking)

sub load_fh         { return shift->load(@_); }
sub load_file       { return shift->load(@_); }
sub store           { return shift->save(@_); }
sub save_as_string  { return shift->save_to_string(@_); }
sub saveToString    { return shift->save_to_string(@_); }
sub getProperty     { return shift->get_property(@_); }
sub addProperty     { return shift->add_property(@_); }
sub requireProperty { return shift->require_property(@_); }
sub set_property    { return shift->reset_property(@_); }
sub setProperty     { return shift->reset_property(@_); }
sub changeProperty  { return shift->reset_property(@_); }
sub clear           { return shift->clear_properties(@_); }
sub clearProperty   { return shift->delete_property(@_); }
sub deleteProperty  { return shift->delete_property(@_); }
sub containsKey     { return shift->has_property(@_); }
sub getProperties   { return shift->properties(@_); }
sub subset          { return shift->properties(@_); }
sub getKeys         { return shift->property_names(@_); }
sub propertyNames   { return shift->property_names(@_); }
sub getFileNames    { return shift->get_files_loaded(@_); }
sub isEmpty         { return shift->is_empty(@_); }

## use critic

#######################
# INTERNAL METHODS
#######################

# =====================
# Process options
# =====================
sub _set_options {
    my ( $self, @args ) = @_;

    # Read Options
    my $in_options = {};
    if (@args) {
        if ( ref $args[0] eq 'HASH' ) {
            $in_options = $args[0];
        }
        else {
            $in_options = {@args};
        }
    } ## end if (@args)

    # ---------------------
    # PARAM SPEC
    # ---------------------

    # Load spec
    my %pv_load_spec = (

        # List delimiter - this identifies multi-token values
        token_delimiter => {
            optional => 1,
            type     => SCALAR | UNDEF,
            default  => ',',
        },

        # Include keyword
        include_keyword => {
            optional => 1,
            type     => SCALAR,
            regex    => qr{^[^\s]+$}x,
            default  => 'include',
        },

        # Include basedir
        includes_basepath => {
            optional => 1,
            type     => SCALAR | UNDEF,
            default  => undef,
        },

        # Process Includes?
        process_includes => {
            optional => 1,
            type     => SCALAR,
            regex    => qr{^[01]$}x,
            default  => 1,
        },

        # Allow recursive includes?
        cache_files => {
            optional => 1,
            type     => SCALAR,
            regex    => qr{^[01]$}x,
            default  => 1,
        },

        # Process property interpolation?
        interpolation => {
            optional => 1,
            type     => SCALAR,
            regex    => qr{^[01]$}x,
            default  => 1,
        },

        # Force values to be array-refs
        force_value_arrayref => {
            optional => 1,
            type     => SCALAR,
            regex    => qr{^[01]$}x,
            default  => 0,
        },

        # Allow callback
        callback => {
            optinal => 1,
            type    => CODEREF,
            default => sub { return @_; },
        },

        # Allow defaults
        defaults => {
            optional => 1,
            type     => HASHREF,
            default  => {},
        },

        # Allow filename for auto-load
        load_file => {
            optional => 1,
            type     => SCALAR | HANDLE | UNDEF,
            default  => undef,
        },
    );

    # Save Spec
    my %pv_save_spec = (

        # Save properties with multiple value tokens on a single line
        save_combine_tokens => {
            optional => 1,
            type     => SCALAR,
            regex    => qr{^[01]$}x,
            default  => 0,
        },

        # Wrap and save
        save_wrapped => {
            optional => 1,
            type     => SCALAR,
            regex    => qr{^[01]$}x,
            default  => 1,
        },

        # Wrap length
        save_wrapped_len => {
            optional => 1,
            type     => SCALAR,
            regex    => qr{^\d+$}x,
            default  => 76,
        },

        # key=value separator
        save_separator => {
            optional => 1,
            type     => SCALAR,
            regex    => qr{^\s*[=:\s]\s*$}x,
            default  => ' = ',
        },

        # Save sorting routine
        save_sorter => {
            optional => 1,
            type     => CODEREF,
            default  => sub ($$) { lc( $_[0] ) cmp lc( $_[1] ); },
        },

        # Save Header
        save_header => {
            optional => 1,
            type     => SCALAR,
            default  => '#' x 15,
        },

        # Save footer
        save_footer => {
            optional => 1,
            type     => SCALAR,
            default  => '#' x 15,
        },
    );

    # Option aliases
    my %option_aliases = (

        # __PACKAGE__
        delimiter      => 'token_delimiter',
        include        => 'include_keyword',
        basepath       => 'includes_basepath',
        includes_allow => 'process_includes',
        cache          => 'cache_files',
        interpolate    => 'interpolation',
        force_arrayref => 'force_value_arrayref',
        validate       => 'callback',
        filename       => 'load_file',
        single_line    => 'save_combine_tokens',
        wrap           => 'save_wrapped',
        columns        => 'save_wrapped_len',
        separator      => 'save_separator',
        header         => 'save_header',
        footer         => 'save_footer',

        # Java Style
        setListDelimiter   => 'token_delimiter',
        setInclude         => 'include_keyword',
        setIncludesAllowed => 'process_includes',
        setBasePath        => 'includes_basepath',
    );

    # Normalizer
    #   Allow leading '-' and make case-insensitive
    my $pv_key_normalizer = sub {
        my ($_key) = @_;
        $_key = no_space($_key);
        $_key =~ s{^\-+}{}x;
        $_key = lc($_key);
      return $_key;
    };

    # ---------------------

    # Merge Options
    my $merged_options = $self->{_options};
    foreach my $_opt ( keys %{$in_options} ) {

        # Normalize
        $_opt = $pv_key_normalizer->($_opt);

        # Resolve Aliases
        if ( exists $option_aliases{$_opt} ) {
            $merged_options->{ $option_aliases{$_opt} }
              = $in_options->{$_opt};
        } ## end if ( exists $option_aliases...)
        else {
            $merged_options->{$_opt} = $in_options->{$_opt};
        }
    } ## end foreach my $_opt ( keys %{$in_options...})

    my %valid_options = validate_with(

        # Name used in validation errors
        called => __PACKAGE__ . '::_set_options',

        # Options to process
        params => [$merged_options],

        # Normalize key names.
        normalize_keys => $pv_key_normalizer,

        # Do not Allow extra options
        allow_extra => 0,

        # Option Spec
        spec => { %pv_load_spec, %pv_save_spec, },

    );

  return {%valid_options};
} ## end sub _set_options

# =====================
# Load Properties
# =====================
sub _load {
    my ( $self, $in ) = @_;
    my @lines   = $in->{lines}   ? @{ $in->{lines} }   : ();
    my %options = $in->{options} ? %{ $in->{options} } : ();

    # Check for empty file
  return 1 unless @lines;

    # Check and remote byte order mark
    if ( $lines[0] =~ m{^\x{FEFF}}x ) { shift @lines; }

    # Process lines
    while (@lines) {

        # Get line
        my $line = shift @lines;

        # Remove EOL
        $line = fullchomp($line);

        # Skip Blank
      next unless hascontent($line);

        # Skip Comments
      next if ( $line =~ m{^\s*(?:\#|\!)}x );

        # Trim leading whitespace
        $line = trim(
            $line,
            right => 0,
        );

        # Check for wrapped lines
        if ( $line =~ m{(?<!\\)\\\s*$}x ) {

            # This is a wrapped line. Unwrap
            push( my @wrapped_lines, $line );
            while (@lines) {
                my $_wline = shift @lines;
                $_wline = fullchomp($_wline);
              next unless hascontent($_wline);

                push @wrapped_lines, $_wline;
              last unless ( $_wline =~ m{(?<!\\)\\\s*$}x );
            } ## end while (@lines)

            # Join them
            my @unwrapped;
            foreach my $_wline (@wrapped_lines) {

                # Remove Trailing '\'
                $_wline =~ s{\\\s*$}{}x;

                # Remove leading whitespace
                $_wline = trim(
                    $_wline,
                    right => 0,
                );

                # Save
                push @unwrapped, $_wline;
            } ## end foreach my $_wline (@wrapped_lines)

            $line = join( '', @unwrapped );
        } ## end if ( $line =~ m{(?<!\\)\\\s*$}x)

        # Split key/value
        my ( $key, $value ) = split( _sep_regex(), $line, 2 );

        # Verify key/value
        #   Key is required. Value can be empty
        if ( not( defined $key and hascontent($key) ) ) {
            croak "Invalid key/value format! : $line \n";
        }
        $value = '' unless ( defined $value and hascontent($value) );

        # Unescape
        $key   = _unesc_key($key);
        $value = _unesc_val($value);

        # Perform callback
        ( $key, $value ) = $options{callback}->( $key, $value );
      next
          unless ( ( defined $key and defined $value ) and hascontent($key) );

        # Process tokens
        my @tokens;
        if ( hascontent($value) ) {
            if ( defined $options{token_delimiter} ) {
                my $_delim = $options{token_delimiter};
                foreach my $_token ( _split_tokens( $value, $_delim ) ) {
                    push( @tokens, _unesc_delim( $_token, $_delim ) );
                }
            } ## end if ( defined $options{...})
            else {
                push( @tokens, $value );
            }
        } ## end if ( hascontent($value...))
        else {
            push( @tokens, $value );
        }

        # Interpolate tokens
        my @interpolated_tokens;
        if ( $options{interpolation} ) {
            foreach my $token (@tokens) {
                $token
                  =~ s/(?<!\\)\$\{([^}]+)\}/ $self->_interpolate({key => $1, options => \%options,}) /gex;
                push( @interpolated_tokens, $token );
            } ## end foreach my $token (@tokens)
        } ## end if ( $options{interpolation...})
        else {
            push( @interpolated_tokens, @tokens );
        }

        # Process includes
        if ( $options{process_includes}
            and ( $key eq $options{include_keyword} ) )
        {

            my $_basedir = $self->{_current_file}->{base};
            $_basedir = File::Spec->curdir() if not $_basedir;
            $_basedir = $options{includes_basepath}
              if defined $options{includes_basepath};

            foreach my $_file (@interpolated_tokens) {

                # Determine if filename is absolute or relative
                if ( File::Spec->file_name_is_absolute($_file) ) {
                    $_file = abs_path($_file);
                }
                else {
                    $_file
                      = abs_path( File::Spec->catfile( $_basedir, $_file ) );
                } ## end else [ if ( File::Spec->file_name_is_absolute...)]

                # Check if this is the current file being processed
                if ( $_file eq $self->{_current_file}->{name} ) {

                    # Skip it. Otherwise this is an infinite loop
                  next;
                } ## end if ( $_file eq $self->...)

                # Load file
                my %tmp_cf = %{ $self->{_current_file} };
                $self->load_file( $_file, \%options );
                $self->{_current_file} = {%tmp_cf};
            } ## end foreach my $_file (@interpolated_tokens)

            # Move onto next line
            # i.e., do not save an 'include'
          next;
        } ## end if ( $options{process_includes...})

        # Save key/value
        my $tmp_fvaf = $self->{_options}->{force_value_arrayref};
        $self->{_options}->{force_value_arrayref}
          = $options{force_value_arrayref};
        $self->add_property( $key, [@interpolated_tokens] );
        $self->{_options}->{force_value_arrayref} = $tmp_fvaf;
    } ## end while (@lines)

  return 1;
} ## end sub _load

# =====================
# Interpolate tokens
# =====================
sub _interpolate {
    my ( $self, $in ) = @_;
    my $key     = $in->{key};
    my %options = %{ $in->{options} };

    # Defaults to original
    my $int_key = '${' . $key . '}';

    # Return if key is not set
    if ( not exists $self->{_properties}->{$key} ) {
      return $int_key;
    }

    # Get defined key
    my $def_key = $self->{_properties}->{$key};

    # Check if defined key is a refernce
    if ( ref $def_key ) {

        # Return if defined key has multiple values
      return $int_key if ( scalar( @{$def_key} ) > 1 );

        # Do interpolation if we are forcing array refs
        if ( $options{force_value_arrayref} ) {
            $int_key = $def_key->[0];
        }
    } ## end if ( ref $def_key )
    else {
        $int_key = $def_key;
    }

    # Return empty if undef
  return '' unless defined $int_key;
  return $int_key;
} ## end sub _interpolate

# =====================
# Save Properties
# =====================
sub _save {
    my ( $self, $in ) = @_;
    my %options = %{ $in->{options} };

    # Output String
    my $out_str;

    # Get flattened hash
    my %props = $self->properties();

    # Write Header
    $out_str = fullchomp( $options{save_header} ) . "\n\n";

    # Get max property length
    my $max_prop_len = max map { length $_ } ( keys %props );

    # Get key/value separator
    my $out_sep = $options{save_separator};

    # Get separator length
    my $sep_len = length( $options{save_separator} );

    # Do wrap?
    my $do_wrap = $options{save_wrapped};
    $do_wrap = 0
      if ( ( $max_prop_len + $sep_len + 4 ) >= $options{save_wrapped_len} );

    # Cycle thru' properties
    my $_sorter = $options{save_sorter};
    foreach my $key ( sort $_sorter keys %props ) {
      next unless defined $props{$key};
        my $value = $props{$key};
        $value = '' if not defined $value;

        # Split value into tokens
        my @raw_value_tokens;
        if ( ref($value) ) {
            croak "${key}'s value is an invalid reference!"
              unless ( ref($value) eq 'ARRAY' );
            @raw_value_tokens = @{$value};
        } ## end if ( ref($value) )
        else {
            @raw_value_tokens = ($value);
        }

        # Escape
        $key = _esc_key($key);
        my @value_tokens;
        foreach my $_rvt (@raw_value_tokens) {
            $_rvt = '' unless defined $_rvt;
            if ( defined $options{token_delimiter} ) {
                push @value_tokens,
                  _esc_delim( _esc_val( Encode::encode_utf8($_rvt) ),
                    $options{token_delimiter} );
            } ## end if ( defined $options{...})
            else {
                push @value_tokens, _esc_val( Encode::encode_utf8($_rvt) );
            }
        } ## end foreach my $_rvt (@raw_value_tokens)

        # Save
        if ( $options{save_combine_tokens} ) {
            croak "Cannot combine tokens without a delimiter!"
              unless defined $options{token_delimiter};

            # Get delimiter
            # Append a whitespace to it for read-ability
            my $_delim = $options{token_delimiter};
            $_delim .= ' ' unless ( $_delim =~ m{\s+$}x );

            # Join
            my $_val_str = join( $_delim, @value_tokens );

            # Wrap
            if ($do_wrap) {
                $_val_str = _wrap(
                    {
                        string  => $_val_str,
                        options => {
                            %options,
                            key_len => length($key) + $sep_len,
                        },
                    }
                );
            } ## end if ($do_wrap)

            # Write
            $out_str .= sprintf( "%s${out_sep}%s\n", $key, $_val_str );
        } ## end if ( $options{save_combine_tokens...})
        else {

            # Add surrounding blank lines for read-ability
            if ( scalar(@value_tokens) > 1 ) {
                $out_str .= "\n" unless ( $out_str =~ m{\n{2,}}mx );
            }

            foreach my $token (@value_tokens) {
                my $_val_str;

                # Wrap
                if ($do_wrap) {
                    $_val_str = _wrap(
                        {
                            string  => $token,
                            options => {
                                %options,
                                key_len => length($key) + $sep_len,
                            },
                        }
                    );
                } ## end if ($do_wrap)
                else { $_val_str = $token; }

                # Write
                $out_str .= sprintf( "%s${out_sep}%s\n", $key, $_val_str );
            } ## end foreach my $token (@value_tokens)

            # Add surrounding blank lines for read-ability
            if ( scalar(@value_tokens) > 1 ) { $out_str .= "\n"; }
        } ## end else [ if ( $options{save_combine_tokens...})]
    } ## end foreach my $key ( sort $_sorter...)

    # Write footer
    $out_str .= "\n" . fullchomp( $options{save_footer} ) . "\n\n";

    # Done
  return $out_str;
} ## end sub _save

#######################
# INTERNAL UTILS
#######################

# =====================
# Seperator regex
# =====================
sub _sep_regex {

    # Split key-value that is seperated by:
    #   1. '='
    #   2. ':'
    #   3. Whitespace
    # Where neither of them are backslash escaped
    # Also, any surrounding whitespace is ignored
  return qr{\s*(?: (?: (?<!\\) [\=\:\s] ) )\s*}x;
} ## end sub _sep_regex

# =====================
# Escape Routines
# =====================
sub _esc_key {
    my ($key) = @_;

    # Escape unprintable
    $key =~ s{([^\x20-\x7e])}{sprintf ("\\u%04x", ord $1)}gex;

    # Escape leading '#'
    $key =~ s{^\#}{'\#'}gex;

    # Escape leading '!'
    $key =~ s{^\!}{'\!'}gex;

    # Escape whitespace
    $key =~ s{\s}{'\ '}gex;

  return $key;
} ## end sub _esc_key


sub _esc_val {
    my ($val) = @_;

    # Escape unprintable
    $val =~ s{([^\x20-\x7e])}{sprintf ("\\u%04x", ord $1)}gex;

  return $val;
} ## end sub _esc_val


sub _esc_delim {
    my ( $val, $delim ) = @_;
  return $val if not defined $delim;
  return $val if not hascontent($delim);
  return $val if not hascontent($val);
  return join( "\\$delim ", _split_tokens( $val, $delim ) );
} ## end sub _esc_delim

# =====================
# Unescape Routines
# =====================
sub _unesc_key {
    my ($key) = @_;

    # Un-escape unprintable
    $key =~ s{\\u([\da-fA-F]{4})}{chr(hex($1))}gex;

    # Un-escape leading '#'
    $key =~ s{^\\\#}{'#'}gex;

    # Un-escape leading '!'
    $key =~ s{^\\!}{'!'}gex;

    # Un-escape whitespace
    $key =~ s{(?<!\\)\\\s}{' '}gex;

  return $key;
} ## end sub _unesc_key


sub _unesc_val {
    my ($val) = @_;

    # Un-escape unprintable
    $val =~ s{\\u([\da-fA-F]{4})}{chr(hex($1))}gex;

  return $val;
} ## end sub _unesc_val


sub _unesc_delim {
    my ( $val, $delim ) = @_;
    $val =~ s{ \\ $delim }{$delim}gxi;
  return $val;
} ## end sub _unesc_delim

# =====================
# VALUE WRAPPER
# =====================
sub _wrap {
    my ($in)    = @_;
    my $text    = $in->{string};
    my %options = %{ $in->{options} };

    # Wrap column width
    my $wrap_to = $options{save_wrapped_len} - $options{key_len};

    ## no critic (PackageVars)

    # Text::Wrap settings
    local $Text::Wrap::columns   = $wrap_to;      # Columns
    local $Text::Wrap::break     = qr{(?<!\\)}x;  # Break at NOT '\'
    local $Text::Wrap::unexpand  = 0;             # Don't mess with tabs
    local $Text::Wrap::separator = "\\\n";        # Use a '\' separator
    local $Text::Wrap::huge = 'overflow';  # Leave unbreakable lines alone

    ## use critic

    # Wrap
    my $wrapped = Text::Wrap::wrap(
        '',  # Initial tab is empty
        ' ' x ( $options{key_len} + 1 ), # Subseq tab is aligned to end of key
        $text,                           # Text to wrap
    );

    # Remove EOL
    $wrapped = fullchomp($wrapped);

    # Return
  return $wrapped;
} ## end sub _wrap

# =====================
# TOKEN SPLITTER
# =====================
sub _split_tokens {
    my ( $val, $delim ) = @_;
  return split( qr/(?<!\\) $delim \s*/x, $val );
} ## end sub _split_tokens

#######################
1;

__END__

#######################
# POD SECTION
#######################
=pod

=head1 NAME

Config::Properties::Commons - Read and write Apache Commons
Configuration style Properties

=head1 SYNOPSIS

    use Config::Properties::Commons;

    # Read
    # =====

    # Init
    my $cpc = Config::Properties::Commons->new();

    # Load
    $cpc->load('conf.properties');

    # Access
    my $value = $cpc->get_property('key');

    # Flattened hash
    my %properties = $cpc->properties();

    # Write
    # =====

    # Init
    my $cpc = Config::Properties::Commons->new();

    # Set
    $cpc->set_property( key => 'value' );

    # Save
    $cpc->save('conf.properties');


=head1 DESCRIPTION

C<< Config::Properties::Commons >> is an attempt to provide a Perl API
to read and write L<< Apache Commons
Configuration|http://commons.apache.org/configuration/ >> style C<<
.properties >> files.

This module is an extension of L<< Config::Properties >> and provides a
similar API, but is not fully backwards compatible.

=head1 PROPERITES FILE SYNTAX

A sample file syntax recognized by this module is shown below.

    # This line is a comment
    ! This is a comment as well

    # Key value pairs can be separated by '=', ':' or whitespace
    key1 = value1
    key2 : value2
    key3   value3

    # Keys can contain multiple values that are either
    #   1. Specified on multiple lines
    #   2. OR delimiter(',') separated
    key1 = value1.1
    key1 = value1.2
    key2 = value2.1, value2.2

    # Long values can span multiple lines by including a
    # '\' escape at the end of a line
    key = this is a \
            multi-line value

    # Property files can _include_ other files as well
    include = file1, file2, ....

    # Values can reference previous parsed properties
    base   = /etc/myapp
    config = ${base}/config

The complete syntax reference can be found at the L<<
PropertiesConfiguration API
Doc|http://commons.apache.org/configuration/apidocs/org/apache/commons/configuration/PropertiesConfiguration.html
>>.

=head1 METHODS

=head2 C<< new(%options) >>

    my $cpc = Config::Properties::Commons->new(\%options);

This creates and returns a C<< Config::Properties::Commons >> object.

=head2 Options

The following options can be provided to the constructor.

=over

=item token_delimiter

This option specifies the delimiter used to split a value into multiple
tokens. The default is a C<< ',' >>. You can set this to C<< undef >>
to disable splitting.

=item include_keyword

Use this option to set the keyword that identifies additional files to
load. The default is I<< include >>.

=item includes_basepath

Use this option to set the base path for files being loaded via an I<<
include >>. By default, files are expected to be in the same directory
as the parent file being loaded. If we are loading from a file handle,
then additional files are expected to be in the current directory.

=item process_includes

Use this option to toggle whether additional files are loaded via I<<
include >> or not. Defaults to true.

=item cache_files

Use this option to toggle file caching. If enabled, then files are
loaded only once. Disabling this is not recommended as it might lead to
circular references. Default is enabled.

=item interpolation

Use this option to toggle property references/interpolation. Defaults
to true.

=item force_value_arrayref

When set to true, all values are stored as an array-ref. Otherwise,
single values are stored as a scalar and multiple values are stored as
an array-ref. Default is false.

=item callback

This should be a code reference, which is called when a key/value pair
is parsed. The callback is called with 2 arguments for C<< $key >> and
C<< $value >> respectively, and expects the same to be returned as a
list.

This allows you to hook into the parsing process to normalize or
perform additional operations when a key/value is parsed.

    # Example to read case-insensitve properties
    my $cpc = Config::Properties::Commons->new({
        callback => sub {
            my ($_k, $_v) = @_;
            $_k = lc($_k);
            return ( $_k, $_v );
        },
    });

=item defaults

You can provide a default set of properties as a hash-ref to the
object.

=item load_file

Requires a filename. This is a short-circuit for C<< new();
load($file); >>. When used with the constructor, the file is loaded
before returning.

=item save_combine_tokens

When true, keys with multiple values are joined using the I<<
token_delimiter >> and written to a single line. Otherwise they are
saved/written on multiple lines. Defaults to false.

=item save_wrapped

When true, long values are wrapped before being saved. Defaults to
true.

=item save_wrapped_len

Use this option to set the maximum line length when wrapping long
values. This option is ignored if wrapping is disabled. Defaults to 76.

=item save_separator

Use this option to set the key/value separator to be used when saving.
Defaults to C<< ' = ' >>.

=item save_sorter

This option should provide a sort SUBNAME as specified by L<<
sort|http://perldoc.perl.org/functions/sort.html >>.

This is used for sorting property names to decide the order in which
they are saved. Defaults to a case-insensitive alphabetical sort.

=item save_header

You can use this to specify a header used when saving.

=item save_footer

You can use this to specify a footer used when saving.

=item Option Aliases

The following aliases can be used for the options specified above. This
is mainly available for API compatibility and ease of use.

    # Option Name           Aliases
    # ------------          ----------------------------------
    token_delimiter         delimiter       setListDelimiter
    include_keyword         include         setInclude
    includes_basepath       basepath        setBasePath
    process_includes        includes_allow  setIncludesAllowed
    cache_files             cache
    interpolation           interpolate
    force_value_arrayref    force_arrayref
    callback                validate
    load_file               filename
    save_combine_tokens     single_line
    save_wrapped            wrap
    save_wrapped_len        columns
    save_separator          separator
    save_header             header
    save_footer             footer

=back

=head2 Reading and Writing Files

=head3 C<< load($file, \%options) >>

    $cpc->load($file); # Parse and Load properties from a file
    $cpc->load($fh);   # Parse and Load properties from a file handle

This method reads, parses and loads the properties from a file-name or
a file-handle. The file is read through a C<< ':utf8' >> layer. An
exception is thrown in case of parse failures.

C<< load() >> is an I<< additive >> operation. i.e, you can load
multiple files and any previously loaded properties are either updated
or preserved.

    $cpc->load('file1');
    $cpc->load('file2');

Any options provided to the constructor can be set/overridden here as
well.

This method can also be called using the C<< load_fh() >> or C<<
load_file() >> aliases.

=head3 C<< save($file, \%options) >>

    $cpc->save($file); # Saves properties to a file
    $cpc->save($fh);   # Saves properties to a file-handle

This method saves all properties set to a provided file or file-handle
via a C<< ':utf8' >> layer. Existing files are overwritten. Original
file format or the order of properties set is not preserved.

Any options provided to the constructor can be set/overridden here as
well.

This method can also be called using the C<< store() >> alias.

=head3 C<< save_to_string(\%options) >>

    my $text = $cpc->save_to_string();

This is identical to C<< save() >>, but returns a single string with
the content.

Any options provided to the constructor can be set/overridden here as
well.

This method can also be called using the C<< save_as_string() >> or C<<
saveToString() >> aliases.

=head3 C<< get_files_loaded() >>

    my @file_list = $cpc->get_files_loaded();

This method returns a list of files loaded by the object. This, of
course, is available only when properties were loaded via file-names
and not handles. This also includes any I<< include-ded >> files.

This method can also be called using the C<< getFileNames() >> alias.

=head2 Get Properties

=head3 C<< get_property($key) >>

    my $value = $cpc->get_property($key);

This method returns the value for C<< $key >> or undef if a property
for C<< $key >> is not set.

This method can also be called using the C<< getProperty() >> alias.

=head3 C<< require_property($key) >>

This method is similar to C<< get_property() >>, but throws an
exception if a property for C<< $key >> is not set.

This method can also be called using the C<< requireProperty() >>
alias.

=head3 C<< properties($prefix, $separator) >>

    my %properties = $cpc->properties();

This method returns a flattened hashref (or hash in list context) of
the properties set in the object.

If a C<< $prefix >> is specified, only properties that begin with C<<
$prefix >> is returned with the C<< $prefix >> removed. For e.g.,

    # Properties
    env.key1 = value1
    env.key2 = value2

    # Get all 'env' properties
    my %env_props = $cpc->properties('env');

    # Now %env_props looks like -
    %env_props = (
        key1 => 'value1',
        key2 => 'value2',
    );

The default seaparator C<< '.' >> can be overridden using the second
argument.

This method can also be called using the C<< getProperties() >> or C<<
subset() >> aliases.

=head3 C<< property_names() >>

    my @names = $cpc->propery_names();

This method returns a list of property names set in the object.

This method can also be called using the C<< propertyNames() >> or C<<
getKeys() >> aliases.

=head3 C<< is_empty() >>

    say "No properties set" if $cpc->is_empty();

This method returns true if there are no properties set. False
otherwise.

This method can also be called using the C<< isEmpty() >> alias.

=head3 C<< has_property($key) >>

    say "foo is set" if $cpc->has_property('foo');

This method returns true if a property for C<< $key >> is set. False
otherwise.

This method can also be called using the C<< containsKey() >> alias.

=head2 Set Properties

=head3 C<< add_propertry( key => 'value' ) >>

    $cpc->add_property( key  => 'value1' );
    $cpc->add_property( key  => 'value2' );
    $cpc->add_property( key2 => [ 'value1', 'value2' ] );

This method sets a new property or adds values to existing properties.
Old properties are not forgotten.

Values can be a scalar or an array-ref for multiple values.

This method can also be called using the C<< addProperty() >> alias.

=head3 C<< delete_property($key) >>

    $cpc->delete_property('foo');

This method deletes a property specified by C<< $key >> from the
object.

This method can also be called using the C<< clearProperty() >> or C<<
deleteProperty() >> aliases.

=head3 C<< reset_property( key => 'value' ) >>

This method is equivalent to C<< delete_property('key');
add_property(key => 'value' ); >> - which means any previously set
property is forgotten.

This method can also be called using the C<< set_property() >>, C<<
setProperty() >>, or C<< changeProperty() >> aliases.

=head3 C<< clear_properties() >>

    $cpc->clear_properties();

This method deletes all properties loaded.

This method can also be called using the C<< clear() >> alias.

=head1 SEE ALSO

=over

=item L<< Config::Properties >>

=item L<< PropertiesConfiguration JavaDoc|http://commons.apache.org/configuration/apidocs/org/apache/commons/configuration/PropertiesConfiguration.html >>

=back

=head1 DEPENDENCIES

=over

=item perl-5.8.1

=item L<< Encode >>

=item L<< File::Basename >>

=item L<< File::Slurp >>

=item L<< File::Spec >>

=item L<< List::Util >>

=item L<< Params::Validate >>

=item L<< String::Util >>

=item L<< Text::Wrap >>

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<https://github.com/mithun/perl-config-properties-commons/issues>

=head1 TODO

Provide support for remembering property format and order when parsed

=head1 AUTHOR

Mithun Ayachit C<mithun@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014, Mithun Ayachit. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut
