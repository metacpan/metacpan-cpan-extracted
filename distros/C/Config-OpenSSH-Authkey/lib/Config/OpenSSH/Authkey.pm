# -*- Perl -*-
#
# methods to interact with OpenSSH authorized_keys file data
#
# run perldoc(1) on this file for additional documentation

package Config::OpenSSH::Authkey;

use 5.006000;
use strict;
use warnings;

use Carp qw(croak);
use Config::OpenSSH::Authkey::Entry ();

use IO::Handle qw(getline);

our $VERSION = '1.06';

######################################################################
#
# Utility Methods - Internal

{
    # Utility class for comments or blank lines in authorized_keys files
    package Config::OpenSSH::Authkey::MetaEntry;

    sub new {
        my $class = shift;
        my $entry = shift;
        bless \$entry, $class;
    }

    sub as_string {
        ${ $_[0] };
    }
}

######################################################################
#
# Class methods

sub new {
    my $class       = shift;
    my $options_ref = shift || {};

    my $self = {
        _fh                  => undef,
        _keys                => [],
        _seen_keys           => {},
        _auto_store          => 0,
        _tag_dups            => 0,
        _nostore_nonkey_data => 0
    };

    for my $pref (qw/auto_store tag_dups nostore_nonkey_data/) {
        if ( exists $options_ref->{$pref} ) {
            $self->{"_$pref"} = $options_ref->{$pref} ? 1 : 0;
        }
    }

    bless $self, $class;
    return $self;
}

######################################################################
#
# Instance methods

sub fh {
    my $self = shift;
    my $fh   = shift || croak 'fh requires a filehandle';

    $self->{_fh} = $fh;
    return $self;
}

sub file {
    my $self = shift;
    my $file = shift || croak 'file requires a file';

    my $fh;
    open( $fh, '<', $file ) or croak $!;
    $self->{_fh} = $fh;

    return $self;
}

sub iterate {
    my $self = shift;
    croak 'no filehandle to iterate on' if !defined $self->{_fh};

    my $line = $self->{_fh}->getline;
    return defined $line ? $self->parse($line) : ();
}

sub consume {
    my $self = shift;
    croak 'no filehandle to consume' if !defined $self->{_fh};

    my $old_auto_store = $self->auto_store();
    $self->auto_store(1);

    while ( my $line = $self->{_fh}->getline ) {
        $self->parse($line);
    }

    $self->auto_store($old_auto_store);

    return $self;
}

sub parse {
    my $self = shift;
    my $data = shift || croak 'need data to parse';

    my $entry;

    if ( $data =~ m/^\s*(?:#|$)/ ) {
        chomp($data);
        $entry = Config::OpenSSH::Authkey::MetaEntry->new($data);
        if ( $self->{_auto_store} and !$self->{_nostore_nonkey_data} ) {
            push @{ $self->{_keys} }, $entry;
        }
    } else {
        $entry = Config::OpenSSH::Authkey::Entry->new($data);
        if ( $self->{_tag_dups} ) {
            if ( exists $self->{_seen_keys}->{ $entry->key } ) {
                $entry->duplicate_of( $self->{_seen_keys}->{ $entry->key } );
            } else {
                $self->{_seen_keys}->{ $entry->key } = $entry;
            }
        }
        push @{ $self->{_keys} }, $entry if $self->{_auto_store};
    }

    return $entry;
}

sub get_stored_keys {
    shift->{_keys};
}

sub reset_store {
    my $self = shift;
    $self->{_seen_keys} = {};
    $self->{_keys}      = [];
    return $self;
}

sub reset_dups {
    my $self = shift;
    $self->{_seen_keys} = {};
    return $self;
}

sub auto_store {
    my $self    = shift;
    my $setting = shift;
    if ( defined $setting ) {
        $self->{_auto_store} = $setting ? 1 : 0;
    }
    return $self->{_auto_store};
}

sub tag_dups {
    my $self    = shift;
    my $setting = shift;
    if ( defined $setting ) {
        $self->{_tag_dups} = $setting ? 1 : 0;
    }
    return $self->{_tag_dups};
}

sub nostore_nonkey_data {
    my $self    = shift;
    my $setting = shift;
    if ( defined $setting ) {
        $self->{_nostore_nonkey_data} = $setting ? 1 : 0;
    }
    return $self->{_nostore_nonkey_data};
}

1;

__END__

=head1 NAME

Config::OpenSSH::Authkey - interface to OpenSSH authorized_keys data

=head1 SYNOPSIS

  use Config::OpenSSH::Authkey ();
  my $ak = Config::OpenSSH::Authkey->new;
  
  $ak->file( 'authorized_keys' );
  
  while (my $entry = $ak->iterate) {
    ...

=head1 DESCRIPTION

This module provides an interface to the entries in an OpenSSH
C<authorzied_keys> file. Both SSH1 and SSH2 protocol public keys are
supported. L<Config::OpenSSH::Authkey::Entry> provides an interface to
individual entries (lines) in the C<authorzied_keys> file.

=over 4

=item *

The B<AUTHORIZED_KEYS FILE FORMAT> section of sshd(8) details the format
of C<authorzied_keys> entries.

=item *

Consult the L</"OPTIONS"> section for means to customize how this
module operates.

=back

=head2 Caveats

This is a pure Perl interface, so may differ from how OpenSSH parses the
C<authorzied_keys> data. The sshd(8) manual and OpenSSH 5.2 source code
were consulted in the creation of this module. C<authorzied_keys> file
options, in particular, are not checked for validity: this module will
parse the valid C<no-pty> option along with the invalid C<asdf>. This
makes the module future proof against options being added to OpenSSH, at
the cost of passing potentially garbage data around.

=head2 Ruminations on Managing authorized_keys Files

OpenSSH C<authorized_keys> files could be managed by a user, or by a
centralized control system, or shared between different groups using the
same systems. Site legal or security policy may dictate how
C<authorized_keys> must be handled: how frequently the keys must be
rotated, whether port forwarding and so forth are permitted, whether to
restrict keys to only run specific commands.

=over 4

=item *

Centralized control is the easiest, as the raw keys will be stored under
configuration management, or in a database, or directory service, and
code will update the various supported C<authorized_keys> files,
removing (and possibly warning about) any unknown key entries. The code
should include a comment at the top of every managed C<authorized_keys>
file stating that the file is managed, and linking to instructions on
how to properly add or change keys.

=item *

Shared systems require caution; foreign keys must not be wiped out.
The easiest method is to include the target C<authorized_keys> file as
one of the sources for valid key material. A comment should be added
into to the C<authorized_keys> file, noting what keys are managed by
the software.

=back

Rotating C<authorized_keys> data is difficult, as the entries contain
no date related metadata like X.509 certificates do. Solutions would be
to schedule a yearly calendar event during which all the keys are
rotated, or maintain the keys in a database that includes a creation
date field on the record.

=head1 CLASS METHODS

=over 4

=item B<new>

Constructor method. Accepts a hash reference containing L</"OPTIONS">
that alter how the instance behaves.

  my $ak = Config::OpenSSH::Authkey->new({
    tag_dups => 1,
    nostore_nonkey_data => 1,
  });

=back

=head1 INSTANCE METHODS

=over 4

=item B<fh>

Accepts a filehandle, stores this handle in the instance, for future use
by B<iterate> or B<consume>.

=item B<file>

Accepts a filename, attempts to open this file, and store the resulting
filehandle in the instance for future use by B<iterate> or B<consume>.
Throws an exception if the file cannot be opened.

=item B<iterate>

Returns the next entry of the filehandle (or, lacking a filehandle in
the instance, throws an error. Call B<fh> or B<file> first). Returned
data will either be L<Config::OpenSSH::Authkey::MetaEntry> (comments,
blank lines) or L<Config::OpenSSH::Authkey::Entry> (public key) objects.

For example, to exclude SSHv1 C<authorized_keys> data, while retaining
all other data in the file:

  while (my $entry = $ak->iterate) {
    if ($entry->can("prototol")) {
      next if $entry->protocol == 1;
    }
    
    print $output_fh $entry->as_string, "\n";
  }

=item B<consume>

This method consumes all data in the B<fh> or B<file> opened in the
instance, and saves it to the module key store. The B<auto_store> option
is temporarily enabled to allow this. Set the B<nostore_nonkey_data>
option to avoid saving non-key material to the key store. Stored keys
can be accessed by calling the B<get_stored_keys> method.

=item B<parse> I<data>

Attempts to parse input data, either as a comment or blank line with
L"Config::OpenSSH::Authkey::MetaEntry>, or as a public key via
L<Config::OpenSSH::Authkey::Entry>. Will throw an exception if the
public key cannot be parsed.

Returns either an L<Config::OpenSSH::Authkey::MetaEntry> or
L<Config::OpenSSH::Authkey::Entry> object.

=item B<get_stored_keys>

Returns an array reference of any public keys stored in the instance.
B<keys> will only be populated if the B<auto_store> option is enabled.

Keys will be either L<Config::OpenSSH::Authkey::MetaEntry> (comments,
blank lines) or L<Config::OpenSSH::Authkey::Entry> (public key) objects.
To avoid storing comments and blank lines, enable the
B<nostore_nonkey_data> option before calling B<iterate> or B<consume>.

=item B<reset_store>

Removes all C<authorized_keys> entries stored by the instance. Also
removes all the seen keys from the duplicate check stash.

=item B<reset_dups>

Removes all the seen keys from the duplicate check stash. This method is
likely useless if a custom code reference has been installed to handle
the duplicate key checks.

=back

=head1 OPTIONS

The following options can be specified as arguments in a hash reference
to the B<new> method, or by calling the option name as a method. All
options default to false. Pass a true value to enable.

=over 4

=item B<auto_store> I<boolean>

Whether to store parsed entries in the instance. The default is to not
store any entries.

=item B<tag_dups> I<boolean>

Whether to check for duplicate C<authorized_keys> keys. The default is
to not check for duplicate keys. If this option is enabled, the
B<duplicate_of> method of L<Config::OpenSSH::Authkey::Entry> should be
used to check whether a particular entry is a duplicate.

=item B<nostore_nonkey_data> I<boolean>

Whether to store non-key data (comments, blank lines) in the auto-store
data structure. The default is to store these lines. The B<iterate>
method always returns these lines, regardless of this setting.

=back

=head1 Config::OpenSSH::Authkey::MetaEntry

Utility class that stores blank lines or comments. The object
supports an B<as_string> method that will return the line. Disable
the storage of this data in the key store by enabling the
B<nostore_nonkey_data> option.

Use the C<ref> function or the C<can> method to distinguish these
entries from L<Config::OpenSSH::Authkey::Entry> objects.

=head1 BUGS

No known bugs. Newer versions of this module may be available from CPAN.

If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

https://github.com/thrig/Config-OpenSSH-Authkey

=head1 SEE ALSO

sshd(8), L<Config::OpenSSH::Authkey::Entry>,
L<Config::OpenSSH::Authkey::Entry::Options>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT

Copyright 2009-2010,2012,2015,2019 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
