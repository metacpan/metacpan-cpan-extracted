requires 'perl', '5.008005';

# requires 'Some::Module', 'VERSION';
requires 'Carp', '0';
requires 'parent', '0';

on test => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Exception','0';
};

on 'develop' => sub {
  requires 'Test::Spelling';
  requires 'Test::MinimumVersion';
  requires 'Test::Pod::Coverage';
  requires 'Test::PureASCII';
};