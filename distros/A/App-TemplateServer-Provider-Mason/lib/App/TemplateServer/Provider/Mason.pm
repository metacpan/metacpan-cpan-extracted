package App::TemplateServer::Provider::Mason;
use Moose;
use Method::Signatures;
use File::Find;
use HTML::Mason::Interp;
use Path::Class qw(file);
use feature ':5.10';

our $VERSION = '0.01';

with 'App::TemplateServer::Provider::Filesystem';

method render_template($template, $context){
    my $outbuf;
    
    my %data = %{$context->data||{}};
    my @globals = map { "\$$_" } keys %data;
    
    my $interp = HTML::Mason::Interp->new(
        comp_root     => [map {state $a = 1; [$a++ => "$_"]} $self->docroot],
        out_method    => \$outbuf,
        allow_globals => \@globals,
    );
    
    # set globals
    for my $var (keys %data){
        my $val  = $data{$var};
        $interp->set_global($var, $val);
    }
    
    $interp->exec("/$template");
    return $outbuf;
};

1;

__END__

=head1 NAME

App::TemplateServer::Provider::Mason - serve Mason templates with App::TemplateServer

=head1 SYNOPSIS

Use Mason templates with L<App::TemplateServer|App::TemplateServer>.

   template-server --provider Mason --docroot /mason/templates

See L<template-server> and <App::TemplateServer> for details.

=head1 AUTHOR AND COPYRIGHT

Jonathan Rockway C<< <jrockway@cpan.org> >>

This module is Free software, you may redistribute it under the same
terms as Perl itself.

