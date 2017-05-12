<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xsl:output method="text" indent="yes"  />

<xsl:include href="../incName.xsl" />

<xsl:template match="/">
{
    package <xsl:value-of select="$RealAppName" />::<xsl:value-of select="$RealAppName" />ServiceHandler;
    use strict;
    use warnings;

    use Ambrosia::Logger assign => '<xsl:value-of select="$RealAppName" />';
    our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);


    #use SOAP::Lite +trace => 'all';
    use SOAP::Transport::HTTP;
    $SOAP::Constants::DO_NOT_USE_XML_PARSER = 1;

    sub handler
    {
        my $r = shift;

        my $server = SOAP::Transport::HTTP::Apache
            ->dispatch_with( { $ENV{HTTP_SOAPACTION} => '<xsl:value-of select="$RealAppName" />::<xsl:value-of select="$RealAppName" />Services' } );

        eval
        {
            $server->handler($r);
        };
        if ( $@ )
        {
            logger->error($@);
        }
        1;
    }
}

{
    package <xsl:value-of select="$RealAppName" />::<xsl:value-of select="$RealAppName" />Services;
    use strict;
    use warnings;
    our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

    BEGIN
    {
        use Ambrosia::Config assign => '<xsl:value-of select="$RealAppName" />';
        use Ambrosia::Logger assign => '<xsl:value-of select="$RealAppName" />';
    }

    use Ambrosia::Context;
    use Ambrosia::DataProvider;
    use Ambrosia::Dispatcher;
    use Ambrosia::View::XSLT;
    use Ambrosia::View::JSON;
    use Ambrosia::BaseManager;

    our $dispatcher;
    our $Result;
    our $viewXML;
    our $viewJSON;
    BEGIN
    {
        instance Ambrosia::DataProvider( <xsl:value-of select="$RealAppName" /> => config->data_source);
        instance Ambrosia::Context();

        $viewXML  = new Ambrosia::View::XSLT( charset => config->Charset, rootName => '<xsl:value-of select="$UcAppName" />' );
        $viewJSON = new Ambrosia::View::JSON( charset => config->Charset );

        $dispatcher = Ambrosia::Dispatcher
            ->new()
            ->on_error(sub {
                    logger->error(@_);
                    storage->foreach('cancel_transaction');
                    storage->foreach('close_connection');
                    Context->error(@_);
                    die $@;
                })
            ->on_success(sub {
                    if ( @_ )
                    {
                        if ( Context->param('format') eq 'json' )
                        {
                            $Result = $viewJson->render(undef, Context->data);
                        }
                        else
                        {
                            $Result = $viewXml->as_xml;
                        }
                    }
                    else
                    {
                        error('Action is undefined.');
                    }

                    storage->foreach('save_transaction');
                    storage->foreach('close_connection');
                });
    }

<xsl:for-each select="//atns:Entitys/atns:Entity">
    <xsl:variable name="entityName" select="translate(@Name, $vUppercaseChars_CONST, $vLowercaseChars_CONST)"/>
    <xsl:variable name="typeEntity" select="translate(@Type, $vLowercaseChars_CONST, $vUppercaseChars_CONST)"/>
    <xsl:if test="$typeEntity='TABLE' or $typeEntity='VIEW'">
    sub get<xsl:value-of select="@Name"/>
    {
        my $proto = shift;
        <xsl:for-each select="./atns:Key/atns:FieldRef">my $<xsl:value-of select="@Name"/> = shift;
</xsl:for-each>
        run(
            action => '/get/<xsl:value-of select="$entityName" />',
            <xsl:for-each select="./atns:Key/atns:FieldRef">
            <xsl:value-of select="@Name"/> => $<xsl:value-of select="@Name"/>,</xsl:for-each>
        );
        return $Result;
    }
    </xsl:if>
</xsl:for-each>


    sub run
    {
        my %params = @_;
        eval
        {
            Ambrosia::Config::assign '<xsl:value-of select="$RealAppName" />';
            Ambrosia::Logger::assign '<xsl:value-of select="$RealAppName" />';
            Ambrosia::DataProvider::assign '<xsl:value-of select="$RealAppName" />';
            controller(__managers => config->MANAGERS);
            do
            {
                Context->start_session();
                Context->param($_ => $params{$_}) foreach (keys %params);

                $dispatcher->run(Context->action);
                Context->finish_session;
            } while (!Context->is_complete);
        };

        if ($@)
        {
            error(config->DEBUG ? $@ : "Internal error.\n");
            logger->error($@);
        }
    }

    sub error
    {
        $Result = shift || 'Internal error.';
    }
}

1;

__END__

</xsl:template>

</xsl:stylesheet>