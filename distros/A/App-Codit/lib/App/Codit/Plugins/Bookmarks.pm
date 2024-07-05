package App::Codit::Plugins::Bookmarks;

=head1 NAME

App::Codit::Plugins::Bookmarks - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.03;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

What's an editor without bookmarks?.

Not yet implemented

=cut
sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	return $self;
}

sub Unload {
	my $self = shift;
	return $self->SUPER::Unload;
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=back

=cut

1;

