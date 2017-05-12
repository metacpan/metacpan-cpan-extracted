package Catalyst::Plugin::Hooks;

use strict;
use warnings;

use NEXT;
use Carp;

our $VERSION = '0.03';

my %actions;
@actions{ qw(
    handle_request
    prepare
    prepare_request
    prepare_connection
    prepare_query_parameters
    prepare_headers
    prepare_cookies
    prepare_path
    prepare_body
    prepare_body_parameters
    prepare_parameters
    prepare_uploads
    prepare_action
    dispatch
    finalize
    finalize_uploads
    finalize_error
    finalize_headers
    finalize_cookies
    finalize_body
) } = ();

for my $action ( keys %actions ) {
    no strict 'refs';
    *{"add_". $action ."_hook"} = sub {
        my ( $c, $hook ) = @_;
        croak "add_". $action ."_hook( CODE )" unless ref $hook eq "CODE";
        __PACKAGE__->initialize_action( $action )
            unless $action->{initialized};

        push @{ $actions{$action}->{before} }, $hook;
    };
    *{"add_before_". $action ."_hook"} = \*{"add_". $action ."_hook"};

    *{"add_after_". $action ."_hook"} = sub {
        my ( $c, $hook ) = @_;
        croak "add_after_". $action ."_hook( CODE )" unless ref $hook eq "CODE";
        __PACKAGE__->initialize_action( $action )
            unless $action->{initialized};

        push @{ $actions{$action}->{after} }, $hook;
    };

    *{"remove_all_". $action ."_hooks"} = sub {
        $actions{$action}->{before} = [];
        $actions{$action}->{after}  = [];
    };
}

sub initialize_action {
    my ( $self, $action ) = @_;

    no strict 'refs';
    ### Had to use eval for NEXT::$action
    eval q/ sub /. $action .q/ {
        my $c = shift;
        my $action = '/. $action .q/';

        for my $hook ( @{ $actions{$action}->{before} } ) {
            $hook->( $c, @_ );
        }
        $c->NEXT::/. $action .q/(@_);
        for my $hook ( @{ $actions{$action}->{after} } ) {
            $hook->( $c, @_ );
        }
    } /;
    die $@ if $@;
    $actions{ $action }->{initialized} = 1;
}

sub remove_all_hooks {
    my $self = shift;

    for my $action ( values %actions ) {
        $action->{before} = [];
        $action->{after}  = [];
    }
}


1

__END__

=head1 NAME

Catalyst::Plugin::Hooks - Add hooks to Catalyst engine actions

=head1 SYNOPSIS

In MyApp.pm:

  use Catalyst qw(
    -Debug
    Hooks
  );

In Some model:

  sub new {
    my $self = shift;
    my ( $c ) = @_;

    $self = $self->NEXT::new( @_ );

    open my $filehandle, "> foo.log";

    $c->add_after_finalize_hook( sub {
        my $c = shift;
        $filehandle->flush();
        $c->log->info( "Flushed filehandle after finalize" );
    } );

    return $self;
  }


=head1 DESCRIPTION

Don't use this plugin!

Use L<Catalyst::Plugin::Observe>. All functionality provided in C:P:Hooks will
very shortly be available in C:P:Observe. C:P:Hooks is probably not going to
work in the next Catalyst release, so rewrite your code to use C:P:Observe.


This Plugin is usefull for when you want to run some code before or after a
catalyst engine action. Consider writing a Catalyst plugin if you implement
more general functionality. But let's say you want to flush your log's
filehandle after the request is done (then the requestor doesn't have to wait
for your log's to be flushed). It would be nice to put the code for flushing
the filehandle next to the rest of the code that's bothered with the
filehandle, so you don't have to pass the filehandle around. Example for this
is shown in the L</SYNOPSIS>.

Hooks are addable everywhere a $c exists, even in Controllers. But remember,
adding a hook every request will cause a memory overflow. So don't put these
methods in Controller actions.

=head2 METHODS

All of these methods are currently hookable:

    handle_request
    prepare
    prepare_request
    prepare_connection
    prepare_query_parameters
    prepare_headers
    prepare_cookies
    prepare_path
    prepare_body
    prepare_body_parameters
    prepare_parameters
    prepare_uploads
    prepare_action
    dispatch
    finalize
    finalize_uploads
    finalize_error
    finalize_headers
    finalize_cookies
    finalize_body

To add a I<before> hook:
  $c->add_ <method name> _hook( sub { some code } );

To add an I<after> hook:
  $c->add_after_ <method name> _hook( sub { some code } );

C<< $c->add_before_ <method name> _hook >> is an alias to C<< $c->add_ <method name> _hook >>.

To remove all hooks for an action:
  $c->remove_all_ <method name> _hooks;

To remove all hooks set by this module:
  $c->remove_all_hooks;

=head1 SEE ALSO

L<Catalyst>,
L<Catalyst::Manual::Internals> for when the different actions are called.

=head1 AUTHOR

Berik Visschers <berikv@xs4all.nl>

=cut
