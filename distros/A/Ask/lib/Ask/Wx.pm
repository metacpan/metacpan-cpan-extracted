use 5.008008;
use strict;
use warnings;

package Ask::Wx;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Moo;
use Path::Tiny 'path';
use Wx;
use namespace::autoclean;

with 'Ask::API';

sub is_usable {
	my ( $self ) = @_;
	return !!$ENV{'DISPLAY'};
}

sub quality {
	return 10;    # raise to 50 once multi file selection implemented
}

sub info {
	my ( $self, %o ) = @_;
	$o{messagebox_icon} = Wx::wxICON_INFORMATION()
		unless defined $o{messagebox_icon};
	$o{messagebox_buttons} = Wx::wxOK()    unless defined $o{messagebox_buttons};
	$o{text}               = ''            unless exists $o{text};
	$o{title}              = 'Information' unless exists $o{title};
	Wx::MessageBox(
		$o{text},
		$o{title},
		$o{messagebox_icon} | $o{messagebox_buttons},
	);
} #/ sub info

sub warning {
	my ( $self, %o ) = @_;
	$self->info( messagebox_icon => Wx::wxICON_WARNING(), title => 'Warning', %o );
}

sub error {
	my ( $self, %o ) = @_;
	$self->info( messagebox_icon => Wx::wxICON_ERROR(), title => 'Error', %o );
}

sub question {
	my ( $self, %o ) = @_;
	Wx::wxYES() == $self->info(
		title              => 'Question',
		messagebox_icon    => Wx::wxICON_QUESTION(),
		messagebox_buttons => Wx::wxYES_NO(),
		%o,
	);
}

sub entry {
	my ( $self, %o ) = @_;
	
	$o{text}       = ''           unless exists $o{text};
	$o{title}      = 'Text extry' unless exists $o{title};
	$o{entry_text} = ''           unless exists $o{entry_text};
	
	$o{hide_text}
		? Wx::GetPasswordFromUser( $o{text}, $o{title}, $o{entry_text} )
		: Wx::GetTextFromUser( $o{text}, $o{title}, $o{entry_text} );
} #/ sub entry

sub file_selection {
	my ( $self, %o ) = @_;
	
	$o{text} = '' unless exists $o{text};
	
	return Wx::DirSelector( $o{text} )
		if $o{dir};
		
	warn "Multiple file selection box not implemented in Ask::Wx yet!\n"
		if $o{multiple};
		
	my $f = Wx::FileSelector(
		$o{text},
		'',       # default path
		'',       # default filename
		'',       # default extension
		'*.*',    # wildcard
		$o{save} ? Wx::wxFD_SAVE() : Wx::wxFD_OPEN(),
	);
	
	path( $f );
} #/ sub file_selection

sub single_choice {
	my ( $self, %o ) = @_;
	
	$o{text}    = ''           unless exists $o{text};
	$o{title}   = 'Choose one' unless exists $o{title};
	$o{choices} = []           unless defined $o{choices};
	
	my $return = Wx::GetSingleChoiceIndex(
		$o{text} || $o{title},
		$o{title},
		[ map $_->[1], @{ $o{choices} } ],
	);
	return if $return < 0;
	return $o{choices}[$return][0];
} #/ sub single_choice

sub multiple_choice {
	my ( $self, %o ) = @_;
	
	$o{text}    = ''           unless exists $o{text};
	$o{title}   = 'Choose one' unless exists $o{title};
	$o{choices} = []           unless defined $o{choices};
	
	my @return = Wx::GetMultipleChoices(
		$o{text} || $o{title},
		$o{title},
		[ map $_->[1], @{ $o{choices} } ],
	);
	return if @return && $return[0] < 0;
	return map $o{choices}[$_][0], @return;
} #/ sub multiple_choice

1;

__END__

=head1 NAME

Ask::Wx - interact with a user via a WxWidgets GUI

=head1 SYNOPSIS

	my $ask = Ask::Wx->new;
	
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
