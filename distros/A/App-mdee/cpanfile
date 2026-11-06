requires 'perl', '5.026';

requires 'File::Share';
requires 'Text::ANSI::Fold', '2.38';
requires 'Text::ANSI::Fold::Util';
requires 'Text::VisualWidth::PP', '0.09';
requires 'URI::Escape';

requires 'App::ansiecho';
requires 'App::ansifold', '1.38';
requires 'App::ansicolumn', '1.61';
requires 'Term::ANSIColor::Concise', '3.03';

requires 'App::nup', '1.10';
requires 'Getopt::Long::Bash', '0.7.2';

requires 'App::Greple', '10.04';
requires 'App::Greple::tee', '1.04';
requires 'Getopt::EX', '3.05';
requires 'Getopt::EX::Config', '1.0202';
requires 'Command::Run', '1.04';

requires 'Getopt::EX::termcolor', '1.10';

requires 'App::cat::v';

# --refill finds the paragraphs with Markdown::Perl (pure Perl), or faster
# with CommonMark (needs libcmark); pandoc is a third choice
requires 'Markdown::Perl', '1.14';
recommends 'CommonMark';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
