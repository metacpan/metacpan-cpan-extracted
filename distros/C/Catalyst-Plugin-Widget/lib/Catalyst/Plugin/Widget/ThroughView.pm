package Catalyst::Plugin::Widget::ThroughView;

=head1 NAME

Catalyst::Plugin::Widget::ThroughView - Widget rendered through L<Catalyst::View>

=cut

use Carp qw( croak );
use Moose::Role;

requires 'context';


=head1 SYNOPSIS

  package MyApp::Widget::Sample;
  use Moose;
  extends 'Catalyst::Plugin::Widget::Base';
  with    'Catalyst::Plugin::Widget::ThroughView';

  has '+view' => ( is => 'rw', default => 'MyView' );

  1;


=head1 METHODS

=head2 extension

Returns default extension for template file name. Defaults to assume '.tt'
for view inherited from L<Catalyst::View::TT>, '.tx' for
L<Catalyst::View::Xslate> descendants and '' for remainders.

=cut

has extension => ( is => 'rw', isa => 'Str', lazy => 1,
	builder => '_extension' );

# builder for 'extension'.
sub _extension {
	my ( $self ) = @_;

	$self->view_instance->isa('Catalyst::View::TT') &&
		'.tt' ||
	$self->view_instance->isa('Catalyst::View::Xslate') &&
		'.tx' ||
	'';
}


=head2 populate_stash

Fill stash with required data. Can be altered in descendants with L<Moose>
method modifiers.

=cut

sub populate_stash {
	my $self = shift;

	$self->context->stash( self => $self );
	$self->context->stash( template => $self->template )
		if $self->template;
}


=head2 render

Overriden method from L<Catalyst::Plugin::Widget::Base>.

=cut

sub render {
	my ( $self ) = @_;

	# we have to modify Moose internal storage
	local $self->context->{ stash } = {};
	local $self->context->res->{ body };

	$self->populate_stash;

	# rendering
	$self->context->forward( $self->view_instance );

	return $self->context->res->body;
}


=head2 template

Returns name of template file using for widget rendering.
Default is lower cased widget class name remaining (after word 'Widget')
with all '::' replaced with '/' and 'extension' appended.

=cut

has template => ( is => 'rw', isa => 'Str | Undef', lazy => 1,
	builder => '_template' );

# builder for 'template'.
sub _template {
	my ( $self ) = @_;

	( my $t = ref $self ) =~ s/.*::(Widget::.+)/$1/;
	$t =~ s|::|/|g;

	return lc($t) . $self->extension;
}


=head2 view

Returns L<Catalyst::View> (name or instance) for widget rendering.

=cut

has view => ( is => 'rw', isa => 'Catalyst::View | Str', required => 1 );


=head2 view_instance

Returns L<Catalyst::View> instance for widget rendering.

=cut

has view_instance => ( is => 'rw', isa => 'Catalyst::View', init_arg => undef,
	lazy => 1, builder => '_view_instance' );

# builder for 'view_instance'.
sub _view_instance {
	my $self = shift;

	ref $self->view ?
		$self->view :
		$self->context->view( $self->view ) or
	croak "No such view: '" . $self->view ."'";
}


1;

