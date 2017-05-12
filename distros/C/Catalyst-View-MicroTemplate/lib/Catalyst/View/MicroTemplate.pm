package Catalyst::View::MicroTemplate;
use Moose;
use Text::MicroTemplate::Extended;
use namespace::clean -except => qw(meta);

our $VERSION = '0.00002';

extends 'Catalyst::View';

has context => (
    is => 'rw',
    isa => 'Catalyst',
);

has content_type => (
    is => 'ro',
    isa => 'Str',
    default => 'text/html'
);

has charset => (
    is => 'ro',
    isa => 'Str',
    default => 'utf8',
);

has include_path => (
    is => 'ro',
    isa => 'ArrayRef',
);

has template_suffix => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1
);

has stash_key => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1
);

has template_args => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1
);

has template => (
    is => 'ro',
    isa => 'Text::MicroTemplate::Extended',
    lazy_build => 1,
);

around BUILDARGS => sub {
    my ($next, $self, $c, $args) = @_;

    my $paths = $args->{include_path};
    if (!$paths || ref $paths ne 'ARRAY') {
        if (! defined $paths) {
            $paths ||= [];
        } else {
            $paths = [ $paths ];
        }
        $args->{include_path} = $paths;
    }

    if (scalar @$paths < 1) {
        push @$paths, $c->path_to('root');
    }
    return $self->$next($args);
};

sub ACCEPT_CONTEXT {
    my ($self, $c) = @_;
    $self->context($c);
    return $self;
}

sub _build_template_suffix {
    return '.mt';
}

sub _build_stash_key {
    my $self = shift;
    return '__' . ref($self) . '_template';
}

sub _build_template_args {
    return {};
}

sub _build_template {
    my ($self) = @_;

    return Text::MicroTemplate::Extended->new(
        extension     => $self->template_suffix,
        include_path  => $self->include_path,
        template_args => $self->template_args,
    );
}

sub render {
    my ($self, $template, $args) = @_;
    my $mt = $self->template;
    return $mt->render_file($template, $self->context, $args);
}

sub process {
    my ($self) = @_;

    my $c = $self->context;
    my $template = $self->get_template_file( $c );
    $c->log->debug( sprintf("[%s] rendering template %s", blessed $self, $template ) ) if $c->debug;

    $c->res->content_type( sprintf("%s; charset=%s", $self->content_type, $self->charset ) );
    $self->template->template_args( $c->stash );
    my $body = $self->render( $template, $c->stash );
    if (blessed $body && $body->can('as_string')) {
        $body = $body->as_string;
    }
    $c->res->body( $body );
}

sub get_template_file {
    my ($self, $c) = @_;
    
    # hopefully they're using the new $c->view->template
    my $template = $c->stash->{$self->stash_key()};
    
    # if that's empty, get the template the old way, $c->stash->{template}
    $template ||= $c->stash->{template};
    
    # if those aren't set, try $c->action 
    $template ||= $c->action;
    
    return $template;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Catalyst::View::MicroTemplate - Text::MicroTemplate View For Catalyst

=head1 SYNOPSIS

    # MyApp::View::MicroTemplate
    package MyApp::View::MicroTemplate;
    use strict;
    use base qw(Catalyst::View::MicroTemplate);

    # in your config
    <View::MicroTemplate>
        content_type text/html # added to header
        charset UTF-8          # added to header
        inlucde_path __path_to(root)__
        include_path /path/to/include/path
        template_suffix .mt # default
        <template_args>
            foo bar # $foo will be available in the template
        </template_args>
    </View::MicroTemplate>

    # same thing in YAML
    'View::MicroTemplate':
        content_type: text/html
        charset: UTF-8
        include_path:
            - __path_to(root)__
            - /path/to/include/path
        template_args:
            foo: bar
        template_suffix: .mt
        
=head1 DESCRIPTION

This is a Text::MicroTemplate view for Catalyst. 

Text::MicroTemplate is based on Mojo::Template, and it's aimed for speed and efficiency. In thismodule we use Text::MicroTemplate::Extended, as it allows a more
realistic usage for applications.

=head1 AUTHORS

Daisuke Maki C<< <daisuke@endeworks.jp> >> 

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut