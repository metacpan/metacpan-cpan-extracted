<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:atns="app://Ambrosia/EntityDataModel/2011/V1">

<xsl:output method="text" indent="yes"  />

<xsl:include href="../incName.xsl" />

<xsl:template match="/">
package <xsl:value-of select="$RealAppName" />::<xsl:value-of select="$RealAppName" />;
use strict;
use warnings;

our $VERSION = sprintf('0.%03d', q$Revision: 01 $ =~ /(\d+)/o);

our $dispatcher;
BEGIN
{
    use Ambrosia::Config assign => '<xsl:value-of select="$RealAppName" />';
    use Ambrosia::Logger assign => '<xsl:value-of select="$RealAppName" />';
    use Ambrosia::Context;
    use Ambrosia::DataProvider;
    use Ambrosia::Dispatcher;
    use Ambrosia::View::XSLT;
    use Ambrosia::View::JSON;
    use Ambrosia::BaseManager;
<xsl:if test="/atns:Application/@Authorization!='NO'">
    use Ambrosia::Addons::Session;
    use Ambrosia::Addons::Session::Cookie;
    use Ambrosia::Addons::Accessor;
    use <xsl:value-of select="$RealAppName" />::Accessor;
    use <xsl:value-of select="$RealAppName" />::Authorize;

    instance <xsl:value-of select="$RealAppName" />::Accessor( <xsl:value-of select="$RealAppName" /> => authorize => new <xsl:value-of select="$RealAppName" />::Authorize() );
</xsl:if>

    instance Ambrosia::Context(config->CommonGatewayInterface)
        ->on_start( sub {
                instance Ambrosia::Addons::Session(storage => new Ambrosia::Addons::Session::Cookie())
            } )
        ->on_abort( sub {session->destroy} )
        ->on_finish( sub {session->destroy} );

    instance Ambrosia::DataProvider(<xsl:value-of select="$RealAppName" /> => config->data_source);

    my $viewXML  = new Ambrosia::View::XSLT( charset => config->Charset, rootName => '<xsl:value-of select="$UcAppName" />' );
    my $viewJSON = new Ambrosia::View::JSON( charset => config->Charset );

    $dispatcher = Ambrosia::Dispatcher
        ->new()
<xsl:if test="/atns:Application/@Authorization!='NO'">
        ->on_check_access(\&amp;check_access)
</xsl:if>
        ->on_error(sub { error($_[1]) })
        ->on_complete(sub {
                Context->repository->set( __debug => config->DEBUG );
                if ( my $mng = shift )
                {
                    if( Context->response_type eq 'xml' )
                    {
                        Context->print_response_header(
                                -Content_type => 'application/xml',
                                -Charset      => config->Charset,
                                -cookie       => session->getSessionValue,
                            );
                        print scalar $viewXML->as_xml();
                    }
                    elsif( Context->response_type eq 'json' )
                    {
                        Context->print_response_header(
                                -Content_type => 'text/html',
                                -Charset      => config->Charset,
                                -cookie       => session->getSessionValue,
                            );
                        print $viewJSON->render( undef, Context->data );
                    }
                    else
                    {
                        Context->print_response_header(
                                -Content_type => 'text/html',
                                -Charset      => config->Charset,
                                -cookie       => session->getSessionValue,
                            );

                        my $template_path = ($viewXML->can_xml_xsl
                                            ? (config->template_web_path2 || '/Templates_' . config->ID)
                                            : (config->template_path || '.')
                                        ) . '/';
                        print $viewXML->render(
                            $template_path . $mng->{template}, Context->data);
                    }
                }
                else
                {
                    Context->print_response_header(
                            -Content_type => 'text/html',
                            -Charset      => config->Charset,
                            -cookie       => session->getSessionValue,
                        );
                    error(Context->action ? 'Unknown action:' . Context->action : 'Action is undefined.');
                }

                storage->foreach('save_transaction');
                storage->foreach('close_connection');
            });

#uncomment this block if your application use remoute services
=rem
use Ambrosia::RPC;
    instance Ambrosia::RPC(config->service_conf);
=cut

}

sub handler
{
    eval
    {
        Ambrosia::Config::assign '<xsl:value-of select="$RealAppName" />';
        Ambrosia::Logger::assign '<xsl:value-of select="$RealAppName" />';
        Ambrosia::DataProvider::assign '<xsl:value-of select="$RealAppName" />';
<xsl:if test="/atns:Application/@Authorization!='NO'">
        Ambrosia::Addons::Accessor::assign '<xsl:value-of select="$RealAppName" />';
</xsl:if>
#        Ambrosia::RPC::assign '<xsl:value-of select="$RealAppName" />';

        controller( __managers => config->MANAGERS );
        do
        {
            Context->start_session();
            $dispatcher->run(Context->action);
            Context->finish_session;
        } while (!Context->is_complete);
    };

    if ($@)
    {
        error($@);
    }
}

sub error
{
    my $errmsg = shift || 'Internal error.';
    logger->error("$errmsg");
    $errmsg = config->DEBUG ? "$errmsg" : "An error occurred during program execution.\n";

    storage->foreach('cancel_transaction');
    storage->foreach('close_connection');

    Context->print_response_header(
            -Content_type => 'text/html',
            -Charset      => config->Charset,
            -cookie       => session->getSessionValue,
        );

    $errmsg =~ s{\n}{}g;
    my $charset = config->Charset;
    print &lt;&lt;EOB;
<HTML>
<HEAD><TITLE>Error!</TITLE>
<meta http-equiv="Content-Type" content="text/html; charset=$charset" />
</HEAD>
<BODY>
<SPAN style="padding:30px;"><B><FONT color="red" size="+2"><BR/><BR/>$errmsg</FONT></B></SPAN>
</BODY>
</HTML>
EOB

    Context->abort_session();
}

<xsl:if test="/atns:Application/@Authorization!='NO'">
sub check_access
{
    my $mng = shift;
    my $val = session()->getItem(<xsl:value-of select="$RealAppName" />::Accessor::get_access_key_name()) || {};
    my $result = accessor()->authenticate(
            Context->param('login')
                ? (Context->param('login'), Context->param('password'))
                : ($val->{login}, $val->{password}),
            $mng->{access}
        );

    if ( $result->IS_REDIRECT )
    {
        Context->redirect(
                -must_revalidate  => 1,
                -max_age  => 0,
                -no_cache => 1,
                -no_store => 1,
                -charset  => config->Charset,
                -uri      => (Context->proxy || Context->full_script_path) . $ENV{PATH_INFO},
                session->hasSessionData() ? (-cookie   => session->getSessionValue()) : (),
            );
        return 0;
    }

    controller->reset('/authorize') unless $result->IS_PERMIT;

    return 1;
}
</xsl:if>

1;
</xsl:template>

</xsl:stylesheet>