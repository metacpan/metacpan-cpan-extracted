use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

sub ACTION_build
{
	my $self = shift;
	$self->SUPER::ACTION_build(@_);
	$self->run_perl_script('scripts/copy.config.pl');
}
EOF

$class -> new
(
	module_name    => 'Benchmark::Featureset::LocaleCountry',
	license        => 'artistic',
	dist_abstract  => 'Compare Locale::Codes, Locale::Country::Multilingual, WWW::Scraper::Wikipedia::ISO3166, etc',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
	Test::More => 0.94,
	Test::Pod  => 1.44,
	},
	configure_requires =>
	{
		Module::Build => 0.3800,
	},
	requires =>
	{
	Config::Tiny                               => 2.13,
	Date::Simple                               => 3.03,
	File::Copy                                 => 2.18,
	File::HomeDir                              => 0.97,
	Hash::FieldHash                            => 0.10,
	Locale::Country                            => 3.16,
	Locale::Country::Multilingual              => 0.23,
	Locale::Geocode                            => 1.2,
	Locale::Object                             => 0.78,
	Locale::Object::DB                         => 0.78,
	Locale::SubCountry                         => 1.46,
	Path::Class                                => 0.23,
	Set::Array                                 => 0.22,
	strict                                     => 1.04,
	Test::More                                 => 0.94,
	Test::Pod                                  => 1.44,
	Text::Xslate                               => 1.0007,
	warnings                                   => 1.12,
	WWW::Scraper::Wikipedia::ISO3166::Database => 1.01,
	},
) -> create_build_script();
