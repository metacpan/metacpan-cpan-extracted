requires 'perl', '5.014';

requires 'JSON';
requires 'List::Util';
requires 'Hash::Util';
requires 'Clipboard';
requires 'File::Share';
requires 'App::Greple', '9.02';
requires 'App::Greple::msdoc', '1.05';
requires 'App::optex::textconv', '1.04';
requires 'App::sdif', '4.24.0';
requires 'Text::ANSI::Fold', '2.20';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    recommends 'Pod::Markdown';
    recommends 'App::Greple::xp', '0.04';
};
