package TestApp;

use strict;
use warnings;

use Catalyst; # qw/-Debug/;
use Path::Class;
use IO::File;

our $VERSION = '0.07';

my $default_message = 'Hi, Catalyst::View::XSLT user';

__PACKAGE__->config(
    name                  => 'TestApp',
    default_message       => $default_message,
);

__PACKAGE__->setup;

sub default : Private {
    my ($self, $c) = @_;

    $c->response->redirect($c->uri_for('testParams'));
}

sub testRegisterFunction : Local {
    my ($self, $c) = @_;

    $c->stash->{additional_register_function} = [
      {
        uri    => 'urn:catalyst',
        name   => 'test',
        subref => sub { return $default_message },
      },
    ];

    $c->stash->{xml} = '<dummy-root/>';
    $c->stash->{template} = $c->request->param('template');
}

sub testParams : Local {
    my ($self, $c) = @_;

    $c->stash->{xml} = '<dummy-root/>';
    $c->stash->{template} = $c->request->param('template');
    my $message = $c->request->param('message') || $c->config->{default_message};
    $c->stash->{message} = $message;
}

sub testIncludePath : Local {
    my ($self, $c) = @_;

    $c->stash->{xml} = '<dummy-root/>';
    $c->stash->{template} = $c->request->param('template');
    my $message = $c->request->param('message') || $c->config->{default_message};
    $c->stash->{message} = $message;

    if ( $c->request->param('additionalpath') ){
        my $additionalpath = Path::Class::dir($c->config->{root}, $c->request->param('additionalpath'));
        $c->stash->{additional_template_paths} = ["$additionalpath"];
    }
}

sub testNoXSLT : Local {
    my ($self, $c) = @_;

    $c->stash->{xml} = '<dummy-root/>';
    my $message = $c->request->param('message') || $c->config->{default_message};
    $c->stash->{message} = $message;
}

sub testRender : Local {
    my ($self, $c) = @_;

    my $message = $c->request->param('message') || $c->config->{default_message};

    my $out = $c->view('XSLT::XML::LibXSLT')->render($c, $c->req->param('template'), {xml => "<dummy-root>$message</dummy-root>"});

    $c->stash->{xml} = "<dummy-root>$out</dummy-root>";
}

sub test_template_string : Local {
    my ($self, $c) = @_;

    my $message = $c->request->param('message') || $c->config->{default_message};
    my $template = $c->request->param('template') || 'testRender.xsl';

    $c->stash->{xml} = "<dummy-root>$message</dummy-root>";

    open(my $fh, '<', $c->config->{root} . '/' . $template) or $c->error("$!: $template");
    {
        local($/) = undef;

        $c->stash->{template} = <$fh>;
    }
    close($fh);
}

sub test_template_fh : Local {
    my ($self, $c) = @_;

    my $message = $c->request->param('message') || $c->config->{default_message};
    my $template = $c->request->param('template') || 'testRender.xsl';

    $c->stash->{xml} = "<dummy-root>$message</dummy-root>";

    open(my $fh, '<', $c->config->{root} . '/' . $template) or $c->error("$!: $template");
    $c->stash->{template} = $fh;
}

sub test_xml_fh : Local {
    my ($self, $c) = @_;

    my $message = $c->request->param('message') || $c->config->{default_message};
    my $template = $c->request->param('template') || 'testRender.xsl';
    my $xmlfile = 'test.xml';
    my $fh;

    my $xml = "<dummy-root>$message</dummy-root>";

    open($fh, '+>', $c->config->{root} . '/' . $xmlfile) or $c->error("$!: $xmlfile");
    print $fh $xml;
    seek($fh, 0, 0);

    $c->stash->{xml} = $fh;
    $c->stash->{template} = $template;
}

sub test_xml_io_handle : Local {
    my ($self, $c) = @_;

    my $message = $c->request->param('message') || $c->config->{default_message};
    my $template = $c->request->param('template') || 'testRender.xsl';
    my $xmlfile = 'test.xml';

    my $xml = "<dummy-root>$message</dummy-root>";

    my $fh = IO::File->new($c->config->{root}.'/'.$xmlfile, '+>') or $c->error("$!: $xmlfile");
    print $fh $xml;
    seek($fh, 0, 0);

    $c->stash->{xml} = $fh;
    $c->stash->{template} = $template;
}

sub test_xml_libxml_document : Local {
    my ($self, $c) = @_;

    my $message = $c->request->param('message') || $c->config->{default_message};
    my $template = $c->request->param('template') || 'testRender.xsl';

    require XML::LibXML;

    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElement('dummy-root');
    $doc->setDocumentElement($root);
    $root->appendText($message);

    $c->stash->{xml} = $doc;
    $c->stash->{template} = $template;
}

sub test_xml_path_class : Local {
    my ($self, $c) = @_;

    my $message = $c->request->param('message') || $c->config->{default_message};
    my $template = $c->request->param('template') || 'testRender.xsl';
    my $xmlfile = 'test.xml';
    my $fh;

    my $xml = "<dummy-root>$message</dummy-root>";

    open($fh, '>', $c->config->{root} . '/' . $xmlfile) or $c->error("$!: $xmlfile");
    print $fh $xml;
    close($fh);

    $c->stash->{xml} = file($xmlfile);
    $c->stash->{template} = $template;
}

sub test_template_import : Local {
    my ($self, $c) = @_;

    my $message = $c->request->param('message') || $c->config->{default_message};
    my $template = $c->request->param('template') || 'testImport.xsl';

    $c->stash->{xml} = "<dummy-root>$message</dummy-root>";
    $c->stash->{template} = $template;
}

sub test_template_render_filename : Local {
    my ($self, $c) = @_;

    my $message = $c->request->param('message') || $c->config->{default_message};

    my $template = $c->req->param('template');

    my $out = $c->view('XSLT::XML::LibXSLT')->render($c, $template, {xml => "<dummy-root>$message</dummy-root>"});

    $c->stash->{template} = $template;

    $c->stash->{xml} = $out;
}

sub end : Private {
    my ($self, $c) = @_;

    return 1 if $c->response->status =~ /^3\d\d$/;
    return 1 if $c->response->body;

    my $view = 'View::XSLT::' . ($c->request->param('view') || $c->config->{default_view});
    $c->forward($view);
}

1;
