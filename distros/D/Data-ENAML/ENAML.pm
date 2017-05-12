package Data::ENAML;

use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);
require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::ENAML ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	serialize deserialize	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '0.03';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

sub serialize {
	my @pair; 
	if (@_ == 1 && UNIVERSAL::isa($_[0], 'HASH')) {
		my %hash = %{shift()};
		my @keys = keys %hash;
		if (scalar(@keys) != 1) {
			croak "serialized must be called with a key:value pair";
		}
		@pair = %hash;
	} elsif (@_ == 2) {
		@pair = @_;
	} else {
		croak "serialized must be called with a key:value pair";
	}
	unless ($pair[0] =~ /[a-z_-]{1,32}/i) {
		croak "$pair[0] is an illegal key name";
	}
	"$pair[0]: " . &do_serialize($pair[1], {}) . "\r\n";
}

sub do_serialize {
	my ($datum, $history) = @_;
	unless (ref($datum)) {
		return $datum if ($datum =~ /^\d+$/);
		unless ($datum =~ /[\000-\037"%\x7F\xFF]/) {
			return qq!"$datum"!; # TO DO: add UTF8 support
		}
		my $opt1 = $datum;
		$opt1 =~ s/([\000-\037"%\x7F\xFF])/sprintf("%%%02X", ord($1))/ge;
		$opt1 = qq!"$opt1"!;
		my $opt2 = '%' . join("", map {sprintf("%02X", $_);}
			unpack("C*", $datum));
		return (length($opt1) <= length($opt2)) ? $opt1 : $opt2;
	}
	croak "Circular referencing detected" if ++$history->{$datum} > 1;
	if (UNIVERSAL::isa($datum, 'HASH')) {
		my $str = "{ ";
		my $count = 0;
		while (my ($key, $val) = each %$datum) {
			unless ($key =~ /[a-z_-]{1,32}/i) {
				croak "$datum is an illegal key name";
			}
			$str .= " " if (++$count > 1);
			if ($val eq "\000" || !defined($val)) {
				$str .= $key;
				next;
			}
			$str .= "$key: " . &do_serialize($val);
		}
		$str .= " }";
		return $str;
	} elsif (UNIVERSAL::isa($datum, 'ARRAY')) {
		my $str = "[ ";
		my $count = 0;
		foreach (@$datum) {
			$str .= " " if (++$count > 1);
			$str .= &do_serialize($_);	
		}
		$str .= " ]";
		return $str;
	}
	croak "Object type " . ref($datum) . " not supported";
}

sub deserialize {
	my $text = shift;
	$text =~ s/[\r\n]+$//;
	my ($hash, $rem) = &deserialize_hash("$text }");
	croak "Ended at $rem" if ($rem);
	$hash;
}

sub deserialize_hash {
	local ($_) = shift;
	my $struct = {};
	while ($_) {
		s/^\s+//;
		if (s/^\}//) {
			return ($struct, $_);
		}
		unless (s/^([A-Za-z-_]{1,32})(:?)\s*//) {
			croak "Expected: key, at $_";
		}
		my $key = $1;
		unless ($2) {
			$struct->{$key} = undef;
			next;
		}
		($struct->{$key}, $_) = &eat_one($_);
	}
	croak "expected }";
}

sub deserialize_array {
	local ($_) = shift;
	my $array = [];
	while ($_) {
		s/^\s+//;
		if (s/^\]//) {
			return ($array, $_);
		}
		my ($elem, $rem) = &eat_one($_);
		$_ = $rem;
		push(@$array, $elem);
	}
	croak "expected ]";
}

sub eat_one {
	local ($_) = shift;
	if (s/^\{//) {
		my ($hash, $text) = &deserialize_hash($_);
		return ($hash, $text);
	}
	if (s/^\[//) {
		my ($ary, $text) = &deserialize_array($_);
		return ($ary, $text);
	} 
	if (s/^(\d+)(?![^}\]\t ])//) {
		return($1, $_);
	}
	if (s/^\"(.*?)\"//) {
		my $text = $1;
		$text =~ s/%([0-9A-F]{2})/chr(hex($1))/gei;
		return ($text, $_);
	}
	if (s/^%([0-9A-F]+)//i) {
		my $hex = $1;
		croak "Odd number of hex digits" if (length($hex) % 2);
		my @tokens = ($hex =~ /(..)/g);
		my $str = pack("C*", map {hex($_);} @tokens);
		return ($str, $_);
	}
	croak "Could not get token at $_";
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Data::ENAML - Perl extension for ENAML data representation

=head1 SYNOPSIS

  use Data::ENAML qw (serialize deserialize);

  print serialize('login' => {'nick' => 'Schop', 
	'email' => 'ariel@atheist.org.il', 
	'tagline' => 'If I had no modem I would not lose Regina'});

  $struct = deserialize('bad-nick: {nick: "c00l dewd" text: "spaces not allowed"}');

=head1 OVERVIEW

ENAML stands for ENAML is Not A Markup Language. (And as we all know, 
Gnu is Not UNIX, Pine Is Not Email, Wine Is Not Emulator, 
Lame Ain't Mp3 Encoder and so on).

ENAML was defined by Robey Pointer for use in Say2, check 
http://www.lag.net/say2.

=head1 CREDITS

Robey Pointer has an ENAML module, but I couldn't find it in CPAN.
Differences between the modules (besides the different API) include:

=item 

Data::ENAML will marshall blessed objects.

=item

Data::ENAML does not convert UTF-8, and does not automatically assume 
Latin-1 charset.

=item

Data::ENAML represents unassigned properties by undef and not a NULL 
character.

=head1 TODO

Support UTF-8. Robey's module assumes automatically Latin character set. 
Nu, Ivrit Kasha Saffa!

=head1 AUTHOR

Ariel Brosh, schop@cpan.org

=head1 SEE ALSO

perl(1), L<Net::IRC>.

=cut
