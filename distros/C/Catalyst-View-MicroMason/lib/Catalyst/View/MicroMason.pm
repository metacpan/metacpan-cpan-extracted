package Catalyst::View::MicroMason;

use strict;
use base qw/Catalyst::View::Templated Class::Accessor/;
use Text::MicroMason;
use Class::C3;

our $VERSION = '0.05';

# template_root is the old way of saying INCLUDE_PATH.  don't use it.
__PACKAGE__->mk_accessors(qw(_template Mixins template_root));

=head1 NAME

Catalyst::View::MicroMason - MicroMason View Class

=head1 SYNOPSIS

Use the helper:

    script/create.pl view MicroMason MicroMason

To create a simple View subclass:

    # lib/MyApp/View/MicroMason.pm
    package MyApp::View::MicroMason;
    use base 'Catalyst::View::MicroMason';
    1;

And configure it in your app's config:

    MyApp->config->{View::MicroMason} = {
        # -Filters      : to use |h and |u
        # -ExecuteCache : to cache template output
        # -CompileCache : to cache the templates
        Mixins        => [qw( -Filters -CompileCache )], 
        INCLUDE_PATH  => '/path/to/comp_root'
    };
    
In an 'end' action:

    $c->view('MicroMason')->template('foo.mc');
    $c->forward('MyApp::View::MicroMason');

Or perhaps:

    my $output = $c->view('MicroMason')->render('foo.mc');

=head1 DESCRIPTION

Want to use a MicroMason component in your views? No problem!
Catalyst::View::MicroMason comes to the rescue.

=head1 METHODS

=head2 new

Create an instance; should be called from C<COMPONENT>, not by you.

=cut

sub new {
    my ($self, $c, $args) = @_;
    shift;

    my $real_include = $args->{INCLUDE_PATH};
    
    $self = $self->next::method(@_);
    
    my $root = $real_include || 
               $self->template_root || 
               $c->config->{root};

    if (ref $root eq 'ARRAY' && @$root > 1) {
        die "Catalyst::View::MicroMason only supports one entry in ".
          "the INCLUDE_PATH or template_root.";
    }
    
    $root = $root->[0] if ref $root;
    $self->template_root($root);
    
    my @Mixins  = @{ $self->Mixins || [] };
    push @Mixins, qw(-TemplateDir -AllowGlobals); 
    $self->_template(Text::MicroMason->new(@Mixins, 
					  template_root => $root,
					  %$self
					 )
                    );
    
    return $self;
}

=head2 process

Renders the component specified in $c->stash->{template} or by the
value $c->action (if $c->stash->{template} is undefined).  See
L<Catalyst::View::Templated> for all the details.

MicroMason global variables C<$base>, C<$c> (or whatever you pass in
at config time as CATALYST_VAR) and c<$name> are automatically set to the base,
context and name of the app, respectively.

An exception is thrown if processing fails, otherwise the output is stored
in C<< $c->response->body >>.

=head2 render([$template])

Renders the given template and returns output.  

Throws an exception on error.  If C<$template> is not defined, it is
determined by calling C<< $self->template >>.  See
L<Catalyst::View::Templated> for details.

=cut

sub _render {
    my ($self, $template, $stash, $args) = @_;

    my $c_name = '$'. $self->{CATALYST_VAR};
    
    # Set the URL base, context and name of the app as global Mason vars
    # $base, $c and $name
    $self->_template->set_globals( '$base' => $self->context->req->base,
                                   $c_name => $self->context,
                                   '$name' => $self->context->config->{name},
                                 );
    
    delete $stash->{$self->{CATALYST_VAR}};
    delete $stash->{base};
    delete $stash->{name};

    warn "MicroMason: using a stash key called 'file' sets the template" 
      if exists $stash->{file};
    
    return $self->_template->execute(file => $template, %$stash);
}


=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View::Templated>, L<Text::MicroMason>,
L<Catalyst::View::Mason>

=head1 AUTHOR

Jonas Alves C<< <jgda@cpan.org> >>

=head1 MAINTAINER

The Catalyst Core Team L<http://www.catalystframework.org>

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
