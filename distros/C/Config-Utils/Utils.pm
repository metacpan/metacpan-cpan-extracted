package Config::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(conflict hash hash_array);

# Version.
our $VERSION = 0.07;

# Check conflits.
sub conflict {
	my ($self, $config_hr, $key) = @_;
	if ($self->{'set_conflicts'} && exists $config_hr->{$key}) {
		err 'Conflict in \''.join('.', @{$self->{'stack'}}, $key).
			'\'.';
	}
	return;
}

# Create record to hash.
sub hash {
	my ($self, $key_ar, $val) = @_;
	my $config_hr = $self->{'config'};
	my $num = 0;
	foreach my $key (@{$key_ar}) {
		if ($num != $#{$key_ar}) {
			if (! exists $config_hr->{$key}) {
				$config_hr->{$key} = {};
			} elsif (ref $config_hr->{$key} ne 'HASH') {
				conflict($self, $config_hr, $key);
				$config_hr->{$key} = {};
			}
			$config_hr = $config_hr->{$key};
			push @{$self->{'stack'}}, $key;
		} else {
			conflict($self, $config_hr, $key);

			# Process callback.
			if (defined $self->{'callback'}) {
				$val = $self->{'callback'}->(
					[@{$self->{'stack'}}, $key],
					$val,
				);
			}

			# Add value.
			$config_hr->{$key} = $val;

			# Clean.
			$self->{'stack'} = [];
		}
		$num++;
	}
	return;
}

# Create record to hash.
sub hash_array {
	my ($self, $key_ar, $val) = @_;
	my $config_hr = $self->{'config'};
	my $num = 0;
	foreach my $key (@{$key_ar}) {
		if ($num != $#{$key_ar}) {
			if (! exists $config_hr->{$key}) {
				$config_hr->{$key} = {};
			} elsif (ref $config_hr->{$key} ne 'HASH') {
				conflict($self, $config_hr, $key);
				$config_hr->{$key} = {};
			}
			$config_hr = $config_hr->{$key};
			push @{$self->{'stack'}}, $key;
		} else {

			# Process callback.
			if (defined $self->{'callback'}) {
				$val = $self->{'callback'}->(
					[@{$self->{'stack'}}, $key],
					$val,
				);
			}

			# Add value.
			if (ref $config_hr->{$key} eq 'ARRAY') {
				push @{$config_hr->{$key}}, $val;
			} elsif ($config_hr->{$key}) {
				my $foo = $config_hr->{$key};
				$config_hr->{$key} = [$foo, $val];
			} else {
				$config_hr->{$key} = $val;
			}

			# Clean.
			$self->{'stack'} = [];
		}
		$num++;
	}
	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Config::Utils - Common config utilities.

=head1 SYNOPSIS

 use Config::Utils qw(conflict hash hash_array);

 conflict($self, {'key' => 1}, 'key');
 hash($self, ['one', 'two'], $val);
 hash_array($self, ['one', 'two'], $val);

=head1 SUBOUTINES

=over 8

=item C<conflict($self, $config_hr, $key)>

 Check conflicts.
 Affected variables from $self:
 - set_conflicts - Flag, then control conflicts.
 - stack - Reference to array with actual '$key' key position.
 Returns undef or fatal error.

=item C<hash($self, $key_ar, $val)>

 Create record to hash.
 Affected variables from $self:
 - config - Actual configuration in hash reference.
 - set_conflicts - Flag, then control conflicts.
 - stack - Reference to array with actual '$key' key position.
 Returns undef or fatal error.

=item C<hash_array($self, $key_ar, $val)>

 Create record to hash.
 If exists more value record for one key, then create array of values.
 Affected variables from $self:
 - config - Actual configuration in hash reference.
 - set_conflicts - Flag, then control conflicts.
 - stack - Reference to array with actual '$key' key position.
 Returns undef or fatal error.

=back

=head1 ERRORS

 conflict():
         Conflict in '%s'.

 hash():
         Conflict in '%s'.

 hash_array():
         Conflict in '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Config::Utils qw(conflict);

 # Object.
 my $self = {
         'set_conflicts' => 1,
         'stack' => [],
 };

 # Conflict.
 conflict($self, {'key' => 'value'}, 'key');

 # Output:
 # ERROR: Conflict in 'key'.

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Config::Utils qw(hash);
 use Dumpvalue;

 # Object.
 my $self = {
         'config' => {},
         'set_conflicts' => 1,
         'stack' => [],
 };

 # Add records.
 hash($self, ['foo', 'baz1'], 'bar');
 hash($self, ['foo', 'baz2'], 'bar');

 # Dump.
 my $dump = Dumpvalue->new;
 $dump->dumpValues($self);

 # Output:
 # 0  HASH(0x955f3c8)
 #    'config' => HASH(0x955f418)
 #       'foo' => HASH(0x955f308)
 #          'baz1' => 'bar'
 #          'baz2' => 'bar'
 #    'set_conflicts' => 1
 #    'stack' => ARRAY(0x955cc38)
 #         empty array 

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Config::Utils qw(hash_array);
 use Dumpvalue;

 # Object.
 my $self = {
         'config' => {},
         'set_conflicts' => 1,
         'stack' => [],
 };

 # Add records.
 hash_array($self, ['foo', 'baz'], 'bar');
 hash_array($self, ['foo', 'baz'], 'bar');

 # Dump.
 my $dump = Dumpvalue->new;
 $dump->dumpValues($self);

 # Output:
 # 0  HASH(0x8edf890)
 #    'config' => HASH(0x8edf850)
 #       'foo' => HASH(0x8edf840)
 #          'baz' => ARRAY(0x8edf6d0)
 #             0  'bar'
 #             1  'bar'
 #    'set_conflicts' => 1
 #    'stack' => ARRAY(0x8edf6e0)
 #         empty array

=head1 EXAMPLE4

 use strict;
 use warnings;

 use Config::Utils qw(hash_array);
 use Dumpvalue;

 # Object.
 my $self = {
         'callback' => sub {
                 my ($key_ar, $value) = @_;
                 return uc($value);
         },
         'config' => {},
         'set_conflicts' => 1,
         'stack' => [],
 };

 # Add records.
 hash_array($self, ['foo', 'baz'], 'bar');
 hash_array($self, ['foo', 'baz'], 'bar');

 # Dump.
 my $dump = Dumpvalue->new;
 $dump->dumpValues($self);

 # Output:
 # 0  HASH(0x8edf890)
 #    'callback' => CODE(0x8405c40)
 #       -> &CODE(0x8405c40) in ???
 #    'config' => HASH(0x8edf850)
 #       'foo' => HASH(0x8edf840)
 #          'baz' => ARRAY(0x8edf6d0)
 #             0  'BAR'
 #             1  'BAR'
 #    'set_conflicts' => 1
 #    'stack' => ARRAY(0x8edf6e0)
 #         empty array

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Config::Dot>

Module for simple configure file parsing.

=item L<Config::Dot::Array>

Module for simple configure file parsing with arrays.

=back

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Josef Špaček 2011-2020
 BSD 2-Clause License

=head1 VERSION

0.07

=cut
