package Acme::CPANModules::XSVersions;

our $DATE = '2019-01-15'; # DATE
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'XS versions of Perl modules',
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
# ABSTRACT: XS versions of Perl modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::XSVersions - XS versions of Perl modules

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::XSVersions (from Perl distribution Acme-CPANModules-XSVersions), released on 2019-01-15.

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

XS versions of Perl modules.

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

=head1 INCLUDED MODULES

=over

=item * L<Algorithm::Diff>

=item * L<Algorithm::LUHN>

=item * L<Algorithm::PageRank>

=item * L<Algorithm::RectanglesContainingDot>

=item * L<Bytes::Random>

=item * L<Class::Accessor::Fast>

=item * L<Class::C3>

=item * L<Class::Load>

=item * L<Convert::Bencode>

=item * L<Crypt::Passwd>

=item * L<Crypt::TEA_PP>

=item * L<Crypt::XXTEA_PP>

=item * L<DDC::PP>

=item * L<Crypt::Skip32>

=item * L<Date::Calc>

=item * L<Directory::Iterator>

=item * L<Encode>

=item * L<Encoding::FixLatin>

=item * L<File::MMagic>

=item * L<Geo::Coordinates::UTM>

=item * L<Geo::Distance>

=item * L<Geo::Hash>

=item * L<HTTP::Headers::Fast>

=item * L<HTTP::Parser::XS::PP>

=item * L<Heap::Simple>

=item * L<Image::Info>

=item * L<JSON::PP>

=item * L<Language::Befunge::Vector>

=item * L<Language::Befunge::Storage::Generic::Vec>

=item * L<List::BinarySearch>

=item * L<List::Flatten>

=item * L<List::MoreUtils>

=item * L<List::SomeUtils>

=item * L<List::Util>

=item * L<List::UtilsBy>

=item * L<Math::Derivative>

=item * L<Math::Gauss>

=item * L<Math::Utils>

=item * L<MaxMind::DB::Reader>

=item * L<Mojo::Base>

=item * L<Net::IP>

=item * L<Net::SNMP>

=item * L<Number::Closest>

=item * L<Object::Tiny>

=item * L<Object::Tiny::RW>

=item * L<PPI>

=item * L<Package::Stash>

=item * L<Params::Validate>

=item * L<Path::Hilbert>

=item * L<PerlX::ArraySkip>

=item * L<PerlX::Maybe>

=item * L<Protocol::Redis>

=item * L<Readonly>

=item * L<Ref::Util>

=item * L<Set::IntSpan::Fast>

=item * L<Set::Product>

=item * L<SOAP::WSDL::Deserializer::XSD>

=item * L<Sort::Naturally>

=item * L<String::Numeric>

=item * L<Template::Alloy>

=item * L<Template::Stash>

=item * L<Text::CSV>

=item * L<Text::Levenshtein::Damerau>

=item * L<Time::Format>

=item * L<Type::Tiny>

=item * L<Tree::Object>

=item * L<URL::Encode>

=item * L<Unix::Uptime::BSD>

=item * L<XML::CompactTree>

=item * L<YAML::PP>

=item * L<match::simple>

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-XSVersions>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-XSVersions>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-XSVersions>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
