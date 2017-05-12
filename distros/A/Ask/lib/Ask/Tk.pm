use 5.010;
use strict;
use warnings;

{
	package Ask::Tk;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';

	use Moo;
	use Tk;
	use namespace::sweep;

	with 'Ask::API';
	
	sub quality {
		return 30;
	}
	
	sub info {
		my ($self, %o) = @_;
		
		my $mw = "MainWindow"->new;
		$mw->withdraw;
		
		$o{messagebox_type} //= 'ok';
		$o{messagebox_icon} //= 'info';
		
		my $r = $mw->messageBox(
			-title   => $o{title},
			-message => $o{text},
			-type    => $o{messagebox_type},
			-icon    => $o{messagebox_icon},
		);
		$mw->destroy;
		return $r;
	}
	
	sub warning {
		my ($self, %o) = @_;
		$self->info(messagebox_icon => 'warning', %o);
	}

	sub error {
		my ($self, %o) = @_;
		$self->info(messagebox_icon => 'error', %o);
	}

	sub question {
		my ($self, %o) = @_;
		'Ok' eq $self->info(
			messagebox_icon => 'question',
			messagebox_type => 'OkCancel',
			%o,
		);
	}

	sub entry {
		my ($self, %o) = @_;
		my $mw = "MainWindow"->new;
		
		$mw->Label(-text => $o{text})->pack
			if exists $o{text};
		
		my $return = $o{entry_text};
		my $entry = $mw->Entry(
			(-show        => '*') x!!( $o{hide_text} ),
			-textvariable => \$return,
		)->pack;

		$entry->bind('<Return>', [ sub {
			$return = $entry->get;
			$mw->destroy;
		}]);
		
		$entry->focus;
		MainLoop;
		return $return;
	}
	
	sub file_selection {
		my ($self, %o) = @_;
		my @files;
		my $mw = "MainWindow"->new;
		$mw->withdraw;
		
		my %TK = (
			-type   => $o{directory} ? 'dir' : ($o{save} ? 'save' : 'open'),
		);
		
		push @files, $mw->FBox(%TK)->Show;
		while ($o{multiple} and $self->question(text => 'Select another?')) {
			push @files, $mw->FBox(%TK)->Show;
		}
		
		$mw->destroy;
		return @files;
	}

	sub _choice {
		my ($self, %o) = @_;
		my $mw = "MainWindow"->new;
		
		$mw->title( $o{title} );
		$mw->Label(-text => $o{text})->pack if exists $o{text};
		
		my @return;
		my $lbox = $mw->Listbox(-selectmode => ($o{_mode} // 'single'))->pack;
		$lbox->insert(end => map $_->[1], @{$o{choices}});
		
		$mw->Button(
			-text    => 'OK',
			-command => sub {
				@return = map $o{choices}[$_][0], $lbox->curselection;
				$mw->destroy;
			},
		)->pack;
		
		MainLoop;
		return @return;
	}
	
	sub multiple_choice {
		my ($self, %o) = @_;
		$o{title} //= 'Choose';
		$o{_mode}   = 'multiple';
		my @r = $self->_choice(%o);
		return @r;
	}

	sub single_choice {
		my ($self, %o) = @_;
		$o{title} //= 'Choose one';
		$o{_mode}   = 'single';
		my ($r) = $self->_choice(%o);
		return $r;
	}
}

1;

__END__

=head1 NAME

Ask::Tk - interact with a user via a GUI

=head1 SYNOPSIS

	my $ask = Ask::Tk->new;
	
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

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

