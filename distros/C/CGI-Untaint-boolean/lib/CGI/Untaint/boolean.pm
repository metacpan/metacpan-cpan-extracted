package CGI::Untaint::boolean;

use strict;
use vars '$VERSION';

$VERSION = '1.01';

use base 'CGI::Untaint::object';

sub _untaint_re { qr/^(on|)$/ }

sub is_valid
{
	my $self         = shift;
	my $value        = $self->value();
	my ($untainted)  = $value =~ $self->_untaint_re();
	$untainted     ||= '';

	$self->value( $untainted eq 'on' ? 1 : 0 );

	return unless $untainted eq 'on' || $untainted eq '';
	return 1;
}

1;
__END__

=head1 NAME

CGI::Untaint::boolean - untaint boolean values from CGI programs

=head1 SYNOPSIS

  use CGI::Untaint;

  my $handler = CGI::Untaint->new( $q->Vars() );
  my $boolean = $handler->extract( -as_boolean => 'some_feature' );

=head1 DESCRIPTION

This input handler verifies that it is dealing with a reasonable boolean value,
probably from a checkbox with no value specified.  In this case, "reasonable"
means that the value is C<on>, if the checkbox is checked, or empty, if the
client did not send a value.

B<Note:> the C<value()> method will return either true or false.  It will
I<not> return the string "on" or the empty string.  It's boolean for a reason!
(Don't count on it returning C<0> for false either; false is just false.)

=head1 METHOD

=head2 C<is_valid()>

Returns true if the value for this checkbox is valid, setting the value to true
if the value is C<on>, false otherwise.

=head1 SEE ALSO

L<CGI::Untaint>, L<CGI::Untaint::object>

=head1 AUTHOR

chromatic, C<< chromatic at wgz dot org >>

Thanks to Tony Bowden for helpful suggestions, Simon Wilcox for reporting a
false value bug, with a test patch, and Dave Wilcox for helping to disambiguate
the documentation.

=head1 BUGS

No known bugs.  Please report any to L<http://rt.cpan.org/>.

=head1 COPYRIGHT

Copyright (c) 2004 - 2005, chromatic.  All rights reserved.  You may use,
modify, and distribute this module under the same terms as Perl 5.8.x itself,
in the hope that it is useful but certainly under no guarantee.
