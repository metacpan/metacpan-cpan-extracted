package App::TemplateServer::Provider::Null;
use Moose;
use Method::Signatures;
use YAML::Syck;

with 'App::TemplateServer::Provider';

method list_templates {
    return qw/this is a test/;
};

method render_template($template, $context){
    my $data = Dump({%$context, docroot => [$self->docroot]});
    $data =~ s/&/&amp;/g;
    $data =~ s/</&lt;/g;
    $data =~ s/>/&gt;/g;
    
    my $res = "<p>This is a template called $template</p>";
    $res .= "<p>Here is all the data I know about:<br />";
    $res .= "<blockquote><pre>$data</pre></blockquote></p>";

    return $res;
};

1;
__END__

=head1 NAME

App::TemplateServer::Provider::Null - a test template provider

=head1 SYNOPSIS

This doesn't do anything useful.  It's just example code for you
to poke at.

Try it out like this:

  template-server --provider Null --data /path/to/some/yaml

Then visit C<http://localhost:4000/test> and you can see the YAML.

=head1 METHODS

=head2 list_templates

=head2 render_template

Both implemented as C<App::TemplateServer::Provider> suggests.

=head1 SEE ALSO

L<App::TemplateServer|App::TemplateServer>

L<App::TemplateServer::Provider|App::TemplateServer::Provider>
