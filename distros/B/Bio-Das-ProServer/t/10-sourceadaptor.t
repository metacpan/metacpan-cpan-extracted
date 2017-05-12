use strict;
use Test::More tests => 22;
use Bio::Das::ProServer::Config;
use_ok('Bio::Das::ProServer::SourceAdaptor');

my $sa = Bio::Das::ProServer::SourceAdaptor->new();
isa_ok($sa, 'Bio::Das::ProServer::SourceAdaptor');
can_ok($sa, qw(new init length mapmaster title description source_uri version_uri coordinates _coordinates capabilities _capabilities properties init_segments known_segments segment_version dsn dsnversion dsncreated dsncreated_iso dsncreated_unix start end transport config implements das_capabilities das_dsn unknown_segment _gen_link_das_response _encode _gen_feature_das_response das_features error_feature das_sequence das_types das_entry_points das_stylesheet das_alignment das_sourcedata cleanup));
is($sa->init(),             undef,         'init is undef');
is($sa->length(),           0,             'length is 0 by default');
is($sa->mapmaster(),        undef,         'mapmaster is undef');
is($sa->title(),            $sa->dsn(),    'title == dsn');
is($sa->description(),      $sa->title(),  'description == title');
is($sa->init_segments(),    undef,         'init_segments is undef');
is($sa->known_segments(),   undef,         'known_segments is undef');
is($sa->segment_version(),  undef,         'segment_version is undef');
is($sa->dsn(),              'unknown',     'dsn is unknown');
is($sa->dsnversion(),       '1.0',         'dsn version is 1.0');
is($sa->dsncreated(),       0,             'dsn created date is zero (epoch)');
is($sa->dsncreated_iso(),   '1970-01-01T00:00:00Z', 'dsn created date is zero (epoch)');
is($sa->start(),            1,             'start is 1');
is($sa->end(),              $sa->length(), 'end == length');
isa_ok($sa->config(),       'HASH',        'config is a hash');
my $cfg = {
	   'transport' => 'file',
	  };
$sa->config($cfg);
is($sa->config(),           $cfg,          'config get/set ok');
isa_ok($sa->transport(),    'Bio::Das::ProServer::SourceAdaptor::Transport::file', 'file transport created ok');   
is($sa->implements(),       undef,         'implements without arg gives undef');
is($sa->das_capabilities(), '',     'das_capabilities is empty by default');
