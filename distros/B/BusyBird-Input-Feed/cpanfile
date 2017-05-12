
requires 'XML::FeedPP' => '0';
requires 'BusyBird::DateTime::Format' => '0.04';
requires 'DateTime::Format::ISO8601' => '0';
requires 'DateTime' => '0';
requires 'Try::Tiny' => '0';
requires 'WWW::Favicon' => '0';
requires 'LWP::UserAgent' => '0';
requires 'Carp' => '0';
requires 'JSON' => '0';
requires 'URI';

on 'test' => sub {
    requires 'Test::More' => "0";
    requires 'Test::Deep' => '0.084';
    requires 'File::Spec' => '0';
    requires 'Test::Exception' => '0';
};

on 'develop' => sub {
    requires 'Test::LWP::UserAgent' => '0';
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
