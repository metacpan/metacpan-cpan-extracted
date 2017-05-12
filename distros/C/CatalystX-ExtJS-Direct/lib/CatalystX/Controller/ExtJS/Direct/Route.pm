#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Controller::ExtJS::Direct::Route;
$CatalystX::Controller::ExtJS::Direct::Route::VERSION = '2.1.5';
#ABSTRACT: Ext.Direct route object
use Moose;

has 'arguments' => ( is => 'rw', isa => 'Int', lazy_build => 1 );
has 'action'     => ( is => 'ro', required   => 1 );
has 'name'       => ( is => 'rw', lazy_build => 1 );
has 'dispatcher' => ( is => 'rw', weak_ref   => 1 );
has 'form_handler' => ( is => 'rw', default => 0 );

sub _build_name {
    my ($self) = @_;
    return $self->action->attributes->{Direct}->[0] || $self->action->name;
}

sub _build_arguments {
	my ($self) = @_;
    return $self->action->attributes->{DirectArgs}->[0] || 0;
}

sub build_api {
    my ($self) = @_;
    my $fh = $self->form_handler || exists $self->action->attributes->{FormHandler};
    return { name => $self->name, len => $self->arguments + 0, $fh ? ( formHandler => \1 ) : () };
}

sub build_url {
    my ( $self, $data ) = @_;
    return $self->action;
}

sub build {
    return shift->new(@_);
}

sub request {
	my ($self, $req) = @_;
    return ( data => $req->{data});
}

sub prepare_request {
	shift;
	return @_;
}

package CatalystX::Controller::ExtJS::Direct::Route::Chained;
$CatalystX::Controller::ExtJS::Direct::Route::Chained::VERSION = '2.1.5';
use Moose::Role;

sub _build_arguments {
    my ($self) = @_;
    my $action = $self->action;
    my $len = $action->attributes->{Args}[0] || 0;
    my $parent = $action;
    while (
        $parent->attributes->{Chained}
        && (
            $parent = $self->dispatcher->get_action_by_path(
                $parent->attributes->{Chained}->[0]
            )
        )
      )
    {

        $len += $parent->attributes->{CaptureArgs}[0];
    }
    $len +=  $self->action->attributes->{DirectArgs}->[0] 
        if($self->action->attributes->{DirectArgs});
    return $len || 0;
}

sub build_url {
    my ( $route, $data ) = @_;
    my @data = @{ $data || [] };
	@data = grep { !ref $_ } @data;
	my $captures_length =
      defined $route->action->attributes->{Args}->[0]
      ? $route->arguments - $route->action->attributes->{Args}->[0]
      : 0;
    my @captures = splice( @data, 0, $captures_length );
    return $route->action, \@captures, \@data;
}

package CatalystX::Controller::ExtJS::Direct::Route::REST;
$CatalystX::Controller::ExtJS::Direct::Route::REST::VERSION = '2.1.5';
use Moose::Role;

has 'crud_action' => ( is => 'rw', isa => 'Str' );

has 'crud_methods' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            create  => 'POST',
            update  => 'PUT',
            read    => 'GET',
            destroy => 'DELETE',
        };
    }
);

around '_build_arguments' => sub {
    my ( $orig, $self, $args ) = @_;
    my $arguments = $self->$orig();
    $arguments++;
    return $arguments;
};

sub _build_name {
    my ($self) = @_;
    return $self->crud_action;
}

sub build {
    my ( $class, $args ) = @_;
    my @routes;
    foreach my $action (qw(create read update destroy)) {
        push( @routes, $class->new( { %$args, crud_action => $action } ) );
    }
    push( @routes, 
        CatalystX::Controller::ExtJS::Direct::Route->new( { %$args, name => 'submit', form_handler => 1 } ) );
    return @routes;
}

around 'request' => sub {
    my ($orig, $self, $req)   = @_;
    my %params = $self->$orig($req);
    return (
        %params,
		method        => $self->crud_methods->{ $self->crud_action },
        accepted_content_types => ['application/json'],
        content_types => ['application/json'],
        content_type => 'application/json'
    );

};

# split a request in multiple requests if they affect more than one record

sub prepare_request {
	my ($self, $req) = @_;
	$req->{data} = [$req->{data}] unless(ref $req->{data} eq 'ARRAY');
	unless (@{$req->{data} || []}) {
		return $req;
	}
	my $read_or_destroy = $self->crud_action eq 'read' || $self->crud_action eq 'destroy';
    my $create = $self->crud_action eq 'create';
    my $data = $req->{data}->[-1];
	if(ref $data eq 'HASH' && keys %$data == 1) {
		my ($key) =  keys %$data;
		if(ref $data->{$key} eq 'HASH' && !$read_or_destroy) {
			$req->{data} = $data->{$key};
		} elsif ( ref $data->{$key} eq 'ARRAY' ) {
			return map { {%$req, data => $_} } @{$data->{$key}};
		} elsif ((!ref $data->{$key} || !$read_or_destroy) && !$create) {
			$req->{data} = $data->{$key};
		}
	}
	return $req;
}

package CatalystX::Controller::ExtJS::Direct::Route::REST::ExtJS;
$CatalystX::Controller::ExtJS::Direct::Route::REST::ExtJS::VERSION = '2.1.5';
use Moose::Role;

package CatalystX::Controller::ExtJS::Direct::Route::Factory;
$CatalystX::Controller::ExtJS::Direct::Route::Factory::VERSION = '2.1.5';
sub build {
    my ( $class, $dispatcher, $action ) = @_;
    my $params = { action => $action, dispatcher => $dispatcher };
    my @roles;
    if ( $action->attributes->{Chained} ) {
        push( @roles, 'Chained' );
    }
    if (   $action->attributes->{ActionClass}
        && ($action->attributes->{ActionClass}->[0] eq 'Catalyst::Action::REST'
        || $action->attributes->{ActionClass}->[0] eq 'CatalystX::Action::ExtJS::REST') )
    {
        push( @roles, 'REST' );
    }
    if (   $action->name eq 'object'
        && $action->class->isa('CatalystX::Controller::ExtJS::REST') )
    {
        push( @roles, 'REST::ExtJS' );
    }
    @roles =
      map { $_ = 'CatalystX::Controller::ExtJS::Direct::Route::' . $_ } @roles;
    my $anon_class = Moose::Meta::Class->create_anon_class(
        superclasses => [qw(CatalystX::Controller::ExtJS::Direct::Route)],
        ( @roles ? ( roles => [@roles] ) : () ),
        cache => 1,
    );
    return $anon_class->find_method_by_name('build')
      ->execute( $anon_class->name, $params );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Controller::ExtJS::Direct::Route - Ext.Direct route object

=head1 VERSION

version 2.1.5

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
