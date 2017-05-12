use Test::More;
use CGI;
use lib 't/lib';
use MyBase::MyApp;
use strict;

plan(tests => 23);

$ENV{'CGI_APP_RETURN_ONLY'} = 1;

# 1..4
# view_code
{
    my $cgi = CGI->new({
        rm => 'view_code',
    });
    my $app = MyBase::MyApp->new( QUERY => $cgi );
    my $output = $app->run();
    unlike($output, qr/String \{ color:#000000/);
    like($output, qr/<span class="String">/);
    like($output, qr/<span class="LineNumber"><a name="1">1/);
    like($output, qr/<span class="Comment_POD">/);
}

# 5..8
# view_code highlight=0
{
    my $cgi = CGI->new({
        rm          => 'view_code',
        highlight   => 0,
    }); 
    my $app = MyBase::MyApp->new( QUERY => $cgi );
    my $output = $app->run();
    like($output, qr/String \{ color:#000000/);
    like($output, qr/<span class="String">/);
    like($output, qr/<span class="LineNumber"><a name="1">1/);
    like($output, qr/<span class="Comment_POD">/);
}

# 9..12
# view_code hightlight=0, line_no=0
{
    my $cgi = CGI->new({
        rm          => 'view_code',
        highlight   => 0,
        line_no     => 0,
    }); 
    my $app = MyBase::MyApp->new( QUERY => $cgi );
    my $output = $app->run();
    like($output, qr/String \{ color:#000000/);
    like($output, qr/<span class="String">/);
    unlike($output, qr/<span class="LineNumber"><a name="1">1/);
    like($output, qr/<span class="Comment_POD">/);
}

# 13..16
# view_code hightlight=0, line_no=0, pod=0
{
    my $cgi = CGI->new({
        rm          => 'view_code',
        highlight   => 0,
        line_no     => 0,
        pod         => 0,
    });
    my $app = MyBase::MyApp->new( QUERY => $cgi );
    my $output = $app->run();
    like($output, qr/String \{ color:#000000/);
    like($output, qr/<span class="String">/);
    unlike($output, qr/<span class="LineNumber"><a name="1">1/);
    unlike($output, qr/<span class="Comment_POD">/);
}

# 17..23
# module and package links
{
    # using '::'
    my $cgi = CGI->new({
        rm      => 'view_code',
        module  => 'MyBase::MyApp',
    }); 
    my $app = MyBase::MyApp->new( QUERY => $cgi );
    my $output = $app->run();
    like($output, qr/<span class="Keyword">package<.+><a class="Package" href="[^"]+">MyBase::MyApp</);

    # using '-'
    $cgi = CGI->new({
        rm      => 'view_code',
        module  => 'MyBase-MyApp',
    }); 
    $app = MyBase::MyApp->new( QUERY => $cgi );
    $output = $app->run();
    like($output, qr/<span class="String">/);
    like($output, qr/<span class="Keyword">package<.+><a class="Package" href="[^"]+">MyBase::MyApp</);

    # following links
    my ($link) = $output =~ /<a href="\?([^"]+)>MyBase</;
    $cgi = CGI->new($link);
    $output = $app->run(QUERY => $cgi);
    like($output, qr/<span class="Keyword">package<.+><a class="Package" href="[^"]+">MyBase::MyApp</);


    # follow links with a different mode_param()
    $cgi = CGI->new({
        mode    => 'view_code',
        module  => 'MyBase-MyApp',
    });
    $app = MyBase::MyApp->new( QUERY => $cgi );
    $app->mode_param('mode');
    $output = $app->run();
    like($output, qr/<span class="String">/);
    like($output, qr/<span class="Keyword">package<.+><a class="Package" href="[^"]+">MyBase::MyApp</);

    # following links
    ($link) = $output =~ /<a href="\?([^"]+)>MyBase</;
    $cgi = CGI->new($link);
    $output = $app->run(QUERY => $cgi);
    like($output, qr/<span class="Keyword">package<.+><a class="Package" href="[^"]+">MyBase::MyApp</);
}




