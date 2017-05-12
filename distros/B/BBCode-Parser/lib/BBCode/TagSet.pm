# $Id: TagSet.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::TagSet;
use BBCode::Util qw(:tag);
use Carp qw(croak);
use strict;
use warnings;
our $VERSION = '0.34';

sub new($@):method {
	my $class = shift;
	$class = ref($class) || $class;
	my $this = bless {}, $class;
	$this->add(@_) if @_;
	return $this;
}

sub keys($):method {
	return keys %{+shift};
}

sub clone($):method {
	my $this = shift;
	my $that = $this->new();
	$that->add($this);
	return $that;
}

sub _args {
	my($std,$not) = splice @_, 0, 2;
	while(@_) {
		my $arg = shift;

		if(ref $arg) {
			if(UNIVERSAL::isa($arg,'BBCode::TagSet')) {
				foreach($arg->keys) {
					$std->();
				}
			} elsif(UNIVERSAL::isa($arg,'BBCode::Tag')) {
				local $_ = $arg->Tag;
				$std->();
			} elsif(ref $arg eq 'HASH') {
				unshift @_, keys %$arg;
			} elsif(ref $arg eq 'ARRAY') {
				unshift @_, @$arg;
			} elsif(ref $arg eq 'SCALAR' or ref $arg eq 'REF') {
				unshift @_, $$arg;
			} else {
				croak qq(Invalid reference);
			}
		} else {
			if($arg =~ /^(!?)(:\w+)$/) {
				local $_ = uc($2);
				(($1 eq '') ? $std : $not)->();
			} elsif($arg =~ /^(!?)(\w+)$/) {
				local $_ = tagCanonical($2);
				(($1 eq '') ? $std : $not)->();
			} else {
				croak qq(Malformed tag [$arg]);
			}
		}
	}
}

sub add($@):method {
	my $this = shift;
	_args(
		sub { $this->{$_} = 1 },
		sub { delete $this->{$_} },
		@_,
	);
	return $this;
}

sub remove($@):method {
	my $this = shift;
	_args(
		sub { delete $this->{$_} },
		sub { $this->{$_} = 1 },
		@_,
	);
	return $this;
}

sub contains($$):method {
	my $this = shift;
	my $tag = tagCanonical(shift);
	return 1 if exists $this->{$tag};
	return 0;
}

sub toString($):method {
	my $this = shift;
	return join(" ", sort keys %$this);
}
*as_string = *toString;

1;
