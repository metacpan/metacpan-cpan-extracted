use strictures 2;

use Test::Roo;
use App::Licensecheck;

has encoding => ( is => 'ro' );
has license  => ( is => 'ro', required => 1 );
has corpus   => ( is => 'ro' );

sub _build_description { return shift->license }

test "Parse corpus" => sub {
	my $self = shift;

	my $app = App::Licensecheck->new;
	$app->lines(0);
	$app->deb_fmt(1);
	$app->encoding( $self->encoding ) if $self->encoding;

	foreach (
		ref( $self->corpus ) eq 'ARRAY' ? @{ $self->corpus } : $self->corpus )
	{
		my ( $license, $copyright ) = $app->parse("t/fedora/$_");
		is( $license, $self->license, "Corpus file $_" );
	}
};

run_me(
	{   license =>
			'Adobe-Glyph and/or BSL and/or DSDP and/or Expat and/or ICU and/or MIT-CMU and/or MIT-CMU~warranty and/or MIT-enna and/or MIT-feh and/or MIT~old and/or MIT~oldstyle and/or MIT~oldstyle~disclaimer and/or PostgreSQL and/or bdwgc',
		corpus => 'MIT'
	}
);
TODO: {
	local $TODO = 'not all variants covered yet';
	run_me(
		{   license => 'an even longer list...',
			corpus  => 'MIT'
		}
	);
}

done_testing;
