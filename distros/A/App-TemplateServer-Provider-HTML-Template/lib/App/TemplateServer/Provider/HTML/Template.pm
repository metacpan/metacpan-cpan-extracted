package App::TemplateServer::Provider::HTML::Template;
use Moose;
use HTML::Template;
use Method::Signatures;

our $VERSION = '0.01';

with 'App::TemplateServer::Provider::Filesystem';

method render_template($template_file, $context){
    my $template = HTML::Template->new(
        path     => scalar $self->docroot,
        filename => $template_file,
    );
    
    my %data = %{$context->data||{}};
    for my $var (keys %data){
        my $value = $data{$var};
        $template->param($var => $value);
    }
    
    return $template->output;
};

1;

__END__

=head1

App::TemplateServer::Provider::HTML::Template - serve HTML::Template templates with App::TemplateServer

=head1 SYNOPSIS

Use HTML::Template templates with L<App::TemplateServer|App::TemplateServer>.

   template-server --provider HTML::Template --docroot /your/templates

See L<template-server> and L<App::TemplateServer> for details.

=head1 AUTHOR AND COPYRIGHT

Jonathan Rockway C<< <jrockway@cpan.org> >>

This module is Free software, you may redistribute it under the same
terms as Perl itself.

