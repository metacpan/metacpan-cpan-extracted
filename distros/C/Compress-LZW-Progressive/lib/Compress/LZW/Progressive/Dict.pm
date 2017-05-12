package Compress::LZW::Progressive::Dict;

use strict;
use warnings;
use bytes;

our $VERSION = '0.1';

sub new {
	my ($class) = @_;

	my %self = (
		tree => Compress::LZW::Progressive::Dict::Tree->new(),
	#	hash => {},
		array => [],
		next_code => 0,
		reuse_codes => [],
		codes_used => [],
		code_counter => 0,
	);

	my $self = bless \%self, $class;

	$self->add($_) foreach map { chr } 0..255;

	return $self;
}

## Adding and deleting from the dict

sub add {
	my ($self, $phrase, $code) = @_;

	return 0 unless defined $phrase;
	return 1 if $self->code($phrase); #defined $self->{hash}{$phrase};

	if (! defined $code) {
		$code = int @{ $self->{reuse_codes} } ? shift @{ $self->{reuse_codes} } : $self->{next_code}++;
	}

	my @chars = split //, $phrase;
	$self->{tree}->add(\@chars, $code);

#	$self->{hash}{$phrase} = $code;
	$self->{array}[$code] = $phrase;

	return $code;
}

sub delete {
	my ($self, $phrase, $code) = @_;

	return 0 unless defined $phrase && defined $code;
#	return 0 unless defined $self->{hash}{$phrase};
	return 0 unless defined $self->{array}[$code];

	my @chars = split //, $phrase;
	$self->{tree}->delete(\@chars);

#	delete $self->{hash}{$phrase};
	$self->{array}[$code] = undef;
	
	$self->{codes_used}[$code] = undef;

	push @{ $self->{reuse_codes} }, $code;

	return 1;
}

sub delete_phrase {
	my ($self, $phrase) = @_;

	my $code = $self->{hash}{$phrase};
	return $self->delete($phrase, $code);
}

sub delete_code {
	my ($self, $code) = @_;

	my $phrase = $self->{array}[$code];
	return $self->delete($phrase, $code);
}

sub delete_codes {
	my ($self, @codes) = @_;
	while (my $code = shift @codes) {
		my $phrase = $self->{array}[$code];
		return 0 unless $self->delete($phrase, $code);
	}
	return 1;
}

## Accessors

sub code_matching_str {
	my ($self, $str) = @_;
	return $self->code_matching_array([ split //, $str ]);
}
sub code_matching_array {
	my ($self, $arr) = @_;
	return $self->{tree}->search(0, $arr);
}

sub increment_code_usage_count {
	my ($self, $code) = @_;
	$self->{codes_used}[$code] = $self->{code_counter}++;
	return undef;
}

sub next_code {
	return $_[0]->{next_code};
}

sub codes_used {
	my $self = shift;
	return $self->{next_code} - int @{ $self->{reuse_codes} };
}

# Given a count, return that many codes which haven't been used lately

sub least_used_codes {
	my ($self, $count) = @_;

	my $codes_used = $self->{codes_used};
	my @delete =
		sort { $codes_used->[$a] <=> $codes_used->[$b] }
		grep { defined $codes_used->[$_] }
		256..$#{ $codes_used };

	$count = int(@delete) if int(@delete) < $count;

#	print join ', ', map { "$_ => $codes_used->[$_]" } @delete[0..($count-1)];
#	print "\n";

	return @delete[0..($count - 1)];
}

sub phrase {
	my ($self, $code) = @_;

	return $self->{array}[$code];
}

sub code {
	my ($self, $phrase) = @_;

#	return $self->{hash}{$phrase};
	my $code = $self->code_matching_str($phrase);
	if ($code && $self->phrase($code) eq $phrase) {
		return $code;
	}
	else {
		return undef;
	}
}

sub dump {
	my ($self) = shift;

#	print "Phrase Hash\n";
#	foreach my $phrase (keys %{ $self->{hash} }) {
#		printf "%6d : %20s\n", $self->{hash}{$phrase}, $phrase;
#	}

	print "Code Array\n";
	foreach my $code (0..$#{ $self->{array} }) {
		next unless defined $self->{array}[$code];
		printf "%6d : %20s (%8d)\n", $code, $self->{array}[$code], $self->{codes_used}[$code];
	}

	print "Next Code: ".$self->{next_code}."\n";
	print "Reuse Codes:\n" . join(", ", @{ $self->{reuse_codes} }) . "\n";
	
#	return;
	print "Tree\n";
	$self->{tree}->print(0);
}

package Compress::LZW::Progressive::Dict::Tree;

use strict;
use warnings;
no warnings 'recursion';
use bytes;

our $VERSION = '0.11';

sub new {
	my ($class) = @_;
	$class = ref $class if ref $class;

	my @self = (
		{},
		undef,
	);

	return bless \@self, $class;
}

# Given an array of characters and a code, create children for each character and finally
# set the value of the final node

sub add {
	my ($self, $chars, $code) = @_;

	my $char = shift @$chars;
	if (defined $char) {
		$char = 'null' if ord($char) == 0;
		$self->[0]{$char} ||= $self->new();
		$self->[0]{$char}->add($chars, $code);
	}
	else {
		$self->[1] = $code;
	}
}

# Given an array and an index on that array, recursively delete all nodes from that point on and
# backwards while such nodes have no value

sub delete {
	my ($self, $chars) = @_;

	my $char = shift @$chars;
	$char = 'null' if defined $char && ord($char) == 0;

	# Descend to the last char
	if (defined $char && (my $child = $self->[0]{$char})) {
		if ($child->delete($chars)) {
			delete $self->[0]{$char};
		}
	}
	elsif (! defined $char) {
		$self->[1] = undef;
	}

	# Now, delete backwards unless I have children or a value
	return (%{ $self->[0] } || defined $self->[1]) ? 0 : 1;
}

# Given an array and an index on that array, recursively search for a defined node that matches
# as many as possible of the characters

sub search {
	my ($self, $index, $arr) = @_;

	my $found_desc;

	my $char = $arr->[$index];
	$char = 'null' if defined $char && ord($char) == 0;

	if (defined $char && (my $child = $self->[0]{$char})) {
		$found_desc = $child->search($index + 1, $arr);
		return $found_desc if defined $found_desc;
	}

	if (! defined $found_desc && defined $self->[1]) {
		return $self->[1];
	}
	
	return undef;
}

sub print {
	my ($self, $level) = @_;
	
	print ' ' . (' 'x$level) . ' => ' . $self->[1] . "\n" if defined $self->[1];
	foreach my $char (sort keys %{ $self->[0] }) {
		print ' ' . (' 'x$level) . $char . "\n";
		$self->[0]{$char}->print($level + 1);
	}
}

1;
