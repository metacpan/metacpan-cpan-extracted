use 5.008008;
use strict;
use warnings;

package Ask::Prima;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Moo;
use Prima 1.59 ();
use Path::Tiny 'path';
use namespace::autoclean;

with 'Ask::API';

has application => (
	is      => 'lazy',
	default => sub {
		require Prima::Application;
		require Prima::MsgBox;
		'Prima::Application'->import;
		return 1;
	},
);

sub is_usable {
	my ( $self ) = ( shift );
	return !!$ENV{'DISPLAY'};
}

sub entry {
	my ( $self, %opts ) = ( shift, @_ );
	
	$self->application;
	
	my $return = Prima::MsgBox::input_box(
		$opts{title}   || 'Input',
		$opts{text}    || 'Enter text:',
		$opts{default} || '',
	);
	
	return $return;
} #/ sub entry

sub info {
	my ( $self, %opts ) = ( shift, @_ );
	
	$self->application;
	
	Prima::MsgBox::message_box(
		$opts{title} || 'Info',
		$opts{text},
		mb::Ok | mb::Information,
	);
	
	return;
} #/ sub info

sub warning {
	my ( $self, %opts ) = ( shift, @_ );
	
	$self->application;
	
	Prima::MsgBox::message_box(
		$opts{title} || 'Warning',
		$opts{text},
		mb::Ok | mb::Warning,
	);
	
	return;
} #/ sub warning

sub error {
	my ( $self, %opts ) = ( shift, @_ );
	
	$self->application;
	
	Prima::MsgBox::message_box(
		$opts{title} || 'Error',
		$opts{text},
		mb::Ok | mb::Error,
	);
	
	return;
} #/ sub error

sub question {
	my ( $self, %opts ) = ( shift, @_ );
	
	$self->application;
	
	my $return;
	
	Prima::MsgBox::message_box(
		$opts{title} || 'Question',
		$opts{text},
		mb::Yes | mb::No | mb::Question,
		buttons => {
			mb::Yes,
			{
				text    => $opts{ok_label} || 'Yes',
				onClick => sub { $return = 1 },
			},
			mb::No,
			{
				text    => $opts{cancel_label} || 'No',
				onClick => sub { $return = 0 },
			},
		},
	);
	
	return $return;
} #/ sub question

sub file_selection {
	my ( $self, %opts ) = ( shift, @_ );
	
	$self->application;
	
	require Prima::Dialog::FileDialog;
	
	my $dl;
	
	if ( $opts{directory} ) {
		if ( $opts{multiple} ) {
			my @dirs;
			while ( 1 ) {
				$dl = 'Prima::Dialog::ChDirDialog'->new;
				if ( $dl->execute ) {
					push @dirs, path( $dl->directory );
				}
				$self->question( text => "Select another directory?" ) or last;
			}
			return map path( $_ ), @dirs;
		} #/ if ( $opts{multiple} )
		else {
			$dl = 'Prima::Dialog::ChDirDialog'->new;
			if ( $dl->execute ) {
				return path( $dl->directory );
			}
		}
	} #/ if ( $opts{directory} )
	else {
		my $class =
			$opts{save}
			? 'Prima::Dialog::SaveDialog'
			: 'Prima::Dialog::FileDialog';
			
		my %dlopts = (
			system        => 1,
			showDotFiles  => 1,
			fileMustExist => 0+ !!$opts{existing},
			multiSelect   => 0+ !!$opts{multiple},
		);
		if ( $opts{default} ) {
			$dlopts{fileName} = $opts{multiple} ? $opts{default} : [ $opts{default} ];
		}
		
		$dl = $class->new( %dlopts );
		
		if ( $dl->execute ) {
			return map path( $_ ), $dl->fileName;
		}
	} #/ else [ if ( $opts{directory} )]
	
	$opts{multiple} ? @{ $opts{default} or [] } : $opts{default};
} #/ sub file_selection

1;

__END__

=head1 NAME

Ask::Prima - interact with a user via the Prima GUI

=head1 SYNOPSIS

	my $ask = Ask::Prima->new;
	
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

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
