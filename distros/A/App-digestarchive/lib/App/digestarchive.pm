package App::digestarchive;

use strict;
use v5.8.0;
use warnings;
use Archive::Tar;
use Compress::Zlib;
use IO::Uncompress::Bunzip2 qw($Bunzip2Error);
use Digest;
use Data::Dumper;
use Class::Accessor "antlers";

has digest_type  => (is => "rw", type => "Str");
has archiver     => (is => "rw", type => "Str");

our $VERSION = '0.044';
our $DIGEST_TYPE  = "MD5";
our $NONE_DIGEST_MESSAGE = "** can not get digest **";
our @ADD_ENTRY_METHODS   = qw(digest link_or_real_name);

sub new {

	my($class, %args) = @_;
	bless {
		digest_type => (exists $args{digest_type} && defined $args{digest_type}) ? $args{digest_type} : $DIGEST_TYPE,
		# only Archive::Tar
		archiver => Archive::Tar->new
	}, $class;
}


sub read {

	my($self, $file_or_fh_or_buffer) = @_;
	my $buffer = $self->slurp($file_or_fh_or_buffer);
	my $fh;

	my $magic = $self->get_magic($buffer);
	if ($magic =~ Archive::Tar::GZIP_MAGIC_NUM) {
		my $dest = Compress::Zlib::memGunzip($buffer) or die "Cannot uncompress: $gzerrno\n";
		$fh = $self->scalar2fh($dest);
	} elsif ($magic =~ Archive::Tar::BZIP_MAGIC_NUM) {
		$fh = IO::Uncompress::Bunzip2->new(\$buffer) or die "Cannot open bunzip2: $Bunzip2Error\n";
	} else {
		$fh = $self->scalar2fh($buffer);
	}
	$self->archiver->read($fh);
}

sub all {

	my($self, $filter_cb) = @_;
	my @all;
	while (my $f = $self->next) {

		if (defined $filter_cb && ref($filter_cb) && "CODE") {
			if ($filter_cb->($f)) {
				push @all, $f;
			}
		} else {
			push @all, $f;
		}
	} 
	return \@all;
}

sub next {

	my $self = shift;
	my $f = shift @{$self->archiver->_data};
	return if !defined $f;

	{
		no strict "refs"; ## no critic
		no warnings "redefine";
		my $pkg = ref $f;
		foreach my $method (@ADD_ENTRY_METHODS) {
			*{"$pkg\::$method"} = sub {
									my $self = shift;
									if (scalar(@_) > 0) {
										$self->{$method} = $_[0];
									}
									return $self->{$method};
								};
		}
	}

	# set digest
	$f->digest(($f->type == Archive::Tar::FILE or $f->type == Archive::Tar::HARDLINK) ? $self->digest($f->data) : $NONE_DIGEST_MESSAGE);
	# set link_or_real_name
	$f->link_or_real_name(($f->type == Archive::Tar::SYMLINK) ? sprintf "%s -> %s", $f->name, $f->linkname : $f->name);

	return $f;
}


sub digest {

	my($self, $data) = @_;
	return if !defined $data;
	return Digest->new($self->digest_type)->add($data)->hexdigest;
}

sub scalar2fh {

	my($self, $buffer) = @_;
	open my $fh, "<:scalar", \$buffer or die "change readable filehandle convert failed\n";
	return $fh;
}

sub slurp {

	my($self, $file_or_fh_or_buffer) = @_;
	my $fh;
	my $buffer;
	if (ref($file_or_fh_or_buffer) eq "GLOB") {
		$fh = $file_or_fh_or_buffer;
	} elsif (-f $file_or_fh_or_buffer) {
		open $fh, "<", $file_or_fh_or_buffer or die "can not open file:$file_or_fh_or_buffer. $!";
	}

	if (defined $fh) {
		$buffer = do { local $/; <$fh> };
		close $fh;
	} else {
		$buffer = $file_or_fh_or_buffer;
	}
	return $buffer;
}


sub get_magic {

	my($self, $data) = @_;
	if (!defined $data) {
		die "invalid data\n";
	}
	return substr $data, 0, 4;
}


1;
__END__

=head1 NAME

App::digestarchive - package for digestarchive command

=head1 VERSION

0.044

=head1 SYNOPSIS

  use App::digestarchive;

=head1 DESCRIPTION

App::digestarchive is package for digestarchive command

=head1 AUTHOR

Akira Horimoto <emperor.kurt _at_ gmail.com>

=head1 SEE ALSO

L<Class::Accessor>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
