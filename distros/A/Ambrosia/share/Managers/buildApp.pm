package Managers::buildApp;
use strict;
use warnings;

use File::Path;
use File::Copy;

use XML::LibXSLT ();
use XML::LibXML ();
use XML::LibXML::XPathContext ();

use Ambrosia::Config;
use Ambrosia::Context;

use Ambrosia::Meta;

class sealed {
    private => [qw/parser source xslt application/],
    extends => [qw/Ambrosia::BaseManager/]
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    $self->parser = XML::LibXML->new();
    $self->xslt = XML::LibXSLT->new();

    my $source = $self->source = $self->parser->parse_file(Context->param('data'));

    $self->application = ($source->getElementsByTagName('Application'))[0]->cloneNode(0);

    $self->application->addChild(($source->getElementsByTagName('Config'))[0]->cloneNode(1));
    $self->application->addChild(($source->getElementsByTagName('DataSource'))[0]->cloneNode(1));
    $self->application->addChild(($source->getElementsByTagName('Relations'))[0]->cloneNode(1));
    $self->application->addChild(($source->getElementsByTagName('MenuGroups'))[0]->cloneNode(1));
}

our $encoding;

sub prepare
{
    my $self = shift;

    return unless $self->validateDocument();

    Context->repository->set(quiet => 1);
    my $appName = config->ID;

    my %hDir = $self->makeDirectorys($appName);

    $encoding = config->Charset || 'utf-8';
    ############################################################################

    my $tmplPath = (config->TemplatePath || '.');
    $self->makeEntityCode($hDir{dirEntity},     $tmplPath . '/Templates/Common/Entity.xsl',      '.pm');
    $self->makeEntityCode($hDir{dirValidators}, $tmplPath . '/Templates/Common/Validator.xsl',   'Validator.pm');

    $self->makeManagerCode($hDir{dirManagers},   $tmplPath . '/Templates/Common/SaveManager.xsl', 'SaveManager.pm', 0, '@Type!="BIND" and @Type!="VIEW"');
    $self->makeManagerCode($hDir{dirManagers},   $tmplPath . '/Templates/Common/EditManager.xsl', 'EditManager.pm', 0, '@Type!="BIND" and @Type!="VIEW"');
    $self->makeManagerCode($hDir{dirManagers},   $tmplPath . '/Templates/Common/GetTreeManager.xsl', 'EditManager.pm', 1, '@Type!="BIND"');

    $self->makeManagerCode($hDir{dirManagers},   $tmplPath . '/Templates/Common/ListManager.xsl', 'ListManager.pm', 0, '@Type!="BIND"');
    $self->makeManagerCode($hDir{dirManagers},   $tmplPath . '/Templates/Common/TreeManager.xsl', 'TreeManager.pm', 1, '@Type!="BIND"');

    my $tpl_path = '';
    my $ex = '';
    if ( config->TemplateStyle->{htmltemplate} eq 'xslt' )
    {
        $tpl_path = 'XSLT';
        $ex = '.xsl';
    }
    elsif( config->TemplateStyle->{htmltemplate} eq 'tt' )
    {
        $tpl_path = 'TOOLKIT';
        $ex = '.ttkt.html';
    }
    if (  config->TemplateStyle->{jsframework} eq 'dojo' )
    {
        $tpl_path .= '+DOJO';
    }
    $self->makeEntityCode($hDir{dirTemplates}, $tmplPath . '/Templates/Templates/' . $tpl_path . '/edit_json.xsl', '_edit_json' . $ex, 1, '@Type!="BIND" and @Type!="VIEW"');
    copy($tmplPath . '/Templates/Templates/' . $tpl_path . '/message.xsl',
         $hDir{dirTemplates} . '/_message.xsl') or die "Copy failed: $! ['${tmplPath}/Templates/Templates/${tpl_path}/message.xsl']";

    copy($tmplPath . '/Templates/incUtils.xsl',
         $hDir{dirTemplates} . '/_inc_utils.xsl') or die "Copy failed: $! ['${tmplPath}/Templates/incUtils.xsl']";

    {#make main.xsl
        my $style_doc = $self->parser->parse_file($tmplPath . '/Templates/Templates/' . $tpl_path . '/main.xsl');
        ($style_doc->getElementsByLocalName('output'))[0]->setAttribute( encoding => $encoding );
        my $stylesheet = $self->xslt->parse_stylesheet($style_doc);
        my $results = $stylesheet->transform($self->source);
        my $fn = $hDir{dirTemplates} . '/main.xsl';
        if ( -e $fn )
        {
            rename $fn, $fn . '.bak';
        }
        #if ( open my $fh, ">:encoding($encoding)", $fn)
        if ( open my $fh, ">", $fn)
        {
            my $txt = $stylesheet->output_string($results);
            print $fh $txt;
            close $fh;
        }
    }
    {#make list.xsl
        my $style_doc = $self->parser->parse_file($tmplPath . '/Templates/Templates/' . $tpl_path . '/list_json.xsl');
        ($style_doc->getElementsByLocalName('output'))[0]->setAttribute( encoding => $encoding );
        my $stylesheet = $self->xslt->parse_stylesheet($style_doc);
        my $results = $stylesheet->transform($self->source);
        my $fn = $hDir{dirTemplates} . '/list_json.xsl';
        if ( -e $fn )
        {
            rename $fn, $fn . '.bak';
        }
        #if ( open my $fh, ">:encoding($encoding)", $fn)
        if ( open my $fh, ">", $fn)
        {
            my $txt = $stylesheet->output_string($results);
            print $fh $txt;
            close $fh;
        }
    }

    {
        if ( $self->application->getAttribute('Authorization') ne 'NO' )
        {#make authorize.xsl
            my $style_doc = $self->parser->parse_file($tmplPath . '/Templates/Templates/' . $tpl_path . '/authorize.xsl');
            ($style_doc->getElementsByLocalName('output'))[0]->setAttribute( encoding => $encoding );
            my $stylesheet = $self->xslt->parse_stylesheet($style_doc);
            my $results = $stylesheet->transform($self->source);
            my $fn = $hDir{dirTemplates} . '/authorize.xsl';
            if ( -e $fn )
            {
                rename $fn, $fn . '.bak';
            }
            #if ( open my $fh, ">:encoding($encoding)", $fn)
            if ( open my $fh, ">", $fn)
            {
                my $txt = $stylesheet->output_string($results);
                print $fh $txt;
                close $fh;
            }

            $self->singleGeneration($hDir{dirEntity} . '/' . $appName . 'SysUser.pm', $tmplPath . '/Templates/Common/SysUser.xsl');

            $self->singleGeneration($hDir{dirMain} . '/Accessor.pm', $tmplPath . '/Templates/Common/Accessor.xsl');
            $self->singleGeneration($hDir{dirMain} . '/Authorize.pm', $tmplPath . '/Templates/Common/Authorize.xsl');
            $self->singleGeneration($hDir{dirManagers} . '/AuthorizeManager.pm', $tmplPath . '/Templates/Common/AuthorizeManager.xsl');
            $self->singleGeneration($hDir{dirManagers} . '/ExitManager.pm', $tmplPath . '/Templates/Common/ExitManager.xsl');
        }
    }

    {
        my $xc = XML::LibXML::XPathContext->new($self->source);
        my @v = $xc->findnodes(q~//Entitys/Entity[@Type='TREE']~);
        if ( scalar @v )
        {#make tree.xsl
            my $style_doc = $self->parser->parse_file($tmplPath . '/Templates/Templates/' . $tpl_path . '/tree_json.xsl');
            ($style_doc->getElementsByLocalName('output'))[0]->setAttribute( encoding => $encoding );
            my $stylesheet = $self->xslt->parse_stylesheet($style_doc);
            my $results = $stylesheet->transform($self->source);
            my $fn = $hDir{dirTemplates} . '/tree_json.xsl';
            if ( -e $fn )
            {
                rename $fn, $fn . '.bak';
            }
            #if ( open my $fh, ">:encoding($encoding)", $fn)
            if ( open my $fh, ">", $fn)
            {
                my $txt = $stylesheet->output_string($results);
                print $fh $txt;
                close $fh;
            }
        }
    }

    my $name = $self->application->getAttribute('Name');
    $self->singleGeneration($hDir{dirConfig} . '/' . $name . '.conf', $tmplPath . '/Templates/Common/Config.xsl');
    $self->singleGeneration($hDir{dirMain} . '/' . $name . '.pm', $tmplPath . '/Templates/Common/HandlerModule.xsl');
    $self->singleGeneration($hDir{dirMain} . '/' . $name . 'ServiceHandler.pm', $tmplPath . '/Templates/Common/ServiceHandlerModule.xsl');

#    $self->singleGeneration($hDir{dirCgi} . '/' . $name . '.cgi', $tmplPath . '/Templates/Common/Cgi.xsl');

    $self->singleGeneration($hDir{dirManagers} . '/MainManager.pm', $tmplPath . '/Templates/Common/MainManager.xsl');
    $self->singleGeneration($hDir{dirManagers} . '/ListManager.pm', $tmplPath . '/Templates/Common/MListManager.xsl');
    $self->singleGeneration($hDir{dirManagers} . '/BaseManager.pm', $tmplPath . '/Templates/Common/BaseManager.xsl');

    {#write Apache config
        my $style_doc = $self->parser->parse_file($tmplPath . '/Templates/Common/ApacheInclude.xsl');
        ($style_doc->getElementsByLocalName('output'))[0]->setAttribute( encoding => $encoding );

        my $stylesheet = $self->xslt->parse_stylesheet($style_doc);
        my $document = XML::LibXML->createDocument( '1.0', $encoding );
        $document->setDocumentElement($self->application);
        my @apacheIncludeNames = ();
        foreach my $c ( $self->source->getElementsByTagNameNS($self->application->namespaceURI(),'Config') )
        {
            foreach my $h ( $c->getElementsByTagName('Host') )
            {
                my $name = $h->getAttribute('Name');
                my $projectPath = $h->getAttribute('ProjectPath');
                $self->application->addChild($h);

                my $results = $stylesheet->transform($document);
                push @apacheIncludeNames, $projectPath . '/' . config->ID . '/Apache/' . $name . '.conf';
                if ( open my $fh, ">", $hDir{dirApache} . '/' . $name . '.conf')
                {
                    print $fh $stylesheet->output_as_bytes($results);
                    close $fh;
                }
                $self->application->removeChild($h);
            }
        }
        if ( open(my $fh, '>', $hDir{dirApache} . '/readmy') )
        {
            print $fh "insert into apache http.conf one of:\n";
            #print $fh "Include $hDir{dirApache}/${name}.deploy.conf\n";
            print $fh "Include $_\n" foreach @apacheIncludeNames;
            close $fh;
        }
    };

    my $projectName = config->ID;
    my $ServerName = config()->ServerName;
    my $ServerPort = config()->ServerPort;
    $ServerPort = ':' . $ServerPort if $ServerPort && $ServerPort != 80;
    my $message = <<MESSAGE;

#######################################################################
#
#   Application "${projectName}" has been built successfully.
#
#   Now see the file "readmy" in directory ${projectName}/Apache then
#   type 'http://${ServerName}${ServerPort}/${projectName}/' in your browser.
#
#######################################################################

MESSAGE
    Context->repository->set( Message => $message );

}

sub validateDocument
{
    my $self = shift;
    my $xmlschema = XML::LibXML::Schema->new( location => (config->TemplatePath || '.') . '/XSD/AmbrosiaDL.xsd' );
    if ( eval { $xmlschema->validate( $self->source ); 1; } )
    {
        return 1;
    }
    print STDERR "ERROR: wrong in ADL file\n$@\n";
    return 0;
}

sub makeDirectorys
{
    my $self = shift;
    my $appName = shift;
    #make root directory

    my $dirMain = (config->ProjectPath || ('./' . $appName));
    mkpath($dirMain, 0, oct(777)) unless -d $dirMain;

    #make cgi-bin etc.
    my $dirCgi = (config->ProjectPath || ('./' . $appName)) . '/cgi-bin';
    mkpath($dirCgi, 0, oct(777)) unless -d $dirCgi;

    my $dirHtdocs = (config->ProjectPath || ('./' . $appName)) . '/htdocs';
    mkpath($dirHtdocs, 0, oct(777)) unless -d $dirHtdocs;

    my $dirLogs = (config->ProjectPath || ('./' . $appName)) . '/apache_logs';
    mkpath($dirLogs, 0, oct(777)) unless -d $dirLogs;

    my $dirApache = (config->ProjectPath || ('./' . $appName)) . '/Apache';
    mkpath($dirApache, 0, oct(777)) unless -d $dirApache;

    my $dirEntity = (config->ProjectPath || ('./' . $appName)) . '/Entity';
    mkpath($dirEntity, 0, oct(777)) unless -d $dirEntity;

    my $dirResources = (config->ProjectPath || ('./' . $appName)) . '/Resources';
    mkpath($dirResources, 0, oct(777)) unless -d $dirResources;

    my $dirManagers = (config->ProjectPath || ('./' . $appName)) . '/Managers';
    mkpath($dirManagers, 0, oct(777)) unless -d $dirManagers;

    my $dirTemplates = (config->ProjectPath || ('./' . $appName)) . '/Templates';
    mkpath($dirTemplates, 0, oct(777)) unless -d $dirTemplates;
    if ( config->TemplateStyle->{jsframework} eq 'dojo' )
    {
        my $ajaxDir = $dirHtdocs . '/ajax/libs/dojo';
        mkpath($ajaxDir, 0, oct(777)) unless -d $ajaxDir;
        eval { symlink(config->DojoToolkitPath, $ajaxDir . '/1.7.2'); 1 };
    }

    my $dirConfig = (config->ProjectPath || ('./' . $appName)) . '/Config';
    mkpath($dirConfig, 0, oct(777)) unless -d $dirConfig;

    my $dirValidators = (config->ProjectPath || ('./' . $appName)) . '/Validators';
    mkpath($dirValidators, 0, oct(777)) unless -d $dirValidators;


    return dirMain => $dirMain, dirCgi => $dirCgi, dirHtdocs => $dirHtdocs,
           dirApache => $dirApache, dirEntity => $dirEntity, dirResources => $dirResources,
           dirManagers => $dirManagers, dirTemplates => $dirTemplates,
           dirConfig => $dirConfig, dirValidators => $dirValidators;
}

sub makeEntityCode
{
    my $self = shift;
    my $dirOut = shift;
    my $xslTemplate = shift;
    my $fileSuffix = shift;
    my $lc = shift;
    my $filter = shift;

    my $style_doc = $self->parser->parse_file($xslTemplate);
    ($style_doc->getElementsByLocalName('output'))[0]->setAttribute( encoding => $encoding );

    my $stylesheet = $self->xslt->parse_stylesheet($style_doc);

    my $document = XML::LibXML->createDocument( '1.0', $encoding );
    $document->setDocumentElement($self->application);

    foreach my $e ( $self->source->getElementsByTagName('Entity') )
    {
        if ( $filter )
        {
            my $xc = XML::LibXML::XPathContext->new($e);
            $xc->registerNs('atns', $self->application->namespaceURI());
            next unless $xc->find($filter);
        }
        my $name = $e->getAttribute('Name');
        my $eId = $e->getAttribute('Id');
        my $extends = $e->getAttribute('Extends');

        next unless defined $extends;

        #my $entitys = $document->createElementNS($self->application->namespaceURI(), 'Entitys');
        #$entitys->addChild($e->cloneNode(1));
        #$self->application->addChild($entitys);

        my $entity = $e->cloneNode(1);
        $self->application->addChild($entity);

        my $entitysRef = $document->createElementNS($self->application->namespaceURI(), 'EntitysRef');

        my $xc = XML::LibXML::XPathContext->new($self->source);
        $xc->registerNs('atns', $self->application->namespaceURI());
        my @v = $xc->findnodes(qq~//atns:Entitys/atns:Entity[\@Id!="$eId"]~);
        $entitysRef->addChild($_->cloneNode(1)) foreach @v;

        ##direct reference
        #my @v = $xc->findnodes(qq~//atns:Entitys/atns:Entity[\@Id=//atns:Relations/atns:Relation[\@RefId="$eId"]/atns:EntityRef/\@RefId]~);
        #$entitysRef->addChild($_->cloneNode(1)) foreach @v;
        #
        ##for feedback
        #@v = $xc->findnodes(qq~//atns:Entitys/atns:Entity[\@Id=//atns:Relations/atns:Relation/atns:EntityRef[\@RefId="$eId" and \@Feedback='YES']/../\@RefId]~);
        #$entitysRef->addChild($_->cloneNode(1)) foreach @v;

        @v = $xc->findnodes(qq~//atns:Entitys/atns:Entity[\@Name="$extends"]~);
        $entitysRef->addChild($_->cloneNode(1)) foreach @v;
        $self->application->addChild($entitysRef);

#print STDERR $document->toString(2);

        my $results = $stylesheet->transform($document);
        my $fn = $dirOut . '/' . ($lc ? lc($name) : $name) . $fileSuffix;
        if ( -e $fn )
        {
            rename $fn, $fn . '.bak';
        }
        if ( open my $fh, ">", $fn)
        {
            print $fh $stylesheet->output_as_bytes($results);
            close $fh;
        }
        $self->application->removeChild($entity);
        $self->application->removeChild($entitysRef);
    }
}

sub makeManagerCode
{
    my $self = shift;
    my $dirOut = shift;
    my $xslTemplate = shift;
    my $fileSuffix = shift;
    my $tree = shift;
    my $filter = shift;

    my $style_doc = $self->parser->parse_file($xslTemplate);
    ($style_doc->getElementsByLocalName('output'))[0]->setAttribute( encoding => $encoding );

    my $stylesheet = $self->xslt->parse_stylesheet($style_doc);

    my $document = XML::LibXML->createDocument( '1.0', $encoding );
    $document->setDocumentElement($self->application);

    foreach my $e ( $self->source->getElementsByTagName('Entity') )
    {
        if ( $filter )
        {
            my $xc = XML::LibXML::XPathContext->new($e);
            $xc->registerNs('atns', $self->application->namespaceURI());
            next unless $xc->find($filter);
        }
        my $name = $e->getAttribute('Name');
        next if $tree && $e->getAttribute('Type') ne 'TREE'
                or !$tree && $e->getAttribute('Type') eq 'TREE';

        my $entity = $e->cloneNode(1);
        $self->application->addChild($entity);

#########
        my $eId = $e->getAttribute('Id');
        my $entitysRef = $document->createElementNS($self->application->namespaceURI(), 'EntitysRef');

        my $xc = XML::LibXML::XPathContext->new($self->source);
        $xc->registerNs('atns', $self->application->namespaceURI());

        my @v = $xc->findnodes(qq~//atns:Entitys/atns:Entity[\@Id!="$eId"]~);
        $entitysRef->addChild($_->cloneNode(1)) foreach @v;

        ##direct reference
        #my @v = $xc->findnodes(qq~//atns:Entitys/atns:Entity[\@Id=//atns:Relations/atns:Relation[\@RefId="$eId"]/atns:EntityRef/\@RefId]~);
        #$entitysRef->addChild($_->cloneNode(1)) foreach @v;
        $self->application->addChild($entitysRef);
#########

        my $results = $stylesheet->transform($document);
        my $fn = $dirOut . '/' . $name . $fileSuffix;
        if ( -e $fn )
        {
            rename $fn, $fn . '.bak';
        }
        #if ( open my $fh, ">:encoding($encoding)", $fn)
        if ( open my $fh, ">", $fn)
        {
            print $fh $stylesheet->output_as_bytes($results);
            close $fh;
        }
        $self->application->removeChild($entity);
        $self->application->removeChild($entitysRef);
    }
}

sub singleGeneration
{
    my $self = shift;
    my $dirOut = shift;
    my $template = shift;

    my $style_doc = $self->parser->parse_file($template);
    ($style_doc->getElementsByLocalName('output'))[0]->setAttribute( encoding => $encoding );
    my $stylesheet = $self->xslt->parse_stylesheet($style_doc);
    my $results = $stylesheet->transform($self->source);

    if ( -e $dirOut )
    {
        rename $dirOut, $dirOut . '.bak';
    }
    #if ( open my $fh, ">:encoding($encoding)", $dirOut)
    if ( open my $fh, ">", $dirOut )
    {
        print $fh $stylesheet->output_string($results);
        close $fh;
    }
}

1;
