use Module::Build;

my($builder) = Module::Build -> new
(
 module_name    => 'Business::AU::Ledger',
 license        => 'artistic',
 dist_abstract  => 'A simple, web-based, payments/receipts manager',
 dist_author    => 'Ron Savage <ron@savage.net.au>',
 build_requires =>
 {
	 Test::More => 0.94,
	 Test::Pod  => 1.41,
 },
 requires =>
 {
	 CGI::Application                 => 4.31,
	 CGI::Session                     => 4.42,
	 Config::Tiny                     => 2.12,
	 DBIx::Admin::CreateTable         => 2.04,
	 DBIx::Simple                     => 1.32,
	 Data::FormValidator              => 4.65,
	 Data::FormValidator::Constraints => 4.65,
	 Date::Simple                     => 3.03,
	 Encode                           => 2.39,
	 FindBin::Real                    => 1.05,
	 Hash::FieldHash                  => 0.10,
	 HTML::Template                   => 2.9,
	 JSON::XS                         => 2.27,
	 Log::Dispatch                    => 2.26,
	 Log::Dispatch::DBI               => 0.02,
	 Moose                            => 0.98,
	 namespace::autoclean             => 0.09,
	 Regexp::Common                   => 2010010201,
 },
);

$builder -> add_build_element('conf');
$builder -> create_build_script();

