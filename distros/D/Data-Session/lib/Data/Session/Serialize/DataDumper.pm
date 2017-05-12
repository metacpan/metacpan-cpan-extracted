package Data::Session::Serialize::DataDumper;

use parent 'Data::Session::Base';
no autovivification;
use strict;
use warnings;

use Data::Dumper;

use Safe;

use Scalar::Util qw(blessed reftype refaddr);

use vars qw( %overloaded );

require overload;

our $VERSION = '1.17';

# -----------------------------------------------

sub freeze
{
	my($self, $data) = @_;
	my($d) = Data::Dumper -> new([$data], ["D"]);

	$d -> Deepcopy(0);
	$d -> Indent(0);
	$d -> Purity(1);
	$d -> Quotekeys(1);
	$d -> Terse(0);
	$d -> Useqq(0);

	return $d ->Dump;

} # End of freeze.

# -----------------------------------------------

sub new
{
	my($class) = @_;

	return bless({}, $class);

} # End of new.

# -----------------------------------------------
# We need to do this because the values we get back from the safe compartment
# will have packages defined from the safe compartment's *main instead of
# the one we use.

sub _scan
{
	# $_ gets aliased to each value from @_ which are aliases of the values in
	# the current data structure.

	for (@_)
	{
		if (blessed $_)
		{
			if (overload::Overloaded($_) )
			{
				my($address) = refaddr $_;

				# If we already rebuilt and reblessed this item, use the cached
				# copy so our ds is consistent with the one we serialized.

				if (exists $overloaded{$address})
				{
					$_ = $overloaded{$address};
				}
				else
				{
					my($reftype) = reftype $_;

					if ($reftype eq "HASH")
					{
						$_ = $overloaded{$address} = bless { %$_ }, ref $_;
					}
					elsif ($reftype eq "ARRAY")
					{
						$_ = $overloaded{$address} = bless [ @$_ ], ref $_;
					}
					elsif ($reftype eq "SCALAR" || $reftype eq "REF")
					{
						$_ = $overloaded{$address} = bless \do{my $o = $$_}, ref $_;
					}
					else
					{
						die __PACKAGE__ . ". Do not know how to reconstitute blessed object of base type $reftype";
					}
				}
			}
			else
			{
				bless $_, ref $_;
			}
		}
	}

	return @_;

} # End of _scan.

# -----------------------------------------------

sub thaw
{
	my($self, $data) = @_;

	# To make -T happy.

	my($safe_string) = $data =~ m/^(.*)$/s;
	my($rv)          = Safe -> new -> reval($safe_string);

	if ($@)
	{
		die __PACKAGE__ . ". Couldn't thaw. $@";
	}

	_walk($rv);

	return $rv;

} # End of thaw.

# -----------------------------------------------

sub _walk
{
	my(@filter) = _scan(shift);

	local %overloaded;

	my(%seen);

	# We allow the value assigned to a key to be undef.
	# Hence the defined() test is not in the while().

	while (@filter)
	{
		defined(my $x = shift @filter) or next;

		$seen{refaddr $x || ''}++ and next;

		# The original syntax my($r) = reftype($x) or next led to if ($r...)
		# issuing an uninit warning when $r was undef.

		my($r) = reftype($x) || next;

		if ($r eq "HASH")
		{
			# We use this form to make certain we have aliases
			# to the values in %$x and not copies.

			push @filter, _scan(@{$x}{keys %$x});
		}
		elsif ($r eq "ARRAY")
		{
			push @filter, _scan(@$x);
		}
		elsif ($r eq "SCALAR" || $r eq "REF")
		{
			push @filter, _scan($$x);
		}
	}

} # End of _walk.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::Serialize::DataDumper> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::Serialize::DataDumper> allows L<Data::Session> to manipulate sessions with
L<Data::Dumper>.

To use this module do this:

=over 4

=item o Specify a driver of type DataDumper as
Data::Session -> new(type=> '... serialize:DataDumper')

=back

The Data::Dumper options used are:

	$d -> Deepcopy(0);
	$d -> Indent(0);
	$d -> Purity(1);
	$d -> Quotekeys(1);
	$d -> Terse(0);
	$d -> Useqq(0);

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::Serialize::DataDumper>.

C<new()> takes a hash of key/value pairs, some of which might mandatory. Further, some combinations
might be mandatory.

The keys are listed here in alphabetical order.

They are lower-case because they are (also) method names, meaning they can be called to set or get
the value at any time.

=over 4

=item o verbose => $integer

Print to STDERR more or less information.

Typical values are 0, 1 and 2.

This key is normally passed in as Data::Session -> new(verbose => $integer).

This key is optional.

=back

=head1 Method: freeze($data)

Returns $data frozen by L<Data::Dumper>.

=head1 Method: thaw($data)

Returns $data thawed by L<Data::Dumper>.

=head1 Support

Log a bug on RT: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Session>.

=head1 Author

L<Data::Session> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
