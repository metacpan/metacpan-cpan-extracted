use 5.010;
use strict;
use warnings;

{
	package Ask::Zenity;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';
	
	use Moo;
	use File::Which qw(which);
	use System::Command;
	use namespace::sweep;
	
	has zenity_path => (
		is       => 'ro',
		isa      => sub { die "$_[0] not executable" unless -x $_[0] },
		default  => sub { which('zenity') || '/usr/bin/zenity' },
	);
	
	has system_wrapper => (
		is       => 'ro',
		default  => sub { 'System::Command' },
	);
	
	with 'Ask::API';
	
	sub quality {
		return 40;
	}
	
	sub _optionize {
		my $opt = shift;
		$opt =~ s/_/-/g;
		return "--$opt";
	}
	
	sub _zenity {
		my ($self, $cmd, %o) = @_;
		my $zen = $self->system_wrapper->new(
			$self->zenity_path,
			_optionize($cmd),
			map sprintf('%s="%s"', _optionize($_), $o{$_}), keys %o,
		);
		# warn join q[ ], $zen->cmdline;
		return $zen;
	}
	
	sub entry {
		my $self = shift;
		my $text = readline($self->_zenity(entry => @_)->stdout);
		chomp $text;
		return $text;
	}

	sub info {
		my $self = shift;
		$self->_zenity(info => @_)->close;
	}

	sub warning {
		my $self = shift;
		$self->_zenity(warning => @_)->close;
	}

	sub error {
		my $self = shift;
		$self->_zenity(error => @_)->close;
	}

	sub question {
		my $self = shift;
		my $zen  = $self->_zenity(error => @_);
		$zen->close;
		return not $zen->exit;
	}
	
	sub file_selection {
		my $self = shift;
		my $text = readline($self->_zenity(file_selection => @_)->stdout);
		chomp $text;
		return split m#[|]#, $text;
	}
	
	sub single_choice {
		my ($self, %o) = @_;
		$o{title} //= 'Single choice';
		$o{text}  //= 'Choose one.';
		my ($c) = $self->_choice(radiolist => 1, %o);
		return $c;
	}
	
	sub multiple_choice {
		my ($self, %o) = @_;
		$o{title} //= 'Multiple choice';
		$o{text}  //= '';
		return $self->_choice(multiple => 1, checklist => 1, %o);
	}
	
	sub _choice {
		my ($self, %o) = @_;
		my $subsequent;
		my $zen = $self->system_wrapper->new(
			$self->zenity_path,
			'--list',
			($o{radiolist} ? '--radiolist' : ()),
			($o{checklist} ? '--checklist' : ()),
			($o{multiple}  ? '--multiple'  : ()),
			'--column=Select',
			'--column=Code',
			'--column=Choice',
			'--hide-column=2',
			'--text', $o{text},
			map { ($subsequent++ ? 'FALSE' : 'TRUE'), @$_ } @{$o{choices}},
		);
		chomp(my $line = readline($zen->stdout));
		split m{\|}, $line;
	}
}

1;

__END__

=head1 NAME

Ask::Zenity - use C<< /usr/bin/zenity >> to interact with a user

=head1 SYNOPSIS

	my $ask = Ask::Zenity->new(
		zenity_path => '/usr/bin/zenity',
	);
	
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

