package Catalyst::Plugin::Activator::Exception;

use strict;
use warnings;
use Activator::Log qw( :levels );
use Activator::Exception;
use Symbol;

*{Symbol::qualify_to_ref('throw', 'Catalyst')} = sub {

    return &Catalyst::Plugin::Activator::Exception::throw( @_ );
};

sub throw {
    my ($c, $e) = @_;

    if ( !defined $e ) {
	$e = new Activator::Exception('unknown');
    }

    if ( $e eq '' ) {
	$e = new Activator::Exception('unknown');
    }

    if ( !$c->stash->{e}) {
	$c->stash->{e} = ();
    }

    if ( UNIVERSAL::isa( $e, 'Exception::Class' ) ) {
	push @{ $c->stash->{e} }, $e;
    }
    else {
	push @{ $c->stash->{e} }, Activator::Exception->new( $e );
    }
    return;
}

sub finalize {
    my ($c) = @_;
    if ( $c->stash->{e} ) {
	## TODO: figure out how to make this work. no level 1-8 makes
	## sense from the perspective of the log or the request
	#local $Log::Log4perl::caller_depth;
	#$Log::Log4perl::caller_depth += 8;
	WARN("Execution had error(s)");
	foreach my $e ( @{ $c->stash->{e} } ) {
	    WARN($e);
	}
    }
    delete $c->stash->{e};
    return $c->NEXT::finalize(@_);
}

__END__

=head1 AUTHOR

Karim A. Nassar

=head1 COPYRIGHT

Copyright (c) 2007 Karim A. Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
