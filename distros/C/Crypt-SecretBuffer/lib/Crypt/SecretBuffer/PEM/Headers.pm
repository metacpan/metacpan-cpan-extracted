package Crypt::SecretBuffer::PEM::Headers;
# VERSION
# ABSTRACT: Inspect or alter arrayref of PEM headers as if it was a hashref
$Crypt::SecretBuffer::PEM::Headers::VERSION = '0.023';
use strict;
use warnings;
use Scalar::Util 'blessed';
use Carp;
use Crypt::SecretBuffer qw( span );
if ("$]" <  5.016) {
   eval 'sub fc { lc($_[0]) }'
} else {
   eval 'sub fc { CORE::fc($_[0]) }';
}


sub new {
   my $class= shift;
   my $self= bless {}, $class;
   while (@_) {
      my ($k, $v)= splice(@_, 0, 2);
      $self->$k($v);
   }
   $self->{raw_kv_array} ||= [];
   $self;
}


sub raw_kv_array {
   if (@_ > 1) {
      my $kv= $_[1];
      ref $kv eq 'ARRAY' && ($#$kv & 1)
         or croak "Expected even-length arrayref";
      $_[0]{raw_kv_array}= $kv;
      return $_[0];
   }
   $_[0]{raw_kv_array}
}

sub unicode_keys {
   if (@_ > 1) {
      $_[0]{unicode_keys}= !!$_[1];
      return $_[0];
   }
   $_[0]{unicode_keys}
}
sub unicode_values {
   if (@_ > 1) {
      $_[0]{unicode_values}= !!$_[1];
      return $_[0];
   }
   $_[0]{unicode_values}
}
sub trim_keys {
   if (@_ > 1) {
      $_[0]{trim_keys}= !!$_[1];
      return $_[0];
   }
   $_[0]{trim_keys}
}
sub caseless_keys {
   if (@_ > 1) {
      $_[0]{caseless_keys}= !!$_[1];
      return $_[0];
   }
   $_[0]{caseless_keys}
}

sub _find_key_idx {
   my ($self, $key, $first_only)= @_;
   #print "# _find_key_idx($key)\n";
   my $kv= $self->{raw_kv_array};
   my ($uni, $trim, $fc)= @{$self}{'unicode_keys','trim_keys','caseless_keys'};
   my @ret;
   if ($uni) {
      $key= fc($key) if $fc;
      for (0..($#$kv-1)/2) {
         my $k= $kv->[$_*2];
         utf8::decode($k);
         $k =~ s/^\s+//  if $trim;
         $k =~ s/\s+\z// if $trim;
         push(@ret, $_*2) && $first_only && last
            if $key eq ($fc? fc($k) : $k);
      }
   } else {
      utf8::downgrade($key);
      $key= fc($key) if $fc;
      for (0..($#$kv-1)/2) {
         my $k= $kv->[$_*2];
         $k =~ s/^\s+//  if $trim;
         $k =~ s/\s+\z// if $trim;
         push(@ret, $_*2) && $first_only && last
            if $key eq ($fc? fc($k) : $k);
      }
   }
   #print "#  found at [".join(',', @ret)."]\n";
   return \@ret;
}

sub _find_distinct_key_idx {
   my $self= shift;
   my $kv= $self->{raw_kv_array};
   #print "_find_distinct_key_idx raw_kv = [".join(',', @$kv)."]\n";
   my ($uni, $trim, $fc)= @{$self}{'unicode_keys','trim_keys','caseless_keys'};
   my (@ret, %seen);
   for (0..($#$kv-1)/2) {
      my $k= $kv->[$_*2];
      utf8::decode($k) if $uni;
      $k =~ s/^\s+//  if $trim;
      $k =~ s/\s+\z// if $trim;
      push @ret, $_*2
         unless $seen{$fc? fc($k) : $k}++;
   }
   #print "# _find_distinct_key_idx = [".join(',', @ret)."]\n";
   return \@ret;
}


sub keys {
   my $self= shift;
   my $idxs= $self->_find_distinct_key_idx;
   my $kv= $self->{raw_kv_array};
   return @{$kv}[@$idxs];
}


sub get_array {
   my ($self, $key)= @_;
   my $ret= $self->_find_key_idx($key);
   my $kv= $self->{raw_kv_array};
   $_= $kv->[$_+1] for @$ret;
   if ($self->unicode_values) {
      utf8::decode($_) for @$ret
   }
   return $ret;
}


sub get {
   my $vals= shift->get_array(@_);
   return @$vals > 1? $vals : $vals->[0];
}


sub _validate_new_key {
   my $key= shift;
   croak "Key must be a plain scalar"
      if ref $key;
   croak "Key '$key' contains ':', control characters, or leading/trailing whitespace"
      if $key =~ /[:\0-\x1F\x7F]/ or $key =~ /^\s+/ or $key =~ /\s+\z/;
}
sub _validate_value {
   my $val= shift;
   if (ref $val) {
      croak "Value is not a SecretBuffer or Span (stringify the PEM header values before assigning them)"
         unless blessed($val) && (
            $val->isa('Crypt::SecretBuffer')
            || $val->isa('Crypt::SecretBuffer::Span')
         );
   }
}

sub set {
   my ($self, $key, $value)= @_;
   my $kv= $self->{raw_kv_array};
   my $idxs= $self->_find_key_idx($key);
   my $idx= shift @$idxs;
   if (!defined $idx) {
      _validate_new_key($key);
      $self->unicode_keys? utf8::encode($key) : utf8::downgrade($key);
   } else {
      $key= $kv->[$idx];
   }
   my @ins;
   for (ref $value eq 'ARRAY'? @$value : $value) {
      _validate_value(my $v= $_);
      $self->unicode_values? utf8::encode($v) : utf8::downgrade($v)
         unless ref $v;
      push @ins, $key, $v;
   }
   splice(@$kv, $_, 2) for reverse @$idxs;
   $idx= @$kv unless defined $idx;
   splice(@$kv, $idx, 2, @ins);
   $self;
}


sub append {
   my ($self, $key, $value)= @_;
   _validate_new_key($key);
   _validate_value($value);
   $self->unicode_keys? utf8::encode($key) : utf8::downgrade($key);
   $self->unicode_values? utf8::encode($value) : utf8::downgrade($value)
      unless ref $value;
   push @{$self->raw_kv_array}, $key, $value;
}


sub delete {
   my ($self, $key)= @_;
   my $idxs= $self->_find_key_idx($key);
   my $kv= $self->{raw_kv_array};
   my @ret= map $kv->[$_+1], @$idxs;
   splice(@$kv, $_, 2) for reverse @$idxs;
   return @ret;
}

sub _create_tied_hashref {
   my $self= shift;
   my %hash;
   tie %hash, 'Crypt::SecretBuffer::PEM::Headers::_HASH', $self;
   return bless \%hash, 'Crypt::SecretBuffer::PEM::Headers::_Proxy';
}

sub Crypt::SecretBuffer::PEM::Headers::_HASH::TIEHASH {
   my ($classname, $headers)= @_;
   bless [ $headers, [] ], $classname;
}
sub Crypt::SecretBuffer::PEM::Headers::_HASH::FETCH    { $_[0][0]->get($_[1]) }
sub Crypt::SecretBuffer::PEM::Headers::_HASH::STORE    { $_[0][0]->set($_[1], $_[2]) }
sub Crypt::SecretBuffer::PEM::Headers::_HASH::DELETE   { $_[0][0]->delete($_[1]) }
sub Crypt::SecretBuffer::PEM::Headers::_HASH::CLEAR    { @{ $_[0][0]->raw_kv_array }= () }
sub Crypt::SecretBuffer::PEM::Headers::_HASH::EXISTS   { !!@{ $_[0][0]->_find_key_idx($_[1], 1) } }
sub Crypt::SecretBuffer::PEM::Headers::_HASH::FIRSTKEY { $_[0][1]= [ $_[0][0]->keys ]; shift @{$_[0][1]} }
sub Crypt::SecretBuffer::PEM::Headers::_HASH::NEXTKEY  { shift @{$_[0][1]} }
# This class is used to bless the tied hash making it both a magic
# hashref and an object with methods.
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::raw_kv_array   { tied(%{+shift})->[0]->raw_kv_array(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::unicode_keys   { tied(%{+shift})->[0]->unicode_keys(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::unicode_values { tied(%{+shift})->[0]->unicode_values(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::trim_keys      { tied(%{+shift})->[0]->trim_keys(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::caseless_keys  { tied(%{+shift})->[0]->caseless_keys(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::keys           { tied(%{+shift})->[0]->keys(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::get            { tied(%{+shift})->[0]->get(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::get_array      { tied(%{+shift})->[0]->get_array(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::set            { tied(%{+shift})->[0]->set(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::delete         { tied(%{+shift})->[0]->delete(@_) }
sub Crypt::SecretBuffer::PEM::Headers::_Proxy::append         { tied(%{+shift})->[0]->append(@_) }

# avoid depending on namespace::clean
delete @{Crypt::SecretBuffer::PEM::Headers::}{qw( carp croak confess span fc blessed )};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::SecretBuffer::PEM::Headers - Inspect or alter arrayref of PEM headers as if it was a hashref

=head1 SYNOPSIS

  my $headers= Crypt::SecretBuffer::PEM::Headers->new(
    raw_kv_array => [
      x => 1,
      X => 2,
      ' X ' => 3,
    ],
    trim_keys => 1,
    caseless_keys => 1,
  );
  my $vals= $headers->get('x');
  # [1,2,3]
  
  $headers->set(a => 5);
  my $kv= $headers->raw_kv_array;
  # ['x',1,'X',2,' X ',3,a,5]

=head1 DESCRIPTION

This object provides hash-like behavior for inspecting the headers of a PEM file while
maintaining the original arrayref of PEM headers found in the file.  This module manages
character encoding/decoding, case-insensitive comparison, whitespace trimming, and merging
the values of duplicate header names into arrayrefs.  The original whitespace and character
encoding and header order are preserverd in case you want to make minimal changes and then
re-serialize the PEM file without altering more than you intended.

=head1 CONSTRUCTORS

=head2 new

  $headers= Crypt::SecretBuffer::PEM::Headers->new(%attrs);

=head1 ATTRIBUTES

=head2 raw_kv_array

This is an arrayref of C<< [$key0, $val0, $key1, $val1, ...] >> which was parsed from the PEM
header section, in its original order, capitalization, and byte encoding.  The methods of this
object modify the array.

=head2 unicode_keys

If true, assume all keys in L</raw_kv_list> are encoded as UTF-8.  Any that aren't will possibly
trigger exceptions, or just not match any attempt to read/write them.  Any new keys you add are
expected to be unicode (wide characters) and will be encoded as UTF-8 automatically.  If false,
it uses byte matching between the string you supply, and your string must be downgradable to
plain bytes.

=head2 unicode_values

If true, assume all values in L</raw_kv_list> are encoded as UTF-8.  Any that aren't will
possibly throw exceptions.

=head2 trim_keys

If true (the default) any leading or trailing whitespace (C<< \s >> in the key name will be
ignored while comparing to the key name you requested.  The whitespace remains in the original
KV list for clean round-trips.

=head2 caseless_keys

If true, get/set/delete operations on key names will perform a case-insensitive match.  The
original case of the keys is preserved.

=head1 METHODS

=head2 keys

  @name_list= $headers->keys;

Return the list of header names, with duplicates collapsed.  The returned order is the same as
they occur in the L</raw_kv_array>.

=head2 get_array

  $array= $headers->get_array($name);

Return an arrayref of all values for matching key names.  This performs a scan of
L<raw_kv_array> and collects the values of matching keys into an arrayref.

=head2 get

  $val_or_array= $headers->get($name);

Return the value or arrayref of values or C<undef> for matching keys names.

=head2 set

  $headers->set($name => $value);
  $headers->set($name => \@values);

Overwrite any existing values for the header C<$name> with the supplied values.
If there are multiple matches, the values other than the first will all be deleted from the array.
If multiple new values are provided, they will all be inserted at the location of the first
previous value, or the end of the list of there was no previous value.

=head2 append

  $headers->append($name => $value);

Append one name/value pair to the end of the list.

=head2 delete

  @val_list= $headers->delete($name);

Delete all headers matching C<$name>, and return the values deleted.

=head1 VERSION

version 0.023

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
