use Test::More tests => 1;
use Akamai::PropertyFetcher;

# Akamai::Edgegridの読み込みと認証情報のチェックをバイパスする
BEGIN {
    no warnings 'redefine';
    *Akamai::Edgegrid::new = sub { return {}; };  # ダミーのAkamai::Edgegridインスタンスを返す
}

eval {
    my $fetcher = Akamai::PropertyFetcher->new(
        config_file => "$ENV{HOME}/.edgerc",
    );
    pass('Module loaded successfully');
} or do {
    fail('Module failed to load: ' . $@);
};

