package Basket;

use base qw(CGI::Panel);

sub init {
    my ($self) = @_;

    $self->{contents} = [];
}

sub _event_add {
    my ($self, $event) = @_;

    my %local_params = $self->local_params;

    push @{$self->{contents}}, $local_params{item_name};
}

sub display {
    my ($self) = @_;

    return
      '<table bgcolor="#CCCCFF">' .
	join('', (map { "<tr><td>$_</td></tr>" } @{$self->{contents}})) .
        '<tr>' .
	  '<td>' . $self->local_textfield({name => 'item_name', size => 10}) . '</td>' .
	  '<td>' . $self->event_button(label => 'Add', name => 'add') . '</td>' .
        '</tr>' .
      '</table>';
};

1;
