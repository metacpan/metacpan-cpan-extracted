use 5.008008;
use strict;
use warnings;

{
	package Ask::Gtk;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.012';
	
	use Moo;
	use Gtk2 -init;
	use Path::Tiny 'path';
	use namespace::autoclean;
	
	with 'Ask::API';
	
	sub is_usable {
		my ($self) = @_;
		return !! $ENV{'DISPLAY'};
	}
	
	sub info
	{
		my ($self, %o) = @_;
		
		$o{messagedialog_type}    ||= 'info';
		$o{messagedialog_buttons} ||= 'ok';
		
		my $msg = Gtk2::MessageDialog->new(
			undef,
			[qw/ modal destroy-with-parent /],
			$o{messagedialog_type},
			$o{messagedialog_buttons},
			exists $o{title} ? $o{title} : $o{text},
		);
		
		$msg->set_property('secondary-text', $o{text}) if exists $o{title};
		
		return $msg->run;
	}
	
	sub warning
	{
		my ($self, %o) = @_;
		$self->info(messagedialog_type => 'warning', messagedialog_buttons => 'close', %o);
	}
	
	sub error
	{
		my ($self, %o) = @_;
		$self->info(messagedialog_type => 'error', messagedialog_buttons => 'close', %o);
	}
	
	sub question
	{
		my ($self, %o) = @_;
		'yes' eq $self->info(
			messagedialog_type    => 'question',
			messagedialog_buttons => 'yes-no',
			%o,
		);
	}
	
	sub entry
	{
		my ($self, %o) = @_;
		
		my $return;
		
		my $dialog = Gtk2::Dialog->new(
			($o{title} || 'Message'),
			undef,
			[qw/ modal destroy-with-parent /],
			'gtk-ok' => 'none',
		);
		
		if (defined $o{text}) {
			my $label = Gtk2::Label->new($o{text});
			$dialog->vbox->add($label);
		}
		
		my $entry = Gtk2::Entry->new;
		$dialog->vbox->add($entry);
		$entry->set_text($o{entry_text} || '');
		$entry->select_region(0, length $entry->get_text);
		$entry->set_visibility(! $o{hide_text});
		
		my $done = sub {
			$return = $entry->get_text;
			$dialog->destroy;
			Gtk2->main_quit;
		};
		
		$entry->signal_connect(activate => $done);
		$dialog->signal_connect(response => $done);
		
		$dialog->show_all;
		Gtk2->main;
		return $return;
	}
	
	sub file_selection
	{
		my ($self, %o) = @_;
		my @return;
		
		require URI;
		
		my $dialog = Gtk2::FileChooserDialog->new(
			($o{title} || $o{text} || 'File selection'),
			undef,
			$o{directory} ? 'select-folder' : $o{save} ? 'save' : 'open',
			'gtk-ok' => 'none',
		);
		
		$dialog->set_select_multiple(!!$o{multiple});
		
		my $done = sub {
			@return = map path( 'URI'->new($_)->file ), $dialog->get_uris;
			$dialog->destroy;
			Gtk2->main_quit;
		};
		
		$dialog->signal_connect(response => $done);
		
		$dialog->show;
		Gtk2->main;
		
		$o{multiple} ? @return : $return[0];
	}

	sub _choice
	{
		my ($self, %o) = @_;
		
		my $return;
		
		my $dialog = Gtk2::Dialog->new(
			($o{title} || 'Choose'),
			undef,
			[qw/ modal destroy-with-parent /],
			'gtk-ok' => 'none',
		);
		
		if (defined $o{text}) {
			my $label = Gtk2::Label->new($o{text});
			$dialog->vbox->add($label);
		}
		
		my $tree_store = Gtk2::TreeStore->new(qw/Glib::String/);
		for my $choice (@{$o{choices}}) {
			my $iter = $tree_store->append(undef);
			$tree_store->set($iter, 0 => $choice->[1]);
		}
		my $tree_view   = Gtk2::TreeView->new($tree_store);
		my $tree_column = Gtk2::TreeViewColumn->new();
		$tree_column->set_title("Choices");
		my $renderer = Gtk2::CellRendererText->new;
		$tree_column->pack_start($renderer, 0);
		$tree_column->add_attribute($renderer, text => 0);
		$tree_view->append_column($tree_column);
		$dialog->vbox->set_size_request(300, 300);
		$dialog->vbox->add($tree_view);
		$tree_view->get_selection->set_mode($o{_tree_mode} || 'single');
		
		my @return;
		my $done = sub {
			$tree_view->get_selection->selected_foreach(sub {
				my ($i) = $_[1]->get_indices;
				push @return, $o{choices}[$i][0];
			});
			$dialog->destroy;
			Gtk2->main_quit;
		};
		
		$dialog->signal_connect(response => $done);
		
		$dialog->show_all;
		Gtk2->main;
		return @return;
	}

	sub multiple_choice
	{
		my ($self, %o) = @_;
		$o{title} ||= 'Choose';
		$o{_tree_mode} = 'multiple';
		return $self->_choice(%o);
	}

	sub single_choice
	{
		my ($self, %o) = @_;
		$o{title} ||= 'Choose one';
		$o{_tree_mode} = 'single';
		my ($r) = $self->_choice(%o);
		return $r;
	}
}

1;

__END__

=head1 NAME

Ask::Gtk - interact with a user via a Gtk GUI

=head1 SYNOPSIS

	my $ask = Ask::Gtk->new;
	
	$ask->info(text => "I'm Charles Xavier");
	if ($ask->question(text => "Would you like some breakfast?")) {
		...
	}

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Ask>.

=head1 SEE ALSO

L<Ask>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013, 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

