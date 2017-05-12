package Class::MVC;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01.06';

our $DEBUG = 0;

use Class::Maker qw(:all);

use Class::Listener;

use Class::Observable;

	# The Facade
		
	Class::Maker::class
	{
		public =>
		{	
			ref => [qw( model view controller )],
		}, 
	};

	sub _preinit : method
	{
		my $this = shift;
					
			$this->controller( ( ref($this).'::Controller' )->new() );
			
			$this->model( ( ref($this).'::Model' )->new() );
			
			$this->view( ( ref($this).'::View' )->new() );		
	}
	
	sub _postinit : method
	{
		my $this = shift;
	
			$this->interconnect();
	}

	sub interconnect : method
	{
		my $this = shift;
		
			$this->view->model( $this->model ) if $this->model;

			$this->view->controller( $this->controller ) if $this->controller;

			$this->controller->model( $this->model ) if $this->model;

			$this->controller->view( $this->view ) if $this->view;
			
			$this->model->add_observer( $this->view ) if $this->view;
	}
			
package Class::MVC::Model;

	Class::Maker::class
	{
		isa => [qw( Class::Observable )],

	};

	sub DESTROY 
	{
		my $this = shift;
		
			$this->delete_observers;
	}
	
package Class::MVC::View;

	Class::Maker::class
	{
		isa => [qw( Class::Listener )],

		public =>
		{
			ref => [qw( controller model )],			
		},
	};
	
		# dispatch method for Observer ( see Class::Observable )

	sub update : method
	{
		my $this = shift;
	
		my ( $object, $action ) = @_;

	return $this->Class::Listener::signal( $action, $object );							
	}

package Class::MVC::CompositeView;

	Class::Maker::class
	{
		isa => [qw( Class::MVC::View )],
		
		public => 
		{
			# The subView/superView relationship

			ref => [qw( super_view )],
		},
	};

		# not implemented
		
	sub sub_views : method
	{
		my $this = shift;
	}
	
	sub update : method
	{
		my $this = shift;
		
			# update yourself
			
		$this->SUPER::update( @_ );
			
			# and your superviews
			
		$this->super_view->update( @_ ) if $this->super_view;
	}
	
package Class::MVC::Controller;

	Class::Maker::class
	{
		public =>
		{	
			ref => [qw( model view )],
		}, 
	};

	sub _postinit : method
	{
		my $this = shift;
	}

	sub update_model : method
	{
		my $this = shift;
		
				# call Model methods from here
			
			$this->model->Class::Listener::signal( 'update', $this, @_ );
	}

	sub change_view : method
	{		
		my $this = shift;

				# call View methods from here
		
			$this->view->Class::Listener::signal( 'change', $this, @_ );
	}

1;

__END__

=pod

=head1 NAME

Class::MVC - model-view-controller paradigma

=head1 SYNOPSIS

	use Class::Maker 'class';

	use Class::MVC;
	
	class 'Widget',
	{
		isa => [qw( Class::MVC )]
	};

	class 'Widget::ViewModel',
	{			
		isa => [qw( Device::Output::Channel )],
		
		public =>
		{
			string => [qw( info )],
		},
	};

	class 'Widget::Model',
	{
		isa => [qw( Class::MVC::Model Shell::Widget::ViewModel)],
	};

	class 'Widget::View',
	{
		isa => [qw( Class::MVC::CompositeView )],
		
		public =>
		{
			ref => [qw( device )],
		},
	};

	class 'Widget::Controller',
	{
		isa => [qw( Class::MVC::Controller )],		
		
		public => 
		{
			ref => [qw( sensor )],
		},
		
		default =>
		{
			sensor => Device::Input->new(),
		},
	};	
  
=head1 DESCRIPTION

The Model-View-Controller (MVC) is a general paradigma mostly used for GUI-development. It is very well
known and tons of publications are available through your favorite search engine (Or jump to L<"REFERENCES">). 
It is also an introductional example from the famous B<"Design Patterns"> book.

                            +------------+
                            |   Model    |
                            +------------+
                           /\ .          /\
                           / .            \
                          / .              \
                         / .                \
                        / \/                 \
                  +------------+ <------ +------------+
 Graphical  <==== |    View    |         | Controller |  <==== User Input
  Output          +------------+ ......> +------------+

=head2 Class::MVC::Model

This class is derived from C<Class::Observable> (L<Class::Observable>). C<Class::MVC::View>'s observe it to make appropriate
changes to the presentation (aka View) if an update of the C<"Class::MVC::Model"> happens.

[Note] Some publications prefer to separate a I<Data Model> and a I<View Model>. My personal preference tend to have a
simple B<ViewModel> class and let a B<DataModel> class derive from B<Class::MVC::Model> and our B<ViewModel> class.

=head2 Class::MVC::View

=over 4

=item model

Reference to a C<Class::MVC::Model> object.

=item controller 

Reference to a C<Class::MVC::Controller> object.

=back

B<C<Class::MVC::Model->notify_observers( 'update' )>> will call a C<_on_update> method of the observing I<View's>.

[Note] B<Class::MVC::View> is derived from L<Class::Listener> to dispatch the observer notify to the C<_on_update>
method.

=head2 Class::MVC::CompositeView

This is the base class for B<nested> views. A I<CompsiteView> is a derived I<View>. Its C<update()> method takes the job to 
inform the C<super_view> of C<sub_view> changes changes.

See L<"REFERENCES">.

=over 4

=item super_view

Points to the view that contains it and another subviews.

=item sub_views (unimplemented)

An array pointing to all subviews.

=back

=head2 Class::MVC::Controller

=over 4

=item model 

Reference to a C<Class::MVC::Model>.

=item view

Reference to a C<Class::MVC::View>.

=item update_model()

Sends a C<Class::Listener> C<update ( $this, @_ )> B<signal> to the model.

=item change_view()

Sends a C<Class::Listener> C<change ( $this, @_ )> B<signal> to the view.

Calls C<Class::MVC::View> methods to do controller specific view changes (for example
beep() or flicker() when wrong input is done).

=back 

=back

=head2 SIGNALS

Signals are transported via the C<Class::Listener::signal> method (L<"SEE ALSO">).

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Uenalan, E<lt>muenalan@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::Maker>, L<Class::Listener> and L<Class::Observable>.

=head1 REFERENCES

=over 4

=item [1] 

L<http://ootips.org/mvc-pattern.html>

=item [2] 

L<http://www.enode.com/x/markup/tutorial/mvc.html>

=item [3] 

L<http://st-www.cs.uiuc.edu/users/smarch/st-docs/mvc.html>

=cut
