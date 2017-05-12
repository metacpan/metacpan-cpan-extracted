package Config::Ant;
BEGIN {
  $Config::Ant::VERSION = '0.01';
}

# ABSTRACT: Load Ant-style property files

use strict; 
use warnings;

use Carp;
use Scalar::Util qw(openhandle);
use File::Slurp qw(read_file);

sub new {
    my ($this, @initial) = @_;
    my $class = ref($this) || $this;
    my $self = {@initial};
    bless $self, $class;
    return $self;
}

sub read {
    my ($self, $file) = @_;
	my $contents = File::Slurp::read_file($file);
	$self->read_string($contents);
}

sub read_line {
    my ($self, $section, $key, $value) = @_;
    
    return if (exists($self->{$section}->{$key}));

    $value =~ s/\$\{([^}]+)\}/
        if (! exists($self->{$section}->{$1})) {
            '${'.$1.'}';
        } else {
            $self->{$section}->{$1};
        } /eg;

    $self->{$section}->{$key} = $value;
}

# This has been cobbled from Config::Tiny. Most of the rest has been
# written directly using additional dependencies. 

sub read_string {
    my ($self, $contents) = @_;

	# Parse the file
	my $ns      = '_';
	my $counter = 0;
	foreach ( split /(?:\015{1,2}\012|\015|\012)/, $contents ) {
		$counter++;

		# Skip comments and empty lines
		next if /^\s*(?:\#|\;|$)/;

		# Remove inline comments
		s/\s\;\s.+$//g;

		# Handle section headers
		if ( /^\s*\[\s*(.+?)\s*\]\s*$/ ) {
			# Create the sub-hash if it doesn't exist.
			# Without this sections without keys will not
			# appear at all in the completed struct.
			$self->{$ns = $1} ||= {};
			next;
		}

		# Handle properties
		if ( /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
		    $self->read_line($ns, $1, $2);
			next;
		}

		return $self->_error( "Syntax error at line $counter: '$_'" );
	}

	$self;
}

sub write {
    my ($self, $file) = @_;

    my $opened = 0;
    if (! openhandle($file)) {
        open($file, '>', $file) or croak("Failed to open file '$file' for writing: $!");
        $opened = 1;
    }
    
    print $file $self->write_string();
    close($file) if ($opened);
    return;
}

# Again, this bit was cobbled from Config::Tiny. 

sub write_string {
    my ($self) = @_;

	my $contents = '';
	foreach my $section ( sort { (($b eq '_') <=> ($a eq '_')) || ($a cmp $b) } keys %$self ) {
		my $block = $self->{$section};
		$contents .= "\n" if length $contents;
		$contents .= "[$section]\n" unless $section eq '_';
		foreach my $property ( sort keys %$block ) {
			$contents .= "$property=$block->{$property}\n";
		}
	}
	
	$contents;
}

1;

=head1 NAME

Config::Ant - load Ant-style property files

=head1 SYNOPSIS

  # In your configuration file
  root.directory = /usr/local

  lib = ${root.directory}/lib
  bin = ${root.directory}/lib
  perl = ${bin}/perl
  
  # In your program
  use Config::Ant;
  
  # Create a config
  my $config = Config::Ant->new();

  # Read the config
  $config->read('file1.conf');
  
  # You can also read a second file, with properties substituted from the first
  $config->read('file2.conf');
  
  my $rootdir = $config->{_}->{'root.directory'};
  my $perl = $config->{_}->{perl};
  
  # Writing ignores substitutions
  $config->write('files.conf');
  
=head1 DESCRIPTION

Apache Ant uses property files with substitutions in them, which are very helpful for maintaining
a complex set of related properties. This component is a subclass of L<Config::Tiny> which includes
the Ant-style substitution systems. 

Ant properties are set by their first definition and are then immutable, so a second definition
will not affect anything, ever. This is handy, as you can override settings by putting local values
first, and the loading files of defaults. 

Note that the usage interface is I<not> identical to L<Config::Tiny>. This is because L<Config::Tiny> 
assumes that each file is self-contained, and constructs a new object for it. This does not make
sense for Ant-style files, which are often loaded from several files, allowing for local customization.

Also not that the file format is I<not> identical to Ant, in that like L<Config::Tiny>, 
Config::Ant allows "windows style" sections to be used. This can be handy, but it's an optional extra
that will only annoy you if you use property names containing [ or ], which would be a very 
bad move. 

=head1 METHODS

=over 4

=item Config::Ant->new()

Returns a new property file processing instance, which can then be used as a container for 
properties read and written through the other methods.  

=item read($file)

Reads a file (or file handle) into the property system. This reads the text and passes the string to
C<read_string()>. This method can be called many times for a single instance, and this is common
when you want to handle several property files. The first property sets always wins, and there is 
no method defined to allow properties to be removed. 

=item read_string($text)

Reads and processes the properties a line at a time. Comment lines and blanks are skipped, sections
are set, and property lines passed to C<read_line()>

=item read_line($section, $property, $value)

This sets the property, and can be overridden if required. The property will only be set if a value
doesn't exist. The default method also handles the substitution of existing values into the value.

=item write($file)

Opens the file for writing, if necessary (i.e., not a file handle) and then writes out all the 
current properties, using C<write_string()> to obtain the stringified property file text.

=item write_string()

Returns the stringified text for all the properties currently registered. 

=back

=head1 AUTHOR

Stuart Watt E<lt>stuart@morungos.comE<gt>

=head1 COPYRIGHT

Copyright 2010 by the authors.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Partly based on L<Config::Tiny>. 

=cut
