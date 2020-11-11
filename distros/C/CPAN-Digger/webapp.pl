use Mojolicious::Lite -signatures;

use FindBin ();
use DateTime;
use Template;

use lib "$FindBin::Bin/lib";
use CPAN::Digger::DB ();

my $db = CPAN::Digger::DB->new(db => $ENV{CPAN_DIGGER_DB});

get '/' => sub ($c) {
    my $distros = $db->db_get_every_distro();


    my %data = (
        timestamp     => DateTime->now,
        distributions => $distros,
    );

    $c->render(template => 'index',
        distributions => $distros,
    );
};

get '/dist/:dist' => sub ($c) {
    my $distribution = $c->stash('dist');;
    my $distro = $db->db_get_distro($distribution);
    $c->render(template => 'distribution',
        distribution => $distribution,
        dist => $distro,
    );
};

app->start;
