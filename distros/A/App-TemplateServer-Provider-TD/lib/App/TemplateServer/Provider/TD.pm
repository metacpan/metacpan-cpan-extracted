package App::TemplateServer::Provider::TD;
use Moose;
use Method::Signatures;
use Template::Declare;
use Class::MOP;
require Module::Pluggable::Object;

our $VERSION = '0.01';

with 'App::TemplateServer::Provider';

method BUILD {
    my @roots = $self->docroot;
    my @more;
    
    for my $template_root (@roots){
        # first class not always loadable; it depends
        eval { Class::MOP::load_class($template_root) };
        my $mpo = Module::Pluggable::Object->new(
            require     => 0,
            search_path => $template_root,
        );    
        my @extras = $mpo->plugins;
        foreach my $extra (@extras) {
            # load module
            Class::MOP::load_class($extra);
        }
        push @more, @extras;
    }
    Template::Declare->init(roots => [@roots, @more]);
};

method list_templates {
    my @templates;
    my %templates = %{Template::Declare->templates};
    foreach my $package (keys %templates){
        push @templates, @{$templates{$package}||[]};
    }
    return @templates;
};

method render_template($template,$context) {
    
    Template::Declare->new_buffer_frame;
    my $out = Template::Declare->show($template) || "Rendering failed";
    Template::Declare->end_buffer_frame;
    
    $out =~ s/^\n+//g; # kill leading newlines
    return $out;
};

1;
__END__

=head1 NAME

App::TemplateServer::Provider::TD - use Template::Declare templates with App::TemplateServer
