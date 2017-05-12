package Config::ApacheFormat;
use 5.006001;
use strict;
use warnings;
our $VERSION = '1.2';

=head1 NAME

Config::ApacheFormat - use Apache format config files

=head1 SYNOPSIS

Config files used with this module are in Apache's format:

  # comment here
  RootDir /path/foo
  LogDir  /path/foo/log
  Colors red green orange blue \
         black teal

  <Directory /path/foo>
     # override Colors inside block
     Colors red blue black
  </Directory>
  
Code to use this config file might look like:

  use Config::ApacheFormat;

  # load a conf file
  my $config = Config::ApacheFormat->new();
  $config->read("my.conf");

  # access some parameters
  $root_dir = $config->get("RootDir");
  $log_dir  = $config->get("LogDir");
  @colors   = $config->get("colors");

  # using the autoloaded methods
  $config->autoload_support(1);
  $root_dir = $config->RootDir;
  $log_dir  = $config->logdir;

  # access parameters inside a block
  my $block = $config->block(Directory => "/path/foo");
  @colors = $block->get("colors");
  $root_dir = $block->get("root_dir");

=head1 DESCRIPTION

This module is designed to parse a configuration file in the same
syntax used by the Apache web server (see http://httpd.apache.org for
details).  This allows you to build applications which can be easily
managed by experienced Apache admins.  Also, by using this module,
you'll benefit from the support for nested blocks with built-in
parameter inheritance.  This can greatly reduce the amount or repeated
information in your configuration files.

A good reference to the Apache configuration file format can be found
here:

  http://httpd.apache.org/docs-2.0/configuring.html

To quote from that document, concerning directive syntax:

 Apache configuration files contain one directive per line. The
 back-slash "\" may be used as the last character on a line to
 indicate that the directive continues onto the next line. There must
 be no other characters or white space between the back-slash and the
 end of the line.

 Directives in the configuration files are case-insensitive, but
 arguments to directives are often case sensitive. Lines that begin
 with the hash character "#" are considered comments, and are
 ignored. Comments may not be included on a line after a configuration
 directive. Blank lines and white space occurring before a directive
 are ignored, so you may indent directives for clarity.

And block notation:

 Directives placed in the main configuration files apply to the entire
 server. If you wish to change the configuration for only a part of the
 server, you can scope your directives by placing them in <Directory>,
 <DirectoryMatch>, <Files>, <FilesMatch>, <Location>, and
 <LocationMatch> sections. These sections limit the application of the
 directives which they enclose to particular filesystem locations or
 URLs. They can also be nested, allowing for very fine grained
 configuration.

This module will parse actual Apache configuration files, but you will need to set some options to non-default values.  See L<"Parsing a Real Apache Config File">.

=head1 METHODS

=item $config = Config::ApacheFormat->new(opt => "value")

This method creates an object that can then be used to read configuration
files. It does not actually read any files; for that, use the C<read()>
method below. The object supports the following attributes, all of which
may be set through C<new()>:

=over 4

=item inheritance_support

Set this to 0 to turn off the inheritance feature. Block inheritance
means that variables declared outside a block are available from
inside the block unless overriden.  Defaults to 1.

=item include_support

When this is set to 1, the directive "Include" will be treated
specially by the parser.  It will cause the value to be treated as a
filename and that filename will be read in.  If you use "Include"
with a directory, every file in that directory will be included.
This matches Apache's behavior and allows users to break up 
configuration files into multiple, possibly shared, pieces.  
Defaults to 1.

=item autoload_support

Set this to 1 and all your directives will be available as object
methods.  So instead of:

  $config->get("foo");

You can write:

  $config->foo;

Defaults to 0.

=item case_sensitive

Set this to 1 to preserve the case of directive names.  Otherwise, all
names will be C<lc()>ed and matched case-insensitively.  Defaults to 0.

=item fix_booleans

If set to 1, then during parsing, the strings "Yes", "On", and "True"
will be converted to 1, and the strings "No", "Off", and "False" will
be converted to 0. This allows you to more easily use C<get()> in 
conditional statements.

For example:

  # httpd.conf
  UseCanonicalName  On

Then in Perl:

  $config = Config::ApacheFormat->new(fix_booleans => 1);
  $config->read("httpd.conf");

  if ($config->get("UseCanonicalName")) {
      # this will get executed if set to Yes/On/True
  }

This option defaults to 0.

=item expand_vars

If set, then you can use variable expansion in your config file by 
prefixing directives with a C<$>. Hopefully this seems logical to you:

  Website     http://my.own.dom
  JScript     $Website/js
  Images      $Website/images

Undefined variables in your config file will result in an error. To
use a literal C<$>, simply prefix it with a C<\> (backslash). Like
in Perl, you can use brackets to delimit the variables more precisely:

  Nickname    Rob
  Fullname    ${Nickname}ert

Since only scalars are supported, if you use a multi-value, you will
only get back the first one:

  Options     Plus Minus "About the Same"
  Values      $Options

In this examples, "Values" will become "Plus". This is seldom a limitation
since in most cases, variable subsitution is used like the first example
shows. This option defaults to 0.

=item setenv_vars

If this is set to 1, then the special C<SetEnv> directive will be set
values in the environment via C<%ENV>.  Also, the special C<UnSetEnv>
directive will delete environment variables.

For example:

  # $ENV{PATH} = "/usr/sbin:/usr/bin"
  SetEnv PATH "/usr/sbin:/usr/bin"

  # $ENV{MY_SPECIAL_VAR} = 10
  SetEnv MY_SPECIAL_VAR 10

  # delete $ENV{THIS}
  UnsetEnv THIS

This option defaults to 0.

=item valid_directives

If you provide an array of directive names then syntax errors will be
generated during parsing for invalid directives.  Otherwise, any
directive name will be accepted.  For exmaple, to only allow
directives called "Bar" and "Bif":

  $config = Config::ApacheFormat->new(
                      valid_directives => [qw(Bar Bif)],
                                     );

=item valid_blocks

If you provide an array of block names then syntax errors will be
generated during parsing for invalid blocks.  Otherwise, any block
name will be accepted.  For exmaple, to only allow "Directory" and
"Location" blocks in your config file:

  $config = Config::ApacheFormat->new(
                      valid_blocks => [qw(Directory Location)],
                                     );

=item include_directives

This directive controls the name of the include directive.  By default
it is C<< ['Include'] >>, but you can set it to any list of directive
names.

=item root_directive

This controls what the root directive is, if any.  If you set this to
the name of a directive it will be used as a base directory for
C<Include> processing.  This mimics the behavior of C<ServerRoot> in
real Apache config files, and as such you'll want to set it to
'ServerRoot' when parsing an Apache config.  The default is C<undef>.

=item hash_directives

This determines which directives (if any) should be parsed so that the
first value is actually a key into the remaining values. For example,
C<AddHandler> is such a directive.

  AddHandler cgi-script .cgi .sh
  AddHandler server-parsed .shtml

To parse this correctly, use:

  $config = Config::ApacheFormat->new(
                      hash_directives => [qw(AddHandler PerlSetVar)]
                                     );

Then, use the two-argument form of C<get()>:

  @values = $config->get(AddHandler => 'cgi-script');

This allows you to access each directive individually, which is needed
to correctly handle certain special-case Apache settings.

=item duplicate_directives

This option controls how duplicate directives are handled. By default,
if multiple directives of the same name are encountered, the last one
wins:

  Port 8080
  # ...
  Port 5053

In this case, the directive C<Port> would be set to the last value, C<5053>.
This is useful because it allows you to include other config files, which
you can then override:

  # default setup
  Include /my/app/defaults.conf

  # override port
  Port 5053

In addition to this default behavior, C<Config::ApacheFormat> also supports
the following modes:

  last     -  the value from the last one is kept (default)
  error    -  duplicate directives result in an error
  combine  -  combine values of duplicate directives together

These should be self-explanatory. If set to C<error>, any duplicates
will result in an error.  If set to C<last> (the default), the last
value wins. If set to C<combine>, then duplicate directives are
combined together, just like they had been specified on the same line.

=back

All of the above attributes are also available as accessor methods.  Thus,
this:

  $config = Config::ApacheFormat->new(inheritance_support => 0,
                                      include_support => 1);

Is equivalent to:

  $config = Config::ApacheFormat->new();
  $config->inheritance_support(0);
  $config->include_support(1);

=over 4

=cut

use File::Spec;
use Carp           qw(croak);
use Text::Balanced qw(extract_delimited extract_variable);
use Scalar::Util qw(weaken);

# this "placeholder" is used to handle escaped variables (\$)
# if it conflicts with a define in your config file somehow, simply
# override it with "$Config::ApacheFormat::PLACEHOLDER = 'whatever';"
our $PLACEHOLDER = "~PLaCE_h0LDeR_$$~";  

# declare generated methods
use Class::MethodMaker
  new_with_init => "new",
  new_hash_init => "hash_init",
  get_set => [ -noclear => qw/
                inheritance_support
                include_support
                autoload_support
                case_sensitive
                expand_vars
                setenv_vars
                valid_directives
                valid_blocks
                duplicate_directives
                hash_directives
                fix_booleans
                root_directive
                include_directives
                _parent
                _data
                _block_vals
             /];

# setup defaults
sub init {
    my $self = shift;
    my %args = (
                inheritance_support => 1,
                include_support     => 1,
                autoload_support    => 0,
                case_sensitive      => 0,
                expand_vars         => 0,
                setenv_vars         => 0,
                valid_directives    => undef,
                valid_blocks        => undef,
                duplicate_directives=> 'last',
                include_directives  => ['Include'],
                hash_directives     => undef,
                fix_booleans        => 0,
                root_directive      => undef,
                _data               => {},
                @_);

    # could probably use a few more of these...
    croak("Invalid duplicate_directives option '$self->{duplicate_directives}' - must be 'last', 'error', or 'combine'")
      unless $args{duplicate_directives} eq 'last' or 
             $args{duplicate_directives} eq 'error' or 
             $args{duplicate_directives} eq 'combine';

    return $self->hash_init(%args);
}

=item $config->read("my.conf");

=item $config->read(\*FILE);

Reads a configuration file into the config object.  You must pass
either the path of the file to be read or a reference to an open
filehandle.  If an error is encountered while reading the file, this
method will die().

Calling read() more than once will add the new configuration values
from another source, overwriting any conflicting values.  Call clear()
first if you want to read a new set from scratch.

=cut

# read the configuration file, optionally ending at block_name
sub read {
    my ($self, $file) = @_;

    my @fstack;

    # open the file if needed and setup file stack
    my $fh;
    if (ref $file) {
        @fstack = { fh       => $file,
                    filename => "",
                    line_num => 0 };                     
    } else {
        open($fh, "<", $file) or croak("Unable to open file '$file': $!");
        @fstack = { fh       => $fh,
                    filename => $file,
                    line_num => 0 };
    }
    
    return $self->_read(\@fstack);
}

# underlying _read, called recursively an block name for
# nested block objects
sub _read {
    my ($self, $fstack, $block_name) = @_;

    # pre-fetch for loop
    my $case_sensitive = $self->{case_sensitive};
    my $data           = $self->{_data};

    # pre-compute lookups for validation lists, if they exists
    my ($validate_blocks,     %valid_blocks, 
        $validate_directives, %valid_directives);
    if ($self->{valid_directives}) {
        %valid_directives = map { ($case_sensitive ? $_ : lc($_)), 1 } 
          @{$self->{valid_directives}};
        $validate_directives = 1;
    } 
    if ($self->{valid_blocks}) {
        %valid_blocks = map { ($case_sensitive ? $_ : lc($_)), 1 } 
          @{$self->{valid_blocks}};
        $validate_blocks = 1;
    }

    # pre-compute a regex to recognize the include directives
    my $re = '^(?:' . 
      join('|', @{$self->{include_directives}}) . ')$';
    my $include_re;
    if ($self->{case_sensitive}) {
        $include_re = qr/$re/;
    } else {
        $include_re = qr/$re/i;
    }

    # parse through the file, line by line
    my ($name, $values, $line, $orig);
    my ($fh, $filename) = 
      @{$fstack->[-1]}{qw(fh filename)};
    my $line_num = \$fstack->[-1]{line_num};

  LINE: 
    while(1) {
        # done with current file?
        if (eof $fh) {
            last LINE if @$fstack == 1;
            pop @$fstack;
            ($fh, $filename) = 
              @{$fstack->[-1]}{qw(fh filename)};
            $line_num = \$fstack->[-1]{line_num};
        }

        # accumulate a full line, dealing with line-continuation
        $line = "";
        do {
            no warnings 'uninitialized';    # blank warnings
            $_ = <$fh>;
            ${$line_num}++;
            s/^\s+//;            # strip leading space
            next LINE if /^#/;   # skip comments
            s/\s+$//;            # strip trailing space            
            $line .= $_;
        } while ($line =~ s/\\$// and not eof($fh));
        
        # skip blank lines
        next LINE unless length $line;

        # parse line
        if ($line =~ /^<\/(\w+)>$/) {
            # end block            
            $orig = $name = $1;
            $name = lc $name unless $case_sensitive; # lc($1) breaks on 5.6.1!

            croak("Error in config file $filename, line $$line_num: " .
                  "Unexpected end to block '$orig' found" .
                  (defined $block_name ? 
                   "\nI was waiting for </$block_name>\n" : ""))
              unless defined $block_name and $block_name eq $name;

            # this is our cue to return
            last LINE;

        } elsif ($line =~ /^<(\w+)\s*(.*)>$/) {
            # open block
            $orig = $name   = $1;
            $values = $2;
            $name   = lc $name unless $case_sensitive;

            croak("Error in config file $filename, line $$line_num: " .
                  "block '<$orig>' is not a valid block name")
              unless not $validate_blocks or
                     exists $valid_blocks{$name};
            
            my $val = [];
            $val = _parse_value_list($values) if $values;

            # create new object for block, inheriting options from
            # this object, with this object set as parent (using
            # weaken() to avoid creating a circular reference that
            # would leak memory)
            my $parent = $self;
            weaken($parent);
            my $block = ref($self)->new(
                  inheritance_support => $self->{inheritance_support},
                  include_support     => $self->{include_support},
                  autoload_support    => $self->{autoload_support},
                  case_sensitive      => $case_sensitive,
                  expand_vars         => $self->{expand_vars},
                  setenv_vars         => $self->{setenv_vars},
                  valid_directives    => $self->{valid_directives},
                  valid_blocks        => $self->{valid_blocks},
                  duplicate_directives=> $self->{duplicate_directives},
                  hash_directives     => $self->{hash_directives},
                  fix_booleans        => $self->{fix_booleans},
                  root_directive      => $self->{root_directive},
                  include_directives  => $self->{include_directives},
                  _parent             => $parent,
                  _block_vals         => ref $val ? $val : [ $val ],
                                       );
            
            # tell the block to read from $fh up to the closing tag
            # for this block
            $block->_read($fstack, $name);

            # store block for get() and block()
            push @{$data->{$name}}, $block;

        } elsif ($line =~ /^(\w+)(?:\s+(.+))?$/) {
            # directive
            $orig = $name = $1;
            $values = $2;
            $values = 1 unless defined $values;
            $name = lc $name unless $case_sensitive;

            croak("Error in config file $filename, line $$line_num: " .
                  "directive '$name' is not a valid directive name")
              unless not $validate_directives or
                     exists $valid_directives{$name};

            # parse out values, handling any strings or arrays
            my @val;
            eval {
                @val = _parse_value_list($values);
            };
            croak("Error in config file $filename, line $$line_num: $@")
                if $@;

            # expand_vars if set
            eval {
                @val = $self->_expand_vars(@val) if $self->{expand_vars};
            };
            croak("Error in config file $filename, line $$line_num: $@")
                if $@;

            # and then setenv too (allowing PATH "$BASEDIR/bin")
            if ($self->{setenv_vars}) {
                if ($name =~ /^setenv$/i) {
                    croak("Error in config file $filename, line $$line_num: ".
                          " can't use setenv_vars " .
                          "with malformed SetEnv directive") if @val != 2;
                    $ENV{"$val[0]"} = $val[1];
                } elsif ($name =~ /^unsetenv$/i) {
                    croak("Error in config file $filename, line $$line_num: ".
                          "can't use setenv_vars " .
                          "with malformed UnsetEnv directive") unless @val;
                    delete $ENV{$_} for @val;
                }
            }

            # Include processing
            # because of the way our inheritance works, we navigate multiple files in reverse
            if ($name =~ /$include_re/) {
                for my $f (reverse @val) {
                    # if they specified a root_directive (ServerRoot) and
                    # it is defined, prefix that to relative paths
                    my $root = $self->{case_sensitive} ? $self->{root_directive}
                                                       : lc $self->{root_directive};
                    if (! File::Spec->file_name_is_absolute($f) && exists $data->{$root}) {
                        # looks odd; but only reliable method is construct UNIX-style
                        # then deconstruct
                        my @parts = File::Spec->splitpath("$data->{$root}[0]/$f");
                        $f = File::Spec->catpath(@parts);
                    }

                    # this handles directory includes (i.e. will include all files in a directory)
                    my @files;
                    if (-d $f) {
                        opendir(INCD, $f)
                            || croak("Cannot open include directory '$f' at $filename ",
                                     "line $$line_num: $!");
                        @files = map { "$f/$_" } sort grep { -f "$f/$_" } readdir INCD;
                        closedir(INCD);
                    } else {
                        @files = $f;
                    }

                    for my $values (reverse @files) {
                        # just try to open it as-is
                        my $include_fh;
                        unless (open($include_fh, "<", $values)) {
                            if ($fstack->[0]{filename}) {
                                # try opening it relative to the enclosing file
                                # using File::Spec
                                my @parts = File::Spec->splitpath($filename);
                                $parts[-1] = $values;
                                open($include_fh, "<", File::Spec->catpath(@parts)) or 
                                    croak("Unable to open include file '$values' ",
                                        "at $filename line $$line_num: $!");
                                } else {
                                    croak("Unable to open include file '$values' ",
                                        "at $filename line $$line_num: $!");
                                }
                            }

                        # push a new record onto the @fstack for this file
                        push(@$fstack, { fh          => $fh        = $include_fh,
                                         filename    => $filename  = $values,
                                         line_number => 0 });

                        # hook up line counter
                        $line_num = \$fstack->[-1]{line_num};
                    }
                }
                next LINE;
            }

            # for each @val, "fix" booleans if so requested
            # do this *after* include processing so "include yes.conf" works
            if ($self->{fix_booleans}) {
                for (@val) { 
                    if (/^true$/i or /^on$/i or /^yes$/i) {
                        $_ = 1;
                    } elsif (/^false$/i or /^off$/i or /^no$/i) {
                        $_ = 0;
                    }
                }
            }

            # how to handle repeated values
            # this is complicated because we have to allow a semi-union of
            # the hash_directives and duplicate_directives options

            if ($self->{hash_directives}
                && _member($orig, 
                           $self->{hash_directives}, $self->{case_sensitive})){
                my $k = shift @val;
                if ($self->{duplicate_directives} eq 'error') {
                    # must check for a *specific* dup
                    croak "Duplicate directive '$orig $k' at $filename line $$line_num"
                        if $data->{$name}{$k};
                    push @{$data->{$name}{$k}}, @val;
                }
                elsif ($self->{duplicate_directives} eq 'last') {
                    $data->{$name}{$k} = \@val;
                }
                else {
                    # push onto our struct to allow repeated declarations
                    push @{$data->{$name}{$k}}, @val;
                }
            } else {
                if ($self->{duplicate_directives} eq 'error') {
                    # not a hash_directive, so all dups are errors
                    croak "Duplicate directive '$orig' at $filename line $$line_num"
                        if $data->{$name};
                    push @{$data->{$name}}, @val;
                }
                elsif ($self->{duplicate_directives} eq 'last') {
                    $data->{$name} = \@val;
                }
                else {
                    # push onto our struct to allow repeated declarations
                    push @{$data->{$name}}, @val;
                }
            }

        } else {
            croak("Error in config file $filename, line $$line_num: ".
                  "unable to parse line");
        }
    }

    return $self;
}

# given a string returns a list of tokens, allowing for quoted strings
# and otherwise splitting on whitespace
sub _parse_value_list {
    my $values = shift;

    my @val;
    if ($values !~ /['"\s]/) {
        # handle the common case of a single unquoted string
        @val = ($values);
    } elsif ($values !~ /['"]/) {
        # strings without any quote characters can be parsed with split
        @val = split /\s+/, $values;
    } else {
        # break apart line, allowing for quoted strings with
        # escaping
        while($values) {
            my $val;        
            if ($values !~ /^["']/) {
                # strip off a value and put it where it belongs
                ($val, $values) = $values =~ /^(\S+)\s*(.*)$/;
            } else {
                # starts with a quote, bring in the big guns
                $val = extract_delimited($values, q{"'});
                die "value string '$values' not properly formatted\n"
                    unless length $val;
            
                # remove quotes and fixup escaped characters
                $val = substr($val, 1, length($val) - 2);
                $val =~ s/\\(['"])/$1/g;

                # strip off any leftover space
                $values =~ s/^\s*//;
            }
            push(@val, $val);
        }
    }
    die "no value found for directive\n" unless @val;

    return wantarray ? @val : \@val;
}

# expand any $var stuff if expand_vars is set
sub _expand_vars {
    my $self = shift;
    my @vals = @_;
    for (@vals) {
        local $^W = 0;            # shuddup uninit
        s/\\\$/$PLACEHOLDER/g;    # kludge but works (Text::Balanced broken)
        s/\$\{?(\w+)\}?/
            my $var = $1;
            my $val = $self->get($var);
            die "undefined variable '\$$var' seen\n" unless defined $val;
            $val; 
        /ge;
        s/$PLACEHOLDER/\$/g;      # redo placeholders, removing escaping
    }
    return @vals;
}

sub _member {
    # simple "in" style sub
    my($name, $hdir, $case) = @_;
    $name = lc $name unless $case;
    return unless $hdir && ref $hdir eq 'ARRAY';
    for (@$hdir) {
        $_ = lc $_ unless $case;
        return 1 if $name eq $_;
    }
    return;
}

=item C<< $value = $config->get("var_name") >>

=item C<< @vals = $config->get("list_name") >>

=item C<< $value = $config->get("hash_var_name", "key") >>

Returns values from the configuration file.  If the directive contains
a single value, it will be returned.  If the directive contains a list
of values then they will be returned as a list.  If the directive does
not exist in the configuration file then nothing will be returned
(undef in scalar context, empty list in list context).

For example, given this confiuration file:

  Foo 1
  Bar bif baz bop

The following code would work as expected:

  my $foo = $config->get("Foo");   # $foo = 1
  my @bar = $config->get("Bar");   # @bar = ("bif", "baz", "bop")

If the name is the name of a block tag in the configuration file then
a list of available block specifiers will be returned.  For example,
given this configuration file:

  <Site big>
     Size 10
  </Site>

  <Site small>
     Size 1
  </Site>

This call:

  @sites = $config->get("Site");

Will return C<([ Site => "big"], [ Site => "small" ])>.  These arrays
can then be used with the block() method described below.

If the directive was included in the file but did not have a value,
1 is returned by get().

Calling get() with no arguments will return the names of all available
directives.

Directives declared in C<hash_directives> require a key value:

  $handler = $config->get("AddHandler", "cgi-script");

C<directive()> is available as an alias for C<get()>.

=cut

# get a value from the config file.
*directive = \&get;
sub get {
    my ($self, $name, $srch) = @_;

    # handle empty param call
    return keys %{$self->{_data}} if @_ == 1;

    # lookup name in _data
    $name = lc $name unless $self->{case_sensitive};
    my $val = $self->{_data}{$name};

    # Search through up the tree if inheritence is on and we have a
    # parent.  Simulated recursion terminates either when $val is
    # found or when the root is reached and _parent is undef.
    if (not defined $val and 
        $self->{_parent} and 
        $self->{inheritance_support}) {
        my $ptr = $self;
        do {
            $ptr = $ptr->{_parent};
            $val = $ptr->{_data}{$name};
        } while (not defined $val and $ptr->{_parent});
    }

    # didn't find it?
    return unless defined $val;
    
    # for blocks, return a list of valid block identifiers
    my $type = ref $val;
    my @ret;    # tmp to avoid screwing up $val
    if ($type) {
        if ($type eq 'ARRAY' and 
            ref($val->[0]) eq ref($self)) {
            @ret = map { [ $name, @{$_->{_block_vals}} ] } @$val;
            $val = \@ret;
        } elsif ($type eq 'HASH') {
            # hash_directive
            if ($srch) {
                # return the specific one
                $val = $val->{$srch};
            } else {
                # return valid keys
                $val = [ keys %$val ];
            }
            
        }
    }
 
    # return all vals in list ctxt, or just the first in scalar
    return wantarray ? @$val : $val->[0];
}

=item $block = $config->block("BlockName")

=item $block = $config->block(Directory => "/foo/bar")

=item $block = $config->block(Directory => "~" => "^.*/bar")

This method returns a Config::ApacheFormat object used to access the
values inside a block.  Parameters specified within the block will be
available.  Also, if inheritance is turned on (the default), values
set outside the block that are not overwritten inside the block will
also be available.  For example, given this file:

  MaxSize 100

  <Site "big">
     Size 10
  </Site>

  <Site "small">
     Size 1
  </Site>

this code:

  print "Max: ", $config->get("MaxSize"), "\n";

  $block = $config->block(Site => "big");
  print "Big: ", $block->get("Size"), " / ", 
                 $block->get("MaxSize"), "\n";

  $block = $config->block(Site => "small");
  print "Small: ", $block->get("Size"), " / ", 
                   $block->get("MaxSize"), "\n";

will print:

  Max: 100
  Big: 10 / 100
  Small: 1 / 100

Note that C<block()> does not require any particular number of
parameters.  Any number will work, as long as they uniquely identify a
block in the configuration file.  To get a list of available blocks,
use get() with the name of the block tag.

This method will die() if no block can be found matching the specifier
passed in.

=cut

# get object for a given block specifier
sub block {
    my $self = shift;
    my($name, @vals) = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
    $name = lc $name unless $self->{case_sensitive};
    my $data = $self->{_data};

    # make sure we have at least one block named $name
    my $block_array;
    croak("No such block named '$name' in config file")
      unless ($block_array = $data->{$name} and 
              ref($block_array) eq 'ARRAY' and
              ref($block_array->[0]) eq ref($self));

    # find a block matching @vals.  If Perl supported arbitrary
    # structures as hash keys this could be more efficient.
    my @ret;
  BLOCK: 
    foreach my $block (@{$block_array}) {
        if (@vals == @{$block->{_block_vals}}) {
            for (local $_ = 0; $_ < @vals; $_++) {
                next BLOCK unless $vals[$_] eq $block->{_block_vals}[$_];
            }
            return $block unless wantarray;     # saves time
            push @ret, $block;
        }
    }
    return @ret if @ret;

    # redispatch to get() if just given block type ($config->block('location'))
    #return $self->get(@_) unless @vals;

    croak("No such block named '$name' with values ", 
          join(', ', map { "'$_'" } @vals), " in config file");
}   

=item $config->clear()

Clears out all data in $config.  Call before re-calling
$config->read() for a fresh read.

=cut

sub clear {
    my $self = shift;
    delete $self->{_data};
    $self->{_data} = {};
}

=item $config->dump()

This returns a dumped copy of the current configuration. It can be
used on a block object as well. Since it returns a string, you should
say:

    print $config->dump;

Or:

    for ($config->block(VirtualHost => '10.1.65.1')) {
        print $_->dump;
    }

If you want to see any output.

=cut

sub dump {
    my $self = shift;
    require Data::Dumper;
    $Data::Dumper::Indent = 1;
    return Data::Dumper::Dumper($self);
}

# handle autoload_support feature
sub DESTROY { 1 }
sub AUTOLOAD {
    our $AUTOLOAD;

    my $self = shift;
    my ($name) = $AUTOLOAD =~ /([^:]+)$/;
    croak(qq(Can't locate object method "$name" via package ") . 
          ref($self) . '"')
      unless $self->{autoload_support};

    return $self->get($name);
}


1;
__END__

=back

=head1 Parsing a Real Apache Config File

To parse a real Apache config file (ex. C<httpd.conf>) you'll need to
use some non-default options.  Here's a reasonable starting point:

  $config = Config::ApacheFormat->new(
              root_directive     => 'ServerRoot',
              hash_directives    => [ 'AddHandler' ],
              include_directives => [ 'Include', 
                                      'AccessConfig', 
                                      'ResourceConfig' ],
              setenv_vars        => 1,
              fix_booleans       => 1);

              

=head1 TODO

Some possible ideas for future development:

=over 4

=item *

Add a set() method.  (useless?)

=item *

Add a write() method to create a new configuration file.  (useless?)

=back

=head1 BUGS

I know of no bugs in this software.  If you find one, please create a
bug report at:

  http://rt.cpan.org/

Include the version of the module you're using and a small piece of
code that I can run which demonstrates the problem.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2003 Sam Tregar

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=head1 AUTHORS

=item Sam Tregar <sam@tregar.com>

Original author and maintainer

=item Nathan Wiger <nate@wiger.org>

Porting of features from L<Apache::ConfigFile|Apache::ConfigFile>

=head1 SEE ALSO

L<Apache::ConfigFile|Apache::ConfigFile>

L<Apache::ConfigParser|Apache::ConfigParser>

=cut

