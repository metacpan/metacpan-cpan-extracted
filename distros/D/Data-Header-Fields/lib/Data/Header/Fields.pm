package Data::Header::Fields;

use warnings;
use strict;

use IO::Any;
use Carp 'croak';
use String::Escape ();
use List::MoreUtils 'uniq', 'all';

use overload
	'""' => \&as_string,
	'cmp' => \&cmp,
;

our $VERSION = '0.05';

sub new {
	my $class = shift;
	return bless {
		tight_folding => 0,
		key_cmp       => sub { $_[0] cmp $_[1] },
		@_
	}, $class;
}

sub _lines {
	my $self = shift;
	
	$self->{_lines} = shift
		if (@_);
	
	$self->{_lines} = []
		if (not $self->{_lines});
	
	return $self->{_lines};
}

sub key_cmp {
	my $self   = shift;
	$self->{'key_cmp'} = shift
		if @_;
	
	return $self->{'key_cmp'};
}

sub tight_folding {
	my $self = shift;
	
	$self->{tight_folding} = shift
		if (@_);
	
	return 0
		if not ref $self;
	
	return $self->{tight_folding};
}

sub decode {
	my $self = shift;
	my $any  = shift;
	
	my @lines = $self->_read_lines($any);

	my $line_ending = (
		($lines[0] || '') =~ m/\r\n \Z/xms
		? "\r\n"
		: "\n"
	);
	$self->line_ending($line_ending);
	
	@lines = (
		map {
			Data::Header::Fields::Line->new(
				'line'          => $_,
				'parent'        => $self,
			);
		} @lines
	);
	
	if (ref $self) {
		$self->_lines(\@lines);
		return $self;
	}
	
	return \@lines;
}

sub _read_lines {
	my $self = shift;
	my $any  = shift;
	
	my $fh = IO::Any->read($any);
	
	# put folded lines to an array http://tools.ietf.org/html/rfc2822#section-2.2.3
	my @lines;
	while (my $line = <$fh>) {
		# folded line
		if (($line =~ m/^\s/xms)) {
			# ignore if the first line starts with white space
			next if not @lines;
			
			$lines[-1] .= $line;
			next;
		}
		push @lines, $line;
	}
	
	close $fh;

	return @lines;	
}

*as_string = *encode;
sub encode {
	my $self  = shift;
	my $lines = shift || (ref $self ? $self->_lines : undef);
	
	# no additional arguments
	if (@_ == 0) {
		my $text = '';
		$self->encode($lines, \$text);
		return $text;
	}
	
	my $any = shift;
	
	my $fh = IO::Any->write($any);
	foreach my $line (@{$lines}) {
		print $fh $line->as_string;
	}
	
	close $fh;
	
	return $self;
}

sub get_fields {
	my $self       = shift;
	my $field_name = shift or croak 'field_name argument is mandatory';
	
	my $key_cmp = $self->key_cmp;
	return (
		grep {
			$key_cmp->($field_name, $_->key) == 0
		} @{$self->_lines}
	);
}

sub get_field {
	my $self       = shift;
	my $field_name = shift or croak 'field_name argument is mandatory';
	my @extra_args = @_;
	
	my @fields = $self->get_fields($field_name, @extra_args);
	croak 'more then one header field with name "'.$field_name.'"'
		if @fields > 1;
	
	return $fields[0];
}

sub get_value {
	my $self = shift;
	my $key  = shift or croak 'key argument is mandatory';
	my @extra_args = @_;

	my $field = $self->get_field($key, @extra_args);
	return undef if not defined $field;
	return $field->value;
}

sub update_values {
	my $self  = shift;
	my $key   = shift or croak 'key argument is mandatory';
	my $value = shift;

	my $key_cmp = $self->key_cmp;
	my @lines = (
		map {
			($key_cmp->($_->key, $key) == 0 ? $_->value($value) : ());
			$_;
		} @{$self->_lines}
	);
	
	return $self;
}

sub rm_fields {
	my $self          = shift;
	my (@field_names) = (@_) or croak 'field_names argument is mandatory';

	my $key_cmp = $self->key_cmp;
	my @lines = (
		grep {
			my $key = $_->key;
			all { $key_cmp->($key, $_) != 0 } @field_names;
		} @{$self->_lines}
	);
	
	$self->_lines(\@lines);
	
	return $self;
}

sub set_value {
	my $self  = shift;
	my $key   = shift or croak 'key argument is mandatory';
	my $value = shift;

	my @fields = $self->get_fields($key);
	if (@fields == 1) {
		$self->update_values($key, $value);
	}
	elsif (@fields == 0) {
		push @{$self->_lines}, Data::Header::Fields::Line->new(
			'key' => $key,
			'value' => $value,
			'parent' => $self,
		);
	}
	else { 
		croak 'more then one header field with name "'.$key.'"';
	}
	
	
	return $self;
}

sub cmp {
	my $a = shift;
	my $b = shift;
	
	$a = $a->encode if ref $a and $a->can('encode');
	$b = $b->encode if ref $b and $b->can('encode');
	
	return $a cmp $b;
}

sub keys {
	my $self  = shift;	
	my $lines = shift || (ref $self ? $self->_lines : []);
	
	return
		uniq
		map {
			$_->key
		} @{$lines}
	;
}

sub line_ending {
	my $self = shift;
	
	return "\n"
		if not ref $self;
	
	if (@_) {
		$self->{line_ending} = shift;
	}
	$self->{line_ending} = "\n"
		if (not $self->{line_ending});
	
	return $self->{line_ending};
}

sub push_line {
	my $self = shift;
	my $line = shift;

	my $lines = $self->_lines;
	push(@$lines, $line);

	return $self;
}

1;

package Data::Header::Fields::Value;

use Scalar::Util 'weaken', 'isweak';

use overload
	'""' => \&as_string,
	'cmp' => \&cmp,
;

sub new {
	my $class = shift;
	my $value = shift;
	
	if (@_ == 0) {
		if (not ref $value) {
			$value = { 'value' => $value };
		}
	}
	else {
		$value = { $value, @_ };
	}
	
	my $self = bless { 'parent' => $class->_default_parent, %{$value} }, $class;
	
	weaken($self->{'parent'})
		if (ref($self->{'parent'}) && !isweak($self->{'parent'}));
	
	return $self;
}

sub as_string {
	my $self   = shift;

	# remove folding
	my $line = $self->{value};
	if ($self->parent->parent->tight_folding) {
		$line =~ s/\n\s//xmsg;
	}
	else {
		$line =~ s/\n(\s)/$1/xmsg;
	}
	$line =~ s/\r?\n$//;
	$line = String::Escape::unprintable($line);
	
	return $line;
}

sub cmp {
	my $a = shift;
	my $b = shift;
	
	$a = $a->as_string if ref $a and $a->can('as_string');
	$b = $b->as_string if ref $b and $b->can('as_string');
	
	return $a cmp $b;
}

sub _default_parent {
	return 'Data::Header::Fields::Line';
}

sub parent {
	my $self   = shift;
	$self->{'parent'} = shift
		if @_;
	
	return (ref $self->{'parent'} ? $self->{'parent'} : $self->_default_parent);
}

sub value {
	my $self = shift;
	
	if (@_) {
		$self->{'value'} = shift;
		$self->parent->line_changed;
	}
	
	return $self->{'value'};
}
1;

package Data::Header::Fields::Line;

use Scalar::Util 'blessed', 'weaken', 'isweak';

use overload
	'""' => \&as_string,
	'cmp' => \&cmp,
;

sub new {
	my $class = shift;
	my $line  = shift;
	my @args  = @_;
	
	if (@args > 0) {
		$line = { $line, @args };
	}
	
	if (not ref $line) {
		$line = { 'line' => $line };
	}
	
	$line = { 'parent' => $class->_default_parent, %{$line} };
	
	if (exists $line->{'line'}) {
		# reblessing the line object
		if (blessed $line->{'line'}) {
			my $self = delete $line->{'line'};
			foreach my $key (keys %{$line}) {
				$self->{$key} = $line->{$key};
			}
			return bless $self, $class;			
		}
		else {
			my $line_string   = delete $line->{'line'};
			$line->{'original_line'} = $line_string;
			my ($key, $value) = split(/:/, $line_string, 2);
			$line->{'key'}    = $key;
			$line->{'value'}  = Data::Header::Fields::Value->new(
				'value'         => $value,
				'parent'        => $line,
			);
		}
	}
	
	weaken($line->{'parent'})
		if (ref($line->{'parent'}) && !isweak($line->{'parent'}));
	
	return bless $line, $class;
}

sub key {
	my $self   = shift;
	$self->{'key'} = shift
		if @_;
	
	return $self->{'key'};
}
sub value {
	my $self   = shift;
	$self->line_changed->{'value'} = shift
		if @_;
	
	return $self->{'value'};
}

sub line_changed {
	my $self = shift;
	delete $self->{'original_line'}
		if ref $self;
	return $self;
}

sub as_string {
	my $self = shift;
	
	if (exists $self->{'original_line'}) {
		my $original_line = $self->{'original_line'};
		
		# make sure the line has line_ending, even the original one could be created without using ->new()
		$original_line .= $self->parent->line_ending
			if $original_line !~ m/ \n \Z /xms;
		
		return $original_line;
	}

	my ($key, $value) = ($self->key, $self->value);
	$value = String::Escape::printable($value);

	my $line = join(':', $key, $value);
	
	$line .= $self->parent->line_ending
		if $line !~ m/\n$/xms;
	
	return $line;
}

sub cmp {
	my $a = shift;
	my $b = shift;
	
	$a = $a->as_string if ref $a and $a->can('as_string');
	$b = $b->as_string if ref $b and $b->can('as_string');
	
	return $a cmp $b;
}

sub _default_parent {
	return 'Data::Header::Fields';
}

sub parent {
	my $self   = shift;
	$self->{'parent'} = shift
		if @_;
	
	return (ref $self ? $self->{'parent'} : $self->_default_parent);
}


1;


__END__

=head1 NAME

Data::Header::Fields - encode and decode RFC822 header field lines

=head1 SYNOPSIS

	use IO::Any;
	my $email_msg = IO::Any->slurp([ 'path', 'to', 'email.eml' ]);
	my ($email_header, $email_body) = split(/^\s*$/m, $email_msg, 2);

	use Data::Header::Fields;
	my $dhf = Data::Header::Fields->new->decode(\$email_header);
	print 'From    - ', $dhf->get_value('From'), "\n";
	print 'Subject - ', $dhf->get_value('Subject'), "\n";
	print 'Date    - ', $dhf->get_value('Date'), "\n";
	print '--- cut ---', "\n";

	$dhf->set_value('To' => ' anyone@anywhere');
	$dhf->rm_fields('Received');
	
	print $dhf->encode();

=head1 WARNING

experimental, use on your own risk :-)

=head1 DESCRIPTION

RFC822 - Standard for ARPA Internet Text Messages (L<http://tools.ietf.org/html/rfc822#section-3.2>)
describes the format of header lines used in emails. The tricky part is
the line folding.

There are some "forks" of this standard. One of them is Debian RFC-2822-like
fields and the other is RFC2425 that defines the so called vCard format.
L<Data::Header::Fields> is generic enough to serve as a base class to parse
those as well.

One of the main goals of the module is to be able to edit the headers while
keeping the lines that were not changed untouched.

For the moment this is all documentation. After more tests with vCards and
using this module for the basic parsing in L<Parse::Deb::Control> it will
be stable enough.

Currently this distribution is highly radioactive!

=head1 SEE ALSO

L<http://tools.ietf.org/html/rfc2822> - Internet Message Format

=head1 AUTHOR

Jozef Kutej

=cut
