package Catalyst::View::MicroTemplate::DataSection;
use Moose;
use Encode;
use Text::MicroTemplate::DataSection;
use namespace::autoclean;

our $VERSION = "0.03";

extends 'Catalyst::View';
with 'Catalyst::Component::ApplicationAttribute';

has section => (
    is  => 'rw',
    isa => 'Str',
    lazy_build => 1,
);

has context => (
    is  => 'rw',
    isa => 'Catalyst',
);

has content_type => (
    is      => 'rw',
    isa     => 'Str',
    lazy_build => 1,
);

has charset => (
    is      => 'rw',
    isa     => 'Str',
    default => 'UTF-8',
);

has template_extension => (
    is      => 'rw',
    isa     => 'Str',
    default => '.mt',
);

has engine => (
    is         => 'ro',
    isa        => 'Text::MicroTemplate::DataSection',
    lazy_build => 1,
);


sub ACCEPT_CONTEXT {
    my ($self, $c) = @_; 
    $self->context($c);
    return $self;
}

sub _build_section {
    my ($self) = @_;
    return $self->context->action->class;
}

sub _build_content_type {
    my ($self) = @_;
    return $self->context->res->content_type;
}

sub _build_engine {
    my ($self) = @_;
    return Text::MicroTemplate::DataSection->new(package => $self->section);
}

sub render {
    my ($self, $c, $template) = @_;
    return $self->engine->render($template.$self->template_extension, $c->stash);
}

sub process {
    my ($self, $c) = @_;

    my $template = $c->stash->{template} || $c->action->name;
    my $body     = $self->render($c, $template);

    $c->res->content_type($self->content_type.'; charset=' . $self->charset);

    if (blessed $body && $body->can('as_string')) {
        $body = $body->as_string;
    }   

    $c->res->body( $body );
}

__PACKAGE__->meta->make_immutable();


1;
__END__

=head1 NAME

Catalyst::View::MicroTemplate::DataSection - Text::MicroTemplate::DataSection View For Catalyst

=head1 SYNOPSIS

    # subclassing to making your view class
    package MyApp::View::DataSection;
    use Moose;
    extends 'Catalyst::View::MicroTemplate::DataSection';
    1;

    # using in a controller
    sub index :Path :Args(0) {
        my ( $self, $c ) = @_; 
        $c->stash->{username} = 'masakyst';
    }
    ...
    ..
    __PACKAGE__->meta->make_immutable;

    1;
    __DATA__
   
    @@ index.mt
    ? my $stash = shift;
    hello <?= $stash->{username} ?> !!


=head1 DESCRIPTION

Catalyst::View::MicroTemplate::DataSection is simple wrapper module allows you to render MicroTemplate template from __DATA__ section in Catalyst controller.

=head2 One file .psgi example

plackup -a hello.psgi

    package Hello::View::MicroTemplate::DataSection {
        use Moose; extends 'Catalyst::View::MicroTemplate::DataSection';
        sub _build_section { 'main' }
    };

    package Hello::Controller::Root {
        use Moose; BEGIN { extends 'Catalyst::Controller' }
        __PACKAGE__->config(namespace => '');

        sub index :Path :Args(0) {
            my ($self, $c) = @_; 
            $c->stash->{okinawa} = "Yomitan perl mongers";
        }   

        sub end : ActionClass('RenderView') {}
    };

    package Hello 0.01 {
        use Moose;
        use Catalyst::Runtime 5.80;
        extends 'Catalyst';
        __PACKAGE__->setup();
    };

    package main;
    Hello->psgi_app;

    __DATA__

    @@ index.mt
    ? my $stash = shift;
    <?= $stash->{okinawa} ?>


=head1 SEE ALSO

=over 1

=item L<Text::MicroTemplate::DataSection>

=item L<Data::Section::Simple>

=back


=head1 LICENSE

Copyright (C) Masaaki Saito.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masaaki Saito E<lt>masakyst.public@gmail.comE<gt>

=cut

