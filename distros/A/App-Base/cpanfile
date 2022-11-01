requires 'File::Flock::Tiny';
requires 'List::Util';
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::Types';
requires 'Path::Tiny';
requires 'Text::Reform';
requires 'Syntax::Keyword::Try';
requires 'namespace::autoclean';
requires 'perl', '5.01';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on test => sub {
    requires 'File::Slurp';
    requires 'Test::Exit';
    requires 'Test::FailWarnings';
    requires 'Test::More', '0.94';
    requires 'Test::Most', '0.21';
    requires 'Test::Warn';
    requires 'Text::Trim';
};
