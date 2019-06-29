package Data::TableReader::Decoder::CSV;
use Moo 2;
use Try::Tiny;
use Carp;
use IO::Handle;
extends 'Data::TableReader::Decoder';

# ABSTRACT: Access rows of a comma-delimited text file
our $VERSION = '0.011'; # VERSION

our @csv_probe_modules= ( ['Text::CSV_XS' => 1.06], ['Text::CSV' => 1.91] );
our $default_csv_module;
sub default_csv_module {
	$default_csv_module ||=
		Data::TableReader::Decoder::_first_sufficient_module('CSV parser', \@csv_probe_modules);
}


has _parser_args => ( is => 'ro', init_arg => 'parser' );

has parser => ( is => 'lazy', init_arg => undef );
sub _build_parser {
	my $self= shift;
	my $args= $self->_parser_args || {};
	return $args if ref($args)->can('getline');
	return $self->default_csv_module->new({
		binary => 1,
		allow_loose_quotes => 1,
		auto_diag => 2,
		%$args
	});
}


has autodetect_encoding => ( is => 'rw', default => sub { 1 } );

sub encoding {
	my ($self, $enc)= @_;
	my $fh= $self->file_handle;
	if (defined $enc) {
		binmode($fh, ":encoding($enc)");
		return $enc;
	}
	
	my @layers= PerlIO::get_layers($fh);
	if (($enc)= grep { /^encoding|^utf/ } @layers) {
		# extract encoding name
		return 'UTF-8' if $enc eq 'utf8';
		return uc($1) if $enc =~ /encoding\(([^)]+)\)/;
		return uc($enc); # could throw a parse error, but this is probably more useful behavior
	}
	
	# fh_start_pos will be set if we have already checked for BOM
	if ($self->autodetect_encoding && !defined $self->_fh_start_pos) {
		$self->_fh_start_pos(tell $fh or 0);
		if (($enc= $self->_autodetect_bom($fh))) {
			binmode($fh, ":encoding($enc)");
			# re-mark the start after the BOM
			$self->_fh_start_pos(tell $fh or 0);
			return $enc;
		}
	}
	return '';
}


has _fh_start_pos => ( is => 'rw' );
has _iterator => ( is => 'rw', weak_ref => 1 );
has _row_ref => ( is => 'rw' );
sub iterator {
	my $self= shift;
	croak "Multiple iterators on CSV stream not supported yet" if $self->_iterator;
	my $parser= $self->parser;
	my $fh= $self->file_handle;
	my $row_ref= $self->_row_ref;
	# Keeping this object is just an indication of whether an iterator has been used yet
	if (!$row_ref) {
		$self->_row_ref($row_ref= \(my $row= 0));
		# trigger BOM detection if needed
		my $enc= $self->encoding;
		$self->_log->('debug', "encoding is ".($enc||'maybe utf8'));
		# ensure _fh_start_pos is set
		$self->_fh_start_pos(tell $fh or 0);
	}
	elsif ($$row_ref) {
		$self->_log->('debug', 'Seeking back to start of input');
		seek($fh, $self->_fh_start_pos, 0)
			or die "Can't seek back to start of stream";
		$$row_ref= 0;
	}
	my $i= Data::TableReader::Decoder::CSV::_Iter->new(
		sub {
			++$$row_ref;
			my $r= $parser->getline($fh) or return undef;
			@$r= @{$r}[ @{$_[0]} ] if $_[0]; # optional slice argument
			return $r;
		},
		{
			row => $row_ref,
			fh  => $fh,
			origin => $self->_fh_start_pos,
		}
	);
	$self->_iterator($i);
	return $i;
}

# This design is simplified from File::BOM in that it ignores UTF-32
# and in any "normal" case it can read from a pipe with only one
# character to push back, avoiding the need to tie the file handle.
# It also checks for whether layers have already been enabled.
# It also avoids seeking to the start of the file handle, in case
# the user deliberately seeked to a position.
sub _autodetect_bom {
	my ($self, $fh)= @_;
	my $fpos= tell($fh);
	
	local $!;
	read($fh, my $buf, 1) || return;
	if ($buf eq "\xFF" || $buf eq "\xFE" || $buf eq "\xEF") {
		if (read($fh, $buf, 1, 1)) {
			if ($buf eq "\xFF\xFE") {
				return 'UTF-16LE';
			} elsif ($buf eq "\xFE\xFF") {
				return 'UTF-16BE';
			} elsif ($buf eq "\xEF\xBB" and read($fh, $buf, 1, 2) and $buf eq "\xEF\xBB\xBF") {
				return 'UTF-8';
			}
		}
	}
	
	# It wasn't a BOM.  Try to undo our read.
	$self->_log->('debug', 'No BOM in stream, seeking back to start');
	if (length $buf == 1) {
		$fh->ungetc(ord $buf);
	} elsif (!seek($fh, $fpos, 0)) {
		# Can't seek
		if ($fh->can('ungets')) { # support for FileHandle::Unget
			$fh->ungets($buf);
		} else {
			croak "Can't seek input handle after BOM detection; You should set an encoding manually, buffer the entire input, or use FileHandle::Unget";
		}
	}
	return;
}

# If you need to subclass this iterator, don't.  Just implement your own.
# i.e. I'm not declaring this implementation stable, yet.
use Data::TableReader::Iterator;
BEGIN { @Data::TableReader::Decoder::CSV::_Iter::ISA= ('Data::TableReader::Iterator'); }

sub Data::TableReader::Decoder::CSV::_Iter::position {
	my $f= shift->_fields;
	'row '.${ $f->{row} };
}

sub Data::TableReader::Decoder::CSV::_Iter::progress {
	my $f= shift->_fields;
	# lazy-build the file size, using seek
	unless (exists $f->{file_size}) {
		my $pos= tell $f->{fh};
		if (defined $pos and $pos >= 0 and seek($f->{fh}, 0, 2)) {
			$f->{file_size}= tell($f->{fh});
			seek($f->{fh}, $pos, 0) or die "seek: $!";
		} else {
			$f->{file_size}= undef;
		}
	}
	return $f->{file_size}? (tell $f->{fh})/$f->{file_size} : undef;
}

sub Data::TableReader::Decoder::CSV::_Iter::tell {
	my $f= shift->_fields;
	my $pos= tell($f->{fh});
	return undef unless defined $pos && $pos >= 0;
	return [ $pos, ${$f->{row}} ];
}

sub Data::TableReader::Decoder::CSV::_Iter::seek {
	my ($self, $to)= @_;
	my $f= $self->_fields;
	seek($f->{fh}, ($to? $to->[0] : $f->{origin}), 0) or croak("seek failed: $!");
	${ $f->{row} }= $to? $to->[1] : 0;
	1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableReader::Decoder::CSV - Access rows of a comma-delimited text file

=head1 VERSION

version 0.011

=head1 DESCRIPTION

This decoder wraps an instance of either L<Text::CSV> or L<Text::CSV_XS>.
You may pass your own options via the L</parser> attribute, which
will override the defaults of this module on a per-field basis.

This module defaults to:

  parser => {
    binary => 1,
    allow_loose_quotes => 1,
    auto_diag => 2,
  }

This module makes an attempt at automatic unicode support:

=over

=item *

If the stream has a PerlIO encoding() on it, no additional decoding is done.

=item *

If the stream has a BOM (byte-order mark) for UTF-8 or UTF-16, it adds that
encoding with C<binmode>.

=item *

Else, it lets the parser decide.  The default Text::CSV parser will
automatically upgrade UTF-8 sequences that it finds.  (and, you can't disable
this without also disabling unicode received from IO layers, which seems like
a bug...)

=back

Because auto-detection might need to read multiple bytes, it is possible that
for non-seekable streams (like pipes, stdin, etc) this may result in an
exception.  Only un-seekable streams beginning with C<"\xEF">, C<"\xFE">, or
C<"\xFF"> will have this problem.  You can solve this by supplying an encoding
layer on the file handle (avoiding detection), setting L</autodetect_encoding>
to false, buffering the entire input in a scalar and creating a file handle
from that (making it seekable), or using a file handle that supports "ungets"
like L<FileHandle::Unget>.

=head1 ATTRIBUTES

=head2 parser

An instance of L<Text::CSV> or L<Text::CSV_XS> or compatible, or arguments to pass to the
constructor.  Constructor arguments are passed to CSV_XS if it is installed, else CSV.

=head2 autodetect_encoding

Whether to look for a byte-order mark on the input.

=head2 encoding

If autodetection is enabled, this will first check for a byte-order mark on
the input.  Else, or afterward, it will return whatever encoding PerlIO layer
is configured on the file handle.  Setting this attribute will change the
PerlIO layer on the file handle, possibly skipping detection.

=head2 iterator

  my $iterator= $decoder->iterator;

Return an L<iterator|Data::TableReader::Iterator> which returns each row of the table as an
arrayref.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
