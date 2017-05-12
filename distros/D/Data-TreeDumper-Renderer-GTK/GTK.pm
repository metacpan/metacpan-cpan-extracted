
package Data::TreeDumper::Renderer::GTK ;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.02';

use Data::TreeDumper ;

use Gtk2 -init;
use Glib ':constants';

use base qw(Gtk2::TreeView Exporter);

sub new 
{
my $class = shift;
my %args = (data => undef, @_);

my $self = bless Gtk2::TreeView->new, $class;

$self->insert_column_with_attributes(0, 'Data', Gtk2::CellRendererText->new, text => 0);
$self->set_data ($args{data}, $args{dumper_setup}) if exists $args{data} ;
$self->set_title ($args{title});

$self->signal_connect
	(
	button_press_event => 
		sub 
		{
		my ($widget, $event) = @_;
		if ($event->button == 3) {
			_do_context_menu ($widget, $event);
			return TRUE;
		}
		
		return FALSE;
		}
	);


return $self;
}

sub _do_context_menu 
{
	my ($self, $event) = @_;
	my $menu = Gtk2::Menu->new;
	foreach my $method ('expand_all', 'collapse_all') {
		my $label = join ' ', map { ucfirst $_ } split /_/, $method;
		my $item = Gtk2::MenuItem->new ($label);
		$menu->append ($item);
		$item->show;
		$item->signal_connect (activate => sub {
				       $self->$method;
				       });
	}
	$menu->popup (undef, undef, undef, undef, $event->button, $event->time);
}

sub set_data 
{
my ($self, $data, $dumper_setup) = @_;

my $model = Gtk2::TreeStore->new ('Glib::String');

DumpTree
	(
	  $data
	, 'GTK-perl data dump'
	, %$dumper_setup
	, RENDERER => 
		{
		  NODE  => \&RenderNode
		 
		# data needed by the renderer
		, PREVIOUS_LEVEL => 0
		, MODEL => $model
		, PARENT => [Gtk2::TreePath->new_from_string()]
		}
	) ;

$self->set_model ($model);
}

sub set_title 
{
	my ($self, $title) = @_;
	
	if (defined $title and length $title) {
		$self->get_column (0)->set_title ($title);
		$self->set_headers_visible (TRUE);
	} else {
		$self->set_headers_visible (FALSE);
	}
}


#-------------------------------------------------------------------------------------------

sub RenderNode
{
my
	(
	  $element
	, $level
	, $is_terminal
	, $previous_level_separator
	, $separator
	, $element_name
	, $element_value
	, $td_address
	, $address_link
	, $perl_size
	, $perl_address
	, $setup
	) = @_ ;

my $model          = $setup->{RENDERER}{MODEL} ;
my $parents        = $setup->{RENDERER}{PARENT} ;
my $previous_level = $setup->{RENDERER}{PREVIOUS_LEVEL} ;

# wind up the parents list if necessary
splice @$parents, 0, ($previous_level - $level) if($level < $previous_level) ;

my $path = $parents->[0] ;
my $parent = $model->get_iter($path) if($path->get_depth() > 0) ;
	
$element_value = " = $element_value" if($element_value ne '') ;

my $address = $td_address ;
$address .= "-> $address_link" if defined $address_link ;

$perl_size = "<$perl_size>" if $perl_size ne '' ;

my $rendering ;
if($setup->{DISPLAY_ADDRESS})
	{
	$rendering = "$element_name$element_value [$address] $perl_size $perl_address" ;
	}
else	
	{
	$rendering = "$element_name$element_value $perl_size $perl_address" ;
	}

unless($is_terminal)
	{
	my $parent = $model->append ($parent);
	$model->set($parent, 0, $rendering);
	
	my $path = $model->get_path($parent) ;
	unshift @{$setup->{RENDERER}{PARENT}}, $path ;
	}
else
	{
	$model->set($model->append($parent),0, $rendering);
	}
	
$setup->{RENDERER}{PREVIOUS_LEVEL} = $level ;
} 
	

1;

__END__

=head1 NAME

Data::TreeDumper::Renderer::GTK - Gtk2::TreeView renderer for B<Data::TreeDumper>

=head1 SYNOPSIS

  my $treedumper = Data::TreeDumper::Renderer::GTK->new
  			(
  			data => \%data,
  			title => 'Test Data',
  			dumper_setup => {DISPLAY_PERL_SIZE => 1}
  			);
  			
  $treedumper->modify_font(Gtk2::Pango::FontDescription->from_string ('monospace'));
  $treedumper->expand_all;
  
  # some boilerplate to get the widget onto the screen...
  my $window = Gtk2::Window->new;
  
  my $scroller = Gtk2::ScrolledWindow->new;
  $scroller->add ($treedumper);
  
  $window->add ($scroller);
  $window->show_all;

=head1 HIERARCHY

  Glib::Object
  +----Gtk2::Object
        +----Gtk2::Widget
              +----Gtk2::Container
                    +----Gtk2::TreeView
                          +----Data::TreeDumper::Renderer::GTK

=head1 DESCRIPTION

GTK-perl renderer for B<Data::TreeDumper>. 

This widget is the gui equivalent of Data::TreeDumper; it will display a
perl data structure in a TreeView, allowing you to fold and unfold child
data structures and get a quick feel for what's where.  Right-clicking
anywhere in the view brings up a context menu, from which the user can
choose to expand or collapse all items.

=head1 EXAMPLE

B<gtk_test.pl>


=head1 METHODS

=over

=item widget = Data::TreeDumper::Renderer::GTK::TreeDumper->new (...)

Create a new TreeDumper.  The optional arguments are expect to be key/val
pairs.

=over

=item - dumper_setup => hash reference

All data is passed to Data::TreeDumper

=item - data => scalar

Equivalent to calling C<< $treedumper->set_data ($scalar) >>.

=item - title => string or undef

Equivalent to calling C<< $treedumper->set_title ($string) >>.

=back

=item $treedumper->set_data ($newdata)

=over

=item * $newdata (scalar)

=back

Fill the tree with I<$newdata>, which may be any scalar.  The tree does
not reference I<$newdata> -- necessary data is copied.

=item $treedumper->set_title ($title=undef)

=over

=item * $title (string or undef) a new title

=back

Set the string displayed as the column title.  The view is created with one
column, and the header is visible only if there is a title set.

=back

=head1 EXPORT

None

=head1 AUTHORS

Khemir Nadim ibn Hamouda. <nadim@khemir.net>
Muppet <scott at asofyet dot org>

  Copyright (c) 2005 Nadim Ibn Hamouda el Khemir and 
  Muppet. All rights reserved.
  
  This program is free software; you can redistribute
  it and/or modify it under the same terms as Perlitself.
  
If you find any value in this module, mail me!  All hints, tips, flames and wishes
are welcome at <nadim@khemir.net>.

=head1 SEE ALSO

B<Data::TreeDumper> for advanced usage of the dumper engine.

=cut
