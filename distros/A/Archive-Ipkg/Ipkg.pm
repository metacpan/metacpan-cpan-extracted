package Archive::Ipkg;

use strict;
use warnings;
use Carp;

use lib qw(.);

use Archive::Tar;
use Compress::Zlib;

our $VERSION = '0.04';

# constructor
sub new {
    my $class = shift;
    my %opts = @_;

    my $self = {};

    $self->{sloppy} = 0;
    $self->{sloppy} = $opts{sloppy}
        if exists $opts{sloppy};

    bless $self, $class;

    # initialize properties without defaults
    $self->config_files(@{$opts{config_files}})
        if exists $opts{config_files};
    $self->depends($opts{depends})
        if exists $opts{depends};
    $self->description($opts{description})
        if exists $opts{description};
    $self->filename($opts{filename})
        if exists $opts{filename};
    $self->maintainer($opts{maintainer})
        if exists $opts{maintainer};
    $self->name($opts{name})
        if exists $opts{name};
    $self->preinst_script($opts{preinst_script})
        if exists $opts{preinst_script};
    $self->postinst_script($opts{postinst_script})
        if exists $opts{postinst_script};
    $self->prerm_script($opts{prerm_script})
        if exists $opts{prerm_script};
    $self->postrm_script($opts{postrm_script})
        if exists $opts{postrm_script};

    # initialize properties with defaults
    $self->architecture(exists $opts{architecture} ?
        $opts{architecture} : $self->default_architecture);
    $self->priority(exists $opts{priority} ?
        $opts{priority} : $self->default_priority);
    $self->section(exists $opts{section} ?
        $opts{section} : $self->default_section);
    $self->version(exists $opts{version} ?
        $opts{version} : $self->default_version);

    # initialize internal archives
    $self->{TAR_CONTROL} = undef; # create when saving
    $self->{TAR_DATA} = Archive::Tar->new();
    $self->{TAR_IPKG} = undef; # create when saving

    return $self;
}

# control property checking
sub sloppy_checks {
    my $self = shift;
    
    $self->{sloppy} = 1;
}

sub strict_checks {
    my $self = shift;

    $self->{sloppy} = 0;
}


# default values for properties
sub default_architecture {
    return "arm";
}

sub default_priority {
    return "optional";
}

sub default_section {
    return "misc";
}

sub default_version {
    return "";
}

# accessor functions for properties
sub config_files {
    my $self = shift;
    my $config_files = shift;

    $self->{config_files} = $config_files
        if (defined $config_files && ref $config_files);
    return $self->{config_files};
}

sub depends {
    my $self = shift;
    my $depends = shift;
    
    return $self->{depends} unless defined $depends;

    if ($self->{sloppy} || $depends =~ /^[a-z0-9.+-]+(,[a-z0-9.+-]+)*$/) {
        $self->{depends} = $depends;
    } else {
        $self->{depends} = undef;
    }
    
    return $self->{depends};
}

sub description {
    my $self = shift;
    my $description = shift;
    
    return $self->{description} unless defined $description;

    if ($self->{sloppy} || $description =~ /\S/) {
        $self->{description} = $description;
    } else {
        $self->{description} = undef;
    }
    
    return $self->{description};
}

sub filename {
    my $self = shift;
    my $filename = shift;
    
    if (defined $filename) {
        $self->{filename} = $filename;
    } elsif (!defined $self->{filename}) {
        if (defined $self->{name}) {
	    $self->{filename} = $self->{name};

	    $self->{filename} .= "_" . $self->{version}
                if (defined $self->{version} && 
		    $self->{version} =~ /\S/);
	    $self->{filename} .= "_" . $self->{architecture}
                if (defined $self->{architecture} && 
		    $self->{architecture} =~ /\S/);
	    $self->{filename} .= ".ipk";
	}
    }
    
    return $self->{filename};
}

sub maintainer {
    my $self = shift;
    my $maintainer = shift;

    return $self->{maintainer} unless defined $maintainer;
    
    if ($self->{sloppy} || $maintainer =~ /\@/) {
        $self->{maintainer} = $maintainer;
    } else {
        $self->{maintainer} = undef;
    }
    
    return $self->{maintainer};
}

sub name {
    my $self = shift;
    my $name = shift;

    return $self->{name} unless defined $name;

    if ($self->{sloppy} || $name =~ /^[a-z0-9.+-]+$/) {
        $self->{name} = $name;
    } else {
        $self->{name} = undef;
    }

    return $self->{name};
}

sub preinst_script {
    my $self = shift;
    my $preinst_script = shift;

    $self->{preinst_script} = $preinst_script if defined $preinst_script;
    return $self->{preinst_script};
}

sub postinst_script {
    my $self = shift;
    my $postinst_script = shift;

    $self->{postinst_script} = $postinst_script if defined $postinst_script;
    return $self->{postinst_script};
}

sub prerm_script {
    my $self = shift;
    my $prerm_script = shift;

    $self->{prerm_script} = $prerm_script if defined $prerm_script;
    return $self->{prerm_script};
}

sub postrm_script {
    my $self = shift;
    my $postrm_script = shift;

    $self->{postrm_script} = $postrm_script if defined $postrm_script;
    return $self->{postrm_script};
}

sub architecture {
    my $self = shift;
    my $architecture = shift;

    return $self->{architecture} unless defined $architecture;

    if ($self->{sloppy} || $architecture =~ /^arm|all$/) {
        $self->{architecture} = $architecture;
    } else {
        $self->{architecture} = undef;
    }

    return $self->{architecture};
}

sub priority {
    my $self = shift;
    my $priority = shift;

    return $self->{priority} unless defined $priority;

    if ($self->{sloppy} || $priority =~ /^required|standard|important|optional|extra$/) {
        $self->{priority} = $priority;
    } else {
        $self->{priority} = undef;
    }

    return $self->{priority};
}

sub section {
    my $self = shift;
    my $section = shift;

    my @zaurus_sections = qw(Games Multimedia Communications Settings
                             Utilities Applications Console Misc);
    my @familiar_sections = qw(admin base comm editors extras graphics libs
                               misc net text web x11);
    my $regex = '^' . join('|', @zaurus_sections, @familiar_sections) . '$';

    return $self->{section} unless defined $section;

    if ($self->{sloppy} || $section =~ $regex) {
        $self->{section} = $section;
    } else {
        $self->{section} = undef;
    }

    return $self->{section};
}

sub version {
    my $self = shift;
    my $version = shift;

    return $self->{version} unless defined $version;

    if ($self->{sloppy} ||
	($version =~ /^[a-zA-Z0-9.+]*$/ && $version =~ /\d/)) {
        $self->{version} = $version;
    } elsif ($version =~ /^\s*$/) {
	$self->{version} = "";
    } else {
        $self->{version} = undef;
    }

    return $self->{version};
}

# verification

sub verify {
    my $self = shift;
    my $verify = undef;
    
# required: package, version, architecture, maintainer, section, description
    $verify .= "No package name\n" unless (defined $self->{name});
    # version should be at least empty
    $verify .= "No version\n" unless (defined $self->{architecture});
    $verify .= "No architecture\n" unless (defined $self->{architecture});
    $verify .= "No maintainer\n" unless (defined $self->{maintainer});
    $verify .= "No section\n" unless (defined $self->{section});

    $verify .= "No description\n" unless (defined $self->{description});

    return $verify;
}

# file handling

sub add_files {
    my $self = shift;
    
    return $self->{TAR_DATA}->add_files(@_);
}

sub add_file {
    my $self = shift;
    my ($filename, $new_filename) = @_;

    $new_filename = $filename unless defined $new_filename;
    $new_filename =~ s|^/?|./|;
    
    return undef unless open(ADDFILE, "<$filename");
    binmode ADDFILE;
    local $/; undef $/;
    $self->{TAR_DATA}->add_data($new_filename, <ADDFILE>, { mode => 0100644 });
    close(ADDFILE);

    return 1;
}

sub add_file_by_data {
    my $self = shift;
    my ($filename, $data, $opts) = @_;

    $filename =~ s|^/?|./|;

    $opts = { mode => 0100644 }
      unless (defined $opts && ref $opts && exists $opts->{mode});

    return $self->{TAR_DATA}->add_data($filename, $data, $opts);
}

# whole archive handling

# returns "control" file contents
sub control {
    my $self = shift;

    my $control = '';

    $control .= "Package: " . $self->{name} . "\n";
    $control .= "Priority: " . $self->{priority} . "\n"
        if (defined $self->{priority});
    $control .= "Section: " . $self->{section} . "\n";
    $control .= "Version: " . $self->{version} . "\n";
    $control .= "Architecture: " . $self->{architecture} . "\n";
    $control .= "Maintainer: " . $self->{maintainer} . "\n";
    $control .= "Depends: " . $self->{depends} . "\n"
        if (defined $self->{depends});

    my $desc = $self->{description};
    # start lines with space
    $desc =~ s/\n/ \n/g;
    # start empty lines with space and .
    $desc =~ s/\n \n/\n .\n/g;
    $control .= "Description: $desc\n";

    return $control;
}

sub data {
    my $self = shift;
    
    return undef if $self->verify;
    # make control package
    $self->{TAR_CONTROL} = Archive::Tar->new();

    $self->{TAR_CONTROL}->add_data("./control", $self->control, { mode => 0100644 });
    foreach (qw(preinst postinst prerm postrm)) {
        $self->{TAR_CONTROL}->add_data("./$_", $self->{$_},
            {mode => 0100755}) if (defined $self->{$_});
    }

    $self->{TAR_CONTROL}->add_data("./conffiles",
        join"\n", $self->{config_files}, { mode => 0100644 })
        if (defined $self->{config_files} && ref $self->{config_files});

    # make package
    $self->{TAR_IPKG} = Archive::Tar->new();
    $self->{TAR_IPKG}->add_data("./debian-binary", "2.0\n", { mode => 0100644 });

    my ($tar_data);

    $tar_data = Compress::Zlib::memGzip($self->{TAR_DATA}->write());
    return undef unless defined $tar_data;
    $self->{TAR_IPKG}->add_data("./data.tar.gz",
        $tar_data, { mode => 0100644 });

    $tar_data = Compress::Zlib::memGzip($self->{TAR_CONTROL}->write());

    return undef unless defined $tar_data;
    $self->{TAR_IPKG}->add_data("./control.tar.gz",
        $tar_data, { mode => 0100644 });

    $tar_data = Compress::Zlib::memGzip($self->{TAR_IPKG}->write());
    return $tar_data;
}

sub write {
    my $self = shift;

    my $filename = $self->filename;
    my $data = $self->data;
    
    return undef unless ($filename && defined $data);

    open IPKG, ">$filename" or carp "Can't write iPKG '$filename': $!";
    binmode IPKG;
    print IPKG $data;
    close IPKG;
}

1;
__END__

=head1 NAME

Archive::Ipkg - Module for manipulation of iPKG archives

=head1 SYNOPSIS

  use Archive::Ipkg;

  my $ipkg = Archive::Ipkg->new(
    name    => 'foo',
    version => '0.1');

  $ipkg->add_files(@filenames);
  $ipkg->add_file($filename, $name_in_archive);
  $ipkg->add_file_by_data($filename, $data);

  $ipkg->name("changedmymind");
  $ipkg->description("Useless package of mine\nDon't use it!");
  $ipkg->version("0.0");

  $ipkg->write;
  my $data = $ipkg->data;


=head1 DESCRIPTION

This module aids in the construction of iPKG packages (See links below
for description of the implemented package format). The interface is
somewhat similar to that of L<Archive::Tar>, but with a couple
differences. I consider the module to be in a beta stage.

The typical workflow is as follows: Create a new object, add files to it, set
the properties of the iPKG package and write it to a file (or get the data as
a scalar). There are a number of properties, and many of them are compulsory
and need to be in a certain format. The module only generates the final
package if the specs are meet. See below for a description of all properties
and how to circumvent some of the checks.

=head1 CLASS METHODS

=head2 CONSTRUCTOR

=over 4

=item C<$ipkg = Archive::Ipkg-E<gt>new(...)>

The C<new> constructor creates a new object. You can pass any property to the
constructor, if you want, or set the properties later.

=back

=head2 ADDING FILES

The following functions add files to the internal data archive. All return
undef on failure.

=over 4

=item C<$ipkg-E<gt>add_files(@filenames)>

Is directly passed through to L<Archive::Tar> to add several files.

=item C<$ipkg-E<gt>add_file_by_data($filename, $data [, $properties_hash]);>

Is directly passed through to L<Archive::Tar> to add a file given its name,
contents and optionally some properties. See L<Archive::Tar> for a description
of the properties available.

=item C<$ipkg->add_file($filename, $name_in_archive)>

A convenience function that lets you add a file with a new name. Reads the
file's content and uses L<Archive::Tar>'s C<add_data> to add the file.

=back

=head2 WRITING THE PACKAGE

=over 4

=item C<$ctl = $ipkg-E<gt>control()>

Returns the text of the control file that will be written. You just need this
if you want to check the file.

=item C<$errmsg = $ipkg-E<gt>verify()>

Verifies whether the archive can be written by checking whether at least the
required properties are set (see below).
Returns an error message if unsuccessful, else undef (!).

=item C<$ipkg-E<gt>write()>

Writes the archive to disk, in the current directory. If no filename is given,
it uses the internally generated default filename (see filename property).
You can either set a filename of your own before writing or combine the default
filename and a directory name to save the package in the directory of your
choice. Returns undef on failure.

=item C<$ipkg-E<gt>data()>

Returns the archive data as a scalar. Unlike L<Archive::Tar>'s C<data>, this
does not return the internal data structures, but rather the archive's contents
as they would be written to disk. Returns undef on failure.

=back

=head2 PROPERTIES

The following properties are obligatory: name, version, architecture,
maintainer, section and description. Some of them have defaults set by the
module, though, so you don't need to set all of them. If a property needs to
be in a certain format, the accessor function will set the value to undef to
make your C<write> fail if you set an invalid value.

Except of C<sloppy_checks> and C<strict_checks>, all the following functions
will return undef if a new value is set and the syntax check fails, else
the properties (new) value.

=over 4

=item C<$ipkg-E<gt>sloppy_checks>

Will switch of all syntax checks in accessor functions. C<verify> will still
check whether all required properties are set.

=item C<$ipkg-E<gt>strict_checks>

Re-enables syntax checks in accessor functions (this is the default).

=item C<$ipkg-E<gt>architecture("arch")>

The architecture the module is supposed to work on. Currently either C<arm>
or C<all>

B<Default:> C<arm>

=item C<$ipkg-E<gt>config_files($array_ref)>

Marks a number of files (names contained in C<$array_ref>) as configuration
files, so ipkg will not automatically overwrite them. Note that you still
need to add the files. Will not check whether the files are actually
contained in the archive.

B<Default:> No config files

=item C<$ipkg-E<gt>depends("pkg1,pkg2")>

The packages this package depends on, as a comma-separated list of package
names (ie, matching /^[a-z0-9.+-]+(,[a-z0-9.+-]+)*$/ ).

B<Default:> No depends

=item C<$ipkg-E<gt>description("text, even on\nmultiple lines")>

A short description of the module. Note that C<data> and C<write> will take
appropriate care of newlines, so you don't have to do it yourself. Just write
C<\n>, as you normally would The description should be non-empty.

B<Default:> No description, you need to set one.

=item C<$ipkg-E<gt>filename("../foo.ipk")>

The filename (including directory) of the module.

B<Default:> C<$name_$version_$arch.ipkg>

=item C<$ipkg-E<gt>maintainer("Bozo the Clown, bozo@clowns.org")>

The maintainer's name and e-mail address (ie, matches /@/).

=item C<$ipkg-E<gt>name("foo")>

The package name. Matches /^[a-z0-9.+-]+$/.

B<Default:> No name, you need to set one.

=item C<$ipkg-E<gt>priority("optional")>

The package's priority. One of required, standard, important, optional, extra.

B<Default:> C<optional>

=item C<$ipkg-E<gt>section("misc")>

The package's section. Currently, the sections given in the Zaurus and in the
Familiar documentation are allowed. These are the following:

Zaurus: Games Multimedia Communcations Settings Utilities Applications Console Misc

Familiar: admin base comm editors extras graphics libs misc net text web x11

B<Default:> C<misc>

=item C<$ipkg-E<gt>version("1.2")>

The package's version, matching /^[a-zA-Z0-9.+]*$/ and having at least one
digit.

B<Default:> No version, you need to set one.

=item C<$ipkg-E<gt>preinst_script($script_text)>

(Shell) script to be executed before installation.

B<Default:> No script

=item C<$ipkg-E<gt>postinst_script($script_text)>

(Shell) script to be executed after installation.

B<Default:> No script

=item C<$ipkg-E<gt>prerm_script($script_text)>

(Shell) script to be executed before removal.

B<Default:> No script

=item C<$ipkg-E<gt>postrm_script($script_text)>

(Shell) script to be executed after removal.

B<Default:> No script

=back

=head2 DEFAULTS METHODS

The following methods return the default values for the properties above.

=over 4

=item C<my $val = $ipkg-E<gt>default_architecture>

=item C<my $val = $ipkg-E<gt>default_priority>

=item C<my $val = $ipkg-E<gt>default_section>

=item C<my $val = $ipkg-E<gt>default_version>

=back

=head1 BUGS

Can't read archives (yet).


=head1 AUTHOR

Christian Renz E<lt>crenz@web42.comE<gt>

=head1 LICENSE

Copyright 2003 Christian Renz E<lt>crenz@web42.comE<gt>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://handhelds.org/moin/moin.cgi/Ipkg?action=highlight&value=iPKG

http://handhelds.org/moin/moin.cgi/BuildingIpkgs?action=highlight&value=iPKG

=cut
