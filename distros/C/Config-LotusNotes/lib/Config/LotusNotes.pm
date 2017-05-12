package Config::LotusNotes;
use strict;
#use warnings;
use Carp;
use Win32;
use Win32::TieRegistry Delimiter => '/';
use Config::LotusNotes::Configuration;

our $VERSION = '0.34';

# constructor ----------------------------------------------------------------

sub new {
    my ($classname, %options) = @_;
    $options{'_classes_root'}  = _is64bit() ? 'Classes/Wow6432Node' : 'Classes';
    $options{'_software_root'} = _is64bit() ? 'LMachine/SOFTWARE/Wow6432Node' : 'LMachine/SOFTWARE';
    return bless {%options}, $classname;
}


sub default_configuration {
    my ($self) = @_;
    my $path = $self->_get_default_location();
    return Config::LotusNotes::Configuration->new(path => $path);
}


sub all_configurations {
    my ($self) = @_;
    my @locations = $self->_get_all_locations();
    my @configurations = $self->_create_configurations(@locations);
    print STDERR "-- Returning " . @configurations . " configuration objects\n"  if $self->{debug};
    return @configurations;
}


sub _get_default_location {
    my ($self) = @_;
    print STDERR "-- Searching default installation\n"  if $self->{debug};

    # first try the handler for the Notes class.
    if (my $class_handler = $self->_get_notes_handler()) {
        return _normalize_path($class_handler);
    }

    # if unsuccessful, try default product keys for Notes and Domino.
    foreach my $product qw(Notes Domino) {
        print STDERR "--  Searching default $product product key\n"  if $self->{debug};
        if (my $path = $Registry->{"LMachine/SOFTWARE/Lotus/$product/Path"}) {
            print STDERR "--   Found $path\n"  if $self->{debug};
            return _normalize_path($path);
        }
    }
    croak 'No Lotus Notes/Domino installation found';
}


sub _get_all_locations {
    my ($self) = @_;
    print STDERR "-- Searching for all installations\n"  if $self->{debug};
    my @all_paths = (
        $self->_get_notes_handler(),
        $self->_get_registered_locations(),
        $self->_get_shared_libs_locations(),
        $self->_get_typelib_locations(),
    );

    print STDERR "-- Removing duplicates\n"  if $self->{debug};
    return _remove_duplicates(@all_paths);
}


sub _create_configurations {
    my ($self, @locations) = @_;
    my @configurations;
    foreach my $path (@locations) {
        my $config;
        # skip invalid installations.
        print STDERR "-- Verifying $path - "  if $self->{debug};
        if ( eval {$config = Config::LotusNotes::Configuration->new(path => $path)} ) {
            print STDERR "OK\n"  if $self->{debug};
            push @configurations, $config;
        }
        else {
            my $errmsg = $@;
            print STDERR "NOK: $errmsg"  if $self->{debug};
            carp $errmsg if $errmsg =~ /^Error parsing /;
        }
    }
    return @configurations;
}


sub _get_notes_handler {
    my ($self) = @_;
    # one install is registered for the Notes class.
    print STDERR "--  Searching Notes class handler\n"  if $self->{debug};
    if (my $path = $Registry->{"Classes/Notes/Shell/Open/Command//"}) {
        $path =~ s/^"([^"]+)".*/$1/;  # first quoted element
        $path =~ s/[^\\]+$//;  # shrink to path
        print STDERR "--   Found $path\n"  if $self->{debug};
        return _normalize_path($path);
    }
    return;
}


sub _get_registered_locations {
# finds installations in version specific keys under $RegNotesRoot
    my ($self) = @_;
    my @result;
    foreach my $product qw(Notes Domino) {
        print STDERR "--  Searching default $product product key\n"  if $self->{debug};
        my $product_root = $Registry->{$self->{_software_root} . "/Lotus/$product/"};
        if (my $path = $product_root->{'Path'}) {
            print STDERR "--   Found $path\n"  if $self->{debug};
            push @result, _normalize_path($path);
        }

        # search for version specific keys
        foreach my $key (keys %$product_root) {
            if ($key =~ m|^\d+(\.\d+)?/$|) {
                if ($self->{debug}) {
                    (my $version = $key) =~ s|/$||;
                    print STDERR "--  Searching $product $version product key\n";
                }
                if (my $path = $product_root->{$key . 'Path'}) {
                    print STDERR "--   Found $path\n"  if $self->{debug};
                    push @result, _normalize_path($path);
                }
            }
        }
    }
    return @result;
}


sub _get_shared_libs_locations {
# search for shared dll entries
    my ($self) = @_;
    print STDERR "--  Searching shared dll entries\n"  if $self->{debug};
    my @result;

    my $shared_dlls = $Registry->{$self->{_software_root} . '/Microsoft/Windows/CurrentVersion/SharedDLLs/'};
    foreach my $path (keys %$shared_dlls) {
        if ($path =~ /nlsxbe.dll$/i) {
            $path =~ s|^/||;
            $path =~ s/[^\\]*$//;  # remove program
            print STDERR "--   Found $path\n"  if $self->{debug};
            push @result, _normalize_path($path);
        }
    }
    return @result;
}


sub _get_typelib_locations {
# search the Lotus.NotesSession COM server's typelibs for installations
    my ($self) = @_;

    print STDERR "--  Searching the Lotus.NotesSession COM server's typelibs\n"  if $self->{debug};
    my @result;

    # get the COM Server's CLSID
    my $com_clsid = $Registry->{'Classes/Lotus.NotesSession/CLSID//'} or return;

    # get the CLSID of its typelib key
    my $typelib_clsid = $Registry->{$self->{_classes_root} . "/CLSID/$com_clsid/TypeLib//"}
        or return;

    # search all available typelib versions for paths
    my $typelib = $Registry->{$self->{_classes_root} . "/TypeLib/$typelib_clsid/"};
    foreach my $key (keys %$typelib) {
        if ($self->{debug}) {
            (my $version = $key) =~ s|/$||;
            print STDERR "--   Searching typelib version $version\n";
        }
        if (my $path = $typelib->{$key . '0/win32//'}) {
            $path =~ s/[^\\]*$//;  # remove program
            print STDERR "--    Found $path\n"  if $self->{debug};
            push @result, _normalize_path($path);
        }
        if (my $path = $typelib->{$key . 'HELPDIR//'}) {
            print STDERR "--    Found $path\n"  if $self->{debug};
            push @result, _normalize_path($path);
        }
    }
    return @result;
}


sub _is64bit {
    my (undef, $osdetail) = Win32::GetOSName();
    return $osdetail =~ /64-bit/;
}

sub _remove_duplicates {
    my (@all) = @_;
    my (%seen, @result);
    foreach my $element (@all) {
        push @result, $element unless $seen{$element}++;
    }
    return @result;
}

sub _normalize_path {
    # append backslash, lowercase
    my ($path) = @_;
    $path .= '\\' unless $path =~ /\\$/;
    return lc $path;
}


1;


=head1 NAME

Config::LotusNotes - Access Lotus Notes/Domino configuration

=head1 VERSION

This documentation refers to C<Config::LotusNotes> 0.34,
released Feb 10, 2011.

=head1 SYNOPSIS

  $factory = Config::LotusNotes->new();

  # access default installation
  $conf = $factory->default_configuration();
  $data = $conf->get_environment_value('Directory');
  $conf->set_environment_value('$NotesEnvParameter', 'value');

  # find all installations
  @installs = $factory->get_all_configurations();

=head1 DESCRIPTION

C<Config::LotusNotes> gives you a view of your local Lotus Notes/Domino
installations from the filesystem's perspective.
Its main purpose is to read and manipulate the Notes configuration file,
F<notes.ini>.

The module can handle multiple installations.

You can use it to

 - enumerate local Notes/Domino installations
 - gather basic information about your local Notes/Domino installations
 - exchange data with Lotus Notes via the environment functions.

A C<Config::LotusNotes> object searches the Windows registry for Lotus Notes
installations, which can then be accessed in their representations as
L<Config::LotusNotes::Configuration|Config::LotusNotes::Configuration> objects.

=head2 The Lotus Notes environment

The Lotus Notes environment is often used to store local user preferences
and to share information between separate parts of an application.

The Lotus Notes formula language has the C<@Environment> and C<@SetEnvironment>
functions and the C<ENVIRONMENT> keyword to access the program's environment.
Lotus script uses the C<GetEnvironmentValue>, C<GetEnvironmentString>,
C<SetEnvironmentVar> and C<Environ> functions for that purpose.
The Lotus Notes environment is stored in the F<notes.ini> file, which is
instantly updated after each change to the environment.
This allows you to communicate data to external programs.

Unfortunately, Lotus Notes does not recognize external changes to
F<notes.ini> while it is running.
If you need to push data to a running instance of Lotus Notes, you can use the
environment functions of the corresponding OLE object as shown in L<SEE ALSO>.
There might be problems with simultaneous programmatic and user access to
the same Lotus Notes session.

=head1 METHODS

=over 4

=item new();

Constructor, returns a C<Config::LotusNotes> object that can give you
L<Config::LotusNotes::Configuration|Config::LotusNotes::Configuration> objects
via its default_configuration() and all_configurations() methods.

=item default_configuration();

Returns a L<Config::LotusNotes::Configuration|Config::LotusNotes::Configuration>
object for the default Lotus Notes installation.
The default installation is the one that is registered in the Windows registry
as the handler for the C<Notes> class.

If there is only one version of Lotus Notes installed on your machine,
this is what you want.

This method will throw an 'No Lotus Notes/Domino installation found' exception
if it cannot find any Lotus Notes installation.

=item all_configurations();

This gives you an array containing one
L<Config::LotusNotes::Configuration|Config::LotusNotes::Configuration> object
for each Lotus Notes/Domino installation found on your machine.
If no installation is found, an empty array is returned.

=back

=head1 SEE ALSO

An alternative way of accessing Lotus Notes/Domino is via its OLE and COM
scripting capabilities. Here is an OLE example:

  use Win32::OLE;

  # print Lotus Notes version:
  $Notes = Win32::OLE->new('Notes.NotesSession')
      or die "Cannot start Notes.NotesSession object.\n";
  ($Version) = ($Notes->{NotesVersion} =~ /\s*(.*\S)\s*$/); # remove blanks
  printf "Running Notes %s on %s.\n", $Version, $Notes->Platform;

  # write value to environment
  print "Setting $key to $value\n";
  $session->SetEnvironmentVar('$NotesEnvParameter', 'test value');

This will start an instance of Lotus Notes if none is already running.
See the Lotus Notes designer documentation for more information.

=head1 DIAGNOSTICS

Call the constructor method new() with the option C<debug =E<gt> 1> to get
diagnostic information on the search progress.

=head1 DEPENDENCIES

This module only works with Microsoft Windows.
It has been tested on Windows NT, 2000, XP and 7 (64-bit).
It uses L<Win32::TieRegistry|Win32::TieRegistry>,
L<Config::IniHash|Config::IniHash> and L<File::HomeDir|File::HomeDir>
(the latter two not being standard modules).
The test require Test::More.
Optional modules for the tests are Test::Pod and Test::Pod::Coverage.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the web interface at
http://rt.cpan.org/Public/Bug/Report.html?Queue=Config-LotusNotes

=head2 Problems locating installations

Lotus Notes/Domino stores information about the installed versions in
registry keys that are specific  to the main version number only,
e.g. 5.0, 6.0 and 7.0, with ".0" being fix.
Each additional installation will overwrite the data of any previous
installation that has the same main version number.

This module works around this problem by searching several additional places
in the registry for possible installation locations.
In complex installations this might not find all instances.

Please bear in mind that such complex situations can only be created if you
cheat the Notes installer by renaming the paths of your existing installations
before each additional installation.
The normal behaviour of the installer is to force you to update your previous
installation.
So in real life, there should be no problem with missed installations.

=head2 Malformed notes.ini files

Under certains conditions a F<notes.ini> file may contain malformed lines,
i.e. lines that do not match the pattern C<parameter=value>.

Such lines are ignored when reading values.
If you write back values to a corrupt F<notes.ini> file using the
L<set_environment_value()|Config::LotusNotes::Configuration/set_environment_value>
function, the malformed lines are removed from F<notes.ini>.

If a F<notes.ini> file cannot be parsed at all, a warning will be issued and the
corresponding installation will be skipped by all_configurations()Z<>.
default_configuration() will throw an "Error parsing ..." exception in that case.

Malformed F<notes.ini> files can be reproduced by writing multiline values to the
environment, e.g. with Notes formula code like this:
C<@SetEnvironment("testvalue"; "A"+@Char(10)+"B")>, which produces two lines,
the second one just containing "B".
A successive read of testvalue will return just "A".

In my environment lines like

 3.2008 09:32:30

are quite common and seem to originate from the Smart Upgrade process.

=head2 Parameter order in notes.ini

If you write to a F<notes.ini> file with the
L<set_environment_value()|Config::LotusNotes::Configuration/set_environment_value>
function, the entries in that file will appear in random order.
This should not pose any problems.

=head1 EXAMPLES

=head2 code example

  use Config::LotusNotes;
  $factory = Config::LotusNotes->new();

  # get default LotusNotes installation
  $conf = $factory->default_configuration();
  print 'Lotus Notes ', $conf->version, ' installed in ', $conf->notespath, "\n";

  # retrieving and setting notes.ini values
  # get name of the user's mail file.
  $mail_file = $conf->get_environment_value('MailFile');
  # store a value in notes.ini
  $conf->set_environment_value('$NotesEnvParameter', 'test value');

  # find all installations
  @all_confs = $factory->all_configurations();

  # print a table with version, type and path of all installations.
  # see demo\FindNotes.pl for an extended version.
  printf "%-8s %-7s %s\n", 'version', 'type', 'path';
  foreach my $conf (@all_confs) {
      printf "%-8s %-7s %s\n",
          $conf->version,
          $conf->is_server ? 'server' : 'client',
          $conf->notespath;
  }

  # filter the list: only servers
  @servers = grep { $_->is_server } @all_confs;

=head2 demo scripts

This module also installs two simple demonstration scripts:
F<FindNotes.pl> enumerates local Notes/Domino installations and
F<editnotesini.pl> reads and changes notes.ini parameters.

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006 HS - Hamburger Software GmbH & Co. KG.
All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantibility or fitness for a particular purpose.

=head1 AUTOR

Harald Albers, albers@cpan.org

See the F<Changes> file for the change history.

=cut
