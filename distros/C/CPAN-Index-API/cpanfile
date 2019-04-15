on 'runtime' => sub {
    requires 'perl' => '5.008001';
    requires 'strict';
    requires 'warnings';
    requires 'base';
    requires 'namespace::autoclean';
    requires 'Carp';
    requires 'Class::Load';
    requires 'Compress::Zlib';
    requires 'File::Basename';
    requires 'File::Temp';
    requires 'List::Util';
    requires 'LWP::Simple';
    requires 'Moose';
    requires 'Moose::Role';
    requires 'Moose::Util::TypeConstraints';
    requires 'MooseX::ClassAttribute';
    requires 'Path::Class';
    requires 'Path::Tiny';
    requires 'Scalar::Util';
    requires 'Symbol';
    requires 'Text::Template';
    requires 'URI';
    requires 'URI::file';
    requires 'XML::Twig';
};

on 'build' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'test' => sub {
    requires 'strict';
    requires 'warnings';
    requires 'Compress::Zlib';
    requires 'ExtUtils::MakeMaker';
    requires 'Path::Tiny';
    requires 'File::Temp';
    requires 'Test::More' => '0.88';
    requires 'Test::Most';
    requires 'Test::XML';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Test::CheckManifest' => '1.29';
    requires 'Test::CPAN::Changes' => '0.4';
    requires 'Test::Kwalitee'      => '1.22';
    requires 'Test::Pod::Spelling::CommonMistakes' => '1.000';
};
