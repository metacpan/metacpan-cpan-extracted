package Acme::Moose;
use Moose;
our $VERSION = '0.02';

=head1 NAME

Acme::Moose - An object-oriented interface to Moose in what else but Moose.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Acme::Moose;
  my $moose = Acme::Moose->new;
  $moose->feed;
  $moose->play;
  $moose->sacrifice;

=head1 DESCRIPTION

This module provides a simplistic, but powerful, interface to a Moose.

=head1 OBJECT INTERFACE

=over

=item B<new>

Create a new moose, all by yourself! :)

=cut

has [ 'foodage','happiness','tired']=> (is=>'rw',default=>0,isa=>'Int',init_arg=>"");
no Moose;

=item B<feed>

A well-fed moose is a happy moose.
The perl gods like happy moose.
Too much food makes a sad moose though. :(
No one likes a sad moose.

[Technical details: returns 1 for a happy hungry moose, and returns 0
for a big full moose. ]

=cut

sub feed {
	my $self = shift;
    $self->foodage($self->foodage()+1);
    if   ( $self->foodage() < 10 ) { 
    	$self->happiness($self->happiness+1) and return 1; 
    }
    else {
		$self->happiness($self->happiness()-1) and return; 
	}
}

=item B<play>

A good moose trainer should play often with their moose, 
as this makes them happy.
Moose get tired though, and then they don't like to play,
they need rest instead then.

[Technical details: returns 1 for a moose that wants to play more,
and returns for a moose that needs a nap. ]

=cut

sub play {
	my $self = shift;
    if ( $self->tired() == 1 ) {
        $self->happiness($self->happiness-5);
        return;
    }
    my $int = int( rand(20) );
    $self->happiness($self->happiness+2);
    if ( $int > 10 ) {
        $self->tired(1);
        return;
    }
    else {
       $self->tired(0);
       return 1;
    }
}

=item B<nap>

Sometimes, even a big Moose get tired.
When Moose are tired, they need a nap to make them 
feel better! But, if the Moose isn't tired, making it
try to take a nap will make it a sad Moose. :(

=cut

sub nap {
	my $self = shift;
    if ($self->tired == 0 ) { 
    	$self->happiness($self->happiness-1); 
    	return; 
    }
    else { 
    	$self->tired(0) and $self->happiness( $self->happiness()+1); 
    	return 1; 
    }
}

=item B<sacrifice>

Ah, we finally have reached the last goal of all good Moose. Sacrificing to the perl gods. 
You'd best hope your Moose was happy enough, or death to your Perl script will come! :(

=back
=cut

sub sacrifice {
    my ( $self) = shift;
    my ( $args ) = @_;
    $args->{'TO'} ||= '';
  
    if ( lc( $args->{'TO'} ) ne 'perl gods' ) {
        die('Who are you sacrificing this Moose to?');
    }
    if ( $self->happiness() > 10 ) {
        print(
"Congratulations. Your sacrifical Moose has appeased the Perl gods!\n"
        );
        exit;
    }
    else {
        die(
"Sorry, your Moose was not happy enough. Try to raise it better next time! :("
        );
    }
}

1;

=head1 AUTHOR

John Scoles <byterock@cpan.org>

=head1 LICENSE

Copyright (c) John Scoles 

This module may be used, modified, and distributed under BSD license. See the beginning of this file for said license.

=head1 SEE ALSO



=cut
