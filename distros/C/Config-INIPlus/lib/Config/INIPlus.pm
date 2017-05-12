package Config::INIPlus;

use warnings;
use strict;

use IO::File;
use IO::String;
use Scalar::Util qw(blessed);
use Carp qw(croak confess);

=head1 NAME

Config::INIPlus - Read and write INI-style config files with structure extensions

=cut

our $VERSION = '1.0.3';

# Some regexes we use for matching
my $sp   = qr/(?:[ ]|\t)+/;      # Space characters
my $osp  = qr/(?:[ ]|\t)*/;      # Optional space characters
my $eol  = qr/(?:\r?\n)/x;       # End of line
my $eolc = qr/(?:;.*)?$eol/x;    # End of line with optional comment

# Modes for calls to ->new
use constant TOP_MODE    => 0;    # When new is called non-recursively (i.e.,
                                  # from the topmost context)
use constant HASH_MODE   => 1;    # When processing a sub-hash
use constant ARRAY_MODE  => 2;    # When processing a sub-array
use constant STRING_MODE => 3;    # When processing a multi-line string

=head1 SYNOPSIS

INIPlus is a configurtion file format based on INI which supports multi-line
strings and nesting of arrays and hashes.  This is useful if you start a
project using INI files, but realize you need nested data in your
configurations and want to support extended configurations without
breaking backward compatibility with existing config files.

=head2 The INIPlus Config File

  ; Comment
  Key=Value ; End of line comment
  Key2="Multi
  Line
  Value" ; Post-multi-line comment
  
  [Section]
  Foo=This is a foo
  Hash {
    Bar=Hey it's a bar
    Baz="Is Baz at the bar?"
  }
  Array (
    Value One
    "Value Two"
    "Value
  Three
  Is multi-line!"
  )

The hashes and arrays can be nested any number of levels deep:

  Hash {
    ArrayOfSubhashes (
      {
        Key1=Val1
        Key2=Val2
      }
      {
        HeyAnotherArray (
          Value1
          Value2
          Value3
        )
      }
    )
  }
  
=head2 Creating a config object

  use Config::INIPlus;
  
  # Create the config object from a file
  $cfg = Config::INIPlus->new( file => 'foo.ini' ); 
  
  # Create the config object from a filehandle
  $filehandle = IO::File->new('file.ini');
  $cfg = Config::INIPlus->new( fh => $filehandle ); 
  
  # Create the config from a string
  $string = <<EOF;
  Key1=Val1
  Key2=Val2
  ; ...
  EOF
  
  $cfg = Config::INIPlus->new( string => $string );

=head2 Extracting the contents of a config object

  # Gets a non-sectioned value (like "Key2" in the example INI above)
  my $val = $cfg->get( 'KeyName' ); 
  
  # Gets a value from a section (e.g., "Foo" under "Section" in
  # the example above)
  my $val = $cfg->get( 'KeyName', 'SectionName' ); 
                                 
  # Gets the entire structure as a hash reference
  my $hash = $cfg->as_hashref(); 
  
  # Get one section as a hash reference (e.g., "Section" in the
  # exampe INI above)
  my $sec = $cfg->section_as_hashref( 'SectionName' );

=head2 Modifying a config object

  # Set a non-sectioned value
  $cfg->set( 'KeyName', 'KeyValue' );
  
  # Set a value for a key within a section
  $cfg->set( 'KeyName', 'KeyValue', 'SectionName' ); 
  
  # Remove a non-sectioned key (and respective value)
  $cfg->del( 'KeyName' );
  
  # Remove a sectioned key
  $cfg->del( 'KeyName', 'SectionName' );
  
  # Add a section
  $cfg->add_section( 'SectionName' ); 
  
  # Remove a section
  $cfg->del_section( 'SectionName' ); 
  
=head2 Getting the config object as text / writing to a file

  # Get the configuration as a string
  $string = $cfg->as_string; 
  
  # Write the configuration back into the file it was originally
  # read from
  $cfg->write;

  # Write the configuration to a specific file
  $cfg->write( 'filename.ini' );

=head1 METHODS

=head2 Config::INIPlus->new( file => 'filename' )

=head2 Config::INIPlus->new( fh => $perl_filehandle )

=head2 Config::INIPlus->new( string => $string_config )

Creates a new config object.  You can use a filename with the 'file' paramter,
a IO::Handle style filehandle using the 'fh', or pull from the entire INIPlus
configuration loaded into a string using the 'string' paramter.

=cut

sub new {

    my $pkg = shift;    # Package
    my %p   = @_;       # Parameters

    # Default some of the parameters
    unless ( defined $p{'debug'} ) { $p{'debug'} = 0; }
    unless ( defined $p{'file'} )  { $p{'file'}  = ''; }
    unless ( defined $p{'_mode'} ) { $p{'_mode'} = TOP_MODE; }

    # Are we being called from the topmost context without a filehandle?
    if ( ( $p{'_mode'} == TOP_MODE ) && ( not defined $p{'fh'} ) ) {
        if ( defined $p{'string'} ) {

            # Turn the string we've been passed into a filehandle
            $p{'fh'} = IO::String->new( $p{'string'}, 'r' );
            if ( not defined $p{'fh'} ) {
                croak "Error opening string $p{'string'}: $!";
            }
        }
        elsif ( $p{'file'} ) {

            # Open the filename we've been passed to a new filehandle
            $p{'fh'} = IO::File->new( $p{'file'}, 'r' );
            if ( not defined $p{'fh'} ) {
                croak "Error opening file $p{'file'}: $!";
            }
        }
    }

    # Check that the filehandle we should have at this point looks like a
    # filehandle (I used ->can instead of ->isa since many handle interfaces
    # don't actually inherit from IO::Handle but all of the ones which work
    # with this module will support the method 'getline'
    unless ( defined( $p{'fh'} ) && eval { $p{'fh'}->can('getline') } ) {
        croak "Must be called with a filename, string or filehandle";
    }

    my $struct;    # This contains whatever we're going to return up the
                   # chain: a hash, array or string
    my @sections = ();    # This is a list of INI file sections
    my $section  = '';    # This is the current section being processed
    my $line     = '';    # The current line being processed

    local $/ = "\012";    # Unix newline...  will catch DOS newlines too.
                          # Local is necessary if the parent context has set
                          # $/ to something different

    # Keep processing the FH until we hit the end
    while ( not $p{'fh'}->eof ) {

        $line = $p{'fh'}->getline;

        # If debugging is enabled then show the line being processed
        $p{'debug'} && _debug( $p{'fh'}, $line, "line - $line" );

        if ( $p{'_mode'} == TOP_MODE || $p{'_mode'} == HASH_MODE ) {

            # Process in a HASH style context
            unless ( defined $struct ) { $struct = {}; }

            my $name;
            my $val;

            if ( $line =~ m/ ^ $osp $eolc $ /x ) {
                $p{'debug'}
                    && _debug( $p{'fh'}, "Skipping blank/comment line" );
            }
            elsif ( $line =~ m/ ^ $osp \[ $osp (.+) $osp \] $osp $eolc $ /x )
            {

                # Process a [section] definition
                $section = $1;
                if ( $section =~ m/^_/ ) {
                    croak( $p{'fh'}, $p{'file'},
                        "Sections cannot begin with underscore" );
                }
                if ( $p{'_mode'} == TOP_MODE ) {
                    push @sections, $section;
                }
                else {
                    croak _error( $p{'fh'}, $line, $p{'file'},
                        "Unexpected section definition $section during subhash"
                    );
                }
            }
            elsif ( $line =~ m/ ^ $osp (.*?) $osp \{ $osp $eolc $ /x ) {
                $name = $1;
                $val = $pkg->new( %p, '_mode' => HASH_MODE );
            }
            elsif ( $line =~ m/ ^ $osp (.*?) $osp \( $osp $eolc $ /x ) {
                $name = $1;
                $val = $pkg->new( %p, '_mode' => ARRAY_MODE );
            }
            elsif (
                $line =~ m/ ^ $osp (.*?) $osp \= $osp \"( [^"]* $eol ) $ /x )
            {
                $name = $1;
                $val  = _fix_newlines(
                    $2 . $pkg->new( %p, '_mode' => STRING_MODE ) );
            }
            elsif (
                $line =~ m/ ^ $osp (.*?) $osp \= $osp \"([^"]+)\" $eolc $ /x )
            {
                $name = $1;
                $val  = $2;
            }
            elsif (
                $line =~ m/ ^ $osp (.*?) $osp \= $osp (.*?) $osp $eolc $ /x )
            {
                $name = $1;
                $val  = $2;
            }
            elsif ( $line =~ m/ ^ $osp ( \} | \) )$osp $eolc $ /x ) {
                my $char = $1;
                if ( ( $p{'_mode'} != TOP_MODE ) && ( $char eq '}' ) ) {

                    # We should only get to this line if we're nested
                    $p{'debug'}
                        && _debug( $p{'fh'},
                        "Returning nested hash back up the chain" );
                    return $struct;
                }

                # We saw a } or ) that doesn't belong here.
                croak _error( $p{'fh'}, $line, $p{'file'},
                    "Unexpected $char" );
            }
            else {
                croak _error( $p{'fh'}, $line, $p{'file'}, "Malformed line" );
            }

            if ( defined($name) && defined($val) ) {
                if ( ( $p{'_mode'} == TOP_MODE ) && $section ) {
                    $struct->{$section}{$name} = $val;
                }
                else {
                    $struct->{$name} = $val;
                }
            }

        } ## end if ( $p{'_mode'} == TOP_MODE || $p{'_mode'} == HASH_MODE )
        elsif ( $p{'_mode'} == ARRAY_MODE ) {

            # Process in an ARRAY style context
            unless ( defined $struct ) { $struct = []; }

            my $val;

            if ( $line =~ m/ ^ $osp $eolc $/x ) {
                $p{'debug'}
                    && _debug( $p{'fh'}, "Skipping blank/comment line" );
            }
            elsif ( $line =~ m/ ^ $osp \[ $osp (.+) $osp \] $osp $eolc $ /x )
            {
                croak _error( $p{'fh'}, $line, $p{'file'},
                    "Unexpected section definition $1 during subarray" );
            }
            elsif ( $line =~ m/ ^  $osp \{ $osp $eolc $ /x ) {
                $val = $pkg->new( %p, '_mode' => HASH_MODE );
            }
            elsif ( $line =~ m/ ^ $osp \( $osp $eolc $ /x ) {
                $val = $pkg->new( %p, '_mode' => ARRAY_MODE );
            }
            elsif ( $line =~ m/ ^ $osp \"( [^"]* $eol ) $ /x ) {
                $val = _fix_newlines(
                    $1 . $pkg->new( %p, '_mode' => STRING_MODE ) );
            }
            elsif ( $line =~ m/ ^ $osp \"([^"]+)\" $osp $eolc $ /x ) {
                $val = $1;
            }
            elsif ( $line =~ m/ ^ $osp \} $osp $eolc $ /x ) {

                # We saw a } that doesn't belong here.
                croak _error( $p{'fh'}, $line, $p{'file'}, "Unexpected }" );
            }
            elsif ( $line =~ m/ ^ $osp \) $osp $eolc $ /x ) {

                # We should only get to this line if we're nested
                $p{'debug'}
                    && _debug( $p{'fh'},
                    "Returning nested array back up the chain" );
                return $struct;
            }
            elsif ( $line =~ m/ ^ $osp (.*?) $osp $eolc $ /x ) {
                $val = $1;
            }
            else {
                croak _error( $p{'fh'}, $line, $p{'file'}, "Malformed line" );
            }

            push @$struct, $val;
        }
        elsif ( $p{'_mode'} == STRING_MODE ) {

            # Process in a multi-line string context
            unless ( defined $struct ) { $struct = ''; }

            if ( $line =~ m/ ^ ([^"]*) " $osp $eolc $ /x ) {
                return $struct . $1;
            }
            elsif ( $line =~ m/"/ ) {
                croak _error( $p{'fh'}, $line, $p{'file'},
                    "Unexpected mid-string quote" );
            }
            else {
                $struct .= $line;
            }

        }
        else {
            croak _error( $p{'fh'}, $line, $p{'file'},
                "Unknown mode: $p{'_mode'}" );
        }
    } ## end while ( not $p{'fh'}->eof )

    # If we got to the end of the file, but we weren't done processing a
    # context other than top, then the file ended before we expected.
    if ( $p{'_mode'} != TOP_MODE ) {
        croak _error( $p{'fh'}, $line, $p{'file'}, "Premature end of file" );
    }

    # Weed out any duplicate sections
    my %sections_index     = ();   # Keeps an index of unique sections
    my @sections_flattened = ();   # Keeps the final list of sections in order
    foreach my $section (@sections) {
        next if ( exists $sections_index{$section} );
        $sections_index{$section} = undef;
        push @sections_flattened, $section;
    }

    # Save metadata into the object
    $struct->{'_file'}           = $p{'file'};           # Filename, used for
                                                         # writing the file
                                                         # back out
    $struct->{'_debug'}          = $p{'debug'};          # Enable/disable
                                                         # debugging
    $struct->{'_sections'}       = \@sections_flattened; # List of sections in
                                                         # order
    $struct->{'_sections_index'} = \%sections_index;     # List of unique
                                                         # sections

    # We're done constructing the object, return it back up the chain
    bless $struct, $pkg;

} ## end sub new

# Print debugging information to STDERR
sub _debug {

    my $fh      = shift;    # For the line number
    my $message = shift;    # What we're reporting

    print STDERR __PACKAGE__ 
        . " Line "
        . $fh->input_line_number . ' '
        . $message . "\n";
}

# Format an error message with context information about the line
# number and contents for passing to croak
sub _error {

    my $fh      = shift;    # For the line number
    my $line    = shift;    # For the contents of the line
    my $file    = shift;    # What file we're processing (if available)
    my $message = shift;    # What we're complaining about

    chomp $line;

    $message
        .= " at input line " . $fh->input_line_number . " '" . $line . "'";
    if ($file) { $message .= " in file $file"; }

    return $message;

}

=head2 $cfg->as_hashref

Returns the entire INIPlus structure as a reference to a hash.

=cut

sub as_hashref {

    my $self = shift;
    my $out  = shift;

    foreach my $key ( keys %$self ) {
        next if ( $key =~ m/^_/ );
        $out->{$key} = $self->{$key};
    }

    return $out;
}

=head2 $cfg->get( name [ , section ] )

Gets the value of a particular entry.  For entries within a section, the
section name must be provided.

=cut

sub get {

    my $self    = shift;
    my $name    = shift;
    my $section = shift;

    if ( defined($section) && ( $section ne '' ) ) {
        return $self->{$section}{$name};
    }
    else {
        return $self->{$name};
    }
}

=head2 $cfg->set( name, val [ , section ] )

Sets the value of a particular entry.  If an existing entry exists it will be
overwritten. For entries within a section, the section name must be provided.

=cut

sub set {

    my $self    = shift;
    my $name    = shift;
    my $val     = shift;
    my $section = shift;

    if ( ( not defined $name ) || ( $name eq '' ) ) {
        croak "Name must be provided";
    }
    unless ( defined($val) ) {
        croak "Value must be defined";
    }
    if ( $name =~ m/^_/ ) {
        croak "Keys can not begin with underscore";
    }

    if ( defined($section) && ( $section ne '' ) ) {
        $self->{$section}{$name} = $val;
    }
    else {
        $self->{$name} = $val;
    }
}

=head2 $cfg->del( name [ , section ] );

Removes an entry.  For entries within a section, the section name must be
provided.

=cut

sub del {

    my $self    = shift;
    my $name    = shift;
    my $section = shift;

    if ( ( not defined $name ) || ( $name eq '' ) ) {
        croak "Name must be provided";
    }

    if ( defined($section) && ( $section ne '' ) ) {
        delete $self->{$section}{$name};
    }
    else {
        delete $self->{$name};
    }

}

=head2 $cfg->add_section( section )

Adds a new section.

=cut

sub add_section {

    my $self    = shift;
    my $section = shift;

    if ( ( not defined $section ) || ( $section eq '' ) ) {
        croak "Section must be provided";
    }
    if ( $section =~ m/^_/ ) {
        croak "Sections cannot begin with underscore";
    }

    if ( $self->section_exists($section) ) {
        croak "Section $section already exists";
    }
    if ( defined $self->{$section} ) {
        croak "Cannot create a conflicting top-level section when the same "
            . "key name $section already exists";
    }
    else {
        $self->{$section} = {};
        push @{ $self->{'_sections'} }, $section;
        $self->{'_sections_index'}{$section} = undef;
    }
}

=head2 $cfg->section_exists( section )

Returns true if a section exists, false if it does not.

=cut

sub section_exists {

    my $self    = shift;
    my $section = shift;

    if ( ( not defined $section ) || ( $section eq '' ) ) {
        croak "Section must be provided";
    }

    return exists $self->{'_sections_index'}{$section};
}

=head2 $cfg->sections()

Returns a list of all of the sections in the file

=cut

sub sections {

    my $self = shift;

    return @$self->{'_sections'};
}

=head2 $cfg->del_section( section )

Removes a section.

=cut

sub del_section {

    my $self    = shift;
    my $section = shift;

    if ( ( not defined $section ) || ( $section eq '' ) ) {
        croak "Section must be provided";
    }

    delete $self->{$section};
    delete $self->{'_sections_index'}{$section};
    $self->{'_sections'}
        = [ grep { !/^\Q$section\E$/ } @$self->{'_sections'} ];
}

=head2 $cfg->section_as_hashref( section )

Retrieves a section as a reference to a hash.

=cut

sub section_as_hashref {

    my $self    = shift;
    my $section = shift;

    return $self->{$section};

}

=head2 $cfg->write( [ $filename ] )

Writes out the configuration to a file to disk.  If a filename is provided,
the configuration is written to that file.  If the object was read from a
source filename and no filename is provided to the write method, then the
original file is overwritten.  The file written will not include the
formatting or comments of the original file read by this object.

=cut

sub write {
    my $self = shift;
    my $file = shift;

    unless ( defined($file) && $file ) {
        $file = $self->{'file'};
        unless ( defined($file) && $file ) {
            croak "You must provide a filename to write if the read "
                . "INIPlus file does not have an associated file name";
        }
    }

    my $fh = IO::File->new( $file, 'w' );

    $fh->print( $self->as_string );

}

=head2 $cfg->as_string()

Retrieves the configuration as a string.  This will not include the formatting
or comments of the original file read by this object.

=cut

sub as_string {
    my $obj = shift;
    my %p   = @_;

    if ( not defined $p{indent_level} ) {
        $p{indent_level} = 0;
    }

    if ( not defined $p{indent_string} ) {
        $p{indent_string} = '  ';
    }

    my $indent = $p{indent_string} x $p{indent_level};

    my $out = '';

    my $at_root = blessed($obj) && $obj->isa('Config::INIPlus');

    if ( $at_root || ( ref $obj eq 'HASH' ) ) {
        foreach my $key ( keys %{$obj} ) {
            next if ( $key =~ m/^_/ );
            next if ( $at_root && $obj->section_exists($key) );
            my $value = $obj->{$key};
            if ( ref $value eq 'ARRAY' ) {
                $out .= $indent . $key . " (\n";
                $out .= as_string( $value,
                    'indent_level' => $p{indent_level} + 1 );
                $out .= $indent . ")\n";
            }
            elsif ( ref $value eq 'HASH' ) {
                $out .= $indent . $key . " {\n";
                $out .= as_string( $value,
                    'indent_level' => $p{indent_level} + 1 );
                $out .= $indent . "}\n";
            }
            elsif ( $value =~ m/"/ ) {
                croak "Strings with quotes cannot be serialized";
            }
            elsif ( $value =~ m/$eol/ ) {
                $out .= $indent . "$key=\"$value\"\n";
            }
            else {
                $out .= $indent . "$key=$value\n";
            }
        }
        $out .= "\n";
        if ($at_root) {
            foreach my $section ( @{ $obj->{'_sections'} } ) {
                $out .= "[$section]\n";
                if ( defined $obj->{$section} ) {
                    $out .= as_string( $obj->{$section} );
                }
                $out .= "\n";
            }
        }
    }
    elsif ( ref $obj eq 'ARRAY' ) {
        foreach my $value (@$obj) {
            if ( ref $value eq 'ARRAY' ) {
                $out .= $indent . "(\n";
                $out .= as_string( $value,
                    'indent_level' => $p{indent_level} + 1 );
                $out .= $indent . ")\n";
            }
            elsif ( ref $value eq 'HASH' ) {
                $out .= $indent . "{\n";
                $out .= as_string( $value,
                    'indent_level' => $p{indent_level} + 1 );
                $out .= $indent . "}\n";
            }
            elsif ( $value =~ m/"/ ) {
                croak "Strings with quotes cannot be serialized";
            }
            elsif ( $value =~ m/$eol/ ) {
                $out .= $indent . "\"$value\"\n";
            }
            else {
                $out .= $indent . "$value\n";
            }
        }
    }
    else {
        confess "Only INIPlus objects consisting of perl native hashes and "
            . "arrays can be serialized by as_string";
    }

    return $out;

}

# Takes a string and translates any newlines into whatever the local system's
# newline is
sub _fix_newlines {
    my $str = shift;
    $str =~ s/$eol/\n/gs;
    return $str;
}

=head1 FAQ

=over 4

=item Why not use YAML/JSON/XML?

There are times when you have existing INI files you need to maintain backward
compatibility with, but you need the ability to add richer syntax.  If that's
the problem you're trying to solve, this module's for you.  If you're not, then
you'll likely be better served by L<YAML>.

=back

=head1 CAVEATS

=over 4

=item * Right now writing will preserve all data, but comments and formatting
        will be lost

=item * Since double quotes are used to contain multi-line strings, they are
        not allowed in values.  This behaviour is different than most other
        INI parsers.

=item * Obviously any of the formatting which allows for nested arrays and
        hashes will not be compatible with existing INI parsers

=item * Keys and section names cannot start with an underscore

=back

=head1 SEE ALSO

=over 4

=item * L<Config::INI> - The most popular module for reading and writing INI
        files

=item * L<YAML> - A non-INI way of reading and writing nested structures into
        config files

=back

=head1 AUTHOR

Anthony Kilna, C<< <anthony at kilna dot com> >> - L<http://anthony.kilna.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-iniplus at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-INIPlus>.  I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::INIPlus

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-INIPlus>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-INIPlus>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-INIPlus>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-INIPlus>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kilna Companies.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Config::INIPlus
