use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Interfaces::Stealth;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Interfaces::Stealth - Interface for hidden Wyrds

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

Interface that automatically "Hides" the member Wyrd from it's children,
so as to apply conditionals to the inside of Wyrds which have
dependencies on their children.

This is useful, say, in enclosing a group of Form::Input wyrds without
disconnecting them from their enclosing form.


=head1 BUGS/CAVEATS/RESERVED METHODS

Overrides the _pre_spawn method.

=cut

sub _pre_spawn {
	my ($self, $class, $init_hash) = @_;
	$init_hash->{'_parent'}=$self->{'_parent'};
	return ($class, $init_hash);
}


=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;
