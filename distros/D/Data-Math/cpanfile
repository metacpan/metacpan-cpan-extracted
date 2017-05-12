requires 'perl', '5.008005';

requires 'Moo';
requires 'MooX::Types::MooseLike::Base';
requires 'List::MoreUtils';
requires 'Scalar::Classify';

# core modules
requires 'Carp';
requires 'Data::Dumper';
requires 'Scalar::Util';
requires 'List::Util';
requires 'lib';
requires 'strict';
requires 'warnings';
requires 'FindBin';

on test => sub {
    requires 'Test::More', '0.96';

    # non-core
    requires 'List::MoreUtils';
    requires 'Test::Deep';
    requires 'Test::Exception';
    requires 'Test::Trap';

    # other core modules
    requires 'Data::Dumper';
    requires 'File::Path';
    requires 'File::Basename';
    requires 'File::Copy';
    requires 'Fatal';
    requires 'Cwd';
    requires 'Env';
    requires 'lib';
    requires 'FindBin';

};
