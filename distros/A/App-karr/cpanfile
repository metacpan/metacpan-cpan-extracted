requires 'Moo';
requires 'MooX::Cmd';
requires 'MooX::Options';
requires 'YAML::XS';
requires 'Path::Tiny';
requires 'JSON::MaybeXS';
requires 'Term::ANSIColor';
requires 'Time::Piece';
requires 'File::ShareDir';
requires 'Try::Tiny';
requires 'Encode';
requires 'Scalar::Util';
requires 'IO::Select';
requires 'Errno';
requires 'POSIX';
requires 'Time::HiRes';
requires 'Git::Native', '0.005';
requires 'Git::Libgit2', '0.006';

on test => sub {
    requires 'Test::More';
    requires 'File::Temp';
    # t/124-source-ascii-only.t classifies every token in lib/ and bin/ so that
    # POD and comments stay exempt; a regex over lines cannot tell a `#` opening
    # a comment from one inside a string.
    requires 'PPI';
};
