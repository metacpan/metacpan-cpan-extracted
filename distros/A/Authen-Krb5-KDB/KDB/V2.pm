package Authen::Krb5::KDB::V2;

# $Id: V2.pm,v 1.8 2002/10/09 20:42:10 steiner Exp $

use Carp;
use POSIX qw(strftime);
use strict;
use vars qw($VERSION);

$VERSION = do{my@r=q$Revision: 1.8 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
        # checks => level
        # data => "string"

    $args{'raw_data'} = $args{'data'};

    my $p = $class->new_princ ( %args );
    return $p;
}

sub new_princ {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
        # checks => level
        # data => "string"
    my $self = {};
    my @data;

    if (defined($args{'data'})) {
	if ($args{'data'} =~ /;$/) { 
	    chop($args{'data'});
	} else {
	    croak "princ record missing final ';' at line $args{'lineno'}";
	}
	@data = split(/\t/, $args{'data'});
	$self->{'raw_data'} = defined($args{'raw_data'}) ? $args{'raw_data'} : $args{'data'};
    } else {
	croak "data for new principal not defined at line $args{'lineno'}";
    }

    $self->{'type'} = 'princ';

croak "V2 not yet implemented."; # XXX

    if (@data) {
	carp "Still data left: @data";
    }
    bless($self, $class);
    return $self;
}

sub _strdate {
    my $when = shift;
    return "[never]"  if (not $when);
    my @tm = localtime($when);
    return strftime("%a %b %d %H:%M:%S %Z %Y", @tm);
}

1;
__END__

=head1 NAME

Authen::Krb5::KDB::V2 - objects for Kerberos V5 database V2 principals


=head1 SYNOPSIS

Generally you won't load this library or call it's C<new> methods directly.
See L<Authen::Krb5::KDB> for more information.

    use Authen::Krb5::KDB::V2;

    $p = Authen::Krb5::KDB::V2->new( data => "..." );

    [XXX]

=head1 DESCRIPTION

=over 4

=item  new( data => "..." )

Parses version 2 principal entries and returns the data via an object.
Calls C<new_princ> to do the work.

Arguments are:

data => E<lt>stringE<gt>

Data to be parsed.  This argument is required.

checks => E<lt>levelE<gt>

Data checking level.  Level 0 means no checks; level 1 (the default)
does basic checks like checking that the lengths in the records are
correct; level 2 does much further consistency checks on the data.

lineno => E<lt>NE<gt>

Line number of the data file where this data came from (for error messages).

=back


=head2 Principals

=over 4

=item  new_princ( data => "..." )

Parses version 2 principal entries and returns the data via an object.

Arguments are:

data => E<lt>stringE<gt>

Data to be parsed.  This argument is required.

checks => E<lt>levelE<gt>

Data checking level.  Level 0 means no checks; level 1 (the default)
does basic checks like checking that the lengths in the records are
correct; level 2 does much further consistency checks on the data.

lineno => E<lt>NE<gt>

Line number of the data file where this data came from (for error messages).

=back


Methods to retrieve and set data fields are:

    [These methods are not implemented yet for V2.]


=head1 AUTHOR

Dave Steiner, E<lt>steiner@bakerst.rutgers.eduE<gt>


=head1 COPYRIGHT

Copyright (c) 2002 David K. Steiner.  All rights reserved.  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), kerberos(1), Authen::Krb5::KDB, Authen::Krb5::KDB_H.

=cut
