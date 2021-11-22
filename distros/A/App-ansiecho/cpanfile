requires 'Encode';
requires 'Getopt::EX', 'v1.26.0';
requires 'Getopt::EX::Colormap';
requires 'Getopt::EX::Long';
requires 'Getopt::EX::Hashed', '1.01';
requires 'List::Util';
requires 'Pod::Usage';
requires 'Text::ANSI::Printf', '2.01';
requires 'perl', 'v5.14.0';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Command::Runner';
};
