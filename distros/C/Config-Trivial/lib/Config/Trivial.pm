#   $Id: Trivial.pm 63 2014-05-23 09:42:15Z adam $

package Config::Trivial;

use 5.010;		# May work on earlier perls but I've not tested
use utf8;
use strict;
use warnings;
use Carp;

our $VERSION = '0.81';
my ( $_package, $_file ) = caller;

#
#   NEW
#

sub new {
    my $class  = shift;
    my %args   = @_;
    my $object = bless {
        _config_file   => $_file,       # The Config file, default is caller
        _self          => 1,            # Set Self Read
        _error_message => q{},          # Error Messages
        _configuration => {},           # Where the configuration data goes
        _backup_char   => q{~},         # Backup marker
        _separator     => q{ },         # Separator
        _multi_file    => 0,            # Multi file mode
        _debug    => $args{debug}    || 0, # Debugging (verbose) mode
        _strict   => $args{strict}   || 0, # Strict mode
        _no_check => $args{no_check} || 0, # Skip filesystem checks
        },
        ref $class || $class;

    if ( $args{config_file} ) {
        croak "Unable to read config file $args{config_file}"
            unless set_config_file( $object, $args{config_file} );
    }
    return $object;
}

#
#   SET_CONFIG_FILE
#

sub set_config_file {
    my $self               = shift;
    my $configuration_file = shift;

    if ( ref $configuration_file ) {
        if ( ref $configuration_file eq 'HASH' ) {
            foreach my $sub_config_file ( sort keys %{$configuration_file} ) {
                my $config_file = $configuration_file->{$sub_config_file};
                if ( $config_file ) {
                    if (! $self->_check_file($config_file) ) {
                        return;
                    }
                }
                else {
                    return $self->_raise_error('File error: No file name supplied')
                }
            }
            $self->{_config_file} = $configuration_file;
            $self->{_self}        = 0;
            $self->{_multi_file}  = 1;
            return $self;
        }
        else {
            croak 'ERROR: Can only deal with a hash references';
        }
    }
    else {
        if ( $self->_check_file($configuration_file) ) {
            $self->{_config_file} = $configuration_file;
            $self->{_self}        = 0;
            $self->{_multi_file}  = 0;
            return $self;
        }
        else {
            return;
        }
    }
}

#
#   READ
#

sub read {
    my $self = shift;
    my $key  = shift;    # If there is a key, return only it's value

    if ( $self->{_multi_file} ) {
        croak 'ERROR: Read can only deal with a single file';
    }

    $self->_read_config( $self->{_config_file});

    return $self->{_configuration}->{$key} if $key;
    return $self->{_configuration};
}


#
#   MULTI_READ
#

sub multi_read {
    my $self = shift;
    my $hash = shift;   # If there is specific hash, return only it's value

    if ( ! $self->{_multi_file} ) {
        croak 'ERROR: Multi_Read is for multiple configuration files';
    }

    foreach my $config_key ( keys %{$self->{_config_file}} ) {
        my $config_file = $self->{_config_file}->{$config_key};
        $self->_read_config( $config_file, $config_key );
#        return unless $self->_check_file( $config_file );
    }

    return $self->{_configuration}->{$hash} if $hash;
    return $self->{_configuration};
}

#
#   GET_CONFIGURATION
#

sub get_configuration {
    my $self = shift;
    my $key  = shift;

    return $self->{_configuration}->{$key} if $key;
    return $self->{_configuration};
}

#
#   SET_CONFIGURATION
#

sub set_configuration {
    my $self = shift;
    my $hash = shift;

    return $self->_raise_error('No configuration data')
        unless $hash;
    return $self->_raise_error('Configuration not a reference')
        unless ref $hash;
    return $self->_raise_error(q{Configuration data isn't a hash reference})
        unless ref $hash eq 'HASH';

    $self->{_configuration} = $hash;
    return $self;
}

#
#   WRITE
#

sub write {
    my $self = shift;
    my %args = @_;

    my $settings = $args{'configuration'} || $self->{_configuration};

    croak 'ERROR: No settings hash to write.'
        unless $settings;
    croak 'ERROR: Settings not a hashref.'
        unless ref $settings eq 'HASH';

    my $file = $args{'config_file'} || $self->{_config_file};

    if ( $file ) {
        if (   ( $_file eq $file )
            || ( $0 eq $file ) )
        {
            return $self->_raise_error(
                'Not allowed to write to the calling file.');
        }
    }
    else {
        croak 'File error: No file name supplied';
    }

    if ( -e $file ) {
        croak "ERROR: Insufficient permissions to write to: $file"
            unless ( -w $file );
        rename $file, $file . $self->{_backup_char}
            or croak "ERROR: Unable to rename $file.";
    }

    open my $config, '>', $file
        or croak "ERROR: Unable to write configuration file: $file";
    print {$config}
        "#\n#\tConfig file written by $_file\n#\tUsing Config::Trivial version $VERSION\n#\n\n";

    foreach my $setting ( keys %{$settings} ) {
        if ( $setting =~ / / ) {                    # Check for spaces in keys
            croak qq{ERROR: Setting key "$setting" contains an illegal space}
                if $self->{_strict};
            carp qq{WARNING: Setting key "$setting" contains an illegal space}
                if $self->{_debug};
            my $old_setting = $setting;
            $setting =~ s/ /_/g;
            croak 'ERROR: Unable to fix space in key, replacement key exists already'
                if $settings->{$setting};
            $settings->{$old_setting} = q{ } unless $settings->{$old_setting};
            $settings->{$old_setting} =~ s/\\\s*$/\\ #/;
            printf {$config} "$setting%s$settings->{$old_setting}\n",
                length $old_setting >= 8 ? "\t" : "\t\t";
            next;
        }
        $settings->{$setting} = q{ } unless $settings->{$setting};
        $settings->{$setting} =~ s/\\\s*$/\\ #/;
        printf {$config} "$setting%s$settings->{$setting}\n",
            length $setting >= 8 ? "\t" : "\t\t";
    }

    my $time = localtime;
    print {$config} "\n#\n#\tThis file written at $time\n#\n";
    close $config;
    return 1;
}

#
#   GET_ERROR
#

sub get_error {
    my $self = shift;
    return $self->{_error_message};
}

#   #################
#   Private Functions
#   #################

#
#   Perform some file checks
#

sub _check_file {
    my $self = shift;
    my $file = shift;

#   Skip ALL checks if no_check is set
    if ( $self->{'_no_check'} ) {
        return $self;
    }

#   Check the filename before using - may be slow on some filesystems
    return $self->_raise_error('File error: No file name supplied')
        unless $file;
    return $self->_raise_error("File error: Cannot find $file")
        unless -e $file;
    return $self->_raise_error("File error: $file isn't a real file")
        unless -f _;
    return $self->_raise_error("File error: Cannot read file $file")
        unless -r _;
    return $self->_raise_error("File error: $file is zero bytes long")
        if -z _;
    return $self;
}

#
#   Open and read an individual config file
#

sub _read_config {
    my $self  = shift;
    my $file  = shift;
    my $f_key = shift;

    return unless $self->_check_file( $file );

    open my $config, '<', $file
        or croak "ERROR: Unable to open configuration file: $file";

    if ( $self->{_self} )
    {    # We are now parsing the calling file for it's __DATA__ section
        while ( <$config> ) {
            last if /^__DATA__\s*$/;
        }
    }
    while ( <$config> ) {
        next if /^\s*#/;                    # Skip comment lines starting #
        next if /^\s*\n/;                   # Skip any empty lines
        last if /^__END__\s*$/;             # Don't care what comes after this
        if ( s/\\\s*$// ) {                 # Look for a continuation character
            $_ .= <$config>;                # If found then glue the lines together
            redo unless eof $config;
        }
        $self->_process_line( $_, $., $f_key );    # Send the line off for processing
    }
    close $config;
    return;
}

#
#   Raise error condition
#
sub _raise_error {
    my $self    = shift;
    my $message = shift;

    croak $message if $self->{_strict};    # STRICT: die with the message
    carp $message  if $self->{_debug};     # DEBUG:  warn with the message
    $self->{_error_message} = $message;    # NORMAL: set the message
    return;
}

#
#   Parse a line and add to Config structure
#
sub _process_line {
    my $self    = shift;
    my $line    = shift;
    my $line_no = shift;
    my $f_key   = shift;
    my ( $key, $value );

    chomp $line;
    $line =~ s/^\s+|\s+$|\s*#+.*$//g;       # Remove comments, and spaces at start or end
    $line =~ s/\s+/ /g;                     # Multiple whitespace to one space globally

    if ( $line ) {
        ( $key, $value ) = split / /, $line, 2;
    }
    if ( $key ) {
	    no warnings 'uninitialized';
        $key = lc _clean_string( $key );
    }
    if ( exists $self->{_configuration}->{$key} ) {
        croak qq{ERROR: Duplicate key "$key" found in config file on line $line_no}
            if $self->{_strict};
        carp qq{WARNING: Duplicate key "$key" found in config file on line $line_no}
            if $self->{_debug};
    }
    if ( $key ) {
        if ( defined $value ) {
            if ( $f_key ) {
                $self->{_configuration}->{$f_key}->{$key} = $value;
            }
            else {
                $self->{_configuration}->{$key} = $value;
            }
        }
        else {
            carp qq{WARNING: Key "$key" has no valid value, on line $line_no of the config file}
                if $self->{_debug};
            $self->{_configuration}->{$key} = undef unless $self->{_strict};
        }
    }
    return;
}

#
#   Clean data up to make a key out of it
#
sub _clean_string {
    my $input = shift;
    my $output;

    $input =~ tr/\e\`\'"%//ds;                              # Remove less gross crud from the input
    $output = $1
        if ( $input =~ /^([\^\$-=\?\/\w.:\\\s\@~\|]+)$/ );  # De-Taint the input line
    $output =~ s/^\s+|\s+$//g if $output;                   # Remove spaces at start or end
    return $output;
}

1;


__END__


=head1 NAME

Config::Trivial - Very simple tool for reading and writing very simple configuration files

=head1 SYNOPSIS

  use Config::Trivial;
  my $config = Config::Trivial->new(config_file => 'path/to/my/config.conf');
  my $settings = $config->read;
  print "Setting Colour is:\t", $settings->{'colour'};
  $settings->{'new-item'} = 'New Setting';

=head1 DESCRIPTION

Use this module when you want use "Yet Another" very simple, light
weight configuration file reader. The module simply returns a
reference to a single hash for you to read configuration values
from, and uses the same hash to write a new config file.


=head1 METHODS

=head2 new

The constructor can be called empty or with a number of optional
parameters. If called with no parameters it will set the configuration
file to be the file name of the file that called it.

  $config = Config::Trivial->new();

or

  $config = Config::Trivial->new(
    config_file => '/my/config/file',
    debug       => 'on',
    strict      => 'on',
    no_check    => 'on' );

By default debug, strict and no_check are set to off. In debug mode
messages and errors will be dumped automatically to STDERR. Normally
messages and non-fatal errors need to be pulled from the error handler. In
strict mode all warnings become fatal. Turning no_check on disables
file tests which may slow the module down if used over a slow network
to a NFS or CIFS filesystem.

If you set a file in the constructor that is invalid for any reason
it will die in any mode - this may change in a later version.

=head2 set_config_file

The configuration file can be set after the constructor has been called.
Simply set the path to the file you want to use as the config file. If the
file does not exist or isn't readable the call will return false and set
the error message.

  $config->set_config_file("/path/to/file");

You may also set a collection of configuration files by passing a reference
to a hash. They keys will be used to extract data, and the values of the
hash will contain the files that you wish to use.

  %config_files = (
    master_config    => "/path/to/master.conf",
    secondary_config => "/path/to/second/conf");
  $config->set_config_file(\%config_files);

=head2 read

The read method opens the file, and parses the configuration returning the
results as a reference to an hash. If the file cannot be read it will die.

  my $settings = $config->read;

Alternatively if you only want a single configuration value you can pass just
that key, and get back it's matching value.

  my $colour = $config->read('colour');

Each call to read will make the module re-read and parse the configuration file.
If you want to re-read data from the oject use the get_configuration method.

=head2 get_configuration

This method simply returns the value requested or a hash reference
of the configuration data. It does NOT perform a re-read of the
data on the disk.

  $settings = $config->get_configuration;

or

  $colour = $config->get_configuration{'colour'};

If your configuration data is from muliple files, then passing a key
will return a hash reference of the "key" file requested rather than
an indiviudal value.

=head2 multi_read

This method is used to read a multiple set of configutaion files in one go.

  my $settings = $config->multi_read;

Alternativly you can return just one hash of one configutation file with.

  my $master = $config->multi_read('master_config');

=head2 set_configuration

If you need to set the configuration object with data you can
pass in a reference to a hash with this method. Any existing
data will be over-written. Returns false on failure.

  $config->set_configuration(\%settings);

or

  $config->set_configuration($hash_ref);

=head2 write

The write method simply writes the configuration hash back out
to the configuration file. It will try to not write to a file if
it has the same filename of the script that called it. This can
easily be bypassed, and bad things will happen!

There are two optional parameters that can be passed, a file
name to use instead of the current one, and a reference of a
hash to write out instead of the currently loaded one.

  $config->write(
    config_file => '/path/to/somewhere/else',
    configuration => $settings);

The method returns true on success. If the file already exists
then it is backed up first. The write is not 'atomic' or
locked for reading in anyway. If the file cannot be written to
then it will die.

Configuration data passed by this method is only written to
file, it is not stored in the internal configuration object.
To store data in the internal use the set_configuration data
method. The option to pass a hash_ref in this method may
be removed in future versions.

=head2 get_error

In normal operation the module will only die if it is unable to read
or write the configuration file, or an invalid file is set in the
constructor. Other errors are non-fatal. If an error occurs it can
be read with the get_error method. Only the most recent error is
stored.

  my $settings = $config->read();
  print get_error unless $settings;

=head1 CONFIG FORMAT

=head2 About The Configuration File Format

The configuration file is a plain text file with a simple structure. Each
setting is stored as a key value pair separated by the first space. Empty
lines are ignored and anything after a hash # is treated as a comment and
is ignored. Depending upon mode, duplicate entries will be silently ignored,
warned about, or cause the module to die.

At the moment this module does not encode or decode data, data remains
in perl native format.

All key names are forced into lower case when read in, values are left intact.

On write spaces in key names will either cause the script to die (strict),
blurt out a warning and substitute an underscore (debug), or silently change
to an underscore. Underscores in keys are NOT changed back to spaces on read.

If you delete a key/value pair it will not be written out when you do a write.
When a key has an undef value, the key will be written out with no matching
value. When you read a key with no value in, in debug mode you will get a warning.

You can continue configuration data over several lines, in a shell like manner,
by placing a backslash at the end of the line followed by a new line. White space
between the backslash and the new line will be ignored and also trigger line
continuation.

If you need to have a backslash at the end of your data, for example a windows
path, then place a # mark after your backslash.

=head2 Sample Configuration File

  #
  # This is a sample config file
  #

  value-0 is very \
  long so it's broken \
  over several lines
  value-1 is foo
  value-1 is bar
  path \ #
  __END__
  value-1 is baz

If parsed the value of value-1 would be "is bar" in normal mode, issue a warning
if in debug mode and die in strict mode. Everything after the __END__ will be
ignored. value-0 will be "is very long so it's broken over several lines".

=head1 MISC

=head2 Prerequisites

At the moment the module only uses core modules. The test suite optionally uses
C<POD::Coverage> and C<Test::Pod>, which will be skipped if you don't have them.

=head2 History

See Changes file.

=head2 Defects and Limitations

Patches Welcome... ;-)

https://rt.cpan.org/Dist/Display.html?Queue=Config-Trivial

=head2 To Do

=over

=item *

Much better test suite.

=item *

Multi-write option

=back

=head1 EXPORT

None.

=head1 AUTHOR

Adam Trickett, E<lt>atrickett@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<Config::Trivial::Storable>, L<ConfigReader::Simple>,
L<Config::Ini>, L<Config::General>, L<Config::Tiny>
and L<Config::IniFiles>.

=head1 LICENSE AND COPYRIGHT

C<Config::Trivial>, Copyright Adam John Trickett 2004-2014

OSI Certified Open Source Software.
Free Software Foundation Free Software.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
