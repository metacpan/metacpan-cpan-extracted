package DateTime::TimeZone::Alias;

use strict;

use Carp qw( croak );
use DateTime::TimeZone::Catalog;

use vars qw( $VERSION );
$VERSION = 0.06;

sub import {
    my $class = shift;

    return unless @_;

    $class->set( @_ );
}

sub set {
    my $class = shift;

    croak "Can't be called without any parameters" unless @_;

    my %p = @_;

    foreach my $key ( keys %p ) {
    	if ( $class->is_alias( $p{ $key } ) ) {
    		$DateTime::TimeZone::Catalog::LINKS{ $key } =
    			$DateTime::TimeZone::Catalog::LINKS{ $p{ $key } }; 
    	} elsif ( $class->is_timezone( $p{ $key } ) ) {
    		$DateTime::TimeZone::Catalog::LINKS{ $key } = $p{ $key };
    	} elsif ( $p{ $key } eq 'floating' ) {
    		$DateTime::TimeZone::Catalog::LINKS{ $key } = 'floating';
    	} elsif ( $p{ $key } eq 'local' ) {
    		$DateTime::TimeZone::Catalog::LINKS{ $key } = 'local';
    	} elsif ( $p{ $key } eq 'UTC' || $p{ $key } eq 'Z' ) {
    		$DateTime::TimeZone::Catalog::LINKS{ $key } = 'UTC';
    	} elsif ( $p{ $key } =~ /^ ([\+\-])? (\d\d?) :? (\d\d) (?::?(\d\d))? $/x ) {
        		my $sign	= $1 || '+';
    		my $hours	= $2;
    		my $minutes	= $3;
    		my $seconds	= sprintf( "%02d", $4 || 0 );

    		$DateTime::TimeZone::Catalog::LINKS{ $key } = "$sign$hours:$minutes:$seconds";
    	} else {
    		croak "Aliases must point to a valid timezone or offset";
    	}
    }
}

sub add {
    my $class = shift;

    croak "Can't be called without any parameters" unless @_;

    my %p = @_;

    foreach my $key ( keys %p ) {
    	if ( ! $class->is_defined( $key )) {
    		$class->set( %p );
    	} else {
    		croak "Attempt to redefine an alias or timezone";
    	}
    }
}

sub remove {
    my $class = shift;

    return unless @_;

    foreach my $key ( @_ ) {
    	if ( ! $class->is_alias( $key ) ) {
    		croak "Attempt to delete a nonexistant alias";
    	}

    	delete $DateTime::TimeZone::Catalog::LINKS{ $key };
    }
}

sub value {
    my( $class, $key ) = @_;

    if ( $class->is_alias( $key ) ) {
    	return $DateTime::TimeZone::Catalog::LINKS{ $key };
    } else {
    	return undef;
    }
}

sub is_defined {
    my( $class, $def_candidate ) = @_;

    if (
    	$class->is_timezone( $def_candidate )
    	|| $class->is_alias( $def_candidate )
    ) {
    	return 1;
    } else {
    	return undef;
    }
}

sub is_alias {
    my( $class, $alias_candidate ) = @_;

    if ( exists $DateTime::TimeZone::Catalog::LINKS{ $alias_candidate } ) {
    	return 1;
    } else {
    	return undef;
    }
}

sub is_timezone {
    my( $class, $tz_candidate ) = @_;

    if ( grep( /^\Q${tz_candidate}\E$/, @DateTime::TimeZone::Catalog::ALL ) ) {
    	return 1;
    } else {
    	return undef;
    }
}

sub aliases {
    my $class = shift;

    return unless defined wantarray;

    if ( wantarray ) {
    	return %DateTime::TimeZone::Catalog::LINKS;
    } else {
    	my %dttz_links_copy = %DateTime::TimeZone::Catalog::LINKS;
    	return \%dttz_links_copy;
    }
}

sub timezones {
    my $class = shift;

    return unless defined wantarray;

    if ( wantarray ) {
    	return @DateTime::TimeZone::Catalog::ALL;
    } else {
    	my @dttz_all_copy = @DateTime::TimeZone::Catalog::ALL;
    	return \@dttz_all_copy;
    }
}

1;

__END__
