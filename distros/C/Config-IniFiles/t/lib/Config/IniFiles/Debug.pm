use strict;
use warnings;

use Carp;

# Checks that the following relationships hold set-wise (e.g. ignoring order):
#
#  keys($self->{v}) = $self->{sects}
#
# And for every section $sect:
#
#  keys($self->{v}{sect}) = $self->{v}{params}
#
# This should be the case whenever control flows outside this module. Croaks
# upon any error.
sub Config::IniFiles::_assert_invariants {
	my ($self)=@_;
	my %set;
	foreach my $sect (@{$self->{sects}}) {
		croak "Non-lowercase section $sect" if ($self->{nocase} &&
											  (lc($sect) ne $sect));
		$set{$sect}++;
	}
	foreach my $sect (keys %{$self->{v}}) {
		croak "Key $sect in \$self->{v} and not in \$self->{sects}" unless
		  ($set{$sect}++);
	}
	grep { croak "Key $_ in \$self->{sects} and not in in \$self->{v}" unless
	   $set{$_} eq 2 } (keys %set);

	foreach my $sect (@{$self->{sects}}) {
		%set=();

		foreach my $parm (@{$self->{parms}{$sect}}) {
			croak "Non-lowercase parameter $parm" if ($self->{nocase} &&
													(lc($parm) ne $parm));
			$set{$parm}++;
		}
		foreach my $parm (keys %{$self->{v}{$sect}}) {
			croak "Key $parm in \$self->{v}{'$sect'} and not in \$self->{parms}{'$sect'}"
			  unless ($set{$parm}++);
		}
		grep { croak "Key $_ in \$self->{parms}{'$sect'} and not in in \$self->{v}{'$sect'}"
				 unless $set{$_} eq 2 } (keys %set);
	}
}

1;

