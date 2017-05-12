package Catalyst::TraitFor::Controller::RenderView;
use MooseX::MethodAttributes::Role;
use Catalyst::Action::RenderView;
use namespace::autoclean;

our $VERSION = '0.002';
$VERSION = eval $VERSION;

sub end :Action {}

after 'end' => sub {
    my ($controller, $ctx) = @_;
    # Yes, yes - I am evil.
    no warnings 'redefine';
    local *next::method = sub { };
    use warnings 'redefine';
    bless({}, 'FakeAction')->Catalyst::Action::RenderView::execute($controller, $ctx);
};

1;

=head1 NAME

Catalyst::TraitFor::Controller::RenderView - Alternative to Catalyst::Action::RenderView using method modifiers.

=head1 SYNOPSIS

    package MyApp::Controller::Root;
    use Moose;
    use namespace::autoclean;

    BEGIN { extends 'Catalyst::Controller' }
    with 'Catalyst::TraitFor::Controller::RenderView;

=head1 DESCRIPTION

This is an experimental alternative to L<Catalyst::Action::RenderView>.

=head1 METHODS

=head2 end

Provided if not present, wrapped to run the same checks
as L<Catalyst::Action::RenderView> after end action.

=head1 BUGS

The code is a B<horrible hack>, as it delegates all the work
to L<Catalyst::Action::RenderView>.

How end method attributes will compose onto other classes which
already have an end method is unknown (they shouldn't..)

How renaming the supplied 'end' method will work is untested at
the moment.

=head1 AUTHOR

Tomas Doran (t0m) C<< bobtfish@bobtfish.net >>.

=head1 COPYRIGHT & LICENSE

Copyright 2009 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut
