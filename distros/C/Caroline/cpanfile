requires 'perl', '5.008001';
requires 'Storable';
requires 'POSIX';
requires 'Text::VisualWidth::PP', 0.03;
requires 'Class::Accessor::Lite', 0.05;
requires 'Term::ReadKey', 2.30;
requires 'IO::Handle';
requires 'Unicode::EastAsianWidth::Detect', '0.03';
requires 'Term::Encoding';
recommends 'Term::ReadLine';

if ($^O eq 'MSWin32') {
    requires 'Win32::API';
    requires 'Encode';
    requires 'Win32::Console::ANSI';
}

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'File::Temp';
};

