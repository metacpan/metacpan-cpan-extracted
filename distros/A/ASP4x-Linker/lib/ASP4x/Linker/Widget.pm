
package ASP4x::Linker::Widget;

use strict;
use warnings 'all';
use Carp 'confess';


sub new
{
  my ($class, %args) = @_;
  
  foreach(qw( name ))
  {
    confess "Required param '$_' was not provided"
      unless $args{$_};
  }# end foreach()
  
  my $context = ASP4::HTTPContext->current;
  my $form = $context->request->Form;
  $args{attrs} ||= [ ];
  $args{triggers} ||= { };
  
  $args{vars} = {
    map { $_ => $form->{"$args{name}.$_"} }
      @{$args{attrs}}
  };
  $args{original_vars} = {
    map { $_ => $form->{"$args{name}.$_"} }
      @{$args{attrs}}
  };
  
  return bless \%args, $class;
}# end new()


sub attrs { sort @{ shift->{attrs} } }

sub name { shift->{name} }

sub set
{
  my ($s, %args) = @_;
  while( my ($attr, $val) = each %args )
  {
    confess "widget '$s->{name}' does not have any attribute named '$attr'"
      unless exists($s->{vars}->{$attr});
    $s->{vars}->{$attr} = $val;
    if( my $triggers = $s->{triggers}->{$attr} )
    {
      map { $_->( $s ) } @$triggers
    }# end if()
  }# end while()
  
#  $val;
  $s;
}# end set()


sub get
{
  my ($s, $key) = @_;
  
  exists( $s->{vars}->{ $key } ) or return;
  $s->{vars}->{$key};
}# end get()


sub vars
{
  my $s = shift;
  
  return $s->{vars};
}# end filters()


sub reset
{
  my $s = shift;
  
  %{ $s->{vars} } = %{ $s->{original_vars} };
}# end reset()


sub linker
{
  my $s = shift;
  @_ ? $s->{linker} = shift : $s->{linker};
}# end linker()


sub uri { shift->linker->uri }


sub on_change
{
  my ($s, $attr, $code) = @_;
  
  return unless exists( $s->{vars}->{$attr} );
  $s->{triggers}->{ $attr } ||= [ ];
  push @{ $s->{triggers}->{ $attr } }, $code;
}# end on_change()

sub DESTROY { my $s = shift; undef(%$s); }

1;# return true:

=pod

=head1 NAME

ASP4x::Linker::Widget - A single item that should be persisted via links.

=head1 SYNOPSIS

  use ASP4x::Linker;
  
  my $linker = ASP4x::Linker->new();
  
  # Add a widget:
  $linker->add_widget(
    name  => 'albums',
    attrs => [qw( page_number page_size sort_col sort_dir )]
  );
  
  # Get the widget:
  my $widget = $linker->widget('albums');
  
  # Change some attributes:
  $widget->set( page_size   => 10 );
  $widget->set( page_number => 4 );
  
  # Get the value of some attributes:
  $widget->get( 'page_size' );    # 10
  $widget->get( 'page_number' );  # 4

  # Make page_number reset to 1 if the page_size is changed:
  $widget->on_change( page_size => sub {
    my $s = shift;
    $s->set( page_number => 1 );
  });
  
  $widget->set( page_size => 20 );
  print $widget->get( 'page_number' );  # 1
  
  # Set multiple values at once:
  $widget->set( %args );
  
  # Set multiple values at once and get the uri:
  warn $widget->set( %args )->uri();
  
  # Set multiple values by chaining and get the uri:
  warn $widget->set( foo => 'bar' )->set( baz => 'bux' )->uri();

=head1 DESCRIPTION

C<ASP4x::Linker::Widget> provides a simple, simple interface to a "thing" on your
web page (which we'll call a "widget").

A "widget" can be anything.  My experience generally means that a widget is a data grid
that supports paging and sorting through multiple records.  However a widget could
represent anything you want it to, as long as you can describe it with a B<name> and
and arrayref of B<attrs> (attributes).  The B<attrs> arrayref for a data grid might 
look like what you see in the example above:

  attrs => [qw( page_number page_size sort_col sort_dir )]

In English, a "widget" can be anything.  The word "widget" could be replaced with "thing" - 
so in this case a "widget" is just a "thing" - anything (with a name and attributes).

=head1 PUBLIC PROPERTIES

=head2 vars

Returns a hashref of all name/value pairs of attributes and their current values.

=head2 attrs

Returns an B<array> of the names of the widget's attributes.

=head1 PUBLIC METHODS

=head2 reset( )

Restores the widget's C<vars> to its original state - as it was when the widget
was first instantiated.

=head2 set( $attr => $value )

Changes the value of an attribute to a new value.

B<NOTE:> As of version , attempts to apply a value to a non-existant attribute will result in a runtime exception.

=head2 get( $attr )

Returns the current value of the attribute.

=head2 on_change( $attr => sub { ... } )

Adds a trigger to the widget that will be called when the given attribute's value is changed via C<set()>.

=head2 uri()

Just a wrapper around the widget's parent C<ASP4x::Linker> object.

=head1 SEE ALSO

L<ASP4x::Linker>

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the same
terms as Perl itself.

=cut

