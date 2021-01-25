requires "perl", "5.8.0";
requires "strict";
requires "warnings";
requires "parent";

requires "XML::Parser";
requires "XML::Writer";
requires "HTTP::CookieJar";
requires "HTTP::Tiny";
requires "File::Basename";
requires "File::Spec";
requires "Encode";
requires "URI";
requires "DateTime::TimeZone";
requires "DateTime::Format::Strptime";
requires "DateTime::Format::ISO8601";
requires "MIME::Base64";

on test => sub {
    requires "IO::Socket::SSL";
    requires "Test::More";
    requires "Test::RequiresInternet";
    requires "DateTime";
    requires "Text::Password::Pronounceable";
    requires "Data::Dumper";
    requires "Clone";
};

on develop => sub {
    requires "Dist::Zilla::PluginBundle::Basic";

    requires "Dist::Zilla::Plugin::Prereqs::FromCPANfile";
    requires "Dist::Zilla::Plugin::GithubMeta";
    requires "Dist::Zilla::Plugin::MetaJSON";
    requires "Dist::Zilla::Plugin::MetaTests";
    requires "Dist::Zilla::Plugin::ModuleBuild";
    requires "Dist::Zilla::Plugin::TravisYML";
    requires "Dist::Zilla::Plugin::Covenant";
    requires "Dist::Zilla::Plugin::DOAP";
    requires "Dist::Zilla::Plugin::Test::Perl::Critic";
    requires "Dist::Zilla::Plugin::Test::Kwalitee";
    requires "Dist::Zilla::Plugin::Test::EOF";
    requires "Dist::Zilla::Plugin::Test::EOL";
    requires "Dist::Zilla::Plugin::Test::NoTabs";
    requires "Dist::Zilla::Plugin::Test::Portability";
    requires "Dist::Zilla::Plugin::Test::ReportPrereqs";
    requires "Dist::Zilla::Plugin::Test::NoBreakpoints";
    requires "Dist::Zilla::Plugin::Test::UnusedVars";
    requires "Dist::Zilla::Plugin::PodSyntaxTests";
    requires "Dist::Zilla::Plugin::RunExtraTests";
    requires "Dist::Zilla::Plugin::PkgVersion";
    requires "Dist::Zilla::Plugin::PodWeaver";
    requires "Dist::Zilla::Plugin::Git::Remote::Check";
    requires "Dist::Zilla::Plugin::Git::Check";
    requires "Dist::Zilla::Plugin::Git::Commit";
    requires "Dist::Zilla::Plugin::Git::GatherDir";
    requires "Dist::Zilla::Plugin::Git::Tag";
    requires "Dist::Zilla::Plugin::PruneCruft";
    requires "Dist::Zilla::Plugin::Clean";
    requires "Dist::Zilla::Plugin::Prereqs";
};
