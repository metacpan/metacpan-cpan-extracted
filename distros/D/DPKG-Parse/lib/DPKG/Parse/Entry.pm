=head1 NAME

DPKG::Parse::Entry - Parse a Package style entry

=head1 SYNOPSIS

    use DPKG::Parse::Entry;

    my $data = <<EOH;
 Package: kernel-image-2.6.12.2
 Source: kernel-source-2.6.12.2
 Version: wrk01
 Priority: optional
 Section: base
 Maintainer: Jamie Heilman <jamie@marchex.com>
 Depends: coreutils | fileutils (>= 4.0)
 Suggests: lilo (>= 19.1) | grub, fdutils, kernel-doc-2.6.12.2 | kernel-source-2.6.12.2
 Provides: kernel-image, kernel-image-2.6
 Architecture: i386
 Filename: packages/./kernel-image-2.6.12.2_wrk01_i386.deb
 Size: 4293154
 Installed-Size: 10312
 MD5sum: 2acf846b127b71a1fa1143214b2b85a9
 Description: Linux kernel binary image for version 2.6.12.2.
 EOH

    my $entry = DPKG::Parse::Entry->new('data' => $data);

    print $entry->package . " " . $entry->version . "\n";

    $entry->package("kernel-foobar");

=head1 DESCRIPTION

L<DPKG::Parse::Entry> parses a dpkg "Package" file entry, creating a new
L<DPKG::Parse::Entry> instance for it.  You submit the contents, beginning
with a "Package:" line, as the 'data' argument to new.  After that, all
the data is populated as lowercased instance methods.  For example, if
we used the above to create an $entry object, we would have:

   $entry->package == "kernel-image-2.6.12.2"
   $entry->size    == 4293154
   $entry->md5sum  == 2acf846b127b71a1fa1143214b2b85a9

L<DPKG::Parse::Entry> will skip any attribute it does not know about.  You
can see what it has skipped by passing a true value to the 'debug' option to
'new()'.

It should know all the attributes present in a Packages, available, and
status file.

See L<DPKG::Parse::Status>, L<DPKG::Parse::Available>, and
L<DPKG::Parse::Packages> for more information on how to easily generate
DPKG::Parse::Entry objects.

=head1 METHODS

=over 4

=cut

package DPKG::Parse::Entry;

our $VERSION = '0.03';

use Params::Validate qw(:all);
use base qw(Class::Accessor);
use Carp;
use strict;
use warnings;

DPKG::Parse::Entry->mk_accessors(qw(
    architecture
    bugs
    build_essential
    conflicts
    config_version
    conffiles
    depends
    description
    enhances
    essential
    filename
    installed_size
    maintainer
    md5sum
    origin
    package
    priority
    provides
    pre_depends
    recommends
    replaces
    size
    source
    section
    suggests
    status
    task
    tag
    url
    version
    original_maintainer
    homepage
    breaks
    python_version
    multi_arch
    gstreamer_decoders
    gstreamer_elements
    gstreamer_encoders
    gstreamer_uri_sources
    gstreamer_version
    python_runtime
    npp_applications
    npp_file
    npp_mimetype
    npp_name
    npp_description
    python_runtime
    gstreamer_uri_sinks
    xul_appid
    original_vcs_browser
    original_vcs_git
));

DPKG::Parse::Entry->mk_ro_accessors(qw(__debug __line_num));

=item Accessor Methods

The following accessor methods correspond directly to the values found in
the parsed Package block, with one exception: "-" characters are replaced
with "_".  So, "build-essential" becomes "build_essential".

The accessors are:

    architecture
    bugs
    build_essential
    conflicts
    config_version
    conffiles
    depends
    description
    enhances
    essential
    filename
    installed_size
    maintainer
    md5sum
    origin
    package
    priority
    provides
    pre_depends
    recommends
    replaces
    size
    source
    section
    suggests
    status
    task
    tag
    url
    version

=item new('data' => $data, 'debug' => 1)

Creates a new L<DPKG::Parse::Entry> object.  'data' should be a scalar that
contains the text of a dpkg-style Package entry.  If the 'debug' flag is
set, we will Carp about entries we don't have accessors for.

=cut
sub new {
    my $pkg = shift;
    my %p = validate(@_,
        {
            'data' => { 'type' => SCALAR, 'optional' => 1 },
            'debug' => { 'type' => SCALAR, 'default' => 0, 'optional' => 1 },
            'line_num' => { type => SCALAR, default => 0, optional => 1 }
        }
    );
    my $ref = {
        __debug => $p{debug},
        __line_num => $p{line_num}
    };
    bless($ref, $pkg);
    if ($p{'data'}) {
        $ref->parse('data' => $p{'data'});
    };
    return $ref;
}

=item parse('data' => $data);

Does the actual parsing of the Package block given to new().  Probably
should only be called once per object.

=cut
sub parse {
    my $pkg = shift;
    my %p = validate(@_,
        {
            'data' => { 'type' => SCALAR, 'optional' => 1 },
        },
    );
    my $field;
    my $contents;
    my $line_num = $pkg->__line_num;
    foreach my $line (split(/\n/, $p{'data'})) {
        ++$line_num;
        if ($line =~ /^([\w|-]+): (.+)$/) {
            $field = $1;
            $contents = $2;
            $field = lc($field);
            $field =~ s/-/_/g;
            if ($pkg->can($field)) {
                $pkg->$field($contents);
            } else {
                if ($pkg->__debug) {
                    carp "line ${line_num}: I don't know about field '${field}'\n";
                }
                next;
            }
        } elsif ($line =~ /^ / && $field) {
            $line =~ s/^ //g;
            $line =~ s/^.$//g;
            if ($contents !~ /\n$/) {
                $contents = $contents . "\n" . $line . "\n";
            } else {
                $contents = $contents . $line;
            }
            if ($pkg->can($field)) {
                $pkg->$field($contents);
            } else {
                if ($pkg->__debug) {
                    carp "line ${line_num}: I don't know about field '${field}'\n";
                }
                next;
            }
        } elsif ($line =~ /^([\w|-]+):\s*$/) {
            $field = $1;
            $field = lc($field);
            $field =~ s/-/_/g;
            if ($pkg->can($field)) {
                $pkg->$field("");
            } else {
                if ($pkg->__debug) {
                    carp "line ${line_num}: I don't know about field '${field}'\n";
                }
                next;
            }
        } else {
            die "line ${line_num}: I have no idea what to do with '${line}'!\n";
        }
    }
}

=back

=cut

1;

