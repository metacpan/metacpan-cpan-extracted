use strict; use warnings;

package Catalyst::View::Template;

our $VERSION = '1.101';

use MRO::Compat ();
use Catalyst::Utils ();

use Catalyst::Component ();
our @ISA = 'Catalyst::Component';

__PACKAGE__->mk_accessors( my @attribute = qw( class_name template_ext content_type template ) );

__PACKAGE__->config(
	class_name   => 'Template',
	template_ext => '',
	content_type => 'text/html; charset=utf-8',
	EVAL_PERL    => 0,
	ENCODING     => 'UTF-8',
	# cannot set INCLUDE_PATH before the app class is set up...
);

sub new {
	my ( $class, $c, $args ) = ( shift, @_ );
	my $self = $class->next::method( @_ );
	my %config = %$self;
	delete @config{ 'catalyst_component_name', @attribute };
	$config{'INCLUDE_PATH'} = [ $c->path_to( 'root' ) ] unless exists $config{'INCLUDE_PATH'};
	$self->template( $self->new_template( $c, \%config ) );
	$self;
}

sub new_template {
	my ( $self, $c, $config ) = ( shift, @_ );
	Catalyst::Utils::ensure_class_loaded $self->class_name;
	$self->class_name->new( $config )
		or die $self->class_name->error;
}

sub process {
	my ( $self, $c ) = ( shift, @_ );

	my %vars = %{ $c->stash };
	my $template = $c->stash->{'template'} || $c->action->reverse;

	my $output;
	$self->render          ( $c, $template, \%vars, \$output )
	? $self->process_output( $c, $template, \%vars, \$output )
	: $self->process_error ( $c, $template, \%vars, )
}

sub render {
	my ( $self, $c, $template, $vars, $output_ref ) = ( shift, @_ );
	$template .= $self->template_ext unless 'SCALAR' eq ref $template;
	$c->log->debug( sprintf 'Rendering template "%s"', ref $template ? "\\\Q$$template\E" : $template )
		if $c->debug;
	$self->template->process( $template, $vars, $output_ref );
}

sub process_output {
	my ( $self, $c, $template, $vars, $output_ref ) = ( shift, @_ );
	$c->res->content_type( $self->content_type ) unless $c->res->content_type;
	$c->res->body( $$output_ref );
	1;
}

sub process_error {
	my ( $self, $c, $template, $vars ) = ( shift, @_ );
	my $error = qq[Couldn't render template "$template": ] . $self->template->error;
	$c->log->error( $error );
	$c->error( $error );
	!1;
}

1;
