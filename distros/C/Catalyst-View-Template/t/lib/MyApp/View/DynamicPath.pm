use strict; use warnings;

package MyApp::View::DynamicPath;

use MRO::Compat ();
use Template::Provider ();

use Catalyst::View::Template ();
BEGIN { our @ISA = 'Catalyst::View::Template' }

{
	my $dynamic_path = bless {}, do {
		package MyApp::Template::DynamicPath;
		sub paths { $_[0]{'paths'} || [] }
		__PACKAGE__
	};

	sub dynamic_path { $dynamic_path }
}

sub new_template {
	my ( $self, $c, $config ) = ( shift, @_ );
	$config->{'INCLUDE_PATH'} = Template::Provider->new( $config )->include_path;
	unshift @{ $config->{'INCLUDE_PATH'} }, $self->dynamic_path;
	$self->next::method( @_ );
}

sub render {
	my ( $self, $c ) = ( shift, @_ );
	local $self->dynamic_path->{'paths'} = $c->stash->{'additional_template_paths'};
	$self->next::method( @_ );
}

__PACKAGE__->config(
	template_ext => '.tt',
	PRE_CHOMP    => 1,
	POST_CHOMP   => 1,
);

1;
