use 5.008008;
use strict;
use warnings;

{
	package Ask::API;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.012';
	
	use Moo::Role;
	use Path::Tiny 'path';
	
	requires 'entry';  # get a string of text
	requires 'info';   # display a string of text
	
	sub _lang_support {
		my $self = shift;
		require Lingua::Boolean::Tiny;
		"Lingua::Boolean::Tiny"->new(@_);
	}
	
	sub is_usable {
		my ($self) = @_;
		return 1;
	}
	
	sub quality {
		return 50;
	}
	
	sub warning {
		my ($self, %o) = @_;
		$o{text} = "WARNING: $o{text}";
		return $self->info(%o);
	}

	sub error {
		my ($self, %o) = @_;
		$o{text} = "ERROR: $o{text}";
		return $self->info(%o);
	}

	sub question {
		my ($self, %o) = @_;
				
		my $response = $self->entry(text => $o{text});
		my $lang     = $self->_lang_support($o{lang});
		$lang->boolean($response);
	}
	
	sub file_selection {
		my ( $self, %opts ) = ( shift, @_ );
		
		$opts{text} ||= 'Enter file name';
		
		my @chosen;
		
		FILE: {
			my $got = $self->entry( text => $opts{text} );
			
			if ( not length $got ) {
				last FILE if $opts{multiple};
				redo FILE;
			}
			
			$got = path $got;
			
			if ( $opts{existing} and not $got->exists ) {
				$self->error( text => 'Does not exist.' );
				redo FILE;
			}
			
			if ( $opts{directory} and not $got->is_dir ) {
				$self->error( text => 'Is not a directory.' );
				redo FILE;
			}
			
			push @chosen, $got;
			
			if ( $opts{multiple} ) {
				$self->info( text => 'Enter another file, or leave blank to finish.' );
				redo FILE;
			}
		};
		
		$opts{multiple} ? @chosen : $chosen[0];
	}
	
	my $format_choices = sub {
		my ($self, $choices) = @_;
		join q[, ], map { sprintf('"%s" (%s)', @$_) } @$choices;
	};
	
	my $filter_chosen = sub {
		my ($self, $choices, $response) = @_;
		my $valid   = {}; $valid->{$_->[0]}++ for @$choices;
		my @choices = ($response =~ /\w+/g);
		return(
			[ grep  $valid->{$_}, @choices ],
			[ grep !$valid->{$_}, @choices ],
		);
	};
	
	sub multiple_choice {
		my ($self, %o) = @_;
		my $choices = $self->$format_choices($o{choices});
		
		my ($allowed, $disallowed, $repeat);
		
		for (;;) {
			my $response = $self->entry(
				text       => "$o{text}. Choices: $choices. (Separate multiple choices with white space.)",
				entry_text => $repeat || '',
			);
			($allowed, $disallowed) = $self->$filter_chosen($o{choices}, $response);
			if (@$disallowed) {
				my $d = join q[, ], @$disallowed;
				$self->error(
					text => "Not valid: $d. Please try again.",
				);
				$repeat = join q[ ], @$allowed;
			}
			else {
				last;
			}
		}
		
		return @$allowed;
	}

	sub single_choice {
		my ($self, %o) = @_;
		my $choices = $self->$format_choices($o{choices});
		
		my ($allowed, $disallowed, $repeat);
		
		for (;;) {
			my $response = $self->entry(
				text       => "$o{text}. Choices: $choices. (Choose one.)",
				entry_text => $repeat || '',
			);
			($allowed, $disallowed) = $self->$filter_chosen($o{choices}, $response);
			if (@$disallowed) {
				my $d = join q[, ], @$disallowed;
				$self->error(
					text => "Not valid: $d. Please try again.",
				);
				$repeat = $allowed->[0];
			}
			elsif (@$allowed != 1) {
				$self->error(
					text => "Not valid: choose one.",
				);
				$repeat = $allowed->[0];
			}
			else {
				last;
			}
		}
		
		return $allowed->[0];
	}
}

1;

__END__

=head1 NAME

Ask::API - an API to ask users things

=head1 SYNOPSIS

	{
		package Ask::AwesomeWidgets;
		use Moo;
		with 'Ask::API';
		sub info {
			my ($self, %arguments) = @_;
			...
		}
		sub entry {
			my ($self, %arguments) = @_;
			...
		}
	}

=head1 DESCRIPTION

C<Ask::API> is a L<Moo> role. This means that you can write your
implementation as either a Moo or Moose class.

The only two methods that you absolutely must implement are C<info> and
C<entry>.

C<Ask::API> provides default implementations of C<warning>, C<error>,
C<question>, C<file_selection>, C<multiple_choice> and C<single_choice>
methods, but they're not espcially good, so you probably want to implement
most of those too.

If you name your package C<< Ask::Something >> then C<< Ask->detect >>
will find it (via L<Module::Pluggable>).

Methods used during detection are C<is_usable> which is called as an
object method, and should return a boolean indicating its usability (for
example, if STDIN is not connected to a terminal, Ask::STDIO returns
false), and C<quality> which is called as a class method and should return
a number between 0 and 100, 100 being a high-quality backend, 0 being
low-quality.

C<< Ask->detect >> returns the highest quality module that it can load,
instantiate and claims to be usable.

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

