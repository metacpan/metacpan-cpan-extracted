package Crop::File::LOCAL;
use base qw/ Crop::File /;

=begin nd
Class: Crop::File::LOCAL
	File local stored.
=cut

use v5.14;
use warnings;

use Fcntl qw/ SEEK_SET O_WRONLY O_CREAT /;
use File::Basename;
use File::Path qw/ make_path /;

use Crop::Error;
use Crop::Util;

use Crop::Debug;

=begin nd
Constant: BUF_SIZE
	Read|Write buffer; reading by small chunks to save memory usage.
=cut
use constant {
	BUF_SIZE => 1024 * 1024, # 1Mb
};

=begin nd
Constructor: new (@attr)
	Set file type.
	
	Specifying explicit type is not allowed.
	
Parameters:
	%attr - class attributes
	
Returns:
	$self - ok
	undef - error
=cut
sub new {
	my ($class, @attr) = @_;
	my $attr = expose_hashes \@attr;
	
	$class->SUPER::new(
		%$attr,
		warehouse => 'LOCAL',  # parent Constructor replace this attribute to integer value
	);
}

=begin nd
Method: upload ($src, $dst)
	Upload field from CGI multipart form field.
	
	Read/Write uses small blocks instead of all-in-one operation.
	
	Path to store disallowed to use '../' (dir up) element for security reason.
	
	Make destination directory unless exists. Set file size.
	
	Only FastCGI is supported now. Refactoring will be required when will new Server interface arrived.
	
Parameters:
	$src - field name in the CGI form
	$dst - path the created file will be stored; see section 'upload' in the global.xml
	
Returns:
	true  - ok
	undef - error
=cut
sub upload {
	my ($self, $src, $dst) = @_;
	$self->{path} = $dst;
	my $S = $self->S;
	
	return warn 'FILE|CRIT: Upload has incomplete params' unless defined $src and defined $dst;
	
	# change directory to level up is not allowed
	my $hack = qr{\.\./};
	return warn 'FILE|ALERT: Upload try HACK!' if $dst =~ $hack;

	exists $S->I->{$src} and $S->cgi->upload($src) or return warn "FILE: upload not exists";  # FastCGI specific
	
	my $src_fh = $S->cgi->upload($src) or return warn "FILE|NOTICE: upload can not get cgi-filehandle for $src field";
	sysseek $src_fh, 0, SEEK_SET or return warn "FILE: Can't seek file from multipart field $src";

	my $dir = dirname $dst;
	unless (-d $dir) {
		unless (make_path $dir, {error => \my $err}) {
			return warn "FILE: Can't upload LOCAL: $err";
		}
	}
	sysopen my $dst_fh, $dst, O_WRONLY|O_CREAT or return warn "FILE: Can't upload file dest '$dst': $!";
	
	my ($buf, $nread, $total);
	while ($nread = sysread $src_fh, $buf, BUF_SIZE) {
		my $left = $nread;
		$total += $nread;

		my $rc;
		while ($left) {
			unless ($rc = syswrite $dst_fh, $buf, $left, $nread - $left) {
				close $dst_fh or return warn "FILE|CRIT: Can't close dst file during uploading: $!";
				return warn "FILE: Can't write upload: $!; rc=$rc";
			}
			$left -= $rc;
		}
	}
	$self->{size} //= -s $src_fh;
	return warn 'FILE|CRIT: Upload size mismatch to source size' unless $total == $self->{size};
	
	close $dst_fh or return warn "FILE|CRIT: Can't close dst file during uploading: $!";
	return warn "FILE|CRIT: Can't read multipart upload: $!" unless defined $nread;
	
	1;
}

1;
