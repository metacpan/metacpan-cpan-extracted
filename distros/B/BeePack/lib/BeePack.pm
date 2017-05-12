package BeePack;
BEGIN {
  $BeePack::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Primitive MsgPack based key value storage
$BeePack::VERSION = '0.102';
use Moo;
use bytes;
use CDB::TinyCDB;
use Data::MessagePack;
use Carp qw( croak );

sub true { Data::MessagePack::true() }
sub false { Data::MessagePack::false() }

# currently workaround to be reset
has cdb => (
  is => 'rw',
  lazy => 1,
  builder => 1,
  init_arg => undef,
  handles => [qw(
    keys
  )],
);

sub _build_cdb {
  my ( $self ) = @_;
  return -f $self->filename
    ? CDB::TinyCDB->open($self->filename, $self->has_tempfile ? (
        for_update => $self->tempfile
      ) : ())
    : $self->readonly
      ? croak("Can't open non-existing readonly database ".$self->filename)
      : CDB::TinyCDB->create($self->filename,$self->tempfile);
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
  $self->cdb;
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
  $self->cdb->put_replace($key,$self->data_messagepack->pack($value));
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
  return 0 unless $self->cdb->exists($key);
  return $self->cdb->exists($key) if $self->nil_exists;
  my $msgpack = $self->cdb->get($key);
  my $value = $self->data_messagepack->unpack($msgpack);
  return defined $value ? 1 : 0;
}

sub get {
  my ( $self, $key ) = @_;
  return undef unless $self->exists($key);
  return $self->data_messagepack->unpack(scalar $self->cdb->get($key));
}

sub get_raw {
  my ( $self, $key ) = @_;
  return scalar $self->cdb->get($key);
}

sub save {
  my ( $self ) = @_;
  croak("Trying to save readonly CDB ".$self->filename) if $self->readonly;
  $self->cdb->finish( save_changes => 1, reopen => 0 );
  # Bug in CDB::TinyCDB? reopen => 1 is not reopening
  $self->cdb(undef);
  $self->cdb($self->_build_cdb);
  return 1;
}

1;

__END__

=pod

=head1 NAME

BeePack - Primitive MsgPack based key value storage

=head1 VERSION

version 0.102

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

=head1 SEE ALSO

=head2 L<bee>

=head2 L<CDB::TinyCDB>

=head2 L<Data::MessagePack>

=head1 SUPPORT

IRC

  Join #vonBienenstock on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/vonBienenstock/p5-beepack
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/vonBienenstock/p5-beepack/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
