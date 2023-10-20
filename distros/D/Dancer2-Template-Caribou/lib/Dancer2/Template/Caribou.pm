package Dancer2::Template::Caribou;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Template::Caribou wrapper for Dancer2
$Dancer2::Template::Caribou::VERSION = '1.0.1';
# TODO move away from Dancer2::Test


use strict;
use warnings;

use Path::Tiny;
use Path::Iterator::Rule;
use Moose::Util qw/ with_traits find_meta /;

use Moo;

with 'Dancer2::Core::Role::Template';

has '+default_tmpl_ext' => (
    default => sub { 'bou' },
);

has view_class => (
    is => 'ro',
    default => sub { { } },
);

has layout_class => (
    is => 'ro',
    default => sub { { } },
);

has namespace => (
    is => 'ro',
    lazy => 1,
    default => sub {
        $_[0]->config->{namespace} || 'Dancer2::View';
    },
);

sub _build_type { 'Caribou' };

sub BUILD {
    my $self = shift;

    my $views_dir = $self->views;

    my @views =
    Path::Iterator::Rule->new->skip_dirs('layouts')->file->name('bou')->all(
        $views_dir );

    $self->generate_view_class( $_ ) for @views;

    my @layouts =
    Path::Iterator::Rule->new->file->name('bou')->all(
        path( $views_dir, 'layouts' ) );

    $self->generate_layout_class( $_ ) for @layouts;
}

sub generate_layout_class {
    my( $self, $bou ) = @_;

    my $bou_dir = path($bou)->parent;
    my $segment = ''.path($bou)->relative($self->views.'/layouts')->parent;

    ( my $name = $segment ) =~ s#/#::#;
    $name = join '::', $self->namespace, $name;

    my $inner = path($bou)->slurp;

    eval qq{
package $name;

use Moose::Role;
use Template::Caribou;

# line 1 "$bou"

$inner;

with 'Template::Caribou::Files' => {
    dirs => [ '$bou_dir' ],
};

1;
} unless find_meta( $name );

    warn $@ if $@;

    $self->layout_class->{$segment} = $name;

}

sub generate_view_class {
    my( $self, $bou ) = @_;

    my $bou_dir = path($bou)->parent;
    my $segment = ''.path($bou)->relative($self->views)->parent;

    ( my $name = $segment ) =~ s#/#::#;
    $name = join '::', $self->namespace, $name;

    return if $self->layout_class->{$segment};

    my $inner = path($bou)->slurp;

    eval qq{
package $name;

use Template::Caribou;

with qw/
    Dancer2::Template::Caribou::DancerVariables
/;

has context => (
    is => 'ro',
);

has app => (
    is => 'ro',
    handles => [ 'config' ],
);

# line 1 "$bou"

$inner;

with 'Template::Caribou::Files' => {
    dirs => [ '$bou_dir' ],
};

1;
} unless find_meta($name);

    warn $@ if $@;

    $self->view_class->{$segment} = $name;

}

sub apply_layout {
    return $_[1];
}

sub render {
    my( $self, $template, $tokens ) = @_;

    $template =~ s/\.bou$//;

    $template = path( $template )->relative( $self->views );

    my $class = $self->view_class->{$template};
    
    unless ( $class ) {
        my $c = $template;
        $c =~ s#/#::#g;
        $c = join '::', $self->namespace, $c;
        die "template '$template' not found\n"
            unless eval { $c->DOES('Template::Caribou::Role') };
        $class = $c;
    }

    if ( my $lay = $self->layout || $self->settings->{layout} ) {
        my $role = $self->layout_class->{$lay}
            or die "layout '$lay' not defined\n";

        $class = with_traits( $class, $role, 
        )
    }

    return $class->new( request => $self->request,  %$tokens)->render('page');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Template::Caribou - Template::Caribou wrapper for Dancer2

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    # in 'config.yml'
    template: Caribou

    engines:
      template:
        Caribou:
          namespace:    MyApp::View


    # and then in the application
    get '/' => sub { 
        ...;

        template 'main' => \%options;
    };

=head1 DESCRIPTION

C<Dancer2::Template::Caribou> is an interface for the L<Template::Caribou>
template system. Be forewarned, both this module and C<Template::Caribou>
itself are alpha-quality software and are still subject to any changes. <Caveat
Maxima Emptor>.

=head2 Basic Usage

At the base, if you do

    get '/' => sub {
        ...

        return template 'MyView', \%options;
    };

the template name (here I<MyView>) will be concatenated with the 
configured view namespace (which defaults to I<Dancer2::View>)
to generate the Caribou class name. A Caribou object is created
using C<%options> as its arguments, and its inner template C<page> is then
rendered. In other words, the last line of the code above becomes 
equivalent to 

    return Dancer2::View::MyView->new( %options )->render('page');

=head2 '/views' template classes

Template classes can be created straight from the C</views> directory.
Any directory containing a file named C<bou> will be turned into a 
C<Template::Caribou> class. Additionally, any file with a C<.bou> extension
contained within that directory will be turned into a inner template for 
that class.

=head3 The 'bou' file

The 'bou' file holds the custom bits of the Template::Caribou class.

For example, a basic welcome template could be:

    # in /views/welcome/bou
    
    use Template::Caribou::Tags::HTML ':all';

    has name => ( is => 'ro' );

    template page => sub {
        my $self = shift;

        html {
            head { title { 'My App' } };
            body {
                h1 { 'hello ' . $self->name .'!' };
            };
        }
    };

which would be invoqued via

    get '/hi/:name' => sub {
        template 'welcome' => { name => param('name') };
    };

=head3 The inner template files

All files with a '.bou' extension found in the same directory as the 'bou'
file become inner templates for the class. So, to continue with the example
above, we could change it into

    # in /views/howdie/bou
    
    use Template::Caribou::Tags::HTML ':all';

    has name => ( is => 'ro' );


    # in /views/howdie/page
    sub {
        my $self = shift;
        html {
            head { title { 'My App' } };
            body {
                h1 { 'howdie ' . $self->name . '!' };
            };
        }
    }

=head3 Layouts as roles

For the layout sub-directory, an additional piece of magic is performed.
The 'bou'-marked directories are turned into roles instead of classes, which will be applied to
the template class. Again, to take our example:

    # in /views/layouts/main/bou
    # empty file

    # in /views/layouts/main/page
    
    # the import of tags really needs to be here 
    # instead than in the 'bou' file 
    use Template::Caribou::Tags::HTML ':all';

    html {
        head { title { 'My App' } };
        body {
            show( 'inner' );
        };
    }

    # in /views/hullo/bou
    
    use Template::Caribou::Tags::HTML ':all';

    has name => ( is => 'ro' );

    # in /views/howdie/inner
    h1 { 'hullo ' . $self->name . '!' };

=head1 CONFIGURATION

=over

=item namespace 

The namespace under which the Caribou classes are created.
defaults to C<Dancer2::View>.

=back

=head1 CONVENIENCE ATTRIBUTES AND METHODS

Auto-generated templates have the
L<Dancer2::Template::Caribou::DancerVariables> role automatically applied to
them, which give them helper methods like C<uri_for()> and C<context()> to
interact with the Dancer environment. If you roll out your own template
classes, you simply have to apply the role to have access to the same niftiness.

    package Dancer2::View::MyView;

    use Template::Caribou;

    with qw/ 
        Dancer2::Template::Caribou::DancerVariables 
    /;

    template page => sub {
        my $self = shift;
        
        print ::RAW $self->uri_for( '/foo' );
    };

=over

=item context()

The L<Dancer2::Core::Context> object associated with the current request.

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
