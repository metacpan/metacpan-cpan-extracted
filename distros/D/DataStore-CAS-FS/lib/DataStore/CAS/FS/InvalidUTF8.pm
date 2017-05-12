package DataStore::CAS::FS::InvalidUTF8;
use strict;
use warnings;
use Carp;
use overload '""' => \&to_string, 'cmp' => \&str_compare, '.' => \&str_concat;

our $VERSION= '0.011000';

# ABSTRACT: Wrapper to represent non-utf8 data in a unicode context


sub decode_utf8 {
	my $str= $_[-1];
	!ref $str || ref($str)->isa(__PACKAGE__)
		or croak "Can't convert ".ref($str);
	return ref($str) || utf8::is_utf8($str) || utf8::decode($str)? $str
		: bless(\$str, __PACKAGE__);
}

sub is_non_unicode { 1 }

sub to_string { ${$_[0]} }

sub str_compare {
	my ($self, $other, $swap)= @_;
	if (ref $other eq __PACKAGE__) { $other= $$other } else { utf8::encode($other) }
	my $ret= $$self cmp $other;
	return $swap? -$ret : $ret;
}

sub str_concat {
	my ($self, $other, $swap)= @_;
	if (ref $other eq __PACKAGE__) { $other= $$other } else { utf8::encode($other) }
	return ref($self)->decode_utf8($swap? $other.$$self : $$self.$other);
}


sub add_json_filter {
	my ($self, $json)= @_;
	$json->filter_json_single_key_object(
		'*InvalidUTF8*' => \&FROM_JSON
	);
	$json;
}

sub TO_JSON {
	my $x= ${$_[0]};
	utf8::upgrade($x);
	return { '*InvalidUTF8*' => $x };
}

sub FROM_JSON {
	my $x= $_[0];
	utf8::downgrade($x) if utf8::is_utf8($x);
	return bless \$x, __PACKAGE__;
}

sub TO_UTF8 {
	${$_[0]};
}

1;

__END__

=pod

=head1 NAME

DataStore::CAS::FS::InvalidUTF8 - Wrapper to represent non-utf8 data in a unicode context

=head1 VERSION

version 0.011000

=head1 SYNOPSIS

  my $j= JSON->new()->convert_blessed;
  DataStore::CAS::FS::InvalidUTF8->add_json_filter($j);
  my $x= DataStore::CAS::FS::InvalidUTF8->decode_utf8("\x{FF}");
  my $json= $j->encode($x);
  my $x2= "".$j->decode($json);
  is( $x, $x2 );
  ok( !utf8::is_utf8($x2) );

=head1 DESCRIPTION

Much like using 'i' (or j) as the square root of -1, InvalidUTF8 allows a value
which should have been utf-8, but isn't, to exist alongside the others.

Combining InvalidUTF8 parts to make a valid utf-8 string will automatically
decode the utf-8 into the resulting unicode string.

Comparing InvalidUTF8 with a regular perl string will first convert the string
to a UTF-8 representation, and then do a byte-wise comparison.

InvalidUTF8 can also safely pass through JSON, if the filter is added to the
JSON decoder, and "allow_blessed" is set on the encoder.

=head1 METHODS

=head2 decode_utf8

  $string_or_ref= $class->decode_utf8( $byte_str )

If the $byte_str is valid UTF-8, this method returns the decoded perl unicode
string.  If not, it returns the string wrapped in an instance of InvalidUTF8.

=head2 is_non_unicode

This method returns true, and can be used in tests like

  if ($_->can('is_non_unicode')) { ... }

as a way of detecting InvalidUTF8 objects by API rather than class hierarchy.

=head2 to_string, '""' operator

Returns the original string.

=head2 str_compare, 'cmp' operator

Converts peer to utf-8 bytes, then compares the bytes.

=head2 str_concat, '.' operator

Converts the peer to utf-8 bytes, concatenates the bytes, and then re-evaluates
whether the result needs to be wrapped in an instance of InvalidUTF8.

=head2 add_json_filter

  $json_instance= $class->add_json_filter($json_instance);

Applies a filter to the JSON object so that when it encounters

  { "*InvalidUTF8*": "$string" }

it will inflate the string using the FROM_JSON method.

=head2 TO_JSON

Called by the JSON module when convert_blessed is enabled.  Returns

  { "*InvalidUTF8*" => $original_str }

which can be converted back to a InvalidUTF8 object during decode_json,
if the filter is applied.

=head2 FROM_JSON

Pass this function to JSON's L<filter_json_single_key_object|JSON/filter_json_single_key_object>
with a key of C<*InvalidUTF8*> to restore the objects that were serialized.
It takes care of calling L<utf8::downgrade|utf8/downgrade> to undo the JSON module's unicode
conversion.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
