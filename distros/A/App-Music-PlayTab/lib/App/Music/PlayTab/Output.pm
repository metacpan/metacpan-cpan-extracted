#! perl

# Author          : Johan Vromans
# Created On      : Thu Mar 27 16:46:54 2014
# Last Modified By: Johan Vromans
# Last Modified On: Tue Dec  5 13:14:36 2017
# Update Count    : 177
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::Output;

use strict;
use warnings;

our $VERSION = "0.001";

sub new {
    my ( $pkg, $args ) = @_;
    my $self = bless {}, $pkg;

    my $generator = $args->{generate};
    my $genpkg = __PACKAGE__ . "::" . $generator;
    eval "use $genpkg";
    die("Cannot find backend for $generator\n$@") if $@;
    $self->{generator} = $genpkg->new($args);

    if ( $args->{output} && $args->{output} ne "-" ) {
	open( $self->{fh}, '>', $args->{output} )
	  or die( $args->{output}, ": $!\n" );
	$self->{fhneedclose} = 1;
    }
    else {
	$self->{fh} = *STDOUT;
	$self->{fhneedclose} = 0;
    }

    $self;
}

sub finish {
    my $self = shift;
    return unless $self->{generator};
    $self->{generator}->finish;
    undef $self->{generator};
    close($self->{fh}) if $self->{fhneedclose};
}

sub DESTROY {
    &finish;
}

sub generate {
    my ( $self, $args ) = @_;

    my $gen = $self->{generator};
    $gen->{fh} = $self->{fh};
    if ( $gen->{raw} ) {
	$gen->generate($args);
	return;
    }

    my $opus = $args->{opus};

    $gen->setup( $args );
    $gen->setuppage( $opus->{title}, $opus->{subtitle} );
    my $prev_line = "";

    foreach my $line ( @{ $opus->{lines} } ) {

	$gen->setupline($line);

	if ( $line->{measures} ) {

	    if ( $prev_line eq 'bars' ) {
		$gen->newline();
	    }
	    if ( $line->{prefix} && $line->{prefix} ne "" ) {
		$gen->newline( $line->{pfx_vsp} )
		  if $prev_line;
		$gen->text( $line->{prefix} );
	    }
	    elsif ( $line->{pfx_vsp} ) {
		$gen->newline( $line->{pfx_vsp} - 1 )
		  if $prev_line;
	    }

	    $gen->bar(1) if @{ $line->{measures} };
	    foreach ( @{ $line->{measures} } ) {
		for ( my $i = 0; $i < @$_; $i++ ) {
		    my $c = $_->[$i];
		    # Mostly, chords are followed by a number of
		    # 'spaces', basically chord repetitions that are
		    # not printed. Count the spaces and pass as an
		    # argument to the chord renderer. Note that this
		    # should be done by the parser instead of here.
		    my $dup = 1;
		    while ( $i+1 < @$_ && $_->[$i+1] eq 'space' ) {
			$i++;
			$dup++;
		    }
		    $gen->chord( $c, $dup );
		}
		$gen->bar(0);
	    }
	    if ( $line->{postfix} && $line->{postfix} ne "" ) {
		$gen->postfix( $line->{postfix} );
	    }
	    $gen->newline();
	    $prev_line = 'bars';
	    next;
	}

	if ( $line->{chords} ) {

	    if ( $line->{pfx_vsp} && $prev_line ) {
		$gen->newline( $line->{pfx_vsp} );
	    }

	    if ( $line->{prefix} && $line->{prefix} ne "" ) {
		$gen->text( $line->{prefix} );
	    }

	    $gen->grids( $line->{chords} );
	    $gen->newline();
	    $prev_line = 'chords';
	    next;
	}

	if ( $line->{prefix} && $line->{prefix} ne "" ) {
	    $gen->text( $line->{prefix} );
	    $gen->newline();
	    $prev_line = 'text';
	    next;
	}
    }
}

1;

__END__

=head1 NAME

App::Music::PlayTab::Output - Output driver.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
