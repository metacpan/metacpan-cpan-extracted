package Config::Tiny;

# If you thought Config::Simple was small...

use strict;
use 5.008001; # For the utf8 stuff.

# Warning: There is another version line, in t/02.main.t.

our $VERSION = '2.30';

BEGIN {
	$Config::Tiny::errstr  = '';
}

# Create an object.

sub new { return bless defined $_[1] ? $_[1] : {}, $_[0] }

# Create an object from a file.

sub read
{
	my($class)           = ref $_[0] ? ref shift : shift;
	my($file, $encoding) = @_;

	return $class -> _error('No file name provided') if (! defined $file || ($file eq '') );

	# Slurp in the file.

	$encoding = $encoding ? "<:$encoding" : '<';
	local $/  = undef;

	open(my $CFG, $encoding, $file) or return $class -> _error( "Failed to open file '$file' for reading: $!" );
	my $contents = <$CFG>;
	close($CFG );

	return $class -> _error("Reading from '$file' returned undef") if (! defined $contents);

	return $class -> read_string( $contents );

} # End of read.

# Create an object from a string.

sub read_string
{
	my($class) = ref $_[0] ? ref shift : shift;
	my($self)  = bless {}, $class;

	return undef unless defined $_[0];

	# Parse the file.

	my $ns      = '_';
	my $counter = 0;

	foreach ( split /(?:\015{1,2}\012|\015|\012)/, shift )
	{
		$counter++;

		# Skip comments and empty lines.

		next if /^\s*(?:\#|\;|$)/;

		# Remove inline comments.

		s/\s\;\s.+$//g;

		# Handle section headers.

		if ( /^\s*\[\s*(.+?)\s*\]\s*$/ )
		{
			# Create the sub-hash if it doesn't exist.
			# Without this sections without keys will not
			# appear at all in the completed struct.

			$self->{$ns = $1} ||= {};

			next;
		}

		# Handle properties.

		if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ )
		{
			if ( substr($1, -2) eq '[]' )
			{
				my $k = substr $1, 0, -2;
				$self->{$ns}->{$k} ||= [];
				return $self -> _error ("Can't mix arrays and scalars at line $counter" ) unless ref $self->{$ns}->{$k} eq 'ARRAY';
				push @{$self->{$ns}->{$k}}, $2;
				next;
			}
			$self->{$ns}->{$1} = $2;

			next;
		}

		return $self -> _error( "Syntax error at line $counter: '$_'" );
	}

	return $self;
}

# Save an object to a file.

sub write
{
	my($self)            = shift;
	my($file, $encoding) = @_;

	return $self -> _error('No file name provided') if (! defined $file or ($file eq '') );

	$encoding = $encoding ? ">:$encoding" : '>';

	# Write it to the file.

	my($string) = $self->write_string;

	return undef unless defined $string;

	open(my $CFG, $encoding, $file) or return $self->_error("Failed to open file '$file' for writing: $!");
	print $CFG $string;
	close($CFG);

	return 1;

} # End of write.

# Save an object to a string.

sub write_string
{
	my($self)     = shift;
	my($contents) = '';

	for my $section ( sort { (($b eq '_') <=> ($a eq '_')) || ($a cmp $b) } keys %$self )
	{
		# Check for several known-bad situations with the section
		# 1. Leading whitespace
		# 2. Trailing whitespace
		# 3. Newlines in section name.

		return $self->_error("Illegal whitespace in section name '$section'") if $section =~ /(?:^\s|\n|\s$)/s;

		my $block = $self->{$section};
		$contents .= "\n" if length $contents;
		$contents .= "[$section]\n" unless $section eq '_';

		for my $property ( sort keys %$block )
		{
			return $self->_error("Illegal newlines in property '$section.$property'") if $block->{$property} =~ /(?:\012|\015)/s;

			if (ref $block->{$property} eq 'ARRAY') {
				for my $element ( @{$block->{$property}} )
				{
					$contents .= "${property}[]=$element\n";
				}
				next;
			}
			$contents .= "$property=$block->{$property}\n";
		}
	}

	return $contents;

} # End of write_string.

# Error handling.

sub errstr { $Config::Tiny::errstr }
sub _error { $Config::Tiny::errstr = $_[1]; undef }

1;

__END__

=pod

=head1 NAME

Config::Tiny - Read/Write .ini style files with as little code as possible

=head1 SYNOPSIS

	# In your configuration file
	rootproperty=blah

	[section]
	one=twp
	greetings[]=Hello
	three= four
	Foo =Bar
	greetings[]=World!
	empty=

	# In your program
	use Config::Tiny;

	# Create an empty config
	my $Config = Config::Tiny->new;

	# Create a config with data
	my $config = Config::Tiny->new({
		_ => { rootproperty => "Bar" },
		section => { one => "value", Foo => 42 } });

	# Open the config
	$Config = Config::Tiny->read( 'file.conf' );
	$Config = Config::Tiny->read( 'file.conf', 'utf8' ); # Neither ':' nor '<:' prefix!
	$Config = Config::Tiny->read( 'file.conf', 'encoding(iso-8859-1)');

	# Reading properties
	my $rootproperty = $Config->{_}->{rootproperty};
	my $one = $Config->{section}->{one};
	my $Foo = $Config->{section}->{Foo};

	# Changing data
	$Config->{newsection} = { this => 'that' }; # Add a section
	$Config->{section}->{Foo} = 'Not Bar!';     # Change a value
	delete $Config->{_};                        # Delete a value or section

	# Save a config
	$Config->write( 'file.conf' );
	$Config->write( 'file.conf', 'utf8' ); # Neither ':' nor '>:' prefix!

	# Shortcuts
	my($rootproperty) = $$Config{_}{rootproperty};

	my($config) = Config::Tiny -> read_string('alpha=bet');
	my($value)  = $$config{_}{alpha}; # $value is 'bet'.

	my($config) = Config::Tiny -> read_string("[init]\nalpha=bet");
	my($value)  = $$config{init}{alpha}; # $value is 'bet'.

=head1 DESCRIPTION

C<Config::Tiny> is a Perl class to read and write .ini style configuration
files with as little code as possible, reducing load time and memory overhead.

Most of the time it is accepted that Perl applications use a lot of memory and modules.

The C<*::Tiny> family of modules is specifically intended to provide an ultralight alternative
to the standard modules.

This module is primarily for reading human written files, and anything we write shouldn't need to
have documentation/comments. If you need something with more power move up to L<Config::Simple>,
L<Config::General> or one of the many other C<Config::*> modules.

Lastly, L<Config::Tiny> does B<not> preserve your comments, whitespace, or the order of your config
file.

See L<Config::Tiny::Ordered> (and possibly others) for the preservation of the order of the entries
in the file.

=head1 CONFIGURATION FILE SYNTAX

Files are the same format as for MS Windows C<*.ini> files. For example:

	[section]
	var1=value1
	var2=value2

But see also ARRAY SYNTAX just below.

If a property is outside of a section at the beginning of a file, it will
be assigned to the C<"root section">, available at C<$Config-E<gt>{_}>.

Lines starting with C<'#'> or C<';'> are considered comments and ignored,
as are blank lines.

When writing back to the config file, all comments, custom whitespace,
and the ordering of your config file elements are discarded. If you need
to keep the human elements of a config when writing back, upgrade to
something better, this module is not for you.

=head1 ARRAY SYNTAX

=head2 Basic Syntax

As of V 2.30, this module supports the case of a key having an array of values.

Sample data (copied from t/test.conf):

	root=something

	[section]
	greetings[]=Hello
	one=two
	Foo=Bar
	greetings[]=World!
	this=Your Mother!
	blank=

	[Section Two]
	something else=blah
	 remove = whitespace

Note specifically that the key name greetings has the empty bracket pair [] as a suffix.
This tells the code that it is not to overwrite the 1st value with the 2nd value, but
rather to push these values onto a stack called 'greetings'.

Note also that you could have used:

	[section]
	greetings[]=Hello
	greetings[]=World!
	one=two
	Foo=Bar
	this=Your Mother!
	blank=

Clearly, the 2 lines using greetings[] do not have to be side-by-side.

If you use e.g. Data::Dumper::Concise to give you a Dumper() function (not method), then
'say Dumper($Config)' the output will look like:

	bless( {
	  "Section Two" => {
	     remove => "whitespace",
	     "something else" => "blah",
	   },
	   _ => {
	     root => "something",
	   },
	   section => {
	     Foo => "Bar",
	     blank => "",
	     greetings => [
	       "Hello",
	       "World!",
	     ],
	     one => "two",
	     this => "Your Mother!",
	   },
	 }, 'Config::Tiny' )

You can see this structure in t/02.main.t starting at line 45. Observe too that the key names are
reported in alphabetical order (by the module Data::Dumper::Concise) despite the differing order
in the setting of these keys, and that the array syntax result is that greetings has an array
for a value.

To access these values, use code like this:

	Dumper($Config);
	Dumper($Config->{section});
	Dumper($Config->{section}->{greetings});
	Dumper($Config->{section}->{greetings}->[0]);
	Dumper($Config->{section}->{greetings}->[1]);
	Dumper(ref $Config);

=head2 Warning

$Config is a blessed value, which means it is accessed differently than if it was
a hash ref. The latter could be accessed as:

	Dumper($$Config{section}{greetings}); # Don't do this for blessed values!

Finally, if a hash ref rather than a blessed value, you could also use, as above:

	Dumper($Config->{section}->{greetings}); # Don't do this for blessed values!

My (Ron Savage) personal preference for hashrefs is the one without the gross '->' chars,
but that requires you to double up the initial $ character (which I hope you noticed!).

=head1 METHODS

=head2 errstr()

Returns a string representing the most recent error, or the empty string.

You can also retrieve the error message from the C<$Config::Tiny::errstr> variable.

=head2 new([$config])

Here, the [] indicate an optional parameter.

The constructor C<new> creates and returns a C<Config::Tiny> object.

This will normally be a new, empty configuration, but you may also pass a
hashref here which will be turned into an object of this class. This hashref
should have a structure suitable for a configuration file, that is, a hash of
hashes where the key C<_> is treated specially as the root section.

=head2 read($filename, [$encoding])

Here, the [] indicate an optional parameter.

The C<read> constructor reads a config file, $filename, and returns a new
C<Config::Tiny> object containing the properties in the file.

$encoding may be used to indicate the encoding of the file, e.g. 'utf8' or 'encoding(iso-8859-1)'.

Do not add a prefix to $encoding, such as '<' or '<:'.

Returns the object on success, or C<undef> on error.

When C<read> fails, C<Config::Tiny> sets an error message internally
you can recover via C<Config::Tiny-E<gt>errstr>. Although in B<some>
cases a failed C<read> will also set the operating system error
variable C<$!>, not all errors do and you should not rely on using
the C<$!> variable.

See t/04.utf8.t and t/04.utf8.txt.

=head2 read_string($string)

The C<read_string> method takes as argument the contents of a config file
as a string and returns the C<Config::Tiny> object for it.

=head2 write($filename, [$encoding])

Here, the [] indicate an optional parameter.

The C<write> method generates the file content for the properties, and
writes it to disk to the filename specified.

$encoding may be used to indicate the encoding of the file, e.g. 'utf8' or 'encoding(iso-8859-1)'.

Do not add a prefix to $encoding, such as '>' or '>:'.

Returns true on success or C<undef> on error.

See t/04.utf8.t and t/04.utf8.txt.

=head2 write_string()

Generates the file content for the object and returns it as a string.

=head1 FAQ

=head2 What happens if a key is repeated?

Case 1: The last value is retained, overwriting any previous values.

See t/06.repeat.key.t for sample code.

Case 2: However, by using the new array syntax, as of V 2.30, you can assign a set of
values to a key.

For details, see the L</ARRAY SYNTAX> section above for sample code.

See t/test.conf for sample data.

=head2 Why can't I put comments at the ends of lines?

=over 4

=item o The # char is only introduces a comment when it's at the start of a line.

So a line like:

	key=value # A comment

Sets key to 'value # A comment', which, presumably, you did not intend.

This conforms to the syntax discussed in L</CONFIGURATION FILE SYNTAX>.

=item o Comments matching /\s\;\s.+$//g; are ignored.

This means you can't preserve the suffix using:

	key = Prefix ; Suffix

Result: key is now 'Prefix'.

But you can do this:

	key = Prefix;Suffix

Result: key is now 'Prefix;Suffix'.

Or this:

	key = Prefix; Suffix

Result: key is now 'Prefix; Suffix'.

=back

See t/07.trailing.comment.t.

=head2 Why can't I omit the '=' signs?

E.g.:

	[Things]
	my =
	list =
	of =
	things =

Instead of:

	[Things]
	my
	list
	of
	things

Because the use of '=' signs is a type of mandatory documentation. It indicates that that section
contains 4 items, and not 1 odd item split over 4 lines.

=head2 Why do I have to assign the result of a method call to a variable?

This question comes from RT#85386.

Yes, the syntax may seem odd, but you don't have to call both new() and read_string().

Try:

	perl -MData::Dumper -MConfig::Tiny -E 'my $c=Config::Tiny->read_string("one=s"); say Dumper $c'

Or:

	my($config) = Config::Tiny -> read_string('alpha=bet');
	my($value)  = $$config{_}{alpha}; # $value is 'bet'.

Or even, a bit ridiculously:

	my($value) = ${Config::Tiny -> read_string('alpha=bet')}{_}{alpha}; # $value is 'bet'.

=head2 Can I use a file called '0' (zero)?

Yes. See t/05.zero.t (test code) and t/0 (test data).

=head1 CAVEATS

Some edge cases in section headers are not supported, and additionally may not
be detected when writing the config file.

Specifically, section headers with leading whitespace, trailing whitespace,
or newlines anywhere in the section header, will not be written correctly
to the file and may cause file corruption.

=head1 Repository

L<https://github.com/ronsavage/Config-Tiny.git>

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<https://github.com/ronsavage/Config-Tiny/issues>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Maintanence from V 2.15: Ron Savage L<http://savage.net.au/>.

=head1 ACKNOWLEGEMENTS

Thanks to Sherzod Ruzmetov E<lt>sherzodr@cpan.orgE<gt> for
L<Config::Simple>, which inspired this module by being not quite
"simple" enough for me :).

=head1 SEE ALSO

See, amongst many: L<Config::Simple> and L<Config::General>.

See L<Config::Tiny::Ordered> (and possibly others) for the preservation of the order of the entries
in the file.

L<IOD>. Ini On Drugs.

L<IOD::Examples>

L<App::IODUtils>

L<Config::IOD::Reader>

L<Config::Perl::V>. Config data from Perl itself.

L<Config::Onion>

L<Config::IniFiles>

L<Config::INIPlus>

L<Config::Hash>. Allows nested data.

L<Config::MVP>. Author: RJBS. Uses Moose. Extremely complex.

L<Config::TOML>. See next few lines:

L<https://github.com/dlc/toml>

L<https://github.com/alexkalderimis/config-toml.pl>. 1 Star rating.

L<https://github.com/toml-lang/toml>

=head1 COPYRIGHT

Copyright 2002 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

