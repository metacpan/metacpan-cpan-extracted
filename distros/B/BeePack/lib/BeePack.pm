package BeePack;
# ABSTRACT: Primitive MsgPack based key value storage
our $VERSION = '0.200';

use Moo;
use bytes;
use CDB_File;
use Data::MessagePack;
use Carp qw( croak );

sub true { Data::MessagePack::true() }
sub false { Data::MessagePack::false() }

# CDB_File has no in-place update, so the source of truth is an in-memory
# buffer of key => raw MsgPack bytes, seeded from the existing file on open
# and written back out atomically on save.
has _data => (
  is => 'lazy',
  init_arg => undef,
);

sub _build__data {
  my ( $self ) = @_;
  my %data;
  if ( -f $self->filename ) {
    tie my %cdb, 'CDB_File', $self->filename
      or croak("Can't open BeePack ".$self->filename.": ".$!);
    %data = %cdb;
    untie %cdb;
  } elsif ( $self->readonly ) {
    croak("Can't open non-existing readonly database ".$self->filename);
  }
  return \%data;
}

sub keys {
  my ( $self ) = @_;
  return CORE::keys %{$self->_data};
}

has filename => (
  is => 'ro',
  required => 1,
);

has tempfile => (
  is => 'ro',
  predicate => 1,
);

has nil_exists => (
  is => 'lazy',
);

sub _build_nil_exists { 0 }

has readonly => (
  is => 'lazy',
);

sub _build_readonly {
  my ( $self ) = @_;
  return $self->has_tempfile ? 0 : 1;
}

has data_messagepack => (
  is => 'lazy',
  init_arg => undef,
);

sub _build_data_messagepack { Data::MessagePack->new->canonical->utf8 }

sub BUILD {
  my ( $self ) = @_;
  croak("Read/Write opening requires tempfile") if !$self->readonly && !$self->has_tempfile;
  $self->_data;
  $self->data_messagepack;
}

sub open {
  my ( $class, $filename, $tempfile, %attr ) = @_;
  return $class->new(
    filename => $filename,
    defined $tempfile ? ( tempfile => $tempfile ) : (),
    %attr,
  );
}

sub set {
  my ( $self, $key, $value ) = @_;
  $self->readonly_check;
  $self->_data->{$key} = $self->data_messagepack->pack($value);
}

sub readonly_check {
  my ( $self ) = @_;  
  croak("Trying to set on readonly BeePack") if $self->readonly;
}

sub set_type {
  my ( $self, $key, $type, $value ) = @_;
  $self->readonly_check;
  my $t = defined $type ? substr($type,0,1) : '';
  if ($t eq 'i') {
    $self->set_integer($key,$value);
  } elsif ($t eq 'b') {
    $self->set_bool($key,$value);
  } elsif ($t eq 's') {
    $self->set_string($key,$value);
  } elsif ($t eq 'n') {
    $self->set_nil($key,$value);
  } elsif ($t eq 'a') {
    my @array = @{$value};
    $self->set($key,\@array);
  } elsif ($t eq 'h') {
    my %hash = %{$value};
    $self->set($key,\%hash);
  } elsif ($t eq '') {
    $self->set($key,$value);
  }
}

sub set_integer {
  my ( $self, $key, $value ) = @_;
  $self->set($key, 0 + $value);
}

sub set_bool {
  my ( $self, $key, $value ) = @_;
  $self->set($key, $value
    ? Data::MessagePack::true()
    : Data::MessagePack::false()
  );
}

sub set_string {
  my ( $self, $key, $value ) = @_;
  $self->set($key, "$value");
}

sub set_nil {
  my ( $self, $key ) = @_;
  $self->set($key, undef);
}

sub exists {
  my ( $self, $key ) = @_;
  return 0 unless CORE::exists $self->_data->{$key};
  return 1 if $self->nil_exists;
  my $value = $self->data_messagepack->unpack($self->_data->{$key});
  return defined $value ? 1 : 0;
}

sub get {
  my ( $self, $key ) = @_;
  return undef unless $self->exists($key);
  return $self->data_messagepack->unpack($self->_data->{$key});
}

sub get_raw {
  my ( $self, $key ) = @_;
  return $self->_data->{$key};
}

sub save {
  my ( $self ) = @_;
  croak("Trying to save readonly CDB ".$self->filename) if $self->readonly;
  my $cdb = CDB_File->new($self->filename,$self->tempfile)
    or croak("Can't create BeePack ".$self->filename.": ".$!);
  for my $key ( sort CORE::keys %{$self->_data} ) {
    $cdb->insert($key,$self->_data->{$key});
  }
  $cdb->finish;
  # in-memory buffer stays the source of truth, so the pack is usable for
  # further reads and writes after save
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeePack - Primitive MsgPack based key value storage

=head1 VERSION

version 0.200

=head1 SYNOPSIS

  use BeePack;

  # read only opening, error if fail
  my $beepack_ro = BeePack->open('my.bee');
  # read/write opening (with temp file), create if missing
  my $beepack_rw = BeePack->open('my.bee', 'my.bee.'.$$);
  # read only opening with nil_exists set
  my $beepack_ro = BeePack->open('my.bee', undef, nil_exists => 1 );

  $beepack_rw->set( key => $value ); # overwrite value

  $beepack_rw->set_integer( key => $value );   # force integer
  $beepack_rw->set_type( key => i => $value ); # alternative way
  $beepack_rw->set_bool( key => $value );      # force bool
  $beepack_rw->set_type( key => b => $value ); # alternative way
  $beepack_rw->set_string( key => $value );    # force stringification
  $beepack_rw->set_type( key => s => $value ); # alternative way
  $beepack_rw->set_nil( 'key' );       # set nil value
  $beepack_rw->set_type( key => 'n' ); # alternative way

  # array of 2 true bool
  $beepack_rw->set( key => [
    BeePack->true, BeePack->true,
  ]);

  # hash with true and false bool
  $beepack_rw->set( key => {
    false => BeePack->false,
    true => BeePack->true,
  });

  $beepack_rw->save; # save changes and reopen

  my $value = $beepack_ro->get('key');

  # getting the raw msgpack bytes
  my $msgpack = $beepack_ro->get_raw('key');

=head1 DESCRIPTION

B<BeePack> is made out of the requirement to encapsule small key values and
giant binary blobs into a compact file format for exchange and easy update
even with the low amount of microcontroller memory.

Technical B<BeePack> is B<CDB> with additionally using B<MsgPack> for storing
the values inside the B<CDB>. We picked B<MsgPack> for the inner storage, to not
reinvent the wheel of storing interoperational values (like B<BeePack> generated
on a Linux machine with x86 while being read by a microcontroller with ARM).

For simplification we do NOT store several values for a key inside the B<CDB>,
which is a capability of B<CDB>. By default B<BeePack> is saying a key that has a
nil value doesn't exist. You can deactivate this behaviour by setting the
B<nil_exists> attribute to B<1> on B<open>.

We also simplify the implementation of B<MsgPack> inside the B<BeePack> with
not allowing specific types in there. Because of the usage of L<Data::MessagePack>
this implementation will still flawless read them, while all types we are
excluding are also those you can't get out of L<Data::MessagePack>, so the Perl
implementation is anyway not capable of adding them to the B<BeePack>. The C
implementation will be getting strict on this.

This distribution includes L<bee>, which is a little tool to read, generate and
manipulate B<BeePack> from the comandline.

=head2 true

  my $true = BeePack->true;

Returns the MsgPack C<true> boolean singleton (from L<Data::MessagePack>), for
building booleans inside arrays and hashes passed to L</set>. See L</set_bool>
to force a single key to a boolean directly.

=head2 false

  my $false = BeePack->false;

Returns the MsgPack C<false> boolean singleton, the counterpart to L</true>.

=head2 filename

The path to the C<.bee> file on disk. Required, and read-only after
construction. Used both to read the existing file on open and, on L</save>,
as the destination C<CDB_File> renames the rebuilt file onto.

=head2 tempfile

The path C<CDB_File> uses to build the new file before atomically renaming it
onto L</filename> on L</save>. Its presence -- not a separate flag -- is what
switches the pack to read/write mode: give a C<tempfile> (to L</open> or
C<new>) and L</readonly> defaults to false; leave it out and the pack opens
read-only. A pack that is not readonly but has no C<tempfile> is rejected at
construction ("Read/Write opening requires tempfile").

=head2 nil_exists

  BeePack->open('my.bee', undef, nil_exists => 1);

Controls whether a key holding a nil (C<undef>) value counts as existing.
Defaults to false, so by default L</exists> (and therefore L</get>) treats a
nil-valued key exactly like an absent one. Set it to true to make L</exists>
return true for a key that is present in the pack regardless of whether its
value happens to be nil.

=head2 readonly

Whether the pack refuses writes: every setter and L</save> croak on a
readonly pack instead of mutating it. Lazily derives to true when no
L</tempfile> was given and false when one was -- so the normal way to control
this is by giving or withholding C<tempfile>, not by setting C<readonly>
directly. It can still be passed explicitly to the constructor (for example,
to open a pack with a tempfile but keep it read-only); passing it as false
without a C<tempfile> is rejected at construction instead.

=head2 open

  my $beepack = BeePack->open($filename);                      # read-only
  my $beepack = BeePack->open($filename, $tempfile);            # read/write
  my $beepack = BeePack->open($filename, undef, nil_exists=>1); # read-only, nil_exists

Constructor helper: turns the positional C<$filename>/C<$tempfile> pair into
the matching named constructor arguments and calls C<new>. C<$tempfile> may
be C<undef> to open read-only while still passing further C<%attr> (such as
C<nil_exists>) through to C<new>.

=head2 keys

  my @keys = $beepack->keys;

Returns the keys currently in the pack, in whatever order the underlying hash
buffer yields them -- unlike L</save>, this does not sort.

=head2 set

  $beepack->set( $key => $value );

MsgPack-packs C<$value> exactly as given (however Perl and L<Data::MessagePack>
currently see its type) and stores it in the in-memory buffer under C<$key>,
overwriting any existing value for that key. Nothing reaches disk until
L</save>. Croaks on a L</readonly> pack. Use L</set_integer>, L</set_bool>,
L</set_string> or L</set_nil> instead when the MsgPack type must be pinned
regardless of how the Perl scalar happens to be flagged.

=head2 set_type

  $beepack->set_type( $key => $type => $value );

Alternate setter that dispatches on the first character of C<$type> -- the
same single-letter scheme the C<bee> command line uses (see
L<bee/DESCRIPTION>): C<i> integer (L</set_integer>), C<b> bool
(L</set_bool>), C<s> string (L</set_string>), C<n> nil (L</set_nil>;
C<$value> is ignored), C<a> array (L</set> with C<$value> dereferenced as an
arrayref), C<h> hash (L</set> with C<$value> dereferenced as a hashref), or
an empty/undefined C<$type> for a plain L</set>. A new type letter is a
paired change: add the branch here and the matching branch in C<bee>'s
command-line dispatch.

=head2 set_integer

  $beepack->set_integer( $key => $value );

Forces C<$value> to a MsgPack integer (Perl's C<0 + $value>) and L</set>s it,
regardless of how C<$value> is currently represented.

=head2 set_bool

  $beepack->set_bool( $key => $value );

Forces C<$value> to a MsgPack boolean -- L</true> if C<$value> is true in Perl
terms, L</false> otherwise -- and L</set>s it.

=head2 set_string

  $beepack->set_string( $key => $value );

Forces C<$value> to a MsgPack string (Perl's C<"$value">) and L</set>s it,
regardless of how C<$value> is currently represented.

=head2 set_nil

  $beepack->set_nil( $key );

Sets C<$key> to a MsgPack nil (C<undef>). See L</nil_exists> for how a
nil-valued key interacts with L</exists>.

=head2 exists

  my $bool = $beepack->exists( $key );

Returns false when C<$key> is not in the buffer at all. Otherwise, returns
true unconditionally when L</nil_exists> is set; when it is not, unpacks the
value and returns true only if that value is defined -- so by default a
nil-valued key is reported as not existing.

=head2 get

  my $value = $beepack->get( $key );

Returns C<undef> when L</exists> says C<$key> doesn't exist (which, by
default, includes a key whose stored value is nil -- see L</nil_exists>);
otherwise unpacks and returns the stored value.

=head2 get_raw

  my $bytes = $beepack->get_raw( $key );

Returns the raw MsgPack-encoded bytes stored for C<$key>, unchanged -- no
unpack and no L</exists> check -- or C<undef> if the key is absent from the
buffer. Useful for passing an opaque value (such as a gzipped blob) straight
through without paying for an unpack/repack round trip.

=head2 save

  $beepack->save;

Rebuilds the on-disk C<.bee> file from the in-memory buffer: since
L<CDB_File> has no in-place update, this creates a fresh C<CDB_File> at
L</filename> via L</tempfile>, inserts every buffered key in sorted order (so
the on-disk file is deterministic regardless of hash iteration order, though
not necessarily byte-identical across cdb implementations), and finishes it,
which atomically renames the tempfile onto C<filename>. The in-memory buffer
remains the source of truth afterwards, so the pack stays usable for further
L</get>/L</set> calls without reopening. Croaks on a L</readonly> pack.

=head1 SEE ALSO

=head2 L<bee>

=head2 L<CDB_File>

=head2 L<Data::MessagePack>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/cindustries/p5-beepack/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
