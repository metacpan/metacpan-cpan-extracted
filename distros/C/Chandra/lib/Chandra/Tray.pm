package Chandra::Tray;

use strict;
use warnings;

our $VERSION = '0.06';

use Cpanel::JSON::XS ();

my $json = Cpanel::JSON::XS->new->utf8->allow_nonref;

sub new {
	my ($class, %args) = @_;
	return bless {
		app       => $args{app},
		icon      => $args{icon} // '',
		tooltip   => $args{tooltip} // '',
		_items    => [],
		_next_id  => 1,
		_handlers => {},
		_on_click => undef,
		_active   => 0,
	}, $class;
}

sub add_item {
	my ($self, $label, $handler) = @_;
	my $id = $self->{_next_id}++;
	push @{$self->{_items}}, {
		id    => $id,
		label => $label,
	};
	$self->{_handlers}{$id} = $handler if ref $handler eq 'CODE';
	$self->_sync if $self->{_active};
	return $self;
}

sub add_separator {
	my ($self) = @_;
	push @{$self->{_items}}, {
		id        => 0,
		separator => 1,
	};
	$self->_sync if $self->{_active};
	return $self;
}

sub add_submenu {
	my ($self, $label, $items) = @_;
	return $self unless ref $items eq 'ARRAY';
	my @sub_items;
	for my $sub (@$items) {
		my $id = $self->{_next_id}++;
		push @sub_items, {
			id    => $id,
			label => $sub->{label} // '',
		};
		$self->{_handlers}{$id} = $sub->{handler}
			if $sub->{handler} && ref $sub->{handler} eq 'CODE';
	}
	push @{$self->{_items}}, {
		id       => 0,
		label    => $label,
		submenu  => \@sub_items,
	};
	$self->_sync if $self->{_active};
	return $self;
}

sub set_icon {
	my ($self, $icon) = @_;
	$self->{icon} = $icon // '';
	$self->_sync if $self->{_active};
	return $self;
}

sub set_tooltip {
	my ($self, $tooltip) = @_;
	$self->{tooltip} = $tooltip // '';
	$self->_sync if $self->{_active};
	return $self;
}

sub update_item {
	my ($self, $id_or_label, %opts) = @_;
	my $is_numeric = $id_or_label =~ /^\d+$/;
	for my $item (@{$self->{_items}}) {
		if (($is_numeric && $item->{id} && $item->{id} == $id_or_label) ||
		    (!$is_numeric && $item->{label} && $item->{label} eq $id_or_label)) {
			$item->{label} = $opts{label} if exists $opts{label};
			$item->{disabled} = $opts{disabled} ? 1 : 0 if exists $opts{disabled};
			$item->{checked} = $opts{checked} ? 1 : 0 if exists $opts{checked};
			$self->{_handlers}{$item->{id}} = $opts{handler}
				if $opts{handler} && ref $opts{handler} eq 'CODE';
			last;
		}
	}
	$self->_sync if $self->{_active};
	return $self;
}

sub on_click {
	my ($self, $handler) = @_;
	$self->{_on_click} = $handler;
	return $self;
}

sub items {
	my ($self) = @_;
	return [ @{$self->{_items}} ];
}

sub item_count {
	my ($self) = @_;
	return scalar @{$self->{_items}};
}

sub show {
	my ($self) = @_;
	return $self if $self->{_active};
	return $self unless $self->{app};

	# Defer creation until the event loop is running (webview_init
	# must execute first to establish the GUI connection).
	unless ($self->{app}{_started}) {
		$self->{_pending} = 1;
		return $self;
	}

	my $wv = $self->{app}->webview;
	return $self unless $wv;

	my $menu_json = $self->_menu_json;
	my $cb = $self->_make_dispatch_callback;
	my $result = $wv->_tray_create(
		$self->{icon},
		$self->{tooltip},
		$menu_json,
		$cb,
	);
	$self->{_active} = 1 if defined $result && $result == 0;
	$self->{_pending} = 0;
	return $self;
}

sub remove {
	my ($self) = @_;
	return $self unless $self->{_active};
	if ($self->{app} && $self->{app}->webview) {
		$self->{app}->webview->_tray_destroy;
	}
	$self->{_active} = 0;
	return $self;
}

sub is_active {
	my ($self) = @_;
	return $self->{_active} ? 1 : 0;
}

# ---- Private ----

sub _sync {
	my ($self) = @_;
	return unless $self->{_active} && $self->{app} && $self->{app}->webview;
	$self->{app}->webview->_tray_update(
		$self->{icon},
		$self->{tooltip},
		$self->_menu_json,
	);
}

sub _menu_json {
	my ($self) = @_;
	my @out;
	for my $item (@{$self->{_items}}) {
		if ($item->{separator}) {
			push @out, { separator => 1 };
		} elsif ($item->{submenu}) {
			# Submenu items need special handling in C layer
			# For now, flatten as regular items
			push @out, { id => $item->{id} || 0, label => $item->{label} };
			for my $sub (@{$item->{submenu}}) {
				push @out, { id => $sub->{id}, label => "  $sub->{label}" };
			}
		} else {
			my $entry = { id => $item->{id}, label => $item->{label} };
			$entry->{disabled} = 1 if $item->{disabled};
			$entry->{checked} = 1 if $item->{checked};
			push @out, $entry;
		}
	}
	return $json->encode(\@out);
}

sub _make_dispatch_callback {
	my ($self) = @_;
	my $handlers = $self->{_handlers};
	my $on_click = $self->{_on_click};
	return sub {
		my ($item_id) = @_;
		if ($item_id == -1 && $on_click) {
			$on_click->();
			return;
		}
		if ($handlers->{$item_id}) {
			$handlers->{$item_id}->();
		}
	};
}

1;

__END__

=head1 NAME

Chandra::Tray - System tray icon with context menu

=head1 SYNOPSIS

    use Chandra::Tray;

    my $tray = Chandra::Tray->new(
        app     => $app,
        icon    => '/path/to/icon.png',
        tooltip => 'My App',
    );

    $tray->add_item('Show Window' => sub { $app->show });
    $tray->add_separator;
    $tray->add_item('Quit' => sub { $app->terminate });
    $tray->show;

=head1 DESCRIPTION

Creates a native system tray icon with a context menu.  Uses
C<NSStatusBar> on macOS, C<GtkStatusIcon> on Linux, and
C<Shell_NotifyIcon> on Windows.

=head1 CONSTRUCTOR

=head2 new(%args)

    my $tray = Chandra::Tray->new(
        app     => $app,       # Chandra::App instance (required for show)
        icon    => 'icon.png', # path to icon file
        tooltip => 'My App',   # hover tooltip
    );

=head1 METHODS

=head2 add_item($label, \&handler)

Add a menu item.  Returns C<$self> for chaining.

=head2 add_separator()

Add a menu separator.  Returns C<$self>.

=head2 add_submenu($label, \@items)

Add a submenu.  Each item in C<@items> is a hashref with C<label> and
C<handler> keys.

=head2 set_icon($path)

Change the tray icon.  Returns C<$self>.

=head2 set_tooltip($text)

Change the tooltip.  Returns C<$self>.

=head2 update_item($id_or_label, %opts)

Update an existing menu item.  Options: C<label>, C<disabled>,
C<checked>, C<handler>.

=head2 on_click(\&handler)

Set a handler for left-clicking the tray icon.

=head2 show()

Display the tray icon.  Requires C<app> to be set.

=head2 remove()

Remove the tray icon.

=head2 is_active()

Returns true if the tray icon is currently displayed.

=head2 items()

Returns an arrayref of the current menu items.

=head2 item_count()

Returns the number of menu items.

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Dialog>

=cut
