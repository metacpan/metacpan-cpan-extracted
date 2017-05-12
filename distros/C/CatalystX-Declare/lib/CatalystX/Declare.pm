use MooseX::Declare;
use 5.008008;

class CatalystX::Declare extends MooseX::Declare is dirty {

    use aliased 'CatalystX::Declare::Keyword::Model',       'ModelKeyword';
    use aliased 'CatalystX::Declare::Keyword::View',        'ViewKeyword';
    use aliased 'CatalystX::Declare::Keyword::Controller',  'ControllerKeyword';
    use aliased 'CatalystX::Declare::Keyword::Role',        'RoleKeyword';
    use aliased 'CatalystX::Declare::Keyword::Application', 'ApplicationKeyword';

    clean;

    our $VERSION = '0.015';

    around keywords (ClassName $self:) {
        $self->$orig,
        ControllerKeyword->new(     identifier => 'controller'      ),
        RoleKeyword->new(           identifier => 'controller_role' ),
        ApplicationKeyword->new(    identifier => 'application'     ),
        ViewKeyword->new(           identifier => 'view'            ),
        ModelKeyword->new(          identifier => 'model'           ),
    }
}

__END__

=head1 NAME

CatalystX::Declare - EXPERIMENTAL Declarative Syntax for Catalyst Applications

=head1 SYNOPSIS

=head2 Application

    use CatalystX::Declare;
    
    application MyApp::Web with Static::Simple {
    
        $CLASS->config(name => 'My Declarative Web Application');
    }

See also: 
L<CatalystX::Declare::Keyword::Application>, 
L<MooseX::Declare/class>

=head2 Controllers

    use CatalystX::Declare;

    controller MyApp::Web::Controller::Foo
          with MyApp::Web::ControllerRole::Bar {
        
        use MooseX::Types::Moose qw( Str );
        
        
        has welcome_message => (
            is          => 'rw',
            isa         => Str,
            required    => 1,
            lazy_build  => 1,
        );
        
        method _build_welcome_message { 'Welcome' }
        
        
        action base under '/' as '';
        
        under base {
            
            final action welcome {
                $ctx->response->body( $self->welcome_message );
            }
        }
    }

See also: 
L<CatalystX::Declare::Keyword::Controller>, 
L<CatalystX::Declare::Keyword::Action>, 
L<CatalystX::Declare::Keyword::Component>, 
L<MooseX::Declare/class>

=head2 Roles

    use CatalystX::Declare;

    controller_role MyApp::Web::ControllerRole::Bar {

        use MyApp::Types qw( Username );


        around _build_welcome_message { $self->$orig . '!' }

        after welcome (Object $ctx) {

            $ctx->response->body(join "\n",
                $ctx->response->body,
                time(),
            );
        }


        final action special_welcome (Username $name) under base {

            $ctx->response->body('Hugs to ' . $name);
        }
    }

See also: 
L<CatalystX::Declare::Keyword::Role>, 
L<CatalystX::Declare::Keyword::Action>, 
L<MooseX::Declare/class>

=head2 Views

    use CatalystX::Declare;

    view MyApp::Web::View::TT
        extends Catalyst::View::TT {

        $CLASS->config(
            TEMPLATE_EXTENSION => '.html',
        );
    }

See also: 
L<CatalystX::Declare::Keyword::View>, 
L<CatalystX::Declare::Keyword::Component>, 
L<MooseX::Declare/class>

=head2 Models

    use CatalystX::Declare;

    model MyApp::Web::Model::DBIC::Schema
        extends Catalyst::Model::DBIC::Schema {

        $CLASS->config(
            schema_class => 'MyApp::Schema',
        );
    }

See also: 
L<CatalystX::Declare::Keyword::Model>, 
L<CatalystX::Declare::Keyword::Component>, 
L<MooseX::Declare/class>

=head1 DESCRIPTION

B<This module is EXPERIMENTAL>

This module provides a declarative syntax for L<Catalyst|Catalyst::Runtime> 
applications. Its main focus is currently on common and repetitious parts of
the application, such as the application class itself, controllers, and
controller roles.

=head2 Not a Source Filter

The used syntax elements are not parsed via source filter mechanism, but 
through L<Devel::Declare>, which is a much less fragile deal to handle and
allows extensions to mix without problems. For example, all keywords added
by this module are separete handlers.

=head2 Syntax Documentation

The documentation about syntax is in the respective parts of the distribution
below the C<CatalystX::Declare::Keyword::> namespace. Here are the manual
pages you will be interested in to familiarize yourself with this module's
syntax extensions:

=over

=item L<CatalystX::Declare::Keyword::Application>

=item L<CatalystX::Declare::Keyword::Action>

=item L<CatalystX::Declare::Keyword::Controller>

=item L<CatalystX::Declare::Keyword::Role>

=item L<CatalystX::Declare::Keyword::View>

=item L<CatalystX::Declare::Keyword::Model>

=back

Things like models, views, roles for request or response objects, can be built
declaratively with L<MooseX::Declare>, which is used to additionally provide
keywords for C<class>, C<role>, C<method> and the available method modifier
declarations. This allows for constructs such as:

    use CatalystX::Declare;

    class Foo {

        method bar { 23 }
    }

    controller MyApp::Web::Controller::Baz {

        final action qux under '/' { 
            $ctx->response->body(Foo->new->bar) 
        }
    }

=head1 SEE ALSO

=head2 For Usage Information

These links are intended for the common user of this module.

=over

=item L<Catalyst::Runtime>

=item L<Catalyst::Devel>

=item L<Catalyst::Manual>

Although you probably already know Catalyst, since you otherwise probably
wouldn't be here, I include these links for completeness sake.

=item L<Moose>

The powerful modern Perl object orientation implementation that is used
as basis for Catalyst. L<MooseX::Declare>, on which L<CatalystX::Declare>
is based, provides a declarative syntax for L<Moose>.

=item L<MooseX::Declare>

We inherit almost all functionality from L<MooseX::Declare> to allow the
declaration of traditional classes, roles, methods, modifiers, etc. Refer
to this documentation first for syntax elements that aren't part of
L<CatalystX::Declare>.

=item L<MooseX::Method::Signatures>

This isn't directly used, but L<MooseX::Declare> utilises this to provide
us with method and modifier declarations. For extended information on the
usage of methods, especially signatures, refer to this module after 
looking for an answer in the L<MooseX::Declare> documentation.

=back

=head2 For Developer Information

This section contains links relevant to the implementation of this module.

=over

=item L<Devel::Declare>

You could call this is the basic machine room that runs the interaction with 
perl. It provides a way to hook into perl's source code parsing and change 
small parts on a per-statement basis.

=item L<MooseX::MethodAttributes>

We use this module to easily communicate the action attributes to 
L<Catalyst|Catalyst::Runtime>. Currently, this is the easiest solution for
now but may be subject to change in the future.

=back


=head1 AUTHOR

=over

=item Robert 'phaylon' Sedlacek, L<E<lt>rs@474.atE<gt>>

=back

With contributions from, and many thanks to:

=over

=item Florian Ragwitz

=item John Napiorkowski

=back


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under 
the same terms as perl itself.

=cut
