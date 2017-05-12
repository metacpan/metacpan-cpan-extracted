package Aard;

use 5.014000;
use strict;
use warnings;
our $VERSION = '0.001';

use IO::Uncompress::Inflate qw/inflate/;
use IO::Uncompress::Bunzip2 qw/bunzip2/;
use List::Util qw/sum/;

use JSON::MaybeXS qw/decode_json/;
use UUID::Tiny qw/uuid_to_string/;

use constant HEADER_SPEC => [
	[signature             => 'Z4' , 4 ],
	[sha1sum               => 'Z40', 40],
	[version               => 'S>' , 2 ],
	[uuid                  => 'Z16', 16],
	[volume                => 'S>' , 2 ],
	[total_volumes         => 'S>' , 2 ],
	[meta_length           => 'L>' , 4 ],
	[index_count           => 'L>' , 4 ],
	[article_offset        => 'L>' , 4 ],
	[index1_item_format    => 'Z4' , 4 ],
	[key_length_format     => 'Z2' , 2 ],
	[article_length_format => 'Z2' , 2 ],
];

my $header_length = sum map { $_->[2] } @{HEADER_SPEC()};

sub decompress {
	my ($input) = @_;
	my $output = $input;
	inflate \$input => \$output;
	bunzip2 \$input => \$output if $input =~ /^BZ/;
	$output
}

sub read_at {
	my ($self, $offset, $length) = @_;
	my $fh = $self->{fh};
	my $part;
	seek $fh, $offset, 0;
	read $fh, $part, $length;
	$part
}

sub index1 {
	my ($self, $index) = @_;
	unless (exists $self->{index1}{$index}) {
		my $part = $self->read_at($self->{index1_offset} + $index * $self->{index_length}, $self->{index_length});
		$self->{index1}{$index} = [unpack $self->{index_format}, $part]
	}
	$self->{index1}{$index}
}

sub fh            { shift->{fh} }
sub sha1sum       { shift->{sha1sum} }
sub uuid          { shift->{uuid} }
sub uuid_string   { uuid_to_string shift->uuid }
sub volume        { shift->{volume} }
sub total_volumes { shift->{total_volumes} }
sub count         { shift->{index_count} }

sub meta                          { shift->{meta} }
sub article_count                 { shift->meta->{article_count} }
sub article_count_is_volume_total { shift->meta->{article_count_is_volume_total} }
sub index_language                { shift->meta->{index_language} }
sub article_language              { shift->meta->{article_language} }
sub title                         { shift->meta->{title} }
sub version                       { shift->meta->{version} }
sub description                   { shift->meta->{description} }
sub copyright                     { shift->meta->{copyright} }
sub license                       { shift->meta->{license} }
sub source                        { shift->meta->{source} }

sub key {
	my ($self, $index) = @_;
	unless (exists $self->{key}{$index}) {
		my $part = $self->read_at($self->{index2_offset} + $self->index1($index)->[0], 2);
		my $len = unpack 'S>', $part;
		read $self->{fh}, $self->{key}{$index}, $len;
	}
	$self->{key}{$index}
}

sub article {
	my ($self, $index) = @_;
	unless (exists $self->{article}{$index}) {
		my $part = $self->read_at($self->{article_offset} + $self->index1($index)->[1], 4);
		my $len = unpack 'L>', $part;
		read $self->{fh}, $part, $len;
		$self->{article}{$index} = decompress $part
	}
	$self->{article}{$index}
}

sub new {
	my ($self, $file) = @_;
	open my $fh, '<', $file or die $!;
	binmode $fh;
	my %header;
	for (@{HEADER_SPEC()}) {
		read $fh, my $part, $_->[2];
		$header{$_->[0]} = unpack $_->[1], $part;
	}

	die 'Not a recognized aarddict dictionary file' if $header{signature} ne 'aard';
	die 'Unknown file format version' if $header{version} != 1;

	read $fh, my $meta, $header{meta_length};
	$meta = decode_json decompress $meta;

	my %obj = (
		%header,
		fh => $fh,
		meta => $meta,
		index_format => ($header{index1_item_format} eq '>LL' ? 'L>L>' : 'L>Q>'),
		index_length => ($header{index1_item_format} eq '>LL' ? 8 : 12),
	);
	$obj{index1_offset} = $header_length + $obj{meta_length};
	$obj{index2_offset} = $obj{index1_offset} + $obj{index_count} * $obj{index_length};
	bless \%obj, $self
}

1;
__END__

=head1 NAME

Aard - Read aarddict dictionaries

=head1 SYNOPSIS

  use Aard;
  my $dict = Aard->new('something.aar');
  printf "This dictionary (volume %d of %d) has %d entries\n", $dict->volume, $dict->total_volumes, $dict->count;
  printf "The tenth entry's key: %s\n", $dict->key(9);
  printf "The tenth entry's value: %s\n", $dict->article(9);

=head1 DESCRIPTION

Aard is a module for reading files in the Aard Dictionary format (.aar). A dictionary is an array of I<(key, article)> pairs, with some associated metadata.

=over

=item B<new>(I<filename>)

Creates a new Aard object for the given file.

=item B<fh>

Returns the open filehandle to the dictionary.

=item B<count>

Returns the number of entries in this dictionary.

=item B<key>(I<index>)

Returns the key of the I<index>th element. This method caches the keys.

=item B<article>(I<index>)

Returns the article of the I<index>th element. This method caches the articles.

=item B<uuid>

Returns the UUID of this dictionary as a binary string. This is a value shared by all volumes of the same dictionary.

=item B<uuid_string>

Returns the UUID of this dictionary as a human-readable string. This is a value shared by all volumes of the same dictionary.

=item B<volume>

Returns the volume number of this file.

=item B<total_volumes>

Returns the total number of volumes for this dictionary.

=item B<meta>

Returns the raw metadata as a hashref.

=item B<article_count>

Returns the number of unique articles in this volume (if B<article_count_is_volume_total> is true) or in this dictionary (otherwise).

=item B<article_count_is_volume_total>

Returns true if B<article_count> means number of articles in this volume. This is always true since aardtools 0.9.0.

=item B<index_language>

Returns the dictionary's "from" language (two or three letter ISO code)

=item B<article_language>

Returns the dictionary's "to" language (two or three letter ISO code)

=item B<title>

Returns the dictionary title

=item B<version>

Returns the dictionary version

=item B<description>

Returns the dictionary description

=item B<copyright>

Returns the copyright notice

=item B<license>

Returns the full license text

=item B<source>

Returns the dictionary data source

=back

=head1 SEE ALSO

L<http://aarddict.org>, L<http://aarddict.org/aardtools/doc/aardformat.html>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
