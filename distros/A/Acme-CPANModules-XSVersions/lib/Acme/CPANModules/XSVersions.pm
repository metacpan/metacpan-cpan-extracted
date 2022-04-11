package Acme::CPANModules::XSVersions;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-XSVersions'; # DIST
our $VERSION = '0.003'; # VERSION

our $LIST = {
    summary => 'List of XS versions of Perl modules',
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
        {module => 'JSON::PP', pp_module=>'JSON', xs_module => 'JSON::XS'},
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
        {module => 'Net::IP', xs_module => 'Net::IP::XS'},
        {module => 'Net::SNMP', xs_module => 'Net::SNMP::XS'},
        {module => 'Number::Closest', xs_module => 'Number::Closest::XS'},
        {module => 'Object::Tiny', xs_module => 'Object::Tiny::XS'},
        {module => 'Object::Tiny::RW', xs_module => 'Object::Tiny::RW::XS'},
        {module => 'PPI', xs_module => 'PPI::XS'},
        {module => 'Package::Stash', xs_module => 'Package::Stash::XS'},
        {module => 'Params::Validate', xs_module => 'Params::Validate::XS'},
        {module => 'Path::Hilbert', xs_module => 'Path::Hilbert::XS'},
        {module => 'PerlX::ArraySkip', xs_module => 'PerlX::ArraySkip::XS'},
        {module => 'PerlX::Maybe', xs_module => 'PerlX::Maybe::XS'},
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
# ABSTRACT: List of XS versions of Perl modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::XSVersions - List of XS versions of Perl modules

=head1 VERSION

This document describes version 0.003 of Acme::CPANModules::XSVersions (from Perl distribution Acme-CPANModules-XSVersions), released on 2022-03-18.

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

=item * L<Algorithm::Diff> - Compute `intelligent' differences between two files / lists

Author: L<RJBS|https://metacpan.org/author/RJBS>

=item * L<Algorithm::LUHN> - Calculate the Modulus 10 Double Add Double checksum

Author: L<NEILB|https://metacpan.org/author/NEILB>

=item * L<Algorithm::PageRank> - Calculate PageRank in Perl

Author: L<XERN|https://metacpan.org/author/XERN>

=item * L<Algorithm::RectanglesContainingDot> - find rectangles containing a given dot

Author: L<SALVA|https://metacpan.org/author/SALVA>

=item * L<Bytes::Random> - Perl extension to generate random bytes.

Author: L<JOHND|https://metacpan.org/author/JOHND>

=item * L<Class::Accessor::Fast> - Faster, but less expandable, accessors

Author: L<KASEI|https://metacpan.org/author/KASEI>

=item * L<Class::C3> - A pragma to use the C3 method resolution order algorithm

Author: L<HAARG|https://metacpan.org/author/HAARG>

=item * L<Class::Load> - A working (require "Class::Name") and more

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item * L<Convert::Bencode> - Functions for converting to/from bencoded strings

Author: L<ORCLEV|https://metacpan.org/author/ORCLEV>

=item * L<Crypt::Passwd> - Perl wrapper around the UFC Crypt

Author: L<LUISMUNOZ|https://metacpan.org/author/LUISMUNOZ>

=item * L<Crypt::TEA_PP> - Pure Perl Implementation of the Tiny Encryption Algorithm

Author: L<JAHIY|https://metacpan.org/author/JAHIY>

=item * L<Crypt::XXTEA_PP> - Pure Perl Implementation of Corrected Block Tiny Encryption Algorithm

Author: L<JAHIY|https://metacpan.org/author/JAHIY>

=item * L<DDC::PP> - pure-perl DDC::XS clone: constants

Author: L<MOOCOW|https://metacpan.org/author/MOOCOW>

=item * L<Crypt::Skip32> - 32-bit block cipher based on Skipjack

Author: L<ESH|https://metacpan.org/author/ESH>

=item * L<Date::Calc>

Author: L<STBEY|https://metacpan.org/author/STBEY>

=item * L<Directory::Iterator> - Simple, efficient recursive directory listing

Author: L<SANBEG|https://metacpan.org/author/SANBEG>

=item * L<Encode> - character encodings in Perl

Author: L<DANKOGAI|https://metacpan.org/author/DANKOGAI>

=item * L<Encoding::FixLatin> - takes mixed encoding input and produces UTF-8 output

Author: L<GRANTM|https://metacpan.org/author/GRANTM>

=item * L<File::MMagic> - Guess file type

Author: L<KNOK|https://metacpan.org/author/KNOK>

=item * L<Geo::Coordinates::UTM> - Perl extension for Latitiude Longitude conversions.

Author: L<GRAHAMC|https://metacpan.org/author/GRAHAMC>

=item * L<Geo::Distance> - Calculate distances and closest locations. (DEPRECATED)

Author: L<BLUEFEET|https://metacpan.org/author/BLUEFEET>

=item * L<Geo::Hash> - Encode / decode geohash.org locations.

Author: L<ANDYA|https://metacpan.org/author/ANDYA>

=item * L<HTTP::Headers::Fast> - faster implementation of HTTP::Headers

Author: L<TOKUHIROM|https://metacpan.org/author/TOKUHIROM>

=item * L<HTTP::Parser::XS::PP>

Author: L<KAZUHO|https://metacpan.org/author/KAZUHO>

=item * L<Heap::Simple> - Fast and easy to use classic heaps

Author: L<THOSPEL|https://metacpan.org/author/THOSPEL>

=item * L<Image::Info> - Extract meta information from image files

Author: L<SREZIC|https://metacpan.org/author/SREZIC>

=item * L<JSON::PP> - JSON::XS compatible pure-Perl module.

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

=item * L<Language::Befunge::Vector> - an opaque, N-dimensional vector class

Author: L<JQUELIN|https://metacpan.org/author/JQUELIN>

=item * L<Language::Befunge::Storage::Generic::Vec> - a generic N-dimensional LaheySpace

Author: L<JQUELIN|https://metacpan.org/author/JQUELIN>

=item * L<List::BinarySearch> - Binary Search within a sorted array.

Author: L<DAVIDO|https://metacpan.org/author/DAVIDO>

=item * L<List::Flatten> - Interpolate array references in a list

Author: L<OBRADOVIC|https://metacpan.org/author/OBRADOVIC>

=item * L<List::MoreUtils> - Provide the stuff missing in List::Util

Author: L<REHSACK|https://metacpan.org/author/REHSACK>

=item * L<List::SomeUtils> - Provide the stuff missing in List::Util

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

=item * L<List::Util> - A selection of general-utility list subroutines

Author: L<PEVANS|https://metacpan.org/author/PEVANS>

=item * L<List::UtilsBy> - higher-order list utility functions

Author: L<PEVANS|https://metacpan.org/author/PEVANS>

=item * L<Math::Derivative> - Numeric 1st and 2nd order differentiation

Author: L<JGAMBLE|https://metacpan.org/author/JGAMBLE>

=item * L<Math::Gauss> - Gaussian distribution function and its inverse

Author: L<JANERT|https://metacpan.org/author/JANERT>

=item * L<Math::Utils> - Useful mathematical functions not in Perl.

Author: L<JGAMBLE|https://metacpan.org/author/JGAMBLE>

=item * L<MaxMind::DB::Reader> - Read MaxMind DB files and look up IP addresses

Author: L<MAXMIND|https://metacpan.org/author/MAXMIND>

=item * L<Mojo::Base> - Minimal base class for Mojo projects

Author: L<SRI|https://metacpan.org/author/SRI>

=item * L<Net::IP> - Perl extension for manipulating IPv4/IPv6 addresses

Author: L<MANU|https://metacpan.org/author/MANU>

=item * L<Net::SNMP> - Object oriented interface to SNMP 

Author: L<DTOWN|https://metacpan.org/author/DTOWN>

=item * L<Number::Closest> - Find number(s) closest to a number in a list of numbers

Author: L<ACCARDO|https://metacpan.org/author/ACCARDO>

=item * L<Object::Tiny> - Class building as simple as it gets

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item * L<Object::Tiny::RW> - Class building as simple as it gets (with rw accessors)

Author: L<SCHWIGON|https://metacpan.org/author/SCHWIGON>

=item * L<PPI> - Parse, Analyze and Manipulate Perl (without perl)

Author: L<OALDERS|https://metacpan.org/author/OALDERS>

=item * L<Package::Stash> - Routines for manipulating stashes

Author: L<ETHER|https://metacpan.org/author/ETHER>

=item * L<Params::Validate> - Validate method/function parameters

Author: L<DROLSKY|https://metacpan.org/author/DROLSKY>

=item * L<Path::Hilbert> - A no-frills converter between 1D and 2D spaces using the Hilbert curve

Author: L<PWBENNETT|https://metacpan.org/author/PWBENNETT>

=item * L<PerlX::ArraySkip> - sub { shift; @_ }

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item * L<PerlX::Maybe> - return a pair only if they are both defined

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item * L<Protocol::Redis> - Redis protocol parser/encoder with asynchronous capabilities.

Author: L<UNDEF|https://metacpan.org/author/UNDEF>

=item * L<Readonly> - Facility for creating read-only scalars, arrays, hashes

Author: L<SANKO|https://metacpan.org/author/SANKO>

=item * L<Ref::Util> - Utility functions for checking references

Author: L<ARC|https://metacpan.org/author/ARC>

=item * L<Set::IntSpan::Fast> - Fast handling of sets containing integer spans.

Author: L<ANDYA|https://metacpan.org/author/ANDYA>

=item * L<Set::Product> - generates the cartesian product of a set of lists

Author: L<GRAY|https://metacpan.org/author/GRAY>

=item * L<SOAP::WSDL::Deserializer::XSD> - Deserializer SOAP messages into SOAP::WSDL::XSD::Typelib:: objects

Author: L<SWALTERS|https://metacpan.org/author/SWALTERS>

=item * L<Sort::Naturally>

Author: L<BINGOS|https://metacpan.org/author/BINGOS>

=item * L<String::Numeric> - Determine whether a string represents a numeric value

Author: L<CHANSEN|https://metacpan.org/author/CHANSEN>

=item * L<Template::Alloy>

Author: L<RHANDOM|https://metacpan.org/author/RHANDOM>

=item * L<Template::Stash> - Magical storage for template variables

Author: L<ATOOMIC|https://metacpan.org/author/ATOOMIC>

=item * L<Text::CSV> - comma-separated values manipulator (using XS or PurePerl)

Author: L<ISHIGAKI|https://metacpan.org/author/ISHIGAKI>

=item * L<Text::Levenshtein::Damerau> - Damerau Levenshtein edit distance.

Author: L<UGEXE|https://metacpan.org/author/UGEXE>

=item * L<Time::Format> - Easy-to-use date/time formatting.

Author: L<ROODE|https://metacpan.org/author/ROODE>

=item * L<Type::Tiny> - tiny, yet Moo(se)-compatible type constraint

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item * L<Tree::Object> - Generic tree objects

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<URL::Encode>

Author: L<CHANSEN|https://metacpan.org/author/CHANSEN>

=item * L<Unix::Uptime::BSD> - BSD implementation of Unix::Uptime (for Darwin, DragonFly, and *BSD)

Author: L<PIOTO|https://metacpan.org/author/PIOTO>

=item * L<XML::CompactTree> - builder of compact tree structures from XML documents

Author: L<PAJAS|https://metacpan.org/author/PAJAS>

=item * L<YAML::PP> - YAML 1.2 processor

Author: L<TINITA|https://metacpan.org/author/TINITA>

=item * L<match::simple> - simplified clone of smartmatch operator

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-XSVersions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
