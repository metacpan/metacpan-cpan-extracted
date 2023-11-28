use Test::More;
use Plack::Test;
use HTTP::Request::Common; # install separately
use File::Basename 'dirname';
use File::Spec;

# Empty app with welcome screen
{
    package EmptyApp;
    use Dancer2;
    set views => File::Spec->catfile( dirname(__FILE__), 'views');
    set appdir => File::Spec->catfile(dirname(__FILE__), 'lib'); # no files will be found here
    set logger => 'Null';
    require 'Dancer2/Plugin/LiteBlog.pm';
    Dancer2::Plugin::LiteBlog->import;
    liteblog_init();
}

my $emptyapp = EmptyApp->to_app;
my $t_empty = Plack::Test->create($emptyapp);

$res = $t_empty->request(GET '/' );
is ($res->code, 200, 'a default totally empty app works');
like($res->content, qr/Now it's time to enable some widgets/, 
    "No widgets found, welcome section displayed"); 

done_testing;
