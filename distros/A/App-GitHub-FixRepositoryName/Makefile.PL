use inc::Module::Install;

name     'App-GitHub-FixRepositoryName';
all_from 'lib/App/GitHub/FixRepositoryName.pm';
author   'Robert Krimen <rkrimen@cpan.org>';
license  'perl';

resources repository => 'http://github.com/robertkrimen/App-GitHub-FixRepositoryName/tree/master';

install_script 'github-fix-repository-name';

{
    require ExtUtils::MakeMaker;
    use strict;
    no strict 'refs';

    my $libscan = \&{"ExtUtils::MM_Any::libscan"};
    *{"ExtUtils::MM_Any::libscan"} = sub {
        return '' unless $libscan->(@_);
        return '' if $_[1] =~ /\.sw[p-z]$/;
        return $_[1];
    };
}

{
    map { my ($pk, $vr) = split m/\s/; build_requires $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
Test::Most
Directory::Scratch
_END_

    map { my ($pk, $vr) = split m/\s/; requires $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
App::GitHub::FindRepository
Carp::Clan
Digest::SHA1
File::AtomicWrite
File::Temp
Getopt::Long
Path::Class
Term::Prompt
_END_
}

if (-e 'inc/.author') {
    my $all_from = join '/', 'lib', split m/-/, name . '.pm';
    `perldoc -tF $all_from > README` if ! -e 'README' || (stat $all_from)[9] > (stat 'README')[9];
}

WriteAll;
