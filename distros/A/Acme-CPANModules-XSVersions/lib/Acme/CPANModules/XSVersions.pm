package Acme::CPANModules::XSVersions;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-05'; # DATE
our $DIST = 'Acme-CPANModules-XSVersions'; # DIST
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => 'List of Perl modules which have XS implementation or backend',
    description => <<'_',

This list catalogs (pure-) Perl modules that have their XS counterparts ("fast
versions"), usually in separate distributions so the installation of the XS
version is optional. The two versions of the modules provide the same interface.
When the two modules are different in interface, they are not listed here.

Usually authors use `::XS` or `_XS` suffix for the XS version (for example,
<pm:Type::Tiny> is the PP/pure-perl version and <pm:Type::Tiny::XS> is the XS
version). Or sometimes the other way around is done, a module is an XS module
and another with suffix `::PP` or `_PP` is the PP version. And often a module
like `JSON` is one that can automatically use the XS version (`JSON::XS`) when
it's available or fallback to the PP version (`JSON::PP`).

Additions much welcome.

_
    entries => [
        # 'module' lists the PP version, 'xs_module' lists the XS version

        {module => 'Algorithm::Diff', xs_module => 'Algorithm::Diff::XS'},
        {module=>'Algorithm::LUHN', xs_module=>'Algorithm::LUHN_XS'},
        {module => 'Algorithm::PageRank', xs_module => 'Algorithm::PageRank::XS'},
        {module=>'Algorithm::RectanglesContainingDot', xs_module=>'Algorithm::RectanglesContainingDot_XS'},
        {module => 'Bytes::Random', xs_module => 'Bytes::Random::XS'},
        {module => 'Class::Accessor::Fast', xs_module => 'Class::Accessor::Fast::XS'},
        {module => 'Class::C3', xs_module => 'Class::C3::XS'},
        {module => 'Class::Load', xs_module => 'Class::Load::XS'},
        {module=>'Convert::Bencode', xs_module=>'Convert::Bencode_XS'},
        {module => 'Crypt::Passwd', xs_module => 'Crypt::Passwd::XS'},
        {module=>'Crypt::TEA_PP', xs_module=>'Crypt::TEA_XS'},
        {module=>'Crypt::XXTEA_PP', xs_module=>'Crypt::XXTEA_XS'},
        {module => 'DDC::PP', xs_module => 'DDC::XS'},
        {module => 'Crypt::Skip32', xs_module => 'Crypt::Skip32::XS'},
        {module => 'Date::Calc', pp_module=>'Date::Calc::PP', xs_module => 'Date::Calc::XS'},
        {module => 'Directory::Iterator', pp_module=>'Directory::Iterator::PP', xs_module => 'Directory::Iterator::XS'},
        {module => 'Encode', xs_module => 'Encode::XS'},
        {module => 'Encoding::FixLatin', xs_module => 'Encoding::FixLatin::XS'},
        {module => 'File::MMagic', xs_module => 'File::MMagic::XS'},
        {module => 'Geo::Coordinates::UTM', xs_module => 'Geo::Coordinates::UTM::XS'},
        {module => 'Geo::Distance', xs_module => 'Geo::Distance::XS'},
        {module => 'Geo::Hash', xs_module => 'Geo::Hash::XS'},
        {module => 'HTTP::Headers::Fast', xs_module => 'HTTP::Headers::Fast::XS'},
        {module => 'HTTP::Parser::XS::PP', xs_module => 'HTTP::Parser::XS'},
        {module => 'Heap::Simple', xs_module => 'Heap::Simple::XS'},
        {module => 'Image::Info', xs_module => 'Image::Info::XS'},
        {module => 'JSON', pp_module=>'JSON::PP', xs_module => 'JSON::XS'},
        {module => 'JSON::MaybeXS', xs_module => 'Cpanel::JSON::XS'},
        {module =>'Language::Befunge::Vector', xs_module => 'Language::Befunge::Vector::XS'},
        {module => 'Language::Befunge::Storage::Generic::Vec', xs_module => 'Language::Befunge::Storage::Generic::Vec::XS'},
        {module => 'List::BinarySearch', xs_module => 'List::BinarySearch::XS'},
        {module => 'List::Flatten', xs_module => 'List::Flatten::XS'},
        {module => 'List::MoreUtils', xs_module => 'List::MoreUtils::XS'},
        {module => 'List::SomeUtils', xs_module => 'List::SomeUtils::XS'},
        {module => 'List::Util', xs_module => 'List::Util::XS'},
        {module => 'List::UtilsBy', xs_module => 'List::UtilsBy::XS'},
        {module=>'Math::Derivative', xs_module=>'Math::Derivative_XS'},
        {module => 'Math::Gauss', xs_module => 'Math::Gauss::XS'},
        {module => 'Math::Utils', xs_module => 'Math::Utils::XS'},
        {module => 'MaxMind::DB::Reader', xs_module => 'MaxMind::DB::Reader::XS'},
        {module => 'Mojo::Base', xs_module => 'Mojo::Base::XS'},
        {module => 'Moo', xs_module => 'Class::XSAccessor'},
        # TODO: Mouse
        {module => 'Net::IP', xs_module => 'Net::IP::XS'},
        {module => 'Net::SNMP', xs_module => 'Net::SNMP::XS'},
        {module => 'Number::Closest', xs_module => 'Number::Closest::XS'},
        {module => 'Object::Adhoc', xs_module => 'Class::XSAccessor'},
        {module => 'Object::Accessor', xs_module => 'Object::Accessor::XS'},
        {module => 'Object::Tiny', xs_module => 'Object::Tiny::XS'},
        {module => 'Object::Tiny::RW', xs_module => 'Object::Tiny::RW::XS'},
        {module => 'PPI', xs_module => 'PPI::XS'},
        {module => 'Package::Stash', xs_module => 'Package::Stash::XS'},
        {module => 'Params::Validate', xs_module => 'Params::Validate::XS'},
        {module => 'Path::Hilbert', xs_module => 'Path::Hilbert::XS'},
        {module => 'PerlX::ArraySkip', xs_module => 'PerlX::ArraySkip::XS'},
        {module => 'PerlX::Maybe', xs_module => 'PerlX::Maybe::XS'},
        {module => 'PPI', xs_module => 'PPI::XS'},
        {module => 'Protocol::Redis', xs_module => 'Protocol::Redis::XS'},
        {module => 'Readonly', xs_module => 'Readonly::XS'},
        {module => 'Ref::Util', xs_module => 'Ref::Util::XS'},
        {module => 'Set::IntSpan::Fast', xs_module => 'Set::IntSpan::Fast::XS'},
        {module => 'Set::Product', xs_module => 'Set::Product::XS'},
        {module=>'SOAP::WSDL::Deserializer::XSD', xs_module=>'SOAP::WSDL::Deserializer::XSD_XS'},
        {module => 'Sort::Naturally', xs_module => 'Sort::Naturally::XS'},
        {module => 'String::Numeric', xs_module => 'String::Numeric::XS'},
        {module => 'Template::Alloy', xs_module => 'Template::Alloy::XS'},
        {module => 'Template::Stash', xs_module => 'Template::Stash::XS'},
        {module => 'Text::CSV', xs_module => 'Text::CSV_XS'},
        # Text::Levenshtein & Text::Levenshtein::XS are different modules
        {module => 'Text::Levenshtein::Damerau', xs_module => 'Text::Levenshtein::Damerau::XS'},
        {module => 'Time::Format', xs_module => 'Time::Format_XS'},
        {module => 'Type::Params', xs_module => 'Class::XSAccessor'},
        {module => 'Type::Tiny', xs_module => 'Type::Tiny::XS'},
        # Tree::Binary & Tree::Binary::XS are different modules
        {module => 'Tree::Object', xs_module => 'Tree::ObjectXS'},
        {module => 'URL::Encode', xs_module => 'URL::Encode::XS'},
        {module => 'Unix::Uptime::BSD', xs_module => 'Unix::Uptime::BSD::XS'},
        # Win32::Unicode & Win32::Unicode::XS?
        {module => 'XML::CompactTree', xs_module => 'XML::CompactTree::XS'},
        # XML::Hash & XML::Hash::XS are different modules
        {module => 'YAML::PP', xs_module => 'YAML::XS'},
        # ZooKeeper & ZooKeeper::XS?
        {module => 'match::simple', xs_module => 'match::simple::XS'},

    ],
};

1;
# ABSTRACT: List of Perl modules which have XS implementation or backend

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::XSVersions - List of Perl modules which have XS implementation or backend

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::XSVersions (from Perl distribution Acme-CPANModules-XSVersions), released on 2023-09-05.

=head1 SYNOPSIS

To install all XS versions of PP modules currently installed on your system:

 % perl -MAcme::CM::Get=XSVersions -MModule::Installed::Tiny=module_installed -E'for (@{$LIST->{entries}}) {
       next unless module_installed($_->{module}) || $_->{pp_module} && module_installed($_->{pp_module});
       say $_->{xs_module};
   }' | cpanm -n

(Note: To run the above snippet, you need to install
L<Acme::CPANModules::XSVersions> which you're reading right now, as well as
L<Acme::CM::Get>, L<Module::Installed::Tiny>, and L<cpanm>.)

=head1 DESCRIPTION

This list catalogs (pure-) Perl modules that have their XS counterparts ("fast
versions"), usually in separate distributions so the installation of the XS
version is optional. The two versions of the modules provide the same interface.
When the two modules are different in interface, they are not listed here.

Usually authors use C<::XS> or C<_XS> suffix for the XS version (for example,
L<Type::Tiny> is the PP/pure-perl version and L<Type::Tiny::XS> is the XS
version). Or sometimes the other way around is done, a module is an XS module
and another with suffix C<::PP> or C<_PP> is the PP version. And often a module
like C<JSON> is one that can automatically use the XS version (C<JSON::XS>) when
it's available or fallback to the PP version (C<JSON::PP>).

Additions much welcome.

=head1 ACME::CPANMODULES ENTRIES

=over

=item L<Algorithm::Diff>

Author: L<RJBS|https://metacpan.org/author/RJBS>

XS module: L<Algorithm::Diff::XS>

=item L<Algorithm::LUHN>

Author: L<NEILB|https://metacpan.org/author/NEILB>

XS module: L<Algorithm::LUHN_XS>

=item L<Algorithm::PageRank>

Author: L<XERN|https://metacpan.org/author/XERN>

XS module: L<Algorithm::PageRank::XS>

=item L<Algorithm::RectanglesContainingDot>

Author: L<SALVA|https://metacpan.org/author/SALVA>

XS module: L<Algorithm::RectanglesContainingDot_XS>

=item L<Bytes::Random>

Author: L<JOHND|https://metacpan.org/author/JOHND>

XS module: L<Bytes::Random::XS>

=item L<Class::Accessor::Fast>

Author: L<KASEI|https://metacpan.org/author/KASEI>

XS module: L<Class::Accessor::Fast::XS>

=item L<Class::C3>

Author: L<HAARG|https://metacpan.org/author/HAARG>

XS module: L<Class::C3::XS>

=item L<Class::Load>

Author: L<ETHER|https://metacpan.org/author/ETHER>

XS module: L<Class::Load::XS>

=item L<Convert::Bencode>

Author: L<ORCLEV|https://metacpan.org/author/ORCLEV>

XS module: L<Convert::Bencode_XS>

=item L<Crypt::Passwd>

Author: L<LUISMUNOZ|https://metacpan.org/author/LUISMUNOZ>

XS module: L<Crypt::Passwd::XS>

=item L<Crypt::TEA_PP>

Author: L<JAHIY|https://metacpan.org/author/JAHIY>

XS module: L<Crypt::TEA_XS>

=item L<Crypt::XXTEA_PP>

Author: L<JAHIY|https://metacpan.org/author/JAHIY>

XS module: L<Crypt::XXTEA_XS>

=item L<DDC::PP>

Author: L<MOOCOW|https://metacpan.org/author/MOOCOW>

XS module: L<DDC::XS>

=item L<Crypt::Skip32>

Author: L<ESH|https://metacpan.org/author/ESH>

XS module: L<Crypt::Skip32::XS>

=item L<Date::Calc>

Author: L<STBEY|https://metacpan.org/author/STBEY>

XS module: L<Date::Calc::XS>

PP module: L<Date::Calc::PP>

=item L<Directory::Iterator>

Author: L<SANBEG|https://metacpan.org/author/SANBEG>

XS module: L<Directory::Iterator::XS>

PP module: L<Directory::Iterator::PP>

=item L<Encode>

Author: L<DANKOGAI|https://metacpan.org/author/DANKOGAI>

XS module: L<Encode::XS>

=item L<Encoding::FixLatin>

Author: L<GRANTM|https://metacpan.org/author/GRANTM>

XS module: L<Encoding::FixLatin::XS>

=item L<File::MMagic>

Author: L<KNOK|https://metacpan.org/author/KNOK>

XS module: L<File::MMagic::XS>

=item L<Geo::Coordinates::UTM>

Author: L<GRAHAMC|https://metacpan.org/author/GRAHAMC>

XS module: L<Geo::Coordinates::UTM::XS>

=item L<Geo::Distance>

Author: L<BLUEFEET|https://metacpan.org/author/BLUEFEET>

XS module: L<Geo::Distance::XS>

=item L<Geo::Hash>

Author: L<ANDYA|https://metacpan.org/author/ANDYA>

XS module: L<Geo::Hash::XS>

=item L<HTTP::Headers::Fast>

Author: L<TOKUHIROM|https://metacpan.org/author/TOKUHIROM>

XS module: L<HTTP::Headers::Fast::XS>

=item L<HTTP::Parser::XS::PP>

Author: L<KAZUHO|https://metacpan.org/author/KAZUHO>

XS module: L<HTTP::Parser::XS>

=item L<Heap::Simple>

Author: L<THOSPEL|https://metacpan.org/author/THOSPEL>

XS module: L<Heap::Simple::XS>

=item L<Image::Info>

Author: L<SREZIC|https://metacpan.org/author/SREZIC>

XS module: L<Image::Info::XS>

=item L<JSON>

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

XS module: L<JSON::XS>

PP module: L<JSON::PP>

=item L<JSON::MaybeXS>

Author: L<ETHER|https://metacpan.org/author/ETHER>

XS module: L<Cpanel::JSON::XS>

=item L<Language::Befunge::Vector>

Author: L<JQUELIN|https://metacpan.org/author/JQUELIN>

XS module: L<Language::Befunge::Vector::XS>

=item L<Language::Befunge::Storage::Generic::Vec>

Author: L<JQUELIN|https://metacpan.org/author/JQUELIN>

XS module: L<Language::Befunge::Storage::Generic::Vec::XS>

=item L<List::BinarySearch>

Author: L<DAVIDO|https://metacpan.org/author/DAVIDO>

XS module: L<List::BinarySearch::XS>

=item L<List::Flatten>

Author: L<OBRADOVIC|https://metacpan.org/author/OBRADOVIC>

XS module: L<List::Flatten::XS>

=item L<List::MoreUtils>

Author: L<REHSACK|https://metacpan.org/author/REHSACK>

XS module: L<List::MoreUtils::XS>

=item L<List::SomeUtils>

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

XS module: L<List::SomeUtils::XS>

=item L<List::Util>

Author: L<PEVANS|https://metacpan.org/author/PEVANS>

XS module: L<List::Util::XS>

=item L<List::UtilsBy>

Author: L<PEVANS|https://metacpan.org/author/PEVANS>

XS module: L<List::UtilsBy::XS>

=item L<Math::Derivative>

Author: L<JGAMBLE|https://metacpan.org/author/JGAMBLE>

XS module: L<Math::Derivative_XS>

=item L<Math::Gauss>

Author: L<JANERT|https://metacpan.org/author/JANERT>

XS module: L<Math::Gauss::XS>

=item L<Math::Utils>

Author: L<JGAMBLE|https://metacpan.org/author/JGAMBLE>

XS module: L<Math::Utils::XS>

=item L<MaxMind::DB::Reader>

Author: L<MAXMIND|https://metacpan.org/author/MAXMIND>

XS module: L<MaxMind::DB::Reader::XS>

=item L<Mojo::Base>

Author: L<SRI|https://metacpan.org/author/SRI>

XS module: L<Mojo::Base::XS>

=item L<Moo>

Author: L<HAARG|https://metacpan.org/author/HAARG>

XS module: L<Class::XSAccessor>

=item L<Net::IP>

Author: L<MANU|https://metacpan.org/author/MANU>

XS module: L<Net::IP::XS>

=item L<Net::SNMP>

Author: L<DTOWN|https://metacpan.org/author/DTOWN>

XS module: L<Net::SNMP::XS>

=item L<Number::Closest>

Author: L<ACCARDO|https://metacpan.org/author/ACCARDO>

XS module: L<Number::Closest::XS>

=item L<Object::Adhoc>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

XS module: L<Class::XSAccessor>

=item L<Object::Accessor>

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

XS module: L<Object::Accessor::XS>

=item L<Object::Tiny>

Author: L<ETHER|https://metacpan.org/author/ETHER>

XS module: L<Object::Tiny::XS>

=item L<Object::Tiny::RW>

Author: L<SCHWIGON|https://metacpan.org/author/SCHWIGON>

XS module: L<Object::Tiny::RW::XS>

=item L<PPI>

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

XS module: L<PPI::XS>

=item L<Package::Stash>

Author: L<ETHER|https://metacpan.org/author/ETHER>

XS module: L<Package::Stash::XS>

=item L<Params::Validate>

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

XS module: L<Params::Validate::XS>

=item L<Path::Hilbert>

Author: L<PWBENNETT|https://metacpan.org/author/PWBENNETT>

XS module: L<Path::Hilbert::XS>

=item L<PerlX::ArraySkip>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

XS module: L<PerlX::ArraySkip::XS>

=item L<PerlX::Maybe>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

XS module: L<PerlX::Maybe::XS>

=item L<PPI>

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

XS module: L<PPI::XS>

=item L<Protocol::Redis>

Author: L<UNDEF|https://metacpan.org/author/UNDEF>

XS module: L<Protocol::Redis::XS>

=item L<Readonly>

Author: L<SANKO|https://metacpan.org/author/SANKO>

XS module: L<Readonly::XS>

=item L<Ref::Util>

Author: L<ARC|https://metacpan.org/author/ARC>

XS module: L<Ref::Util::XS>

=item L<Set::IntSpan::Fast>

Author: L<ANDYA|https://metacpan.org/author/ANDYA>

XS module: L<Set::IntSpan::Fast::XS>

=item L<Set::Product>

Author: L<GRAY|https://metacpan.org/author/GRAY>

XS module: L<Set::Product::XS>

=item L<SOAP::WSDL::Deserializer::XSD>

Author: L<SWALTERS|https://metacpan.org/author/SWALTERS>

XS module: L<SOAP::WSDL::Deserializer::XSD_XS>

=item L<Sort::Naturally>

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

XS module: L<Sort::Naturally::XS>

=item L<String::Numeric>

Author: L<CHANSEN|https://metacpan.org/author/CHANSEN>

XS module: L<String::Numeric::XS>

=item L<Template::Alloy>

Author: L<RHANDOM|https://metacpan.org/author/RHANDOM>

XS module: L<Template::Alloy::XS>

=item L<Template::Stash>

Author: L<ABW|https://metacpan.org/author/ABW>

XS module: L<Template::Stash::XS>

=item L<Text::CSV>

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

XS module: L<Text::CSV_XS>

=item L<Text::Levenshtein::Damerau>

Author: L<UGEXE|https://metacpan.org/author/UGEXE>

XS module: L<Text::Levenshtein::Damerau::XS>

=item L<Time::Format>

Author: L<ROODE|https://metacpan.org/author/ROODE>

XS module: L<Time::Format_XS>

=item L<Type::Params>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

XS module: L<Class::XSAccessor>

=item L<Type::Tiny>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

XS module: L<Type::Tiny::XS>

=item L<Tree::Object>

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

XS module: L<Tree::ObjectXS>

=item L<URL::Encode>

Author: L<CHANSEN|https://metacpan.org/author/CHANSEN>

XS module: L<URL::Encode::XS>

=item L<Unix::Uptime::BSD>

Author: L<PIOTO|https://metacpan.org/author/PIOTO>

XS module: L<Unix::Uptime::BSD::XS>

=item L<XML::CompactTree>

Author: L<PAJAS|https://metacpan.org/author/PAJAS>

XS module: L<XML::CompactTree::XS>

=item L<YAML::PP>

Author: L<TINITA|https://metacpan.org/author/TINITA>

XS module: L<YAML::XS>

=item L<match::simple>

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

XS module: L<match::simple::XS>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n XSVersions

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries XSVersions | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=XSVersions -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::XSVersions -E'say $_->{module} for @{ $Acme::CPANModules::XSVersions::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-XSVersions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-XSVersions>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

L<Missing::XS>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-XSVersions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
