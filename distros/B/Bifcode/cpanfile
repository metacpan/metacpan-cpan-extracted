#!perl
requires 'boolean';
requires 'Carp';
requires 'Exporter::Tidy';
requires 'perl', '5.010';
requires 'strict';
requires 'utf8';
requires 'warnings';

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
};

on develop => sub {
    requires 'App::githook::perltidy';
};

on test => sub {
    requires 'Text::Diff';
    requires 'Test::More', '0.88';
    requires 'Test::Needs';
};

# vim: ft=perl
