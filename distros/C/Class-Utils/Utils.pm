package Class::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use List::Util qw(any);
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(set_params set_params_pub set_split_params
	split_params);

# Version.
our $VERSION = 0.14;

# Set parameters to user values.
sub set_params {
	my ($self, @params) = @_;

	while (@params) {
		my $key = shift @params;
		my $val = shift @params;
		if (! exists $self->{$key}) {
			err "Unknown parameter '$key'.";
		}
		$self->{$key} = $val;
	}

	return;
}

# Set parameters to user values - public variables.
sub set_params_pub {
	my ($self, @params) = @_;

	while (@params) {
		my $key = shift @params;
		my $val = shift @params;
		if ($key =~ m/^_/ms) {
			next;
		}
		if (! exists $self->{$key}) {
			err "Unknown parameter '$key'.";
		}
		$self->{$key} = $val;
	}

	return;
}

# Set params for object and other returns.
sub set_split_params {
	my ($self, @params) = @_;

	my @other_params;	
	while (@params) {
		my $key = shift @params;
		my $val = shift @params;
		if (! exists $self->{$key}) {
			push @other_params, $key, $val;
		} else {
			$self->{$key} = $val;
		}
	}

	return @other_params;
}

# Split params to object and others.
sub split_params {
	my ($object_keys_ar, @params) = @_;

	my @object_params;
	my @other_params;
	while (@params) {
		my $key = shift @params;
		my $val = shift @params;
		if (any { $_ eq $key } @{$object_keys_ar}) {
			push @object_params, $key, $val;
		} else {
			push @other_params, $key, $val;
		}
	}

	return (\@object_params, \@other_params);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Class::Utils - Class utilities.

=head1 SYNOPSIS

 use Class::Utils qw(set_params set_split_params);

 set_params($self, @params);
 set_params_pub($self, @params);
 my @other_params = set_split_params($self, @params);
 my ($object_params_ar, $other_params_ar) = split_params($object_keys_ar, @params);

=head1 SUBROUTINES

=head2 C<set_params>

 set_params($self, @params);

Sets object parameters to user values.
If set key doesn't exist in C<$self> object, turn fatal error.

$self - Object or hash reference.
@params - Key, value pairs.

=head2 C<set_params_pub>

 set_params_pub($self, @params);

Sets object parameters to user values. Only public arguments.
Private arguments are defined by '_' character on begin of key and will be
skip.
If set public key doesn't exist in C<$self> object, turn fatal error.

=over

=item C<$self>

Object or hash reference.

=item C<@params>

Key, value pairs.

=back

Returns undef.

=head2 C<set_split_params>

 my @other_params = set_split_params($self, @params);

Set object params and other returns.

=over

=item C<$self>

Object or hash reference.

=item C<@params>

Key, value pairs.

=back

Returns list of parameters.

=head2 C<split_params>

 my ($object_params_ar, $other_params_ar) = split_params($object_keys_ar, @params);

Split params to list of object params and other params.

Returns array with two values. First is reference to array with object
parameters. Second in reference to array with other parameters.

=head1 ERRORS

 set_params():
         Unknown parameter '%s'.

 set_params_pub():
         Unknown parameter '%s'.

=head1 EXAMPLE1

=for comment filename=set_params_ok.pl

 use strict;
 use warnings;

 use Class::Utils qw(set_params);

 # Hash reference with default parameters.
 my $self = {
        'test' => 'default',
 };

 # Set params.
 set_params($self, 'test', 'real_value');

 # Print 'test' variable.
 print $self->{'test'}."\n";

 # Output:
 # real_value

=head1 EXAMPLE2

=for comment filename=set_params_fail.pl

 use strict;
 use warnings;

 use Class::Utils qw(set_params);

 # Hash reference with default parameters.
 my $self = {};

 # Set bad params.
 set_params($self, 'bad', 'value');

 # Turn error >>Unknown parameter 'bad'.<<.

=head1 EXAMPLE3

=for comment filename=set_params_pub.pl

 use strict;
 use warnings;

 use Class::Utils qw(set_params_pub);

 # Hash reference with default parameters.
 my $self = {
         'public' => 'default',
 };

 # Set params.
 set_params_pub($self,
         'public' => 'value',
         '_private' => 'value',
 );

 # Print 'test' variable.
 print $self->{'public'}."\n";

 # Output:
 # value

=head1 EXAMPLE4

=for comment filename=set_split_params.pl

 use strict;
 use warnings;

 use Class::Utils qw(set_split_params);

 # Hash reference with default parameters.
 my $self = {
        'foo' => undef,
 };

 # Set bad params.
 my @other_params = set_split_params($self,
	'foo', 'bar',
	'bad', 'value',
 );

 # Print out.
 print "Foo: $self->{'foo'}\n";
 print join ': ', @other_params;
 print "\n";

 # Output:
 # Foo: bar
 # bad: value

=head1 EXAMPLE5

=for comment filename=split_params.pl

 use strict;
 use warnings;

 use Class::Utils qw(split_params);

 # Example parameters.
 my @params = qw(foo bar bad value);

 # Set bad params.
 my ($main_params_ar, $other_params_ar) = split_params(['foo'], @params);

 # Print out.
 print "Main params:\n";
 print "* ".(join ': ', @{$main_params_ar});
 print "\n";
 print "Other params:\n";
 print "* ".(join ': ', @{$other_params_ar});
 print "\n";

 # Output:
 # Main params:
 # * foo: bar
 # Other params:
 # * bad: value

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<List::Util>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Class-Utils>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.14

=cut
