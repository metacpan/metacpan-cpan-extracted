requires 'DateTime';
requires 'DateTime::Set';
requires 'Exporter', '5.57';

on configure => sub {
    requires 'Module::Build::XSUtil', '0.16';
};

on test => sub {
    requires 'Test::Exception';
};

on develop => sub {
    requires 'Test::Requires';
    requires 'JSON';
};
