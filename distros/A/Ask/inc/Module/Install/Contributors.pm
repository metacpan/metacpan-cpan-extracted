#line 1
package Module::Install::Contributors;

use 5.006;
use strict;
use warnings;

BEGIN {
	$Module::Install::Contributors::AUTHORITY = 'cpan:TOBYINK';
	$Module::Install::Contributors::VERSION   = '0.001';
}

use base qw(Module::Install::Base);

sub contributors
{
	my $self = shift;
	push @{ $self->Meta->{values}{x_contributors} ||= [] }, @_;
}

1;

__END__

