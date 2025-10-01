#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    # <http://perl.apache.org/docs/2.0/user/coding/coding.html#toc_Cleaning_up>
    # <https://perl.apache.org/docs/2.0/user/handlers/server.html#toc_Startup_File>
    # <http://perl.apache.org/docs/2.0/user/handlers/server.html#toc_Startup_Phases_Demonstration_Module>
    use Apache2::ServerUtil ();
    use Apache2::RequestUtil ();
    use Apache2::Log ();
    use APR::Pool ();
    use Apache2::Const -compile => qw( OK :log );
    use APR::Const     -compile => qw( :error SUCCESS );
};

{
    if( exists( $ENV{MOD_PERL} ) && $ENV{MOD_PERL} =~ /^mod_perl\/(\d+\.[\d\.]+)/ )
    {
        Apache2::ServerUtil::server_shutdown_cleanup_register( \&cleanup );
    }
}

sub cleanup
{
    my $s = Apache2::ServerUtil->server;
    $s->log->info( "startup.pl: cleanup..." );
    # print( STDERR "startup.pl: cleanup Apache2::SSI::Notes...\n" );
}

# Important so Apache/mod_perl2 is happy
1;

__END__

