
use Test::More tests => 247;
BEGIN { use_ok('Config::ApacheFormat'); }

# exhaustive block check for all VirtualHosts
my %blocks = map { $_ => 0 } 
    qw( mvadmin.moveagain.com preview.thepirtgroup.com caladmin.about.com commentadmin.about.com 
        comment.about.com pirtgroup.com admin.flyfishing.about.com prmpix.about.com 
        shuzai.newyorkmetro.thepirtgroup.com shuzai.newyorkmetro.about.com classifieds.about.com preview.gravitygames.com 
        preview.canoekayak.com classifieds.homeandigloo.about.com ca.homeandigloo.about.com classifieds.history.about.com 
        ca.history.about.com ca.sewing.about.com preview.slamonline.com preview.bflex.thepirtgroup.com 
        preview.truckinweb.com preview.automobilemag.com preview.newyorkmetro.com preview.bbric2.thepirtgroup.com 
        preview.caraudiomag.com preview.qabricolage.ops.about.com postad.equisearch.about.com ca.equisearch.com 
        ca-biz.equisearch.com preview.equisearch.com preview.enthusiast.thepirtgroup.com ca.3dgraphics.about.com 
        ca.4wheeldrive.about.com ca.712educators.about.com ca.80music.about.com ca.actionadventure.about.com 
        ca.actionfigures.about.com ca.add.about.com ca.adoption.about.com ca.adulted.about.com 
        ca.adventuretravel.about.com ca.advertising.about.com ca.aids.about.com ca.airtravel.about.com 
        ca.albany.about.com ca.alcoholism.about.com ca.allergies.about.com ca.allmychildren.about.com 
        ca.altmedicine.about.com ca.altmusic.about.com ca.altreligion.about.com ca.animals.about.com 
        ca.animatedtv.about.com ca.animation.about.com ca.anime.about.com ca.antiques.about.com 
        ca.antivirus.about.com ca.apartments.about.com ca.archaeology.about.com ca.architecture.about.com 
        ca.arthistory.about.com ca.arthritis.about.com ca.artsandcrafts.about.com ca.arttech.about.com 
        ca.asthma.about.com ca.astrology.about.com ca.atheism.about.com ca.atlanta.about.com 
        ca.autism.about.com ca.autobuy.about.com ca.autoracing.about.com ca.autorepair.about.com 
        ca.aviation.about.com ca.babyparenting.about.com ca.backandneck.about.com ca.baking.about.com 
        ca.baltimore.about.com ca.bandb.about.com ca.baseball.about.com ca.bbq.about.com 
        ca.beadwork.about.com ca.beauty.about.com ca.beginnersinvest.about.com ca.bicycling.about.com 
        ca.biology.about.com ca.biotech.about.com ca.bipolar.about.com ca.birding.about.com 
        ca.blues.about.com ca.boardgames.about.com ca.bodybuilding.about.com ca.boston.about.com 
        ca.boxing.about.com ca.breastcancer.about.com ca.brooklyn.about.com ca.buddhism.about.com 
        ca.budgettravel.about.com ca.businessmajors.about.com ca.businesssoft.about.com ca.businesstravel.about.com 
        ca.busycooks.about.com ca.motorcycles.about.com preview.motortrend.com preview.trucktrend.com 
        preview.surfermag.com preview.anaheim.com preview.importtuner.com postad.sailmag.about.com 
        ca.sailmag.com ca.exercise.about.com ca.weightloss.about.com ca.austin.about.com 
        ca.vintagecars.about.com ca.ecommerce.about.com ca.email.about.com preview.sportrider.com 
        postad.primediaautomotive.about.com ca.primediaautomotive.com );

my $config = Config::ApacheFormat->new(hash_directives => ['Allow']);

isa_ok($config->read("t/large.conf"), 'Config::ApacheFormat');

is($config->get("User"), 'nobody');
is($config->get("Group"), 'nobody');

my $bl = $config->block(Directory => '/mnt/www/vdir/mp-bin');
is($bl->get('AllowOverride'), 'None');
is(($bl->get('Options'))[0], 'ExecCGI');
is(($bl->get('options'))[1], 'Includes');
is($bl->get('ORDER'), 'allow,deny');
is($bl->get(Allow => 'from'), 'all');
is($bl->get('SetHandler'), 'perl-script');
is($bl->get('PerlHandler'), 'Apache::Registry');

# check for all VirtualHost blocks, using ServerName
for ($config->block(VirtualHost => qw/10.12.13.125 10.12.12.125/)) {
    my $s  = $_->get('servername');
    my $ok = 0;
    if (exists $blocks{$s}) {
        $blocks{$s}++;
        $ok = 1;
    }
    ok($ok);
}

# loop thru and make sure we had them all
while (my($k,$v) = each %blocks) {
    is($blocks{$k}, 1);     # should be 1 and not 0/2/3
}

