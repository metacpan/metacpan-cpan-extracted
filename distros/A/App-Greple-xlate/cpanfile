requires 'perl', 'v5.26';

requires 'JSON';
requires 'List::Util', '1.56';
requires 'Hash::Util';
requires 'Clipboard';
requires 'File::Share';
requires 'App::Greple', '9.23';
requires 'App::Greple::msdoc', '1.06';
requires 'App::Greple::stripe', '1.02';
requires 'Getopt::EX::termcolor';
requires 'App::optex::textconv', '1.07';
requires 'App::sdif', '4.41';
requires 'Text::ANSI::Fold', '2.30';
requires 'App::dozo', '0.9927';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    recommends 'Pod::Markdown';
    recommends 'App::Greple::xp', '1.00';
    recommends 'App::Greple::subst::desumasu';
};
