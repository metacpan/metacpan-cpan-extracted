#!/usr/bin/perl
use Test::More;
eval "require CGI::Application::Plugin::AutoRunmode";
plan skip_all => "CGI::Application::Plugin::AutoRunmode required for this test" if $@;


use lib './t';
use strict;
use warnings;
use CGI ();

{
    package TestAppAutoRunmode;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authentication;
    CGI::Application::Plugin::AutoRunmode->import;
    use Test::More;

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { user1 => '123' } ],
        STORE  => [ 'Store::Dummy' ],
    );

    sub setup {
        my $self = shift;
        $self->authen->protected_runmodes(qw(two));
    }

    eval <<EOM;
        sub one :StartRunmode { return 'test one return value'; }
        sub two :Runmode { return 'test two return value'; }
        sub three :Runmode :RequireAuthentication { return 'test three return value'; }
        sub four :Runmode :Authen { return 'test four return value'; }
EOM

    plan skip_all => "CGI::Application::Plugin::AutoRunmode version does not work with Authentication" if $@;


    package TestAppAutoRunmode::Subclass;

    use base qw(TestAppAutoRunmode);
    use Test::More;

    sub setup {
        my $self = shift;
        $self->authen->protected_runmodes(qw(six));
    }

    eval <<EOM;
        sub five :StartRunmode { return 'test five return value'; }
        sub six :Runmode { return 'test six return value'; }
        sub seven :Runmode :RequireAuthentication { return 'test seven return value'; }
        sub eight :Runmode :Authen { return 'test eight return value'; }
EOM

    plan skip_all => "CGI::Application::Plugin::AutoRunmode version does not work with Authentication" if $@;
}

plan tests => 14;

$ENV{CGI_APP_RETURN_ONLY} = 1;

    my $class = 'TestAppAutoRunmode';

    {
        # Open runmode
        my $query = CGI->new( { rm => 'one' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        like($results, qr/test one return value/, 'runmode one is open');
    }

    {
        # Protected runmode (regular)
        my $query = CGI->new( { rm => 'two' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        unlike($results, qr/test two return value/, 'runmode two is protected');
    }

    {
        # Protected runmode (attribute RequireAuthentication)
        my $query = CGI->new( { rm => 'three' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        unlike($results, qr/test three return value/, 'runmode three is protected');
    }

    {
        # Protected runmode (attribute Authen)
        my $query = CGI->new( { rm => 'four' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        unlike($results, qr/test four return value/, 'runmode four is protected');
    }

    {
        # Successful Login
        my $query = CGI->new( { authen_username => 'user1', authen_password => '123', rm => 'three' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        ok($cgiapp->authen->is_authenticated,'successful login');
        is( $cgiapp->authen->username, 'user1', 'successful login - username set' );
        like($results, qr/test three return value/, 'runmode three is visible after login');
    }



    $class = 'TestAppAutoRunmode::Subclass';

    {
        # Open runmode
        my $query = CGI->new( { rm => 'five' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        like($results, qr/test five return value/, 'runmode five is open');
    }

    {
        # Protected runmode (regular)
        my $query = CGI->new( { rm => 'six' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        unlike($results, qr/test six return value/, 'runmode six is protected');
    }

    {
        # Protected runmode (attribute RequireAuthentication)
        my $query = CGI->new( { rm => 'seven' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        unlike($results, qr/test seven return value/, 'runmode seven is protected');
    }

    {
        # Protected runmode (attribute Authen)
        my $query = CGI->new( { rm => 'eight' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        unlike($results, qr/test eight return value/, 'runmode eight is protected');
    }

    {
        # Successful Login
        my $query = CGI->new( { authen_username => 'user1', authen_password => '123', rm => 'seven' } );
        my $cgiapp = $class->new( QUERY => $query );
        my $results = $cgiapp->run;

        ok($cgiapp->authen->is_authenticated,'successful login');
        is( $cgiapp->authen->username, 'user1', 'successful login - username set' );
        like($results, qr/test seven return value/, 'runmode seven is visible after login');
    }

