package DBIx::Class::DigestColumns;

use strict;
use warnings;

use vars qw($VERSION);
use base qw/DBIx::Class/;
use Digest;

__PACKAGE__->mk_classdata( 'digest_auto_columns' => [] );
__PACKAGE__->mk_classdata( 'digest_auto' => 1 );
__PACKAGE__->mk_classdata( 'digest_dirty' => 0 );
__PACKAGE__->mk_classdata( 'digest_maker' );
__PACKAGE__->mk_classdata( 'encoding' );

__PACKAGE__->digest_algorithm('MD5');
__PACKAGE__->digest_encoding('hex');

# Always remember to do all digits for the version even if they're 0
# i.e. first release of 0.XX *must* be 0.XX000. This avoids fBSD ports
# brain damage and presumably various other packaging systems too

$VERSION = '0.06000';

=head1 NAME

DBIx::Class::DigestColumns - Automatic digest columns

=head1 SYNOPSIS

In your L<DBIx::Class> table class:

  __PACKAGE__->load_components(qw/DigestColumns ... Core/);

  #automatically generate a method "check_password" in result class
  __PACKAGE__->add_columns(
    'password' => {
      data_type => 'char',
      size      => 32,
      digest_check_method => 'check_password',
  }
  __PACKAGE__->digestcolumns(
      columns   => [qw/ password /],
      algorithm => 'MD5',
      encoding  => 'base64',
      dirty     => 1,
      auto      => 1,
  );

B<Note:> The component needs to be loaded I<before> Core.

Alternatively you could call each method individually  

  __PACKAGE__->digest_columns(qw/ password /);
  __PACKAGE__->digest_algorithm('MD5');
  __PACKAGE__->digest_encoding('base64');
  __PACKAGE__->digest_dirty(1);
  __PACKAGE__->digest_auto(1);



=head1 DESCRIPTION

This L<DBIx::Class> component can be used to automatically insert a message
digest of selected columns. By default DigestColumns will use
L<Digest::MD5> to insert a 128-bit hexadecimal message digest of the column
value.

The length of the inserted string will be 32 and it will only contain characters
from this set: '0'..'9' and 'a'..'f'.

If you would like to use a specific digest module to create your message
digest, you can set L</digest_algorithm>:

  __PACKAGE__->digest_algorithm('SHA-1');

=head1 Options added to add_column

=head2 digest_check_method => $method_name

By using the digest_check_method attribute when you declare a column you
can create a check method for that column. The check method accepts a 
plain text string, performs the correct digest on it and returns a boolean
value indicating whether this method matches the currently_stored value.

  $row->password('old_password');
  $row->update;
  $row->password('new_password');
  $row->check_password('new_password'); #returns true
  $row->check_password('old_password'); #returns false
  $row->update;

=head1 METHODS

=head2 digestcolumns

  __PACKAGE__->digestcolumns(
      columns   => [qw/ password /],
      algorithm => $algorithm',
      encoding  => $encoding,
      dirty     => 1,
      auto      => 1,
  );

Calls L</digest_columns>, L</digest_algorithm>, and L</digest_encoding> and L</digest_auto> if the
corresponding argument is defined.

=cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);
    
    return unless defined $info->{'digest_check_method'};

    my $method_name = $info->{'digest_check_method'};
    my $result_class = $self->result_class;
    #don't overwrite another method
    $self->throw_exception("Can't create digest_check_method ${method_name}. ".
			   "{$method_name} already exists.") 
	if $self->can($method_name) || $result_class->can($method_name);;
    my $class_method_name = $result_class."::".$method_name;

    {
	no strict 'refs';
	*$class_method_name = sub{
	    my ($self, $value) = @_;
	    my $col_value = $self->get_column($column);
	    #make sure we DTRT if column is dirty
	    $col_value = $self->_get_digest_string($col_value)
		if $self->is_column_changed($column) && $self->digest_auto;

	    return $col_value eq $self->_get_digest_string($value);
	};
    }
}

=head2 register_column

Override the original register_column to handle the creation of
check methods.

=cut

sub digestcolumns {
    my $self = shift;
    my %args = @_;
    $self->digest_columns( @{$args{columns}} ) if exists $args{columns};
    $self->digest_algorithm( $args{algorithm} ) if exists $args{algorithm};
    $self->digest_encoding( $args{encoding} ) if exists $args{encoding};
    $self->digest_auto( $args{auto} ) if exists $args{auto};
    $self->digest_dirty( $args{dirty} ) if exists $args{dirty};
}

=head2 digest_columns

Takes a list of columns to be convert to a message digest during insert.

  __PACKAGE__->digest_columns(qw/ password /);

=cut

sub digest_columns {
    my $self = shift;
    for (@_) {
        $self->throw_exception("column $_ doesn't exist") unless $self->has_column($_);
    }
    $self->digest_auto_columns(\@_);
}

=head2 digest_algorithm

Takes the name of a digest algorithm to be used to calculate the message digest.

  __PACKAGE__->digest_algorithm('SHA-1');

If a suitible digest module could not be loaded an exception will be thrown.

Supported digest algorithms are:

  MD5
  MD4
  MD2
  SHA-1
  SHA-256
  SHA-384
  SHA-512
  CRC-16
  CRC-32
  CRC-CCITT
  HMAC-SHA-1
  HMAC-MD5
  Whirlpool
  Adler-32

digest_algorithm defaults to C<MD5>.

=cut

sub digest_algorithm {
    my ($self, $class) = @_;

    if ($class) {
        if (!eval { Digest->new($class) }) {
            $self->throw_exception("$class could not be used as a digest algorithm: $@");           
        } else {
            $self->digest_maker(Digest->new($class));
        };
    };
    return ref $self->digest_maker;
}

=head2 digest_encoding

Selects the encoding to use for the message digest.

  __PACKAGE__->digest_encoding('base64');

Possilbe encoding schemes are:

  binary
  hex
  base64

digest_encoding defaults to C<hex>.

=cut

sub digest_encoding {
    my ($self, $encoding) = @_;
    if ($encoding) {
        if ($encoding =~ /^(?:binary|hex|base64)$/) {
            $self->encoding($encoding); 
        } else {
            $self->throw_exception("$encoding is not a supported encoding scheme");
        };
    };
    return $self->encoding;
}

=head2 _get_digest_string $value

Handles the actual encoding of column values into digests.
When given a C<$value> it will return the digest string for
that value. This is the method used by C<_digest_column_values>
So you can use it to create an identical digest if you need one
for comparison (e.g. password authentication).

=cut

sub _get_digest_string {
    my ($self, $value) = @_;
    my $digest_string;
    
    $self->digest_maker->add($value);

    if ($self->encoding eq 'binary') {
        $digest_string = eval { $self->digest_maker->digest };
    
    } elsif ($self->encoding eq 'hex') {
        $digest_string = eval { $self->digest_maker->hexdigest };
    
    } else {
        $digest_string = eval { $self->digest_maker->b64digest } || 
	    eval {$self->digest_maker->base64digest };
    };
    
    $self->throw_exception("could not get a digest string: $@") 
	unless defined( $digest_string );

    return $digest_string;
}

=head2 _digest_column_values

Go through the columns and digest the values that need it.

This method is called by insert and update when automatic digests
are turned on. If dirty is enabled it will only digest the values
of dirtied columns.

=cut

sub _digest_column_values{
    my $self = shift;

    for my $col (@{$self->digest_auto_columns}) {
	#if dirty is required then don't update unchanged columns
	next if $self->digest_dirty && 
	    !$self->is_column_changed( $col ) &&  $self->in_storage;
	
	
	#don't digest null columns
	my $col_v = $self->get_column( $col );
	next unless defined $col_v;
	    
	#update column value with encoded value if needed
	$self->set_column( $col, $self->_get_digest_string( $col_v ) );
    }    
}

=head2 digest_auto

  __PACKAGE__->digest_auto(1);

Turns on and off automatic digest columns.  When on, this feature makes all
UPDATEs and INSERTs automatically insert a message digest of selected columns.

The default is for digest_auto is to be on.

=head2 digest_dirty

  __PACKAGE__->digest_dirty(1);

Turns on and off the limiting of automatic digests to only dirty columns.
When on, only columns that have been dirtied will have their values digested
during UPDATEs and INSERTs. If auto is set to off this option does nothing.

The default is for digest_dirty is to be off to mantain compatibility with older
versions of this module.

=head1 EXTENDED METHODS

The following L<DBIx::Class::Row> methods are extended by this module:-

=over 4

=item insert

=cut

sub insert {
    my $self = shift;
    $self->_digest_column_values if $self->digest_auto;
    $self->next::method(@_);
}

=item update

=cut

sub update {
    my ( $self, $upd, @rest ) = @_;
    if ( ref $upd ) {
        for my $col ( @{$self->digest_auto_columns} ) {
	    $self->set_column($col => delete $upd->{$col}) 
		if ( exists $upd->{$col} );
        }
    }
    $self->_digest_column_values if $self->digest_auto;
    $self->next::method($upd, @rest);
}

1;
__END__

=back

=head1 SEE ALSO

L<DBIx::Class>,
L<Digest>

=head1 AUTHOR

Tom Kirkpatrick (tkp) <tkp@cpan.org>

With contributions from
Guillermo Roditi (groditi) <groditi@cpan.org>
and Marc Mims <marc@questright.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.
