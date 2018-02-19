package Config::Dot::Array;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Config::Utils qw(hash_array);
use English qw(-no_match_vars);
use Error::Pure qw(err);
use Readonly;

Readonly::Scalar my $EMPTY_STR => q{};

our $VERSION = 0.06;

# Constructor.
sub new {
	my ($class, @params) = @_;
	my $self = bless {}, $class;

	# Callback.
	$self->{'callback'} = undef;

	# Config hash.
	$self->{'config'} = {};

	# Set conflicts detection as error.
	$self->{'set_conflicts'} = 1;

	# Process params.
	set_params($self, @params);

	# Check config hash.
	if (! $self->_check($self->{'config'})) {
		err 'Bad \'config\' parameter.';
	}

	# Check callback.
	if (defined $self->{'callback'} && ref $self->{'callback'} ne 'CODE') {
		err 'Parameter \'callback\' isn\'t code reference.';
	}

	# Count of lines.
	$self->{'count'} = 0;

	# Stack.
	$self->{'stack'} = [];

	# Object.
	return $self;
}

# Parse text or array of texts.
sub parse {
	my ($self, $string_or_array_ref) = @_;
	my @text;
	if (ref $string_or_array_ref eq 'ARRAY') {
		@text = @{$string_or_array_ref};
	} else {
		@text = split m/$INPUT_RECORD_SEPARATOR/ms,
			$string_or_array_ref;
	}
	foreach my $line (@text) {
		$self->{'count'}++;
		$self->_parse($line);
	}
	return $self->{'config'};
}

# Reset content.
sub reset {
	my $self = shift;
	$self->{'config'} = {};
	$self->{'count'} = 0;
	return;
}

# Serialize.
sub serialize {
	my $self = shift;
	return join "\n", $self->_serialize($self->{'config'});
}

# Check structure.
sub _check {
	my ($self, $config_ref) = @_;
	if (ref $config_ref eq 'HASH') {
		foreach my $key (sort keys %{$config_ref}) {
			if (ref $config_ref->{$key} ne ''
				&& ! $self->_check($config_ref->{$key})) {

				return 0;
			}
		}
		return 1;
	} elsif (ref $config_ref eq 'ARRAY') {
		foreach my $val (@{$config_ref}) {
			if (ref $val ne '' && ! $self->_check($val)) {
				return 0;
			}
		}
		return 1;
	} else {
		return 0;
	}
}

# Parse string.
sub _parse {
	my ($self, $string) = @_;

	# Remove comments on single line.
	$string =~ s/^\s*#.*$//ms;

	# Blank space.
	if ($string =~ m/^\s*$/ms) {
		return 0;
	}

	# Split.
	my ($key, $val) = split m/=/ms, $string, 2;

	# Not a key.
	if (length $key < 1) {
		return 0;
	}

	# Bad key.
	if ($key !~ m/^[-\w\.:,]+\+?$/ms) {
		err "Bad key '$key' in string '$string' at line ".
			"'$self->{'count'}'.";
	}

	my @tmp = split m/\./ms, $key;
	hash_array($self, \@tmp, $val);

	# Ok.
	return 1;
}

# Serialize.
sub _serialize {
	my ($self, $config_ref) = @_;
	if (ref $config_ref eq 'HASH') {
		my @ret;
		foreach my $key (sort keys %{$config_ref}) {
			my @subkey = $self->_serialize(
				$config_ref->{$key});
			foreach my $subkey (@subkey) {
				if ($subkey !~ m/^=/ms) {
					$subkey = '.'.$subkey;
				}
				push @ret, $key.$subkey;
			}
		}
		return @ret;
	} elsif (ref $config_ref eq 'ARRAY') {
		my @ret;
		foreach my $val (@{$config_ref}) {
			push @ret, $self->_serialize($val);
		}
		return @ret;
	} else {
		return '='.$config_ref;
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Config::Dot::Array - Module for simple configure file parsing with arrays.

=head1 SYNOPSIS

 my $cnf = Config::Dot::Array->new(%params);
 my $struct_hr = $cnf->parse($string);
 $cnf->reset;
 my $serialized = $cnf->serialize;

=head1 METHODS

=over 8

=item C<new(%params)>

 Constructor.

=over 8

=item * C<callback>

 Callback code for adding parameter.
 Callback arguments are:
 $key_ar - Reference to array with keys.
 $value - Key value.
 Default is undef.

=item * C<config>

 Reference to hash structure with default config data.
 This is hash of hashes or arrays structure.
 Default value is reference to blank hash.

=item * C<set_conflicts>

 Set conflicts detection as error.
 Default value is 1.

=back

=item C<parse($string_or_array_ref)>

Parse string $string_or_array_ref or reference to array 
$string_or_array_ref and returns hash structure.

=item C<reset()>

Reset content in class (config parameter).

=item C<serialize()>

Serialize 'config' hash to output.

=back

=head1 PARAMETER_FILE

 # Comment.
 # blabla

 # White space.
 /^\s*$/

 # Parameters.
 # Key must be '[-\w\.:,]+'.
 # Separator is '='.
 key=val
 key2.subkey.subkey=val

 # Arrays.
 key3=val1
 key3=val2

=head1 ERRORS

 new():
         Bad 'config' parameter.
         Parameter 'callback' isn't code reference.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 parse():
         Bad key '%s' in string '%s' at line '%s'.
         From Config::Utils::hash_array():
                 Conflict in '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Config::Dot::Array;
 use Dumpvalue;

 # Object.
 my $struct_hr = Config::Dot::Array->new->parse(<<'END');
 key1=value1
 key2=value2
 key2=value3
 key3.subkey1=value4
 key3.subkey1=value5
 END

 # Dump
 my $dump = Dumpvalue->new;
 $dump->dumpValues($struct_hr);

 # Output:
 # 0  HASH(0x9970430)
 #    'key1' => 'value1'
 #    'key2' => ARRAY(0x9970660)
 #       0  'value2'
 #       1  'value3'
 #    'key3' => HASH(0x9970240)
 #       'subkey1' => ARRAY(0xa053658)
 #          0  'value4'
 #          1  'value5'

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Config::Dot::Array;

 # Object with data.
 my $c = Config::Dot::Array->new(
         'config' => {
                 'key1' => {
                         'subkey1' => 'value1',
                 },
                 'key2' => [
                         'value2',
                         'value3',
                 ],
         },
 );

 # Serialize.
 print $c->serialize."\n";

 # Output:
 # key1=subkey1.value1
 # key2=value2
 # key2=value3

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Config::Dot::Array;
 use Dumpvalue;

 # Object.
 my $struct_hr = Config::Dot::Array->new(
         'callback' => sub {
                my ($key_ar, $value) = @_;
                if ($key_ar->[0] eq 'key3' && $key_ar->[1] eq 'subkey1'
                        && $value eq 'value3') {

                        return 'FOOBAR';
                }
                return $value;
         },
 )->parse(<<'END');
 key1=value1
 key2=value2
 key3.subkey1=value3
 key3.subkey1=value4
 END

 # Dump
 my $dump = Dumpvalue->new;
 $dump->dumpValues($struct_hr);

 # Output:
 # 0  HASH(0x87d05e8)
 #    'key1' => 'value1'
 #    'key2' => 'value2'
 #    'key3' => HASH(0x87e3840)
 #       'subkey1' => ARRAY(0x87e6f68)
 #          0  'FOOBAR'
 #          1  'value4'

=head1 DEPENDENCIES

L<Class::Utils>,
L<Config::Utils>,
L<English>,
L<Error::Pure>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Config::Dot>

Module for simple configure file parsing.

=item L<Config::Utils>

Common config utilities.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Config-Dot-Array>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2011-2018 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.06

=cut
