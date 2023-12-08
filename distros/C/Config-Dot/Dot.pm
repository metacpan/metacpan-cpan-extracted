package Config::Dot;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Config::Utils qw(hash);
use English qw(-no_match_vars);
use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Scalar my $EMPTY_STR => q{};

our $VERSION = 0.10;

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
		@text = split m/$INPUT_RECORD_SEPARATOR/sm,
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
	return join $INPUT_RECORD_SEPARATOR,
		$self->_serialize($self->{'config'});
}

# Check structure.
sub _check {
	my ($self, $config_hr) = @_;
	if (ref $config_hr eq 'HASH') {
		foreach my $key (sort keys %{$config_hr}) {
			if (ref $config_hr->{$key} ne ''
				&& ! $self->_check($config_hr->{$key})) {

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
	$string =~ s/^\s*#.*$//sm;

	# Blank space.
	if ($string =~ m/^\s*$/sm) {
		return 0;
	}

	# Split.
	my ($key, $val) = split m/=/sm, $string, 2;

	# Not a key.
	if (length $key < 1) {
		return 0;
	}

	# Bad key.
	if ($key !~ m/^[-\w\.:,]+\+?$/sm) {
		err "Bad key '$key' in string '$string' at line ".
			"'$self->{'count'}'.";
	}

	my @tmp = split m/\./sm, $key;
	hash($self, \@tmp, $val);

	# Ok.
	return 1;
}

# Serialize.
sub _serialize {
	my ($self, $config_hr) = @_;
	my @ret;
	foreach my $key (sort keys %{$config_hr}) {
		if (ref $config_hr->{$key} eq 'HASH') {
			my @subkey = $self->_serialize($config_hr->{$key});
			foreach my $subkey (@subkey) {
				push @ret, $key.'.'.$subkey;
			}
		} else {
			if ($config_hr->{$key} =~ m/\n/ms) {
				err 'Unsupported stay with newline in value.';
			}
			push @ret, $key.'='.$config_hr->{$key};
		}
	}
	return @ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Config::Dot - Module for simple configure file parsing.

=head1 SYNOPSIS

 use Config::Dot;

 my $cnf = Config::Dot->new(%params);
 my $struct_hr = $cnf->parse($string);
 $cnf->reset;
 my $serialized = $cnf->serialize;

=head1 METHODS

=head2 C<new>

 my $cnf = Config::Dot->new(%params);

Constructor.

=over 8

=item * C<callback>

Callback code for adding parameter.

Callback arguments are:

=over

=item C<$key_ar>

Reference to array with keys.

=item C<$value>

Key value.

=back

Default is undef.

=item * C<config>

Reference to hash structure with default config data.
This is hash of hashes structure.

Default value is reference to blank hash.

=item * C<set_conflicts>

Set conflicts detection as error.

Default value is 1.

=back

Returns instance of object.

=head2 C<parse>

 my $struct_hr = $cnf->parse($string);

Parse string C<$string_or_array_ref> or reference to array C<$string_or_array_ref>.
Use C<$INPUT_RECORD_SEPARATOR> variable to split lines.

Returns hash structure with configuration.

=head2 C<reset>

 $cnf->reset;

Reset content in class (config parameter).

Returns undef.

=head2 C<serialize>

 my $serialized = $cnf->serialize;

Serialize 'config' hash to output.
Use C<$INPUT_RECORD_SEPARATOR> variable to join lines.

Returns string with serialized configuration.

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

=head1 ERRORS

 new():
         Bad 'config' parameter.
         Parameter 'callback' isn't code reference.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 parse():
         Bad key '%s' in string '%s' at line '%s'.
         From Config::Utils::hash():
                  Conflict in '%s'.

 serialize():
         Unsupported stay with newline in value.

=head1 EXAMPLE1

=for comment filename=parse_example.pl

 use strict;
 use warnings;

 use Config::Dot;
 use Data::Printer;

 # Object.
 my $struct_hr = Config::Dot->new->parse(<<'END');
 key1=value1
 key2=value2
 key3.subkey1=value3
 END

 # Dump.
 p $struct_hr;

 # Output:
 # {
 #     key1   "value1",
 #     key2   "value2",
 #     key3   {
 #         subkey1   "value3"
 #     }
 # }

=head1 EXAMPLE2

=for comment filename=serialize_example.pl

 use strict;
 use warnings;

 use Config::Dot;

 # Object with data.
 my $c = Config::Dot->new(
         'config' => {
                 'key1' => {
                         'subkey1' => 'value1',
                 },
                 'key2' => 'value2',
         },
 );

 # Serialize.
 print $c->serialize."\n";

 # Output:
 # key1.subkey1=value1
 # key2=value2

=head1 EXAMPLE3

=for comment filename=parse_example_with_callback.pl

 use strict;
 use warnings;

 use Config::Dot;
 use Data::Printer;

 # Object.
 my $struct_hr = Config::Dot->new(
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
 END

 # Dump.
 p $struct_hr;

 # Output:
 # {
 #     key1   "value1",
 #     key2   "value2",
 #     key3   {
 #         subkey1   "FOOBAR"
 #     }
 # }

=head1 DEPENDENCIES

L<Class::Utils>,
L<Config::Utils>,
L<English>,
L<Error::Pure>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Config::Utils>

Common config utilities.

=item L<Config::Dot::Array>

Module for simple configure file parsing with arrays.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Config-Dot>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.10

=cut
