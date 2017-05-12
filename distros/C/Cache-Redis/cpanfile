requires 'Module::Load';
requires 'Redis';
requires 'perl', '5.008_001';

recommends 'Redis::Fast';
recommends 'Data::MessagePack', '0.36';
recommends 'JSON::XS';

on configure => sub {
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Test::RedisServer';
    requires 'Test::Requires';
};

on develop => sub {
    requires 'Cache::Memcached::Fast';
    requires 'Data::MessagePack';
    requires 'File::Temp';
    requires 'JSON::XS';
    requires 'Test::Memcached';
};
