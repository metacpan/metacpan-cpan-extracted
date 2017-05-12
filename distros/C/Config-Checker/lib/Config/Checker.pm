
package Config::Checker;

use strict;
use warnings;
use Eval::LineNumbers qw(eval_line_numbers);
require Exporter;
require Config::YAMLMacros::YAML;
require Module::Load;
require Time::ParseDate;
require Carp;
use Config::YAMLMacros::YAML;

our @ISA = qw(Exporter);
our @EXPORT = qw(config_checker_source);
our @EXPORT_OK = (@EXPORT, qw(unique split_listify));
our $VERSION = 0.42;

our %mults = (
	K	=> 1024,
	M	=> 1024**2,
	G	=> 1024**3,
	T	=> 1024**4,
	P	=> 1024**5,
);

#
# We are returning this code as text for the recipient to compile so that
# it will have access to the recipient's lexical variables.
#
sub config_checker_source
{
return eval_line_numbers(<<'END_SOURCE');

	import Config::Checker qw(unique split_listify);
	sub {
		my ($config, $prototype_string, $where) = @_;
		$prototype_string =~ s/^(\t+)/" " x length($1) * 8/e;
		my $proto = ref($prototype_string)
			? $prototype_string
			: Config::YAMLMacros::YAML::Load($prototype_string);

		my %checker;
		my $error;

		local(%Config::Checker::unique);

		my $cleaner = sub {
			my ($spec) = @_;
			Carp::confess if ref($spec);
			my $desc = $spec;
			my $quantity = '';
			my $default;
			my $name_entry;
			$desc =~ s/^=//
				and $name_entry = 1;
			$desc =~ s/^([*%+?])//
				and $quantity = $1 || '';
			if ($quantity eq '?') {
				$desc =~ s/^<([^<>]*)>//
					and $default = $1;
			} elsif ($quantity eq '+' || $quantity eq '*') {
				$desc =~ s/^<([^<>]*)>//
					and $default = qr/$1/;
			}
			my $type = '';
			$desc =~ s/\[(.*)\]$// 
				and $type = $1 || '';
			my $code = '';
			$desc =~ s/\{(.*)\}$// 
				and $code = $1 || '';
			return ($desc, $type, $code, $quantity, $default);
		};
		my $validate = sub {
			my ($ref, $context, $spec) = @_;
			Carp::confess if ref($spec);
			my $value = $$ref;
			my ($desc, $type, $code, $quantity, $default) = $cleaner->($spec);
#no warnings;
#print <<END;
#----------------
#DESC: $desc
#TYPE: $type
#CODE: $code
#QNTY: $quantity
#DFLT: $default
#END
			if (ref $value) {
				die "Not expecting a ".ref($value)." for $context $where";
			}
			if ($type eq 'MODULE_NAME') {
				eval { Module::Load::load $value };
				die "Could not load module $value for $context ($proto): $@ $where" if $@;
			} elsif ($type eq 'PATH') {
				die "Illegal characters in path '$value' for $context $where"
					if $value =~ /\s/;
			} elsif ($type eq 'DATE') {
				die "Could not understand date '$value' for $context $where"
					unless Time::ParseDate::parsedate($value);
			} elsif ($type eq 'INTEGER') {
				die "An integer is required, not '$value' for $context $where"
					unless $value =~ /^\d+$/;
			} elsif ($type eq 'HOSTNAME') {
				die "A hostname is required: '$value' does not resovle' for $context $where"
					unless gethostbyname($value);
			} elsif ($type eq 'WORD') {
				die "Text that can be used as a filename require. '$value' is not okay for $context $where"
					if $value =~ m{[/\n\r]};
			} elsif ($type eq 'STRING') {
				# anything goes
			} elsif ($type eq 'BOOLEAN') {
				if ($value =~ /^no?$/i || $value =~ /^false$/ || $value eq '0') {
					$$ref = 0;
				} elsif ($value =~ /^y(es)?$/i || $value =~ /^true$/ || $value eq '1') {
					$$ref = 1;
				} else {
					die "True/False/Yes/No/0/1 expected, got '$value' instead for $context $where";
				}
			} elsif ($type eq 'TEXT') {
				die "Illegal characters in $context ($proto): '$value' $where" 
					if $value =~ /[^-\w_\s]/;
				die "Must set a value for $context ($proto) $where"
					unless $value =~ /\S/;
			} elsif ($type eq 'SIZE') {
				if ($value =~ /^\d+$/) {
					# just fine
				} elsif ($value =~ /^(\d+)([KMGTP])$/) {
					$$ref = $1 * $Config::Checker::mults{$2};
				} else {
					die "Expected a size, like 25M, got '$value' for $context $where";
				}
				
			} elsif ($type eq 'CODE') {
				# don't bother to verify here
			} elsif ($type eq 'FREQUENCY') {
				# don't bother to verify here
			} elsif ($type eq 'TIMESPAN') {
				# don't bother to verify here
			} elsif ($type ne '') {
				die "Unknown type specification '$type' for $context $where";
			}
			if ($code) {
				my $override = $code =~ s/^=//;
				undef $error;
				unless ($checker{$code}) {
					$checker{$code} = eval qq{ sub { $code } };
					die "validation code '$code' is broken for validating $context: $@ $where" if $@;
				}
				my $valid = $checker{$code}->($value);
				die $error." $where\n" if $error;
				die "Invalid $context value, should be $desc ($code) $where" unless $valid;
				$$ref = $valid if $override;
			}
		};
		# This is self-referential and will leak.  Oh, well.
		my $compare;
		$compare = sub {
			my ($context, $config, $proto) = @_;
			for my $uk (keys %$config) {
				next if defined $proto->{$uk};
				die "Unexpected configuration key: '$uk' $where";
			}
			for my $k (keys %$proto) {
				my $spec = $proto->{$k};

				if (ref $spec) {
					if (ref($spec) eq 'ARRAY') {
						next unless $config->{$k};
						$config->{$k} = [ $config->{$k} ]
							unless ref($config->{$k}) eq 'ARRAY';
						my $name_entry;
						if (ref($spec->[0]) eq 'HASH') {
							($name_entry) = grep { (!ref $spec->[0]{$_}) && $spec->[0]{$_} =~ /^=/ } keys %{$spec->[0]};
						}
						my $count = 1;
						for my $i (@{$config->{$k}}) {
							my $sub = "[$count]";
							$sub = "{$i->{$name_entry}}"
								if $name_entry && ref($i) eq 'HASH' && $i->{$name_entry};
							$compare->("$context : $k $sub", $i, $spec->[0]);
							$count++;
						}
					} elsif (ref($spec) eq 'HASH') {
						next unless $config->{$k};
						die "Expecting key/values for $context $k $where"
							unless ref($config->{$k}) eq 'HASH';
						my @sk = keys %$spec;
						my $user_supplied = grep { /[][]/ } @sk;
						if ($user_supplied) {
							die "expected only one key $where" unless @sk == 1;
							for my $hk (keys %{$config->{$k}}) {
								$validate->(\$hk, "$context : $hk (key)", $sk[0]);
								$compare->("$context : $hk", $config->{$k}{$hk}, $spec->{$sk[0]});
							}
						} else {
							$compare->("$context : $k", $config->{$k}, $spec);
						}
					}
				} else {
					my ($desc, $type, $code, $quantity, $default) = $cleaner->($spec);

					if ($quantity eq '*') {
						# zero or more
						next unless exists $config->{$k};
						$config->{$k} = split_listify($config->{$k}, $default)
							unless ref $config->{$k};
						my $count = 1;
						for my $i (@{$config->{$k}}) {
							$validate->(\$i, "$context : $k [$count]", $spec);
							$count++;
						}
					} elsif ($quantity eq '+') {
						# one or more
						die "Missing required item $k ($desc) in $context $where"
							unless exists $config->{$k};
						$config->{$k} = split_listify($config->{$k}, $default)
							unless ref $config->{$k};
						my $count = 1;
						for my $i (@{$config->{$k}}) {
							$validate->(\$i, "$context : $k [$count]", $spec);
							$count++;
						}
					} elsif ($quantity eq '?') {
						# optional
						$config->{$k} = $default
							if defined($default) and ! exists $config->{$k};
						$validate->(\$config->{$k}, "$context : $k", $spec)
							if exists $config->{$k};
					} elsif ($quantity eq '%') {
						next unless exists $config->{$k};
						die "Expecting key/values (HASH) for $k ($desc) in $context $where but got '$config->{$k}'"
							unless ref($config->{$k}) eq 'HASH';
					} elsif (! exists $config->{$k}) {
						die "Missing required item $k ($desc) in $context $where";
					} else {
						$validate->(\$config->{$k}, "$context : $k", $spec);
					}
				}
			}
		};

		$compare->("config", $config, $proto);
	}
END_SOURCE
}

sub split_listify
{
	my ($val, $sep) = @_;

	if (defined($sep) && $sep ne '') {
		my @vals = split(/$sep/, $val);
		if (@vals > 1) {
			do { 
				s/^\s+//;
				s/\s+\Z//;
			} for @vals;
		}
		return \@vals;
	} else {
		return [ $val ];
	}
}

our %unique;
sub unique
{
	my ($thing, $value) = @_;
	die "$thing '$value' isn't unique"
		if $unique{$thing}{$value}++;
}

1;

__END__

=head1 NAME

Config::Checker - Validate configuration objects against a template

=head1 SYNOPSIS

 use Config::Checker;

 my $checker = eval config_checker_source;
 die $@ if $@;

 my $prototype_config = 'YAML stuff';
 my $config = YAML::Load($config_file);

 eval { $checker->($config, $prototype_config); }

 print "invalid config: $@" if $@;

=head1 DESCRIPTION

Config::Checker provides a method for verifying 
configuration data against a prototype.  The prototype 
is either a perl object or is a YAML string.

The prototype is structured the same as the configuration
file (assuming the configuration data is specified in YAML).
Hashes are hashes, arrays are arrays, etc.  Arrays of hashes
should have just one record in the prototype.  That one record
will be matched against all the records in the configuration.

Most things are a hash and organized as KEY: VALUE pairs.

The key and value should both be descriptive.  Additionaly,
keys and values can have a type specified, code executed, or
a quantity specified.

All keys are considered manditory unless the quantity specifier
says otherwise.

=head2 C<[TYPE]>

Keys and values can be followed with a C<[TYPE]> signifier.
The TYPES that are currently tested against are: 
C<[HOSTNAME]>, C<[DATE]>, C<[CODE]>, C<[INTEGER]>, 
C<[SIZE]>,
C<[MODULE_NAME]> and C<[PATH]>.

=head2 C<{code}>

Keys and values can be followed with a C<{code}> block.  The
code is executed.  Unless it returns a true value, the 
configuration is deemed invalid.  To precisely control the
error message, the code can set the variable C<$error>.
For example:

 format: 'record format for this source{valid_parser($_[0]) or $error = "invalid parser: <$_[0]> at $context"}'

When there is both a C<[TYPE]> and a C<{code}> specifier, the
C<[TYPE]> comes first.

=head2 Quantity

Values may specifiy a quantity.   The quantity is pre-pended to
the description: 
 
 source: '+name of input the data[TEXT]'

The quantity specifiers are:

=over

=item C<+>(list separator)

One or more of these are required.  If there is more than one,
they should be in an array.  If there is just one and it's not
in an array, it will be put into one.

If there is a list separator, and there is only one item, then
that one item will be split up with the list separator and 
whitespace cleaned.

=item C<*>(list separator)

Zero or more of these are allowed.  If there is exactly one and
it's not an array, it will be put into an array.

If there is a list separator, and there is only one item, then
that one item will be split up with the list separator and 
whitespace cleaned.

=item C<%>

This value should be a hash that is not validated.

=item C<?>

The item is optional.

=item C<?C<lt>default valueC<gt>>

The item is optional in the configuration, but if it not 
specified a default value will be supplied.

 temporary_storage: '?</tmp>Where to keep tmp files[PATH]'

=back

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

