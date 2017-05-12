package Catalyst::Plugin::Widget::WithResultSet;

=head1 NAME

Catalyst::Plugin::Widget::WithResultSet - Widget having DBIx::ResultSet

=cut

use Carp qw( croak );
use Moose::Role;
use Moose::Util::TypeConstraints;

requires 'context';


=head1 SYNOPSIS

  package MyApp::Widget::Sample;
  use Moose;
  extends 'Catalyst::Plugin::Widget::Base';
  with    'Catalyst::Plugin::Widget::WithResultSet';

  has '+rs' => ( is => 'rw', default => 'Schema::User' );

  1;


=head1 METHODS

=head2 rs

L<DBIx::Class::ResultSet> instance or string shortcut for
L<Catalyst-Model-DBIC-Schema>.

=cut

subtype __PACKAGE__ . '::DBIx::Class::ResultSet'
	=> as 'Object'
	=> where { $_->isa('DBIx::Class::ResultSet') }
;

has rs => ( is => 'rw', isa => __PACKAGE__ . '::DBIx::Class::ResultSet | Str',
	required => 1 );


=head2 order_by

Default ordering for 'resultset' (if any specified).

=cut

has order_by => ( is => 'rw', isa => 'Str | Undef' );


=head2 resultset

L<DBIx::Class::ResultSet> instance.

=cut

has resultset => ( is => 'rw', isa => __PACKAGE__ . '::DBIx::Class::ResultSet',
	init_arg => undef, lazy => 1, builder  => '_resultset' );

# builder for 'resultset'.
sub _resultset {
	my $self = shift;

	my $rs = ref $self->rs ?
		$self->rs : $self->context->model( $self->rs ) or
		croak "No such resultset: '" . $self->rs ."'";
	
	$rs = $rs->search( undef, { order_by => $self->order_by } )
		if $self->order_by && ! $rs->is_ordered;
	
	return $rs;
}


1;

