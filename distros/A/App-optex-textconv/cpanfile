requires 'perl', 'v5.14.0';
requires 'App::optex', 'v0.6';
requires 'Command::Run', '1.01';
requires 'Archive::Zip', '1.37';
requires 'Encode';
requires 'List::Util', '1.45';
requires 'Text::Extract::Word';
requires 'Spreadsheet::ParseExcel';

feature 'xslt', 'XSLT impelementation' => sub {
    recommends 'XML::LibXML';
    recommends 'XML::LibXSLT';
};

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
};
