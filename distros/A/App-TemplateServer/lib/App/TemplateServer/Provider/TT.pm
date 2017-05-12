package App::TemplateServer::Provider::TT;
use Moose;
use Template;
use Method::Signatures;

with 'App::TemplateServer::Provider::Filesystem';

has 'engine' => (
    is      => 'ro',
    isa     => 'Template',
    default => sub { Template->new({ INCLUDE_PATH => [shift->docroot] }) },
    lazy    => 1,
);

method render_template($template, $context) {
    my $out;
    $self->engine->process($template, $context->data, \$out)
      or die "Failed to render: ". $self->engine->error;
    return $out;
};

1;

__END__

=head1 NAME

App::TemplateServer::Provider::TT - Template Toolkit template provider for App::TemplateServer

=head1 SYNOPSIS

   my $provider = App::TemplateServer::Provider::TT->new( 
       docroot => ['/path/to/TT/templates']
   );
 
   my @templates = $provider->list_templates;
   my $foo = $provider->render_template('/what/ever/foo.tt');

=head1 METHODS

These methods implement the C<App::TemplateServer::Provider> role.

=head2 list_templates

=head2 render_template



