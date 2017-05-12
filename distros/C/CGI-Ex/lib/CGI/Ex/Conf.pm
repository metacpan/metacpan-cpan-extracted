package CGI::Ex::Conf;

=head1 NAME

CGI::Ex::Conf - Conf Reader/Writer for many different data format types

=cut

###----------------------------------------------------------------###
#  Copyright 2003-2015 - Paul Seamons                                #
#  Distributed under the Perl Artistic License without warranty      #
###----------------------------------------------------------------###

use strict;
use base qw(Exporter);
use Carp qw(croak);
use vars qw($VERSION
            @DEFAULT_PATHS
            $DEFAULT_EXT
            %EXT_READERS
            %EXT_WRITERS
            $DIRECTIVE
            $IMMUTABLE_QR
            $IMMUTABLE_KEY
            %CACHE
            $HTML_KEY
            @EXPORT_OK
            $NO_WARN_ON_FAIL
            );
@EXPORT_OK = qw(conf_read conf_write in_cache);

$VERSION = '2.44';

$DEFAULT_EXT = 'conf';

%EXT_READERS = (''         => \&read_handler_yaml,
                'conf'     => \&read_handler_yaml,
                'json'     => \&read_handler_json,
                'val_json' => \&read_handler_json,
                'ini'      => \&read_handler_ini,
                'pl'       => \&read_handler_pl,
                'sto'      => \&read_handler_storable,
                'storable' => \&read_handler_storable,
                'val'      => \&read_handler_yaml,
                'xml'      => \&read_handler_xml,
                'yaml'     => \&read_handler_yaml,
                'yml'      => \&read_handler_yaml,
                'html'     => \&read_handler_html,
                'htm'      => \&read_handler_html,
                );

%EXT_WRITERS = (''         => \&write_handler_yaml,
                'conf'     => \&write_handler_yaml,
                'ini'      => \&write_handler_ini,
                'json'     => \&write_handler_json,
                'val_json' => \&write_handler_json,
                'pl'       => \&write_handler_pl,
                'sto'      => \&write_handler_storable,
                'storable' => \&write_handler_storable,
                'val'      => \&write_handler_yaml,
                'xml'      => \&write_handler_xml,
                'yaml'     => \&write_handler_yaml,
                'yml'      => \&write_handler_yaml,
                'html'     => \&write_handler_html,
                'htm'      => \&write_handler_html,
                );

### $DIRECTIVE controls how files are looked for when namespaces are not absolute.
### If directories 1, 2 and 3 are passed and each has a config file
### LAST would return 3, FIRST would return 1, and MERGE will
### try to put them all together.  Merge behavior of hashes
### is determined by $IMMUTABLE_\w+ variables.
$DIRECTIVE = 'LAST'; # LAST, MERGE, FIRST

$IMMUTABLE_QR = qr/_immu(?:table)?$/i;

$IMMUTABLE_KEY = 'immutable';

###----------------------------------------------------------------###

sub new {
  my $class = shift || __PACKAGE__;
  my $args  = shift || {};

  return bless {%$args}, $class;
}

sub paths {
  my $self = shift;
  return $self->{paths} ||= \@DEFAULT_PATHS;
}

###----------------------------------------------------------------###

sub conf_read {
  my $file = shift;
  my $args = shift || {};
  my $ext;

  ### they passed the right stuff already
  if (ref $file) {
    if (UNIVERSAL::isa($file, 'SCALAR')) {
      if ($$file =~ /^\s*</) {
        return html_parse_yaml_load($$file, $args); # allow for ref to a YAML string
      } else {
        return yaml_load($$file); # allow for ref to a YAML string
      }
    } else {
      return $file;
    }

  ### allow for a pre-cached reference
  } elsif (exists $CACHE{$file} && ! $args->{no_cache}) {
    return $CACHE{$file};

  ### if contains a newline - treat it as a YAML string
  } elsif (index($file,"\n") != -1) {
    return yaml_load($file);

  ### otherwise base it off of the file extension
  } elsif ($args->{file_type}) {
    $ext = $args->{file_type};
  } elsif ($file =~ /\.(\w+)$/) {
    $ext = $1;
  } else {
    $ext = defined($args->{default_ext}) ? $args->{default_ext}
         : defined($DEFAULT_EXT)         ? $DEFAULT_EXT
         : '';
    $file = length($ext) ? "$file.$ext" : $file;
  }

  ### determine the handler
  my $handler = $EXT_READERS{$ext} || croak "Unknown file extension: $ext";

  ### don't die if the file is not found - do die otherwise
  if (! -e $file) {
      eval { die "Conf file $file not found\n" };
      warn "Conf file $file not found" if ! $args->{'no_warn_on_fail'} && ! $NO_WARN_ON_FAIL;
      return;
  }

  return eval { scalar $handler->($file, $args) } || die "Error while reading conf file $file\n$@";
}

sub read_ref {
  my $self = shift;
  my $file = shift;
  my $args = shift || {};
  return conf_read($file, {%$self, %$args});
}

### allow for different kinds of merging of arguments
### allow for key fallback on hashes
### allow for immutable values on hashes
sub read {
  my $self      = shift;
  my $namespace = shift;
  my $args      = shift || {};
  my $REF       = $args->{ref} || undef;    # can pass in existing set of options
  my $IMMUTABLE = $args->{immutable} || {}; # can pass existing immutable types

  $self = $self->new() if ! ref $self;

  ### allow for fast short ciruit on path lookup for several cases
  my $directive;
  my @paths = ();
  if (ref($namespace)                   # already a ref
      || index($namespace,"\n") != -1   # yaml string to read in
      || $namespace =~ m|^\.{0,2}/.+$|  # absolute or relative file
      ) {
    push @paths, $namespace;
    $directive = 'FIRST';

  ### use the default directories
  } else {
    $directive = uc($args->{directive} || $self->{directive} || $DIRECTIVE);
    $namespace =~ s|::|/|g;  # allow perlish style namespace
    my $paths = $args->{paths} || $self->paths
      || croak "No paths found during read on $namespace";
    $paths = [$paths] if ! ref $paths;
    if ($directive eq 'LAST') { # LAST shall be FIRST
      $directive = 'FIRST';
      $paths = [reverse @$paths] if $#$paths != 0;
    }
    foreach my $path (@$paths) {
      next if exists $CACHE{$path} && ! $CACHE{$path};
      push @paths, "$path/$namespace";
    }
  }

  ### make sure we have at least one path
  if ($#paths == -1) {
    croak "Couldn't find a path for namespace $namespace.  Perhaps you need to pass paths => \@paths";
  }

  ### now loop looking for a ref
  foreach my $path (@paths) {
    my $ref = $self->read_ref($path, $args) || next;
    if (! $REF) {
      if (UNIVERSAL::isa($ref, 'ARRAY')) {
        $REF = [];
      } elsif (UNIVERSAL::isa($ref, 'HASH')) {
        $REF = {};
      } else {
        croak "Unknown config type of \"".ref($ref)."\" for namespace $namespace";
      }
    } elsif (! UNIVERSAL::isa($ref, ref($REF))) {
      croak "Found different reference types for namespace $namespace"
        . " - wanted a type ".ref($REF);
    }
    if (ref($REF) eq 'ARRAY') {
      if ($directive eq 'MERGE') {
        push @$REF, @$ref;
        next;
      }
      splice @$REF, 0, $#$REF + 1, @$ref;
      last;
    } else {
      my $immutable = delete $ref->{$IMMUTABLE_KEY};
      my ($key,$val);
      if ($directive eq 'MERGE') {
        while (($key,$val) = each %$ref) {
          next if $IMMUTABLE->{$key};
          my $immute = $key =~ s/$IMMUTABLE_QR//o;
          $IMMUTABLE->{$key} = 1 if $immute || $immutable;
          $REF->{$key} = $val;
        }
        next;
      }
      delete $REF->{$key} while $key = each %$REF;
      while (($key,$val) = each %$ref) {
        my $immute = $key =~ s/$IMMUTABLE_QR//o;
        $IMMUTABLE->{$key} = 1 if $immute || $immutable;
        $REF->{$key} = $val;
      }
      last;
    }
  }
  $REF->{"Immutable Keys"} = $IMMUTABLE if scalar keys %$IMMUTABLE;
  return $REF;
}

###----------------------------------------------------------------###

sub read_handler_ini {
  my $file = shift;
  require Config::IniHash;
  return Config::IniHash::ReadINI($file);
}

sub read_handler_pl {
  my $file = shift;
  ### do has odd behavior in that it turns a simple hashref
  ### into hash - help it out a little bit
  my @ref = do $file;
  return ($#ref != 0) ? {@ref} : $ref[0];
}

sub read_handler_json {
  my $file = shift;
  local *IN;
  open (IN, $file) || die "Couldn't open $file: $!";
  CORE::read(IN, my $text, -s $file);
  close IN;
  require JSON;
  my $decode = JSON->VERSION > 1.98 ? 'decode' : 'jsonToObj';
  return scalar JSON->new->$decode($text);
}

sub read_handler_storable {
  my $file = shift;
  require Storable;
  return Storable::retrieve($file);
}

sub read_handler_yaml {
  my $file = shift;
  local *IN;
  open (IN, $file) || die "Couldn't open $file: $!";
  CORE::read(IN, my $text, -s $file);
  close IN;
  return yaml_load($text);
}

sub yaml_load {
  my $text = shift;
  require YAML;
  my @ret = eval { YAML::Load($text) };
  if ($@) {
    die "$@";
  }
  return ($#ret == 0) ? $ret[0] : \@ret;
}

sub read_handler_xml {
  my $file = shift;
  require XML::Simple;
  return XML::Simple::XMLin($file);
}

### this handler will only function if a html_key (such as validation)
### is specified - actually this somewhat specific to validation - but
### I left it as a general use for other types

### is specified
sub read_handler_html {
  my $file = shift;
  my $args = shift;
  if (! eval { require YAML }) {
    my $err   = $@;
    my $found = 0;
    my $i     = 0;
    while (my($pkg, $file, $line, $sub) = caller($i++)) {
      return undef if $sub =~ /\bpreload_files$/;
    }
    die $err;
  }

  ### get the html
  local *IN;
  open (IN, $file) || return undef;
  CORE::read(IN, my $html, -s $file);
  close IN;

  return html_parse_yaml_load($html, $args);
}

sub html_parse_yaml_load {
  my $html = shift;
  my $args = shift || {};
  my $key  = $args->{html_key} || $HTML_KEY;
  return undef if ! $key || $key !~ /^\w+$/;

  my $str = '';
  my @order = ();
  while ($html =~ m{
    (document\.    # global javascript
     | var\s+      # local javascript
     | <\w+\s+[^>]*?) # input, form, select, textarea tag
      \Q$key\E   # the key
      \s*=\s*    # an equals sign
      ([\"\'])   # open quote
      (.+?[^\\]) # something in between
      \2        # close quote
    }xsg) {
    my ($line, $quot, $yaml) = ($1, $2, $3);
    if ($line =~ /^(document\.|var\s)/) { # js variable
      $yaml =~ s/\\$quot/$quot/g;
      $yaml =~ s/\\n\\\n?/\n/g;
      $yaml =~ s/\\\\/\\/g;
      $yaml =~ s/\s*$/\n/s; # fix trailing newline
      $str = $yaml; # use last one found
    } else { # inline attributes
      $yaml =~ s/\s*$/\n/s; # fix trailing newline
      if ($line =~ m/<form/i) {
        $yaml =~ s/^\Q$1\E//m if $yaml =~ m/^( +)/s;
        $str .= $yaml;

      } elsif ($line =~ m/\bname\s*=\s*('[^\']*'|"[^\"]*"|\S+)/) {
        my $key = $1;
        push @order, $key;
        $yaml =~ s/^/ /mg; # indent entire thing
        $yaml =~ s/^(\ *[^\s&*\{\[])/\n$1/; # add first newline
        $str .= "$key:$yaml";
      }
    }
  }
  $str .= "group order: [".join(", ",@order)."]\n"
    if $str && $#order != -1 && $key eq 'validation';

  return undef if ! $str;
  my $ref = eval { yaml_load($str) };
  if ($@) {
    my $err = "$@";
    if ($err =~ /line:\s+(\d+)/) {
      my $line = $1;
      while ($str =~ m/(.+)/gm) {
        next if -- $line;
        $err .= "LINE = \"$1\"\n";
        last;
      }
    }
    die $err;
  }
  return $ref;
}

###----------------------------------------------------------------###

sub conf_write {
  my $file = shift;
  my $conf = shift || croak "Missing conf";
  my $args = shift || {};
  my $ext;

  if (ref $file) {
    croak "Invalid filename for write: $file";

  } elsif (index($file,"\n") != -1) {
    croak "Cannot use a yaml string as a filename during write";

  ### allow for a pre-cached reference
  } elsif (exists $CACHE{$file} && ! $args->{no_cache}) {
    warn "Cannot write back to a file that is in the cache";
    return 0;

  ### otherwise base it off of the file extension
  } elsif ($args->{file_type}) {
    $ext = $args->{file_type};
  } elsif ($file =~ /\.(\w+)$/) {
    $ext = $1;
  } else {
    $ext = defined($args->{default_ext}) ? $args->{default_ext}
         : defined($DEFAULT_EXT)         ? $DEFAULT_EXT
         : '';
    $file = length($ext) ? "$file.$ext" : $file;
  }

  ### determine the handler
  my $handler;
  if ($args->{handler}) {
    $handler = (UNIVERSAL::isa($args->{handler},'CODE'))
      ? $args->{handler} : $args->{handler}->{$ext};
  }
  if (! $handler) {
    $handler = $EXT_WRITERS{$ext} || croak "Unknown file extension: $ext";
  }

  return eval { scalar $handler->($file, $conf, $args) } || die "Error while writing conf file $file\n$@";
}

sub write_ref {
  my $self = shift;
  my $file = shift;
  my $conf = shift;
  my $args = shift || {};
  conf_write($file, $conf, {%$self, %$args});
}

### Allow for writing out conf values
### Allow for writing out the correct filename (if there is a path array)
### Allow for not writing out immutable values on hashes
sub write {
  my $self      = shift;
  my $namespace = shift;
  my $conf      = shift || croak "Must pass hashref to write out"; # the info to write
  my $args      = shift || {};
  my $IMMUTABLE = $args->{immutable} || {}; # can pass existing immutable types

  $self = $self->new() if ! ref $self;

  ### allow for fast short ciruit on path lookup for several cases
  my $directive;
  my @paths = ();
  if (ref($namespace)                   # already a ref
      || $namespace =~ m|^\.{0,2}/.+$|  # absolute or relative file
      ) {
    push @paths, $namespace;
    $directive = 'FIRST';

  } elsif (index($namespace,"\n") != -1) { # yaml string - can't write that
    croak "Cannot use a yaml string as a namespace for write";

  ### use the default directories
  } else {
    $directive = uc($args->{directive} || $self->{directive} || $DIRECTIVE);
    $namespace =~ s|::|/|g;  # allow perlish style namespace
    my $paths = $args->{paths} || $self->paths
      || croak "No paths found during write on $namespace";
    $paths = [$paths] if ! ref $paths;
    if ($directive eq 'LAST') { # LAST shall be FIRST
      $directive = 'FIRST';
      $paths = [reverse @$paths] if $#$paths != 0;
    }
    foreach my $path (@$paths) {
      next if exists $CACHE{$path} && ! $CACHE{$path};
      push @paths, "$path/$namespace";
    }
  }

  ### make sure we have at least one path
  if ($#paths == -1) {
    croak "Couldn't find a path for namespace $namespace.  Perhaps you need to pass paths => \@paths";
  }

  my $path;
  if ($directive eq 'FIRST') {
    $path = $paths[0];
  } elsif ($directive eq 'LAST' || $directive eq 'MERGE') {
    $path = $paths[-1];
  } else {
    croak "Unknown directive ($directive) during write of $namespace";
  }

  ### remove immutable items (if any)
  if (UNIVERSAL::isa($conf, 'HASH') && $conf->{"Immutable Keys"}) {
    $conf = {%$conf}; # copy the values - only for immutable
    my $IMMUTABLE = delete $conf->{"Immutable Keys"};
    foreach my $key (keys %$IMMUTABLE) {
      delete $conf->{$key};
    }
  }

  ### finally write it out
  $self->write_ref($path, $conf);

  return 1;
}

###----------------------------------------------------------------###

sub write_handler_ini {
  my $file = shift;
  my $ref  = shift;
  require Config::IniHash;
  return Config::IniHash::WriteINI($file, $ref);
}

sub write_handler_pl {
  my $file = shift;
  my $ref  = shift;
  ### do has odd behavior in that it turns a simple hashref
  ### into hash - help it out a little bit
  require Data::Dumper;
  local $Data::Dump::Purity = 1;
  local $Data::Dumper::Sortkeys  = 1;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Pad       = '  ';
  local $Data::Dumper::Varname   = 'VunderVar';
  my $str = Data::Dumper->Dumpperl([$ref]);
  if ($str =~ s/^(.+?=\s*)//s) {
    my $l = length($1);
    $str =~ s/^\s{1,$l}//mg;
  }
  if ($str =~ /\$VunderVar/) {
    die "Ref to be written contained circular references - can't write";
  }

  local *OUT;
  open (OUT, ">$file") || die $!;
  print OUT $str;
  close OUT;
}

sub write_handler_json {
  my $file = shift;
  my $ref  = shift;
  require JSON;
  my $str;
  if (JSON->VERSION > 1.98) {
      my $j = JSON->new;
      $j->canonical(1);
      $j->pretty;
      $str = $j->encode($ref);
  } else {
      $str = JSON->new->objToJSon($ref, {pretty => 1, indent => 2});
  }
  local *OUT;
  open (OUT, ">$file") || die $!;
  print OUT $str;
  close(OUT);
}

sub write_handler_storable {
  my $file = shift;
  my $ref  = shift;
  require Storable;
  return Storable::store($ref, $file);
}

sub write_handler_yaml {
  my $file = shift;
  my $ref  = shift;
  require YAML;
  return YAML::DumpFile($file, $ref);
}

sub write_handler_xml {
  my $file = shift;
  my $ref  = shift;
  require XML::Simple;
  local *OUT;
  open (OUT, ">$file") || die $!;
  print OUT scalar(XML::Simple->new->XMLout($ref, noattr => 1));
  close(OUT);
}

sub write_handler_html {
  my $file = shift;
  my $ref  = shift;
  die "Write of conf information to html is not supported";
}

###----------------------------------------------------------------###

sub preload_files {
    my $self  = shift;
    my $paths = shift || $self->paths;

    ### what extensions do we look for
    my %EXT;
    if ($self->{'handler'}) {
        if (UNIVERSAL::isa($self->{'handler'},'HASH')) {
            %EXT = %{ $self->{'handler'} };
        }
    } else {
        %EXT = %EXT_READERS;
        if (! $self->{'html_key'} && ! $HTML_KEY) {
            delete $EXT{$_} foreach qw(html htm);
        }
    }
    return if ! keys %EXT;

    ### look in the paths for the files
    foreach my $path (ref($paths) ? @$paths : $paths) {
        $path =~ s|//+|/|g;
        $path =~ s|/$||;
        next if exists $CACHE{$path};
        if (-f $path) {
            my $ext = ($path =~ /\.(\w+)$/) ? $1 : '';
            next if ! $EXT{$ext};
            $CACHE{$path} = $self->read($path);
        } elsif (-d _) {
            $CACHE{$path} = 1;
            require File::Find;
            File::Find::find(sub {
                return if exists $CACHE{$File::Find::name};
                return if $File::Find::name =~ m|/CVS/|;
                return if ! -f;
                my $ext = (/\.(\w+)$/) ? $1 : '';
                return if ! $EXT{$ext};
                $CACHE{$File::Find::name} = $self->read($File::Find::name);
            }, "$path/");
        } else {
            $CACHE{$path} = 0;
        }
    }
}

sub in_cache {
    my ($self, $file) = (@_ == 2) ? @_ : (undef, shift());
    return exists($CACHE{$file}) || 0;
}

###----------------------------------------------------------------###

1;

__END__

=head1 SYNOPSIS

    use CGI::Ex::Conf qw(conf_read conf_write);

    my $hash = conf_read("/tmp/foo.yaml");

    conf_write("/tmp/foo.yaml", {key1 => $val1, key2 => $val2});


    ### OOP interface

    my $cob = CGI::Ex::Conf->new;

    my $full_path_to_file = "/tmp/foo.val"; # supports ini, sto, val, pl, xml
    my $hash = $cob->read($file);

    local $cob->{default_ext} = 'conf'; # default anyway


    my @paths = qw(/tmp, /home/pauls);
    local $cob->{paths} = \@paths;
    my $hash = $cob->read('My::NameSpace');
    # will look in /tmp/My/NameSpace.conf and /home/pauls/My/NameSpace.conf


    my $hash = $cob->read('My::NameSpace', {paths => ['/tmp']});
    # will look in /tmp/My/NameSpace.conf


    local $cob->{directive} = 'MERGE';
    my $hash = $cob->read('FooSpace');
    # OR #
    my $hash = $cob->read('FooSpace', {directive => 'MERGE'});
    # will return merged hashes from /tmp/FooSpace.conf and /home/pauls/FooSpace.conf
    # immutable keys are preserved from originating files


    local $cob->{directive} = 'FIRST';
    my $hash = $cob->read('FooSpace');
    # will return values from first found file in the path.


    local $cob->{directive} = 'LAST'; # default behavior
    my $hash = $cob->read('FooSpace');
    # will return values from last found file in the path.


    ### manipulate $hash
    $cob->write('FooSpace'); # will write it out the changes

=head1 DESCRIPTION

There are half a million Conf readers out there.  Why not add one more.
Actually, this module provides a wrapper around the many file formats
and the config modules that can handle them.  It does not introduce any
formats of its own.

This module also provides a preload ability which is useful in conjunction
with mod_perl.

Oh - and it writes too.

=head1 METHODS

=over 4

=item C<read_ref>

Takes a file and optional argument hashref.  Figures out the type
of handler to use to read the file, reads it and returns the ref.
If you don't need the extended merge functionality, or key fallback,
or immutable keys, or path lookup ability - then use this method.
Otherwise - use ->read.

=item C<read>

First argument may be either a perl data structure, yaml string, a
full filename, or a file "namespace".

The second argument can be a hashref of override values (referred to
as $args below)..

If the first argument is a perl data structure, it will be
copied one level deep and returned (nested structures will contain the
same references).  A yaml string will be parsed and returned.  A full
filename will be read using the appropriate handler and returned (a
file beginning with a / or ./ or ../ is considered to be a full
filename).  A file "namespace" (ie "footer" or "my::config" or
"what/ever") will be turned into a filename by looking for that
namespace in the paths found either in $args->{paths} or in
$self->{paths} or in @DEFAULT_PATHS.  @DEFAULT_PATHS is empty by
default as is $self->{paths} - read makes no attempt to guess what
directories to look in.  If the namespace has no extension the
extension listed in $args->{default_ext} or $self->{default_ext} or
$DEFAULT_EXT will be used).

  my $ref = $cob->read('My::NameSpace', {
    paths => [qw(/tmp /usr/data)],
    default_ext => 'pl',
  });
  # would look first for /tmp/My/NameSpace.pl
  # and then /usr/data/My/NameSpace.pl

  my $ref = $cob->read('foo.sto', {
    paths => [qw(/tmp /usr/data)],
    default_ext => 'pl',
  });
  # would look first for /tmp/foo.sto
  # and then /usr/data/foo.sto

When a namespace is used and there are multiple possible paths, there
area a few options to control which file to look for.  A directive of
'FIRST', 'MERGE', or 'LAST' may be specified in $args->{directive} or
$self->{directive} or the default value in $DIRECTIVE will be used
(default is 'LAST'). When 'FIRST' is specified the first path that
contains the namespace is returned.  If 'LAST' is used, the last
found path that contains the namespace is returned.  If 'MERGE' is
used, the data structures are joined together.  If they are
arrayrefs, they are joined into one large arrayref.  If they are
hashes, they are layered on top of each other with keys found in later
paths overwriting those found in earlier paths.  This allows for
setting system defaults in a root file, and then allow users to have
custom overrides.

It is possible to make keys in a root file be immutable (non
overwritable) by adding a suffix of _immutable or _immu to the key (ie
{foo_immutable => 'bar'}).  If a value is found in the file that
matches $IMMUTABLE_KEY, the entire file is considered immutable.
The immutable defaults may be overriden using $IMMUTABLE_QR and $IMMUTABLE_KEY.

Errors during read die.  If the file does not exist undef is returned.

=item C<write_ref>

Takes a file and the reference to be written.  Figures out the type
of handler to use to write the file and writes it. If you used the ->read_ref
use this method.  Otherwise, use ->write.

=item C<write>

Allows for writing back out the information read in by ->read.  If multiple
paths where used - the directive 'FIRST' will write the changes to the first
file in the path - otherwise the last path will be used.  If ->read had found
immutable keys, then those keys are removed before writing.

Errors during write die.

=item C<preload_files>

Arguments are file(s) and/or directory(s) to preload.  preload_files will
loop through the arguments, find the files that exist, read them in using
the handler which matches the files extension, and cache them by filename
in %CACHE.  Directories are spidered for file extensions which match those
listed in %EXT_READERS.  This is useful for a server environment where CPU
may be more precious than memory.

=item C<in_cache>

Allow for testing if a particular filename is registered in the %CACHE - typically
from a preload_files call.  This is useful when building wrappers around the
conf_read and conf_write method calls.

=back

=head1 FUNCTIONS

=over 4

=item conf_read

Takes a filename.  Returns the read contents of that filename.  The handler
to use is based upon the extention on the file.

    my $hash = conf_read('/tmp/foo.yaml');

    my $hash = conf_read('/tmp/foo', {file_type => 'yaml'});

Takes a filename and a data structure.  Writes the data to the filename.  The handler
to use is based upon the extention on the file.

    conf_write('/tmp/foo.yaml', \%hash);

    conf_write('/tmp/foo', \%hash, {file_type => 'yaml'});

=back

=head1 FILETYPES

CGI::Ex::Conf supports the files found in %EXT_READERS by default.
Additional types may be added to %EXT_READERS, or a custom handler may be
passed via $args->{handler} or $self->{handler}.  If the custom handler is
a code ref, all files will be passed to it.  If it is a hashref, it should
contain keys which are extensions it supports, and values which read those
extensions.

Some file types have benefits over others.  Storable is very fast, but is
binary and not human readable.  YAML is readable but very slow.  I would
suggest using a readable format such as YAML and then using preload_files
to load in what you need at run time.  All preloaded files are faster than
any of the other types.

The following is the list of handlers that ships with CGI::Ex::Conf (they
will only work if the supporting module is installed on your system):

=over 4

=item C<pl>

Should be a file containing a perl structure which is the last thing returned.

=item C<sto> and C<storable>

Should be a file containing a structure stored in Storable format.
See L<Storable>.

=item C<yaml> and C<conf> and C<val>

Should be a file containing a yaml document.  Multiple documents are returned
as a single arrayref.  Also - any file without an extension and custom handler
will be read using YAML.  See L<YAML>.

=item C<ini>

Should be a windows style ini file.  See L<Config::IniHash>

=item C<xml>

Should be an xml file.  It will be read in by XMLin.  See L<XML::Simple>.

=item C<json>

Should be a json file.  It will be read using the JSON library.  See L<JSON>.

=item C<html> and C<htm>

This is actually a custom type intended for use with CGI::Ex::Validate.
The configuration to be read is actually validation that is stored
inline with the html.  The handler will look for any form elements or
input elements with an attribute with the same name as in $HTML_KEY.  It
will also look for a javascript variable by the same name as in $HTML_KEY.
All configuration items done this way should be written in YAML.
For example, if $HTML_KEY contained 'validation' it would find validation in:

  <input type=text name=username validation="{required: 1}">
  # automatically indented and "username:\n" prepended
  # AND #
  <form name=foo validation="
  general no_confirm: 1
  ">
  # AND #
  <script>
  document.validation = "\n\
  username: {required: 1}\n\
  ";
  </script>
  # AND #
  <script>
  var validation = "\n\
  username: {required: 1}\n\
  ";
  </script>

If the key $HTML_KEY is not set, the handler will always return undef
without even opening the file.

=back

=head1 TODO

Make a similar write method that handles immutability.

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=head1 AUTHOR

Paul Seamons <perl at seamons dot com>

=cut

