=head1 NAME

DPKG::Parse - Parse various dpkg files into Perl Objects

=head1 SYNOPSIS

    use DPKG::Parse::Status;
    my $status = DPKG::Parse::Status->new;
    while (my $entry = $status->next_package) {
        print $entry->package . " " . $entry->version . "\n";
    }

    use DPKG::Parse::Available;
    my $available = DPKG::Parse::Available->new;
    while (my $entry = $available->next_package) {
        print $entry->package . " " . $entry->version . "\n";
    }

=head1 DESCRIPTION

DPKG::Parse contains utilities to parse the various files created by
dpkg and turn them into helpful Perl objects.  Current files understood
by various DPKG::Parse modules:

  /var/lib/dpkg/status    - DPKG::Parse::Status
  /var/lib/dpkg/available - DPKG::Parse::Available
  Packages.gz             - DPKG::Parse::Packages

See each module's documentation for particulars - You should not be calling
DPKG::Parse directly.

=head1 METHODS

=over 4

=cut

package DPKG::Parse; # git description: v0.02-2-gca4c3e9

use Params::Validate qw(:all);
use DPKG::Parse::Entry;
use Class::C3;
use base qw(Class::Accessor);

use strict;
use warnings;

DPKG::Parse->mk_accessors(qw(filename entryarray entryhash));
DPKG::Parse->mk_ro_accessors('debug');

our $VERSION = '0.03';

=item filename($filename)

A simple accessor for the file currently being parsed.

=item entryarray

Access to the raw array of entries in a given file.

=item entryhash

Access to the raw hash of entries.  The key is determined by the module,
but is usually the Package name.

=item new('filename' => '/var/lib/dpkg/status');

A generic new function; takes a filename and calls the filename() accessor
with it.  Should not be called directly, but through on of the children of
this package.

=cut
sub new {
    my $pkg = shift;
    my %p = validate(@_,
        {
            'filename' => { 'type' => SCALAR, },
            'debug' => { 'type' => SCALAR, 'default' => 0, 'optional' => 1 }
        }
    );
    my $ref = {};
    if ($p{'filename'}) {
        $ref->{'filename'} = $p{'filename'};
    };
    $ref->{debug} = $p{debug};
    $ref->{'entryarray'} = [];
    $ref->{'entryhash'} = {};
    bless($ref, $pkg);
    return $ref;
}

=item parse

A default parse function; simply calls parse_package_format.

=cut
sub parse {
    my $pkg = shift;
    $pkg->parse_package_format;
}

=item parse_package_format

Takes a file in a format similar to the dpkg "available" file, and creates
L<DPKG::Parse::Entry> objects from each entry.

=cut
sub parse_package_format {
    my $pkg = shift;
    if (! -f $pkg->filename) {
        die "Cannot find " . $pkg->filename . ", or it's not a file at all!";
    }
    open(STATUS, $pkg->filename);
    my $entry;
    my $line_num = -1;
    my $entry_line = 0;
    STATUSLINE: while (my $line = <STATUS>) {
        ++$line_num;
        if ($line =~ /^\n$/) {
            my $dpkg_entry = DPKG::Parse::Entry->new('data' => $entry, debug => $pkg->debug, line_num => $entry_line);
            push(@{$pkg->{'entryarray'}}, $dpkg_entry);
            $pkg->{'entryhash'}->{$dpkg_entry->package} = $dpkg_entry;
            $entry = undef;
            $entry_line = $line_num + 1;
            next STATUSLINE;
        }
        $entry = $entry . $line;
    }
    close(STATUS);
}

=item get_package('name' => 'postfix', 'hash' => 'entryhash');

The value of a hash, if it exists.  By default, it uses the value returned
by the "entryhash" accessor, but that can be overridden with the "hash"
parameter.  Usually returns a L<DPKG::Parse::Entry> object.

=cut
sub get_package {
    my $pkg = shift;
    my %p = validate( @_,
        {
            'name' => { 'type' => SCALAR, },
            'hash' => { 'type' => SCALAR, 'default' => 'entryhash', },
        },
    );
    if (exists($pkg->{$p{'hash'}}->{$p{'name'}})) {
        return $pkg->{$p{'hash'}}->{$p{'name'}};
    } else {
        return undef;
    }
}

=item next_package

Shifts the next value off the array stored in the entryarray() accessor.
If you want to access the raw values, do not use this function!  It shifts!

=cut
sub next_package {
    my $pkg = shift;
    return shift(@{$pkg->{'entryarray'}});
}

1;

__END__
=back

=head1 SEE ALSO

L<DPKG::Parse::Status>, L<DPKG::Parse::Available>, L<DPKG::Parse::Packages>,
L<DPKG::Parse::Entry>

=head1 AUTHOR

Adam Jacob, C<holoway@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
