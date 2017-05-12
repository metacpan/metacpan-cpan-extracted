package App::TemplateServer::Provider;
use Moose::Role;

has 'docroot' => (
    is         => 'ro',
    isa        => 'ArrayRef[Defined]',
    required   => 1,
    auto_deref => 1,
);

requires 'render_template';
requires 'list_templates';

1;

__END__

=head1 NAME

App::TemplateServer::Provider - role that a Provider should consume

=head1 DESCRIPTION

Template systems are interfaced with App::TemplateServer with this
role.  The template server will call the methods required by this role
to provider its functionality.

=head1 REQUIRED METHODS

You need to implement these:

=head2 list_templates

Returns a list of strings representing template names.

=head2 render_template($template, $context)

Return the rendered text of the template named by C<$template>.  If
C<$template> can't be rendered, throw an exception.  C<$context> is
the L<App::TemplateServer::Context|App::TemplateServer::Context>
object for the request.

=head1 SEE ALSO

L<App::TemplateServer::Provider::Filesystem> - a role that provides some useful defaults for fs-based templating systems like TT or Mason.

L<App::TemplateServer::Provider::TT> - a TT provider

L<App::TemplateServer::Provider::Null> - a boring example provider

L<App::TemplateServer|App::TemplateServer>
