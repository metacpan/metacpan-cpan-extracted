use v5.20;
use strict;
use warnings;
use experimental qw( signatures lexical_subs postderef );

package App::Chit::Util;

use AI::Chat;
use Carp qw( croak );
use Cwd qw( getcwd );
use Path::Tiny qw( path );
use YAML::XS qw( LoadFile DumpFile );

use constant CHIT_FILENAME => '.chit.yml';
use constant CHIT_KEY_VAR  => 'OPENAI_API_KEY';

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001001';

sub is_chit_dir ( $dir ) {
	my $path = path( $dir );
	my $file = $path->child( CHIT_FILENAME );
	croak "Chit config file was unexpectedly a directory: $file" if $file->is_dir;
	return $file->is_file;
}

sub find_chit_dir ( $starting_from=getcwd() ) {
	my $path = path( $starting_from );
	while ( not is_chit_dir( $path ) ) {
		return undef if $path->is_rootdir;
		$path = $path->parent;
	}
	is_chit_dir( $path ) ? $path : undef;
}

sub load_chit ( $dir ) {
	my $path = path( $dir );
	is_chit_dir( $path ) or croak "Not a chit dir: $dir";
	my ( $chit ) = LoadFile( $path->child( CHIT_FILENAME )->stringify );
	$chit->{model}       //= 'gpt-4o-mini';
	$chit->{temperature} //= 0.99;
	$chit->{role}        //= "You are a helpful assistant, valued for your precise, accurate, and concise answers.";
	$chit->{history}     //= 100;
	return $chit;
}

sub save_chit ( $dir, $chit ) {
	my $path = path( $dir );
	if ( $chit->{chat} ) {
		$chit->{history} //= 100;
		shift @{ $chit->{chat} } while @{ $chit->{chat} } > $chit->{history};
	}
	return DumpFile( $path->child( CHIT_FILENAME )->stringify, $chit );
}

sub chatgpt ( $chit ) {
	return AI::Chat->new(
		key     => $ENV{ CHIT_KEY_VAR() },
		api     => 'OpenAI',
		model   => $chit->{model},
		role    => $chit->{role},
	);
}

1;

