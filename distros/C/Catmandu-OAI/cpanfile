requires 'perl', 'v5.10.1';

on 'test', sub {
  requires 'Test::Simple', '1.001003';
  requires 'Test::More', '1.001003';
  requires 'Test::Exception','0.32';
  requires 'Test::Pod';
};

requires 'Catmandu', '>=1.0306';
requires 'HTTP::OAI', '>=4.03';
requires 'Moo', '>=1.0';
requires 'XML::Struct', '>=0.18';
requires 'MODS::Record', '>=0.11';
requires 'IO::String', '0';
requires 'URI','0';

# Need recent SSL to talk to https endpoint correctly
requires 'IO::Socket::SSL', '>=1.993';

feature 'xslt' => sub {
    requires 'Catmandu::XML', '>=0.15';
};
