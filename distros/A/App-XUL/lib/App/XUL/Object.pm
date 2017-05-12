package App::XUL::Object;

our $AUTOLOAD;

sub new
{
  my ($class, @args) = @_;
  my $self = bless {}, $class;
  return $self->init(@args);
}

sub init
{
  my ($self, $id) = @_;
	$self->{'id'} = $id;
  return $self
}

sub child
{
	my ($self, $num) = @_;
	my $id = main::push({'action' => 'child', 'id' => $self->{'id'}, 'number' => $num});
	#print STDERR "($id)\n";
	return new App::XUL::Object($id);
}

sub numchildren
{
	my ($self) = @_;
	return main::push({'action' => 'numchildren', 'id' => $self->{'id'}});
}

sub insert
{
	my ($self, $xml, $pos) = @_;
	$pos = 'end' unless defined $pos; # pos: end|start|...
	return main::push({'action' => 'insert', 'id' => $self->{'id'}, 'position' => $pos, 'content' => $xml});
}

sub update
{
	my ($self, @xml) = @_;
	my $xml = join '', @xml;
	return main::push({'action' => 'update', 'id' => $self->{'id'}, 'content' => $xml});
}

sub remove
{
	my ($self) = @_;
	return main::push({'action' => 'remove', 'id' => $self->{'id'}});
}

# attribute/content setting function
sub AUTOLOAD
{
	my ($self, $x) = @_;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	
	return if $name eq 'DESTROY';
	
	my @events =
		qw(abort
			 blur
			 change click
			 dblclick dragdrop
			 error
			 focus
			 keydown keypress keyup
			 load
			 mousedown mousemove mouseout mouseover mouseup move
			 reset resize
			 select submit
			 unload);
	
	if (scalar grep { $_ eq $name } @events) {
		# trigger event
		return main::push({'action' => 'trigger', 'id' => $self->{'id'}, 'name' => $name});
	}
	elsif (scalar grep { $_ eq 'on'.$name } @events) {
		# register/unregister event handler
		my $action = (defined $x ? 'register' : 'unregister');
		return 
			main::push( 
					{'action' => $action, 'id' => $self->{'id'}, 'name' => $name, 
					 ($action eq 'register' ? ('callback' => $x) : ())});
	}
	else {
		# get/set attribute
		if (defined $x) {
			# set attribute & return self
			main::push(
				{'action' => 'setattr', 'id' => $self->{'id'}, 'name' => $name, 'value' => $x});
			return $self;
		} else {
			# get attribute
			return main::push(
				{'action' => 'getattr', 'id' => $self->{'id'}, 'name' => $name});
		}
	}
}

1;
