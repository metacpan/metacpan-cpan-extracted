requires 'perl', '5.036';

requires 'YAML::XS';
requires 'Path::Tiny';
requires 'Term::ANSIColor';
requires 'Getopt::Long';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::DescribeMe';
    requires 'Test::Exception';
};

on 'develop' => sub {
    requires 'Perl::Critic';
    requires 'Devel::Cover';
};
