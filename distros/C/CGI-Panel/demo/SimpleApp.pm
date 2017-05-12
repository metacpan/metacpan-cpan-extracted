package SimpleApp;

use base qw(CGI::Panel);
use Basket;

sub init {
    my ($self) = @_;
    $self->add_panel('basket1', new Basket); # Add a sub-panel
    $self->add_panel('basket2', new Basket); # Add a sub-panel
    $self->add_panel('basket3', new Basket); # Add a sub-panel
    $self->{count} = 1;   # Initialise some persistent data
}

sub _event_add {    # Respond to the button click event below
    my ($self, $event) = @_;
    
    $self->{count}++;  # Change the persistent data
}

sub display {
    my ($self) = @_;

    return
	'This is a very simple app.<p>' .
	# Display the persistent data...
	"My current count is $self->{count}<p>" .
	# Display the sub-panel...
	"<table><tr>" .
	"<td>" . $self->panel('basket1')->display . "</td>" .
	"<td>" . $self->panel('basket2')->display . "</td>" .
	"<td>" . $self->panel('basket3')->display . "</td>" .
        "</tr></table>" .
	# Display a button that will generate an event...
	$self->event_button(label => 'Add 1', name => 'add');
}

1;



