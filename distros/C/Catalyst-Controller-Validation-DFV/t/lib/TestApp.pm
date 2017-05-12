package # hide from PAUSE
    TestApp;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use Catalyst qw/FillInForm/;
use Class::Inspector;
use FindBin;

# our @TEMPLATES = ( 'Mason', 'HTML::Template', 'TT' );
# TODO add tests with View::Mason

# the preferred view is the first in the list
our @TEMPLATES = ( 'TT', 'HTML::Template' );

my ( @except, $template_type );
for (@TEMPLATES) {
    unless ( Class::Inspector->installed( "Catalyst::View::" . $_ ) ) {
        push @except, "TestApp::Component::$_";
    }
    else {
        $template_type ||= $_;
    }
}

__PACKAGE__->config(
    name             => 'TestApp',
    home             => $FindBin::RealBin,
    setup_components =>
      { search_extra => ['TestApp::Component'], except => \@except },
    template_type => $template_type || 'Rendered',
);

__PACKAGE__->setup();


1;
__END__

=pod

=head1 NAME

TestApp - Catalyst application for testing Catalyst::Controller::Validation::DFV

=head1 CREDITS

The core of this TestApp was heavily borrowed from
L<Catalyst::Controller::FormBuilder>.

=head1 AUTHOR

Chisel Wright C<< <chisel@herlpacker.co.uk> >>

=cut
