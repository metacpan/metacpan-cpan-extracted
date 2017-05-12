use inc::Module::Install;
  
name           'App-Bernard';
all_from       'lib/App/Bernard.pm';

requires       'Lingua::EN::Alphabet::Shaw';
requires       'Locale::PO::Callback';
requires       'LWP';
requires       'LWP::UserAgent';
requires       'File::MimeInfo';
requires       'File::Slurp';
requires       'Getopt::Long';

install_script 'bernard';

WriteAll;
