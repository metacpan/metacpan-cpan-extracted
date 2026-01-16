requires 'perl', '5.010';

requires 'Class::Tiny';
requires 'File::Share';
requires 'YAML::XS';
requires 'version';

on configure => sub {
    requires 'Module::Build::Tiny';
};

on develop => sub {
    requires 'Perl::Tidy';
    requires 'Version::Next';
    requires 'CPAN::Uploader';
    requires 'Software::License::MIT';
};

on test => sub {
    requires 'Test2::Bundle::More';
};
