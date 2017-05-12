package Config::Properties;

use strict;
use warnings;

our $VERSION = '1.80';

use IO::Handle;
use Carp;
use PerlIO qw();
use Errno qw();

{
    no warnings;
    sub _t_key ($) {
	my $k=shift;
	defined($k) && length($k)
	    or croak "invalid property key '$k'";
    }

    sub _t_value ($) {
	my $v=shift;
	defined $v
	    or croak "undef is not a valid value for a property";
    }

    sub _t_format ($) {
	my $f=shift;
	defined ($f) && $f=~/\%s.*\%s/
	    or croak "invalid format '%f'";
    }

    sub _t_validator ($) {
	my $v=shift;
	defined($v) &&
	    UNIVERSAL::isa($v, 'CODE') or
		croak "invalid property validator '$v'";
    }

    sub _t_file ($) {
	my $f=shift;
	defined ($f) or
	    croak "invalid file '$f'";
    }

    sub _t_order ($) {
        my $o = shift;
        $o =~ /^(?:keep|alpha|none)$/ or
            croak "invalid order";
    }

    sub _t_encoding ($) {
        my $e = shift;
        $e =~ /^[\w\-]+$/ or
            croak "invalid encoding '$e'";
    }
}

#   new() - Constructor
#
#   The constructor can take one optional argument "$defaultProperties"
#   which is an instance of Config::Properties to be used as defaults
#   for this object.
sub new {
    my $class = shift;
    my $defaults;
    $defaults = shift if @_ & 1;
    my %opts = @_;
    $defaults = delete $opts{defaults} unless defined $defaults;
    my $be_like_java = delete $opts{be_like_java};
    my $format = delete $opts{format};
    $format = '%s=%s' unless defined $format;
    my $wrap = delete $opts{wrap};
    $wrap = !$be_like_java unless defined $wrap;
    my $order = delete $opts{order};
    $order = 'keep' unless defined $order;
    _t_order($order);
    my $file = delete $opts{file};
    my $encoding = delete $opts{encoding};
    $encoding = 'latin1' unless defined $encoding;
    _t_encoding($encoding);
    my $eol_re = delete $opts{eol_re};
    $eol_re = qr/\r\n|\n|\r/ unless defined $eol_re;
    my $line_re = qr/^(.*?)(?:$eol_re)/s;

    %opts and croak "invalid option(s) '" . join("', '", keys %opts) . "'";

    if (defined $defaults) {
        if (ref $defaults eq 'HASH') {
            my $d = Config::Properties->new;
            while (my ($k, $v) = each %$defaults) {
                $d->setProperty($k, $v);
            }
            $defaults = $d;
        }
        elsif (!$defaults->isa('Config::Properties')) {
            croak die "defaults parameter is not a Config::Properties object or a hash"
        }
    }

    my $self = { defaults => $defaults,
                 be_like_java => $be_like_java,
		 format => $format,
                 wrap => $wrap,
                 order => $order,
		 properties => {},
		 last_line_number => 0,
		 property_line_numbers => {},
                 file => $file,
                 encoding => $encoding,
                 line_re => $line_re };
    bless $self, $class;

    if (defined $file) {
        open my $fh, '<', $file or croak "unable to open file '$file': $!";
        $self->load($fh);
        close $fh or croak "unable to load file '$file': $!";
    }
    return $self;
}

# set property only if its going to change the property value.
#
sub changeProperty {
    my ($self, $key, $new, @defaults) = @_;
    _t_key $key;
    _t_value $new;
    my $old=$self->getProperty($key, @defaults);
    if (!defined $old or $old ne $new) {
	$self->setProperty($key, $new);
	return 1;
    }
    return 0;
}

sub deleteProperty {
    my ($self, $key, $recurse) = @_;
    _t_key $key;

    if (exists $self->{properties}{$key}) {
      delete $self->{properties}{$key};
      delete $self->{property_line_numbers}{$key};
    }

    $self->{defaults}->deleteProperty($key, 1)
	if ($recurse and $self->{defaults});
}

#	setProperty() - Set the value for a specific property
sub setProperty {
    my ($self, $key, $value)=@_;
    _t_key $key;
    _t_value $value;

    defined(wantarray) and
	warnings::warnif(void => "warning: setProperty doesn't return the old value anymore");

    $self->{property_line_numbers}{$key} ||= ++$self->{last_line_number};
    $self->{properties}{$key} = $value;
}

sub _properties {
    my $self=shift;
    if (defined ($self->{defaults})) {
	my %p=($self->{defaults}->_properties, %{$self->{properties}});
	return %p;
    }
    return %{ $self->{properties} }
}

#       properties() - return a flated hash with all the properties
sub properties {
    my $self = shift;
    my %p = $self->_properties;
    map { $_ => $p{$_} } $self->_sort_keys(keys %p);
}



#	getProperties() - Return a hashref of all of the properties
sub getProperties { return { shift->_properties }; }


#	getFormat() - Return the output format for the properties
sub getFormat { shift->{format} }


#	setFormat() - Set the output format for the properties
sub setFormat {
    my ($self, $format) = @_;
    defined $format or $format='%s=%s';
    _t_format $format;
    $self->{format} = $format;
}

#	format() - Alias for get/setFormat();
sub format {
    my $self = shift;
    if (@_) {
	return $self->setFormat(@_)
    }
    $self->getFormat();
}


#       setValidator(\&validator) - Set sub to be called to validate
#                property/value pairs.  It is called
#                &validator($property, $value, $config) being $config
#                the Config::Properties object.  $property and $key
#                can be modified by the validator via $_[0] and $_[1]
sub setValidator {
    my ($self, $validator) = @_;
    _t_validator $validator;
    $self->{validator} = $validator;
}


#       getValidator() - Return the current validator sub
sub getValidator { shift->{validator} }

#       validator() - Alias for get/setValidator();
sub validator {
    my $self=shift;
    if (@_) {
	return $self->setValidator(@_)
    }
    $self->getValidator
}

sub setOrder {
    my ($self, $order) = @_;
    _t_order $order;
    $self->{order} = $order
}

sub getOrder { shift->{order} }

sub order {
    my $self = shift;
    $self->setOrder(@_) if @_;
    $self->{order};
}

#	load() - Load the properties from a filehandle
sub load {
    my ($self, $file) = @_;
    _t_file $file;

    # check whether it is a real file handle
    my $fn = do {
        local $@;
        eval { fileno($file) }
    };
    if (defined $fn and $fn >0) {
        unless (grep /^(?:encoding|utf8)\b/, PerlIO::get_layers($file)) {
            binmode $file, ":encoding($self->{encoding})"
                or croak "Unable to set file encoding layer: $!";
        }
    }
    $self->{properties} = {};
    $self->{property_line_numbers} = {};
    my $ln = $file->input_line_number;
    $self->{last_line_number} = ($ln > 0 ? $ln : 0);
    $self->{buffer_in} = '';
    1 while $self->process_line($file);
    $self->{last_line_number};
}


#        escape_key(string), escape_value(string), unescape(string) -
#               subroutines to convert escaped characters to their
#               real counterparts back and forward.

my %esc = ( "\n" => 'n',
	    "\r" => 'r',
	    "\t" => 't' );
my %unesc = reverse %esc;

sub escape_key {
    $_[0]=~s{([\t\n\r\\"' =:])}{
	"\\".($esc{$1}||$1) }ge;
    $_[0]=~s{([^\x20-\x7e])}{sprintf "\\u%04x", ord $1}ge;
    $_[0]=~s/^ /\\ /;
    $_[0]=~s/^([#!])/\\$1/;
    $_[0]=~s/(?<!\\)((?:\\\\)*) $/$1\\ /;
}

sub escape_value {
    $_[0]=~s{([\t\n\r\\])}{
	"\\".($esc{$1}||$1) }ge;
    $_[0]=~s{([^\x20-\x7e])}{sprintf "\\u%04x", ord $1}ge;
    $_[0]=~s/^ /\\ /;
}

sub unescape {
    $_[0]=~s/\\([tnr\\"' =:#!])|\\u([\da-fA-F]{4})/
	defined $1 ? $unesc{$1}||$1 : chr hex $2 /ge;
}

sub read_line {
    my ($self, $file) = @_;
    my $bin = \$self->{buffer_in};
    my $line_re = $self->{line_re};
    while (1) {
        if ($$bin =~ s/$line_re//) {
            $self->{last_line_number}++;
            return $1;
        }
        else {
            my $bytes = read($file, $$bin, 8192, length $$bin);
            last unless $bytes or (not defined $bytes and
                                   ($! == Errno::EGAIN()       or
                                    $! == Errno::EWOULDBLOCK() or
                                    $! == Errno::EINTR()));
        }
    }

    if (length $$bin) {
        $self->{last_line_number}++;
        my $line = $$bin;
        $$bin = '';
        return $line
    }
    undef;
}


#	process_line() - read and parse a line from the properties file.

# this is to workaround a bug in perl 5.6.0 related to unicode
my $bomre = eval(q< qr/^\\x{FEFF}/ >) || qr//;

sub process_line {
    my ($self, $file) = @_;
    my $line = $self->read_line($file);
    defined $line or return undef;

    # remove utf8 byte order mark
    my $ln = $self->{last_line_number};
    $line =~ s/$bomre// if $ln < 2;

    # ignore comments
    $line =~ /^\s*(\#|\!|$)/ and return 1;

    # handle continuation lines
    my @lines;
    while ($line =~ /(\\+)$/ and length($1) & 1) {
	$line =~ s/\\$//;
	push @lines, $line;
	$line = $self->read_line($file);
        $line = '' unless defined $line;
	$line =~ s/^\s+//;
    }
    $line = join('', @lines, $line) if @lines;

    my ($key, $value) = $line =~ /^
				  \s*
				  ((?:[^\s:=\\]|\\.)+)
				  \s*
				  [:=\s]
				  \s*
				  (.*)
				  $
				  /x
       or $self->fail("invalid property line '$line'");

    unescape $key;
    unescape $value;

    $self->validate($key, $value);

    $self->{property_line_numbers}{$key} = $ln;
    $self->{properties}{$key} = $value;

    return 1;
}

sub validate {
    my $self=shift;
    my $validator = $self->{validator};
    if (defined $validator) {
	&{$validator}(@_, $self) or $self->fail("invalid value '$_[1]' for '$_[0]'");
    }
}


#       line_number() - number for the last line read from the configuration file
sub line_number { shift->{last_line_number} }


#       fail(error) - report errors in the configuration file while reading.
sub fail {
    my ($self, $error) = @_;
    die "$error at line ".$self->line_number()."\n";
}

sub _sort_keys {
    my $self = shift;
    my $order = $self->{order};
    if ($order eq 'keep') {
        my $sk = $self->{property_line_numbers};
        no warnings 'uninitialized';
        return sort { $sk->{$a} <=> $sk->{$b} } @_;
    }
    if ($order eq 'alpha') {
        return sort @_;
    }
    return @_;
}

#	_save() - Utility function that performs the actual saving of
#		the properties file to a filehandle.
sub _save {
    my ($self, $file) = @_;
    _t_file $file;

    my $wrap;
    if ($self->{wrap}) {
        eval {
            no warnings;
            require Text::Wrap;
            $wrap=($Text::Wrap::VERSION >= 2001.0929);
        };
        unless ($wrap) {
            warnings::warn("Text::Wrap module is to old, version 2001.0929 or newer required: long lines will not be wrapped");
        }
    }

    local($Text::Wrap::separator)=" \\\n"       if $wrap;
    local($Text::Wrap::unexpand)=undef          if $wrap;
    local($Text::Wrap::huge)='overflow'         if $wrap;
    local($Text::Wrap::break)=qr/(?<!\\) (?! )/ if $wrap;

    foreach ($self->_sort_keys(keys %{$self->{properties}})) {
	my $key=$_;
	my $value=$self->{properties}{$key};
	escape_key $key;
	if ($self->{be_like_java}) {
            escape_key $value;
        }
        else {
            escape_value $value;
        }

	if ($wrap) {
	    $file->print( Text::Wrap::wrap( "",
					    "    ",
					    sprintf( $self->{'format'},
						     $key, $value ) ),
			  "\n" );
	}
	else {
	    $file->print(sprintf( $self->{'format'}, $key, $value ), "\n")
	}
    }
}


#	save() - Save the properties to a filehandle with the given header.
sub save {
    my ($self, $file, $header) = @_;
    _t_file($file);

    if (defined $header) {
	$header=~s/\n/# \n/sg;
	print $file "# $header\n#\n";
    }
    print $file '# ' . localtime() . "\n\n";
    $self->_save( $file );
}

sub saveToString {
    my $self = shift;
    my $str = '';
    open my $fh, '>', \$str
	or die "unable to open string ref as file";
    $self->save($fh, @_);
    close $fh
	or die "unable to write to in memory file";
    return $str;
}

sub _split_to_tree {
    my ($self, $tree, $re, $start) = @_;
    if (defined $self->{defaults}) {
	$self->{defaults}->_split_to_tree($tree, $re, $start);
    }
    for my $key (keys %{$self->{properties}}) {
        my $ekey = $key;

        if (defined $start) {
            $ekey =~ s/$start// or next;
        }

	my @parts = split $re, $ekey;
	@parts = '' unless @parts;
	my $t = $tree;
	while (@parts) {
	    my $part = shift @parts;
	    my $old = $t->{$part};

	    if (@parts) {
		if (defined $old) {
		    if (ref $old) {
			$t = $old;
		    }
		    else {
			$t = $t->{$part} = { '' => $old };
		    }
		}
		else {
		    $t = $t->{$part} = {};
		}
	    }
	    else {
		my $value = $self->{properties}{$key};
		if (ref $old) {
		    $old->{''} = $value;
		}
		else {
		    $t->{$part} = $value;
		}
	    }
	}
    }
}

sub splitToTree {
    my ($self, $re, $start) = @_;
    $re = qr/\./ unless defined $re;
    $re = qr/$re/ unless ref $re;
    if (defined $start) {
        $start = quotemeta $start;
        $start = qr/^$start$re/
    }
    my $tree = {};
    $self->_split_to_tree($tree, $re, $start);
    $tree;
}

sub _unsplit_from_tree {
    my ($self, $method, $tree, $sep, @start) = @_;
    $sep = '.' unless defined $sep;
    my $ref = ref $tree;
    if ($ref eq 'HASH') {
        for my $key (keys %$tree) {
            $self->_unsplit_from_tree($method, $tree->{$key}, $sep,
                               @start, ($key ne '' ? $key : ()))
        }
    }
    elsif ($ref eq 'ARRAY') {
        for my $key (0..$#$tree) {
            $self->_unsplit_from_tree($method, $tree->[$key], $sep, @start, $key)
        }
    }
    elsif ($ref) {
        croak "unexpected object '$ref' found inside tree"
    }
    else {
        $self->$method(join($sep, @start), $tree)
    }
}

sub setFromTree { shift->_unsplit_from_tree(setProperty => @_) }
sub changeFromTree { shift->_unsplit_from_tree(changeProperty => @_) }

#	store() - Synonym for save()
*store = \&save;

#	getProperty() - Return the value of a property key. Returns the default
#		for that key (if there is one) if no value exists for that key.
sub getProperty {
    my $self = shift;
    my $key = shift;
    _t_key $key;

    if (exists $self->{properties}{$key}) {
	return $self->{properties}{$key}
    }
    elsif (defined $self->{defaults}) {
	return $self->{defaults}->getProperty($key, @_);
    }
    for (@_) {
	return $_ if defined $_
    }
    undef
}

sub requireProperty {
    my $this = shift;
    my $prop = $this->getProperty(@_);
    defined $prop
	or die "required property '$_[0]' not found on configuration file\n";
    return $prop;
}

sub _property_line_number {
    my ($self, $key)=@_;
    $self->{property_line_numbers}{$key}
}


#	propertyName() - Returns an array of the keys of the Properties
sub propertyNames {
    my $self = shift;
    my %p = $self->_properties;
    $self->_sort_keys(keys %p);
}


1;
__END__

=head1 NAME

Config::Properties - Read and write property files

=head1 SYNOPSIS

  use Config::Properties;

  # reading...

  open my $fh, '<', 'my_config.props'
    or die "unable to open configuration file";

  my $properties = Config::Properties->new();
  $properties->load($fh);

  $value = $properties->getProperty($key);


  # saving...

  open my $fh, '>', 'my_config.props'
    or die "unable to open configuration file for writing";

  $properties->setProperty($key, $value);

  $properties->format('%s => %s');
  $properties->store($fh, $header );


=head1 DESCRIPTION

Config::Properties is a near implementation of the
java.util.Properties API.  It is designed to allow easy reading,
writing and manipulation of Java-style property files.

The format of a Java-style property file is that of a key-value pair
separated by either whitespace, the colon (:) character, or the equals
(=) character.  Whitespace before the key and on either side of the
separator is ignored.

Lines that begin with either a hash (#) or a bang (!) are considered
comment lines and ignored.

A backslash (\) at the end of a line signifies a continuation and the
next line is counted as part of the current line (minus the backslash,
any whitespace after the backslash, the line break, and any whitespace
at the beginning of the next line).

The official references used to determine this format can be found in
the Java API docs for java.util.Properties at
L<http://java.sun.com/j2se/1.5.0/docs/api/java/util/Properties.html>.

When a property file is saved it is in the format "key=value" for each
line. This can be changed by setting the format attribute using either
$object->format( $format_string ) or $object->setFormat(
$format_string ) (they do the same thing). The format string is fed to
printf and must contain exactly two %s format characters. The first
will be replaced with the key of the property and the second with the
value. The string can contain no other printf control characters, but
can be anything else. A newline will be automatically added to the end
of the string. The current format string can be obtained by using
$object->format() (with no arguments) or $object->getFormat().

If a recent version of L<Text::Wrap> is available, long lines are
conveniently wrapped when saving.

=head1 METHODS

C<Config::Property> objects have this set of methods available:

=over 4

=item Config::Properties-E<gt>new(%opts)

Creates a new Config::Properties object.

The optional arguments are as follows:

=over 4

=item file => $filename

Opens and reads the entries from the given properties file

=item format => $format

Sets the format using for saving the properties to a file. See
L</setFormat>.

=item wrap => 0

Disables wrapping of long lines when saving the properties to a file.

=item defaults => $defaults

Default configuration values.

The given parameter can be a hash reference or another
Config::Properties object.

In that way several configuration objects can be chained. For
instance:

  my %defaults = (...);
  my $global_config = Config::Properties->new(file => '/etc/foo.properties',
                                              defaults => \%defaults);
  my $user_config = Config::Properties->new(file => '/home/jsmith/.foo/foo.properties',
                                            defaults => $global_config);

=item order => 'keep'|'alpha'|'none'

Sets how to order the properties when saved to a file or when returned
by C<properties> and C<propertyNames> methods.

C<alpha> sorts the keys in alphanumeric order. C<keep> keeps the order
of the properties as added or read from a file. C<none> returns the
properties unordered.

=item encoding => $encoding

IO encoding used to read the configuration file. See L<PerlIO>.

When C<load> is called the given encoding is used unless the file
handler already has a encoding layer applied.

C<latin1> is used as the default encoding (as specified in the Java
properties specification).

=item be_like_java => 1

When this feature is enabled, the module will try to mimic the Java
implementation as much as possible when saving files.

Currently, some escaping rules are changed and line wrapping is
disabled.

=back

=item Config::Properties-E<gt>new($defaults)

Calling C<new> in this way is deprecated.

=item $p-E<gt>getProperty($k, $default, $default2, ...)

return property C<$k> or when not defined, the first defined
C<$default*>.

=item $p-E<gt>requireProperty($k, $default, $default2, ...)

this method is similar to C<getProperty> but dies if the requested
property is not found.

=item $p-E<gt>setProperty($k, $v)

set property C<$k> value to C<$v>.

=item $p-E<gt>changeProperty($k, $v)

=item $p-E<gt>changeProperty($k, $v, $default, $default2, ...)

method similar to C<setPropery> but that does nothing when the new
value is equal to the one returned by C<getProperty>.

An example shows why it is useful:

  my $defaults=Config::Properties->new();
  $defaults->setProperty(foo => 'bar');

  my $p1=Config::Properties->new($defaults);
  $p1->setProperty(foo => 'bar');   # we set here!
  $p1->store(FILE1); foo gets saved on the file

  my $p2=Config::Properties->new($defaults);
  $p2->changeProperty(foo => 'bar'); # does nothing!
  $p2->store(FILE2); # foo doesn't get saved on the file

=item $p-E<gt>deleteProperty($k)

=item $p-E<gt>deleteProperty($k, $recurse)

deletes property $k from the object.

If C<$recurse> is true, it also deletes any C<$k> property from the
default properties object.

=item $p-E<gt>properties

returns a flatten hash with all the property key/value pairs, i.e.:

  my %props=$p->properties;

=item $p-E<gt>getProperties

returns a hash reference with all the properties (including those passed as defaults).

=item $p-E<gt>propertyNames;

returns the names of all the properties (including those passed as defaults).

=item $p-E<gt>splitToTree()

=item $p-E<gt>splitToTree($regexp)

=item $p-E<gt>splitToTree($regexp, $start)

builds a tree from the properties, splitting the keys with the regular
expression C<$re> (or C</\./> by default). For instance:

  my $data = <<EOD;
  name = pete
  date.birth = 1958-09-12
  date.death = 2004-05-11
  surname = moo
  surname.length = 3
  EOD

  open my $fh, '<', \$data;
  $cfg->load();
  my $tree = $cfg->splitToTree();

makes...

  $tree = { date => { birth => '1958-09-12',
                      death => '2004-05-11' },
            name => 'pete',
            surname => { '' => 'moo',
                         length => '3' } };



The C<$start> parameter allows to split only a subset of the
properties. For instance, with the same data as on the previous
example:

   my $subtree = $cfg->splitToTree(qr/\./, 'date');

makes...

  $tree = { birth => '1958-09-12',
            death => '2004-05-11' };

=item $p-E<gt>setFromTree($tree)

=item $p-E<gt>setFromTree($tree, $separator)

=item $p-E<gt>setFromTree($tree, $separator, $start)

This method sets properties from a tree of Perl hashes and arrays. It
is the opposite of C<splitToTree>.

C<$separator> is the string used to join the parts of the property
names. The default value is a dot (C<.>).

C<$start> is a string used as the starting point for the property
names.

For instance:

  my $c = Config::Properties->new;
  $c->setFromTree( { foo => { '' => one,
                              hollo => [2, 3, 4, 1] },
                     bar => 'doo' },
                   '->',
                   'mama')

  # sets properties:
  #      mama->bar = doo
  #      mama->foo = one
  #      mama->foo->hollo->0 = 2
  #      mama->foo->hollo->1 = 3
  #      mama->foo->hollo->2 = 4
  #      mama->foo->hollo->3 = 1


=item $p-E<gt>changeFromTree($tree)

=item $p-E<gt>changeFromTree($tree, $separator)

=item $p-E<gt>changeFromTree($tree, $separator, $start)

similar to C<setFromTree> but internally uses C<changeProperty>
instead of C<setProperty> to set the property values.


=item $p-E<gt>load($file)

loads properties from the open file C<$file>.

Old properties on the object are discarded.

=item $p-E<gt>save($file)

=item $p-E<gt>save($file, $header)

=item $p-E<gt>store($file)

=item $p-E<gt>store($file, $header)

save the properties to the open file C<$file>. Default properties are
not saved.

=item $p-E<gt>saveToString($header)

similar to C<save>, but instead of saving to a file, it returns a
string with the content.

=item $p-E<gt>getFormat()

=item $p-E<gt>setFormat($f)

X<setFormat>get/set the format string used when saving the object to a file.

=back

=head1 SEE ALSO

Java docs for C<java.util.Properties> at
L<http://java.sun.com/j2se/1.3/docs/api/index.html>.

L<Config::Properties::Simple> for a simpler alternative interface to
L<Config::Properties>.

=head1 TODO

Add support for derived format as supported by Java class
org.apache.commons.configuration.PropertiesConfiguration
(L<http://commons.apache.org/configuration/apidocs/org/apache/commons/configuration/PropertiesConfiguration.html>)

=head1 AUTHORS

C<Config::Properties> was originally developed by Randy Jay Yarger. It
was maintained for some time by Craig Manley and finally it passed
hands to Salvador FandiE<ntilde>o <sfandino@yahoo.com>, the current
maintainer.

=head1 COPYRIGHT AND LICENSE

Copyright 2001, 2002 by Randy Jay Yarger
Copyright 2002, 2003 by Craig Manley.
Copyright 2003-2009, 2011-2012, 2014-2015 by Salvador FandiE<ntilde>o.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
