package App::TemplateServer::Page::Index;
use Moose;
use Method::Signatures;

with 'App::TemplateServer::Page';

has '+match_regex' => (
    default => qr{^/(?:index(?:html?)?)?$},
);

method render($ctx) {
    my $base = $ctx->server->url;
    $base =~ s{/$}{};
    
    my $head = <<'END';
<html><head><title>Welcome</title></head>
<h1>Welcome</h1>
<p>Here are the templates that are available:</p>
<ul>
END
    my $content = '';
    foreach my $template ($self->provider->list_templates) {
        $content .= <<"END";
<li>
<a href="$base/$template">$template</a>
</li>
END
    }
    my $foot = <<'END';
</ul></body></html>
END
    
    return "$head$content$foot\n";
};

1;
