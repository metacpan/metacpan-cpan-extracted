package Chandra::Element;

use strict;
use warnings;

use Chandra::Bind;

our $VERSION = '0.06';

# Event attributes that map to JS event types
my %EVENT_ATTRS = map { $_ => 1 } qw(
	onclick onchange onsubmit onkeyup onkeydown oninput
	onfocus onblur onmouseover onmouseout ondblclick
	onkeypress onmousedown onmouseup onscroll onresize
	onload onunload
);

# Void elements (no closing tag)
my %VOID = map { $_ => 1 } qw(
	area base br col embed hr img input link meta param source track wbr
);

# Global handler registry and ID counters
my %_handlers;
my $_handler_id = 0;
my $_element_id = 0;

# --- Constructor ---

sub new {
	my ($class, $args) = @_;
	$args = {} unless ref $args eq 'HASH';

	my $self = bless {
		tag        => $args->{tag} // 'div',
		id         => $args->{id},
		class      => $args->{class},
		style      => $args->{style},
		data       => $args->{data},
		raw        => $args->{raw},
		attributes => {},
		children   => [],
		_handlers  => {},
		_eid       => '_e_' . ++$_element_id,
	}, $class;

	# Auto-assign id from _eid if not provided
	$self->{id} //= $self->{_eid};

	# Collect HTML attributes and event handlers from args
	for my $key (keys %$args) {
		next if $key =~ /^(tag|id|class|style|data|raw|children)$/;
		if ($EVENT_ATTRS{$key}) {
			$self->_register_handler($key, $args->{$key});
		} else {
			$self->{attributes}{$key} = $args->{$key};
		}
	}

	# Add children
	if ($args->{children} && ref $args->{children} eq 'ARRAY') {
		for my $child (@{$args->{children}}) {
			$self->add_child($child);
		}
	}

	return $self;
}

# --- Handler registration ---

sub _register_handler {
	my ($self, $event_attr, $sub) = @_;
	return unless ref $sub eq 'CODE';

	my $hid = '_h_' . ++$_handler_id;
	$_handlers{$hid} = $sub;
	$self->{_handlers}{$event_attr} = $hid;

	# Also register in Bind so event dispatch can find it
	Chandra::Bind->register_handler($hid, $sub);
}

# --- Children ---

sub add_child {
	my ($self, $child) = @_;

	if (ref $child eq 'HASH') {
		$child = Chandra::Element->new($child);
	}

	push @{$self->{children}}, $child;
	return $child;
}

sub children {
	return @{shift->{children}};
}

# --- Accessors ---

sub tag { shift->{tag} }

sub id {
	my ($self, $val) = @_;
	$self->{id} = $val if defined $val;
	return $self->{id};
}

sub class {
	my ($self, $val) = @_;
	$self->{class} = $val if defined $val;
	return $self->{class};
}

sub data {
	my ($self, $val) = @_;
	if (defined $val) {
		$self->{data} = ref $val eq 'ARRAY' ? $val->[0] : $val;
	}
	return $self->{data};
}

sub raw {
	my ($self, $val) = @_;
	$self->{raw} = $val if defined $val;
	return $self->{raw};
}

sub style {
	my ($self, $val) = @_;
	$self->{style} = $val if defined $val;
	return $self->{style};
}

sub attribute {
	my ($self, $key, $val) = @_;
	$self->{attributes}{$key} = $val if defined $val;
	return $self->{attributes}{$key};
}

# --- Query ---

sub get_element_by_id {
	my ($self, $id) = @_;
	return $self if defined $self->{id} && $self->{id} eq $id;
	for my $child (@{$self->{children}}) {
		next unless ref $child && $child->can('get_element_by_id');
		my $found = $child->get_element_by_id($id);
		return $found if $found;
	}
	return undef;
}

sub get_element_by_tag {
	my ($self, $tag) = @_;
	return $self if $self->{tag} eq $tag;
	for my $child (@{$self->{children}}) {
		next unless ref $child && $child->can('get_element_by_tag');
		my $found = $child->get_element_by_tag($tag);
		return $found if $found;
	}
	return undef;
}

sub get_elements_by_class {
	my ($self, $class) = @_;
	my @results;
	if (defined $self->{class}) {
		my @classes = split /\s+/, $self->{class};
		push @results, $self if grep { $_ eq $class } @classes;
	}
	for my $child (@{$self->{children}}) {
		next unless ref $child && $child->can('get_elements_by_class');
		push @results, $child->get_elements_by_class($class);
	}
	return @results;
}

# --- Render ---

sub render {
	my ($self) = @_;

	my $tag = $self->{tag};
	my $html = "<$tag";

	# id
	$html .= qq{ id="} . _escape_attr($self->{id}) . qq{"} if defined $self->{id};

	# class
	$html .= qq{ class="} . _escape_attr($self->{class}) . qq{"} if defined $self->{class};

	# style
	if (defined $self->{style}) {
		my $style_str;
		if (ref $self->{style} eq 'HASH') {
			$style_str = join('; ', map { "$_: $self->{style}{$_}" } sort keys %{$self->{style}});
		} else {
			$style_str = $self->{style};
		}
		$html .= qq{ style="} . _escape_attr($style_str) . qq{"} if $style_str;
	}

	# Extra attributes
	for my $attr (sort keys %{$self->{attributes}}) {
		my $val = $self->{attributes}{$attr};
		if (!defined $val) {
			$html .= qq{ $attr};
		} else {
			$html .= qq{ $attr="} . _escape_attr($val) . qq{"};
		}
	}

	# Event handlers → compiled to JS chandra._event calls
	for my $event_attr (sort keys %{$self->{_handlers}}) {
		my $hid = $self->{_handlers}{$event_attr};
		my $eid = $self->{id} // $self->{_eid};
		my $js_event_type = $event_attr;
		$js_event_type =~ s/^on//;
		my $js = qq{window.chandra._event('$hid',window.chandra._eventData(event,{targetId:'} . _escape_js($eid) . qq{'}))};
		$html .= qq{ $event_attr="} . _escape_attr($js) . qq{"};
	}

	if ($VOID{$tag}) {
		$html .= ' />';
		return $html;
	}

	$html .= '>';

	# Raw HTML content (not escaped)
	if (defined $self->{raw}) {
		$html .= $self->{raw};
	}

	# Text content
	if (defined $self->{data}) {
		$html .= _escape_html($self->{data});
	}

	# Children
	for my $child (@{$self->{children}}) {
		if (ref $child && $child->can('render')) {
			$html .= $child->render;
		} else {
			$html .= _escape_html("$child");
		}
	}

	$html .= "</$tag>";
	return $html;
}

# --- Class methods for handler registry ---

sub handlers {
	return \%_handlers;
}

sub get_handler {
	my ($class_or_self, $hid) = @_;
	return $_handlers{$hid};
}

sub clear_handlers {
	%_handlers = ();
	$_handler_id = 0;
}

sub reset_ids {
	$_element_id = 0;
	$_handler_id = 0;
	%_handlers = ();
}

# --- Escaping utilities ---

sub _escape_html {
	my ($text) = @_;
	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	return $text;
}

sub _escape_attr {
	my ($text) = @_;
	$text =~ s/&/&amp;/g;
	$text =~ s/"/&quot;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;
	return $text;
}

sub _escape_js {
	my ($text) = @_;
	$text =~ s/\\/\\\\/g;
	$text =~ s/'/\\'/g;
	return $text;
}

1;

__END__

=head1 NAME

Chandra::Element - DOM-like element construction for Chandra

=head1 SYNOPSIS

	use Chandra::Element;

	my $div = Chandra::Element->new({
	    tag   => 'div',
	    id    => 'app',
	    class => 'container',
	    style => { padding => '20px', background => '#fff' },
	    children => [
	        { tag => 'h1', data => 'Hello World' },
	        {
	            tag     => 'button',
	            data    => 'Click Me',
	            onclick => sub {
	                my ($event, $app) = @_;
	                print "Clicked!\n";
	            },
	        },
	    ],
	});

	my $html = $div->render;

=head1 DESCRIPTION

Chandra::Element provides a Moonshine::Element-compatible API for building
HTML element trees in Perl. Event handlers (onclick, onchange, etc.) are
automatically compiled into JavaScript that communicates with Perl via the
Chandra bridge.

=head1 METHODS

=head2 new(\%args)

Create a new element. Options:

=over 4

=item tag - HTML tag name (default: 'div')

=item id - Element ID (auto-generated if not provided)

=item class - CSS class(es)

=item style - CSS styles as hashref or string

=item data - Text content

=item children - Arrayref of child elements (hashrefs or Element objects)

=item onclick, onchange, etc. - Event handler coderefs

=back

=head2 add_child($child)

Add a child element. Accepts a hashref (auto-wrapped) or Element object.

=head2 children

	my $children = $element->children;

Returns the arrayref of child elements.

=head2 render()

Render the element tree to an HTML string with event wiring.

=head2 get_element_by_id($id)

Find a descendant element by ID.

=head2 get_element_by_tag($tag)

Find the first descendant element with the given tag name.

=head2 get_elements_by_class($class)

Find all descendant elements with the given CSS class.

=head2 handlers()

Class method. Returns the global handler registry hashref.

=head2 get_handler($id)

Class method. Returns the handler coderef registered under C<$id>.

=head2 clear_handlers()

Class method. Clears all registered handlers.

=head2 reset_ids()

Class method. Resets the auto-generated ID counter and clears all
registered handlers. Useful in tests.

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Bind>, L<Chandra::Event>

=cut
