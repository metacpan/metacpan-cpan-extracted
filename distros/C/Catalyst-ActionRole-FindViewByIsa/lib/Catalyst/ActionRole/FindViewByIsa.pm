package Catalyst::ActionRole::FindViewByIsa;
use Moose::Role;
use List::MoreUtils qw/uniq/;
use namespace::autoclean;

our $VERSION = '0.000003';

sub BUILD { }

after 'BUILD' => sub {
    my ($self, $args) = @_;
    my $attrs = $args->{attributes};
    die("Catalyst::ActionRole::FindViewByIsa used without a FindViewByIsa attribute in /" . $self->reverse . "\n")
        unless $attrs->{FindViewByIsa};
};

after 'execute' => sub {
    my ($self, $controller, $c, @args ) = @_;
    return if $c->stash->{current_view};
    my $isa = $self->attributes->{FindViewByIsa}[0];
    if ($c->config->{default_view}) {
        my $view = $c->view($c->config->{default_view});
        $c->stash->{current_view} = $c->config->{default_view}
            if $view->isa($isa);
    }
    my @views = grep { $c->view($_)->isa($isa) } $c->views;
    die("$c does not have a view which is a subclass of $isa")
        unless scalar @views;
    $c->stash->{current_view} = $views[0];
};


=head1 NAME

Catalyst::ActionRole::FindViewByIsa - Select from the available application views by type

=head1 SYNOPSIS

    package MyApp::Controller::Foo;
    use Moose;

    BEGIN { extends 'Catalyst::Controller::ActionRole'; }

    sub foo : Local Does('FindViewByIsa') FindViewByIsa('Catalyst::View::TT') {
        # Code here. If $c->stash->{current_view} is set, it will be left alone
        #            after this method is run. Otherwise it will be set to
        #            the first app view which @ISA Catalyst::View::TT
    }

=head1 DESCRIPTION

If you are trying to write a generic controller component which will be reused within an application, you do not
want to mandate the use of one type of view, but if you're providing templates with your component, then
you need to be able to find a view of the appropriate type.

Therefore this action role will select a the view in the application which
matches the class of view that you want, no matter what it is named locally
within the application.

=head1 AUTHOR

Tomas Doran (t0m), C<< <bobtfish@bobtfish.net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Tomas Doran, some rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

