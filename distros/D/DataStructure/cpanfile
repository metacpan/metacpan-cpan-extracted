requires 'perl', '5.24.0';

requires 'Scalar::Util';

on 'configure' => sub {
  requires 'ExtUtils::MakeMaker::CPANfile', '0.0.9';
};

on 'test' => sub {
  requires 'Test::More';
};

# Phases that exist: configure, build, test, runtime, develop.
# Dependencies can be requires, recommends, or conflicts.
