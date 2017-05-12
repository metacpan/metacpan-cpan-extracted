use inc::Module::Install;

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
Test::More
Directory::Scratch
FindBin
Catalyst::Test
HTML::Declare
_END_

    map { my ($pk, $vr) = split m/\s/; requires $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
Catalyst
Class::Accessor::Fast
File::Assets 0.061
JavaScript::Minifier
CSS::Minifier
_END_

    map { my ($pk, $vr) = split m/\s/; recommends $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
JavaScript::Minifier::XS 0.03
CSS::Minifier::XS 0.03
_END_
}

name     'Catalyst-Plugin-Assets';
all_from 'lib/Catalyst/Plugin/Assets.pm';
author   'Robert Krimen <rkrimen@cpan.org>';

auto_install;

WriteAll;

