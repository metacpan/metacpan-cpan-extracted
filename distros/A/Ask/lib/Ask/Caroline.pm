use 5.008008;
use strict;
use warnings;

package Ask::Caroline;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Moo;
use Caroline ();
use Path::Tiny 'path';
use Term::ANSIColor 'colored';
use namespace::autoclean;

with 'Ask::API';

has caroline => (
	is      => 'lazy',
	default => sub {
		my $self = shift;
		Scalar::Util::weaken( my $weak = $self );
		'Caroline'->new(
			completion_callback => sub {
				return unless $weak && $weak->has_completion;
				$weak->completion->( @_ );
			},
		);
	},
);

has completion => ( is => 'rw', predicate => 1, clearer => 1 );

sub BUILD {
	STDOUT->autoflush( 1 );
}

sub is_usable {
	my ( $self ) = @_;
	-t STDIN and -t STDOUT;
}

sub quality {
	my ( $self ) = ( shift );
	
	( ref( $self ) ? $self : 'Caroline'->new )->is_supported ? 90 : 30;
}

sub entry {
	my ( $self, %opts ) = ( shift, @_ );
	$opts{prompt} = 'entry> ' unless exists $opts{prompt};
	
	if ( exists $opts{completion} ) {
		$self->completion( $opts{completion} );
	}
	else {
		$self->completion(
			sub {
				return $opts{default};
			}
		);
	}
	
	if ( exists $opts{text} ) {
		$self->info(
			text   => $opts{text},
			colour => $opts{colour} || 'bright_cyan',
		);
	}
	
	my ( $line, $tio );
	
	if (
		$opts{hide_text}
		and do { require POSIX; $tio = 'POSIX::Termios'->new }
		)
	{
		$tio->getattr( 0 );
		$tio->setlflag( $tio->getlflag & ~POSIX::ECHO() );
		$tio->setattr( 0 );
		print STDOUT $opts{prompt};    # no new line;
		STDOUT->flush;
		chomp( $line = <STDIN> );
		$tio->setlflag( $tio->getlflag | POSIX::ECHO() );
		$tio->setattr( 0 );
		print STDOUT "\r\n";
		STDOUT->flush;
	} #/ if ( $opts{hide_text} ...)
	else {
		chomp( $line = $self->caroline->readline( $opts{prompt} ) );
	}
	
	$self->clear_completion;
	
	return $line;
} #/ sub entry

sub question {
	my ( $self, %opts ) = ( shift, @_ );
	$opts{prompt} = 'y/n> ' unless exists $opts{prompt};
	
	my $response = $self->entry( %opts );
	my $lang     = $self->_lang_support( $opts{lang} );
	$lang->boolean( $response );
}

sub print_findings {
	my ( $self, $findings, $fh ) = ( shift, @_ );
	
	if ( my @copy = @$findings ) {
		print {$fh} "\r\n";
		my $longest = 0;
		for ( @copy ) { $longest = length if length > $longest }
		my $per_line = int( 80 / ( $longest + 2 ) ) || 1;
		my $template = '%-' . ( $longest + 2 ) . 's';
		while ( @copy ) {
			my @chunk = splice @copy, 0, $per_line;
			while ( @chunk < $per_line ) {
				push @chunk, '';
			}
			printf {$fh} $template x $per_line, @chunk;
			print {$fh} "\r\n";
		}
		$fh->flush;
		return 1;
	} #/ if ( my @copy = @$findings)
	
	return;
} #/ sub print_findings

sub file_selection {
	my ( $self, %opts ) = ( shift, @_ );
	
	my $single = !$opts{multiple};
	
	$opts{prompt} = sprintf( '%s> ', $opts{directory} ? 'directory' : 'file' )
		unless exists $opts{prompt};
		
	unless ( $opts{text} ) {
		$opts{text} =
			$single
			? (
			$opts{directory} ? 'Please choose a directory.' : 'Please choose a file.' )
			: (
			$opts{directory}
			? 'Please choose some directories.'
			: 'Please choose some files.'
			);
	} #/ unless ( $opts{text} )
	
	$self->info(
		text   => $opts{text},
		colour => $opts{colour} || 'bright_cyan',
	);
	
	$self->info(
		text =>
			'Please enter one choice per line; leave a blank line to stop choosing.',
		colour => $opts{colour} || 'bright_cyan',
	) unless $single;
	
	$self->completion(
		sub {
			my $raw = shift;
			$raw = '.' unless length $raw;
			my $got = path( $raw );
			
			my @kids;
			
			if ( $got->is_dir ) {
				@kids = $opts{directory} ? grep( $_->is_dir, $got->children ) : $got->children;
			}
			else {
				my $dir  = $got->parent;
				my $stem = quotemeta( $got->basename );
				
				@kids = $opts{directory} ? grep( $_->is_dir, $dir->children ) : $dir->children;
				@kids = grep $_->basename =~ /^$stem/, @kids;
			}
			
			my @printable = sort map $_->basename . ( $_->is_dir ? '/' : '' ), @kids;
			unshift @printable, '.' if $got->is_dir;
			
			$self->print_findings( \@printable, \*STDOUT );
			return map "$_", ( $got->is_dir ? $got : () ), @kids;
		}
	);
	
	my @chosen;
	
	CHOICE: while ( 1 ) {
	
		chomp( my $line = $self->caroline->readline( $opts{prompt} ) );
		
		if ( $line eq '' ) {
			$single ? next( CHOICE ) : last( CHOICE );
		}
		
		if ( $opts{existing} and not path( $line )->exists ) {
			$self->error(
				text => sprintf( 'Does not exist: %s. Please try again.', $line ),
			);
		}
		elsif ( $opts{directory} and not path( $line )->is_dir ) {
			$self->error(
				text => sprintf( 'Not a directory: %s. Please try again.', $line ),
			);
		}
		else {
			push @chosen, $line;
			last CHOICE if $single;
		}
	} #/ CHOICE: while ( 1 )
	
	return $chosen[0] if $single;
	
	$self->clear_completion;
	
	return @chosen;
} #/ sub file_selection

sub single_choice {
	shift->multiple_choice( @_, _single => 1 );
}

sub multiple_choice {
	my ( $self, %opts ) = ( shift, @_ );
	
	my $single = $opts{_single};
	
	$opts{prompt} = 'choice> ' unless exists $opts{prompt};
	
	if ( exists $opts{text} ) {
		$self->info(
			text   => $opts{text},
			colour => $opts{colour} || 'bright_cyan',
		);
	}
	
	my %allowed;
	my @choices_list = map {
		$allowed{ $_->[0] } = 1;
		defined $_->[1] ? sprintf( '"%s" (%s)', @$_ ) : "\"$_->[0]\""
	} @{ $opts{choices} };
	
	$self->info(
		text   => sprintf( 'Choices: %s.', join( q[, ], @choices_list ) ),
		colour => $opts{colour} || 'bright_cyan',
	) unless $opts{hide_choices};
	
	$self->info(
		text =>
			'Please enter one choice per line; leave a blank line to stop choosing.',
		colour => $opts{colour} || 'bright_cyan',
	) unless $single;
	
	$self->completion(
		sub {
			my $got   = quotemeta( shift );
			my @found = grep /^$got/, map $_->[0], @{ $opts{choices} };
			$self->print_findings( \@found, \*STDOUT );
			return @found;
		}
	);
	
	my @chosen;
	
	CHOICE: while ( 1 ) {
	
		chomp( my $line = $self->caroline->readline( $opts{prompt} ) );
		
		if ( $line eq '' ) {
			$single ? next( CHOICE ) : last( CHOICE );
		}
		
		if ( $allowed{$line} ) {
			push @chosen, $line;
			last CHOICE if $single;
		}
		else {
			$self->error(
				text => sprintf( 'Not valid: %s. Please try again.', $line ),
			);
			$self->info(
				text   => sprintf( 'Choices: %s.', join( q[, ], @choices_list ) ),
				colour => $opts{colour} || 'bright_cyan',
			) unless $opts{hide_choices};
		}
	} #/ CHOICE: while ( 1 )
	
	return $chosen[0] if $single;
	
	$self->clear_completion;
	
	return @chosen;
} #/ sub multiple_choice

sub info {
	my ( $self, %opts ) = ( shift, @_ );
	chomp( my $text = $opts{text} );
	if ( $opts{colour} ) {
		$text = colored( [ $opts{colour} ], $text );
	}
	print STDOUT $text, "\n";
	STDOUT->flush;
}

sub warning {
	my ( $self, %opts ) = ( shift, @_ );
	$opts{colour} ||= 'bright_yellow';
	$self->info( %opts );
}

sub error {
	my ( $self, %opts ) = ( shift, @_ );
	$opts{colour} ||= 'bright_red';
	$self->info( %opts );
}

1;

__END__

=head1 NAME

Ask::Caroline - read lines never seemed so good

=head1 SYNOPSIS

	my $ask = Ask::Caroline->new;
	
	$ask->info(text => "I'm Charles Xavier");
	if ($ask->question(text => "Would you like some breakfast?")) {
		...
	}

=head1 DESCRIPTION

This backend is much like L<Ask::STDIO> but provides tab completion,
coloured output, etc.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Ask>.

=head1 SEE ALSO

L<Ask>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
