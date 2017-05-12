use Test::More;
use CGI;
use lib 't/lib';
use MyBase::MyApp;
use strict;

#plan(tests => 23);
plan('no_plan');

$ENV{'CGI_APP_RETURN_ONLY'} = 1;

# 1..2
# non existant module
{
    my $module = 'Some::NonExistant::Module';
    my $cgi = CGI->new({
        rm => 'view_code',
        module  => $module,
    });
    my $app = MyBase::MyApp->new( QUERY => $cgi );
    my $output = $app->run();
    like($output, qr/View Source Error/i);
    like($output, qr/Module \Q$module\E does not exist/i);
}

# 3..4
# non existant file
{
    my $module = 'Some::NonExistant::Module';
    my $file = 'Some/NonExistant/Module.pm';
    my $cgi = CGI->new({
        rm => 'view_code',
        module  => $module,
    });
    $INC{$file} = $file;
    my $app = MyBase::MyApp->new( QUERY => $cgi );
    my $output = $app->run();
    like($output, qr/View Source Error/i);
    like($output, qr/File \Q$file\E does not exist/i);
}




