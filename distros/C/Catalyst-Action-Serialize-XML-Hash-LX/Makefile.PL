use inc::Module::Install 0.79;

name     'Catalyst-Action-Serialize-XML-Hash-LX';
all_from 'lib/Catalyst/Action/Serialize/XML/Hash/LX.pm';
version   my $v = '0.06';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';
build_requires 'lib::abs', '0.90';

requires 'XML::Hash::LX' => '0.06';
requires 'Catalyst::Action' => '0';

provides 'Catalyst::Action::Deserialize::XML::Hash::LX' => {
	version => $v,
	file    => 'lib/Catalyst/Action/Deserialize/XML/Hash/LX.pm',
};
provides 'Catalyst::Action::Serialize::XML::Hash::LX' => {
	version => $v,
	file    => 'lib/Catalyst/Action/Serialize/XML/Hash/LX.pm',
};

auto_install;

WriteAll;
