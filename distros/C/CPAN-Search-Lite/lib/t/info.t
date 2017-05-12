#!/usr/bin/perl
use strict;
use warnings;
use Test;
use Cwd;
use File::Spec::Functions;
use File::Path;
use CPAN::DistnameInfo;
use FindBin;
use lib "$FindBin::Bin/../../Apache2/t/lib";
use TestCSL qw($expected download %has_doc $ppm_packs has_data);
use CPAN::Search::Lite::Info;
use CPAN::Search::Lite::PPM;

plan tests => 105;

my $cwd = getcwd;
my $CPAN = catdir $cwd, 't', 'cpan';
my $t_dir = catdir $cwd, 't';
$CPAN::Search::Lite::Util::repositories = {
                                           1 => {
                                                 alias => 'csl_test',
                                                 LOCATION => 
                                                 "file:/$t_dir",
                                                 SUMMARYFILE  => 'summary.ppm',
                                                 browse => "file:/$t_dir",
                                                 build => '8xx',
                                                 PerlV => 5.8,
                                                },
                                          };

my ($db, $user, $passwd) = ('test', 'test', '');

ok (-d $CPAN);
my $info = CPAN::Search::Lite::Info->new(CPAN => $CPAN);
ok(ref($info), 'CPAN::Search::Lite::Info');

$info->fetch_info();
ok(has_data($info->{dists}));
ok(has_data($info->{mods}));
ok(has_data($info->{auths}));
foreach my $id (keys %$expected) {
  my $mod = $expected->{$id}->{mod};
  my $dist = $expected->{$id}->{dist};
  my $chapter = $expected->{$id}->{chapter};
  my $fullname = $expected->{$id}->{fullname};
  my $subchapter = $expected->{$id}->{subchapter};

  ok($info->{auths}->{$id}->{fullname}, qq{$fullname});
  ok(defined $info->{auths}->{$id}->{email});

  ok($info->{mods}->{$mod}->{dist}, $dist);
  ok($info->{mods}->{$mod}->{version} > 0);
  ok($info->{mods}->{$mod}->{chapterid}, $chapter);
  ok(defined $info->{mods}->{$mod}->{dslip});
  ok(defined $info->{mods}->{$mod}->{description});

  ok($info->{dists}->{$dist}->{cpanid}, $id);
  my $filename = $info->{dists}->{$dist}->{filename};
  ok($filename, qr{^$dist});
  my $download = download($id, $filename);
  my $d = CPAN::DistnameInfo->new($download);
  ok($info->{dists}->{$dist}->{size} > 0);
  ok($info->{dists}->{$dist}->{version}, $d->version);
  ok(defined $info->{dists}->{$dist}->{date});
  ok(defined $info->{dists}->{$dist}->{modules}->{$mod});
  ok(exists $info->{dists}->{$dist}->{chapterid}->{$chapter});
  ok(exists $info->{dists}->{$dist}->{chapterid}->{$chapter}->{$subchapter});
}

ok(not defined $info->{auths}->{ZZZ});
ok(not defined $info->{mods}->{ZZZ});
ok(not defined $info->{dists}->{ZZZ});

my @tables = qw(dists mods auths);
my $index;
my $package = 'CPAN::Search::Lite::Index';
foreach my $table(@tables) {
  my $class = $package . '::' . $table;
  my $this = {info => $info->{$table}};
  $index->{$table} = bless $this, $class;
}

use CPAN::Search::Lite::DBI qw($tables);
my $cdbi = CPAN::Search::Lite::DBI::Index->new(db => $db,
					       user => $user,
					       passwd => $passwd);
ok(ref($cdbi), 'CPAN::Search::Lite::DBI::Index');
foreach my $table(qw(chapters reps)) {
  my $obj = $cdbi->{objs}->{$table};
  my $schema = $obj->schema($tables->{$table});
  ok($schema);
  $obj->drop_table;
  $obj->create_table($schema);
  $obj->populate;
}

my $ppm = CPAN::Search::Lite::PPM->new(dists => $info->{dists},
				       db => $db, user => $user,
                                       passwd => $passwd, setup => 1);

ok(ref($ppm), 'CPAN::Search::Lite::PPM');
$ppm->fetch_info();
my $ppm_info = $ppm->{ppms};
ok(has_data($ppm_info));
$index->{ppms} = bless {info => $ppm_info},
  'CPAN::Search::Lite::Index::ppms';

ok(scalar keys %{$ppm_info->{1}}, scalar keys %{$ppm_packs});

my $pod_root = catdir $cwd, 't', 'POD';
my $html_root = catdir $cwd, 't', 'HTML';
for my $dir ( ($pod_root, $html_root) ) {
    if (-d $dir) {
        rmtree ($dir, 1, 1) or die "Cannot rmtree $dir: $!";
    }
    mkpath($dir, 1, 0777) or die "Cannot mkpath $dir: $!";
}
use CPAN::Search::Lite::Extract;
my $extract = CPAN::Search::Lite::Extract->new(CPAN => $CPAN,
                                               setup => 1,
                                               index => $index,
                                               pod_root => $pod_root,
                                               split_pod => 1,
                                              );
ok(ref($extract), 'CPAN::Search::Lite::Extract');
$extract->extract();

use CPAN::Search::Lite::Populate;
my $pop = CPAN::Search::Lite::Populate->new(db => $db, user => $user,
                                            passwd => $passwd, setup => 1,
                                            no_mirror => 1,
                                            index => $index);
ok(ref($pop), 'CPAN::Search::Lite::Populate');
$pop->populate();
ok(1);

use CPAN::Search::Lite::HTML;
my $html = CPAN::Search::Lite::HTML->new(pod_root => $pod_root,
					 html_root => $html_root,
					 split_pod => 1, setup => 1,
					 dist_docs => $extract->{dist_docs},
					 db => $db, user => $user,
                                         passwd => $passwd, css => 'cpan.css',
					 dist_obj => $pop->{obj}->{dists},
					 up_img => 'up.png',
					 dist_info => 'http://localhost/dist',
					);
ok(ref($html), 'CPAN::Search::Lite::HTML');
$html->make_html();
foreach my $id (keys %$expected) {
    my $dist = $expected->{$id}->{dist};
    my $d = catdir $pod_root, $dist;
    ok(-d $d, 1);
    for my $file (qw(Changes README)) {
        my $f = catfile $d, $file;
        ok(-f $f && -s _ > 0, 1);
    }
    my $mod = $expected->{$id}->{mod};
    my $f = (catfile($d, split /::/, $mod)) . '.pm';
    ok(-f $f && -s _ > 0, 1);
    $d = catdir $html_root, $dist;
    ok(-d $d, 1);
    for my $file (qw(Changes README index)) {
        my $f = catfile $d, "$file.html";
        ok(-f $f && -s _ > 0, 1);
    }
    $f = (catfile($d, split /::/, $mod)) . '.html';
    ok(-f $f && -s _ > 0, 1);
}

my $dist = 'libnet';

foreach my $mod (keys %has_doc) {
    my $d = catdir $pod_root, $dist;
    my $f = (catfile($d, split /::/, $mod)) . '.pm';
    ok(-f $f && -s _ > 0, 1);
    $d = catdir $html_root, $dist;
    if ($has_doc{$mod}) {
        $f = (catfile($d, split /::/, $mod)) . '.html';
        ok(-f $f && -s _ > 0, 1);
    }
    $f = (catfile($d, split /::/, $mod)) . '.pm.html';
    ok(-f $f && -s _ > 0, 1);
}
