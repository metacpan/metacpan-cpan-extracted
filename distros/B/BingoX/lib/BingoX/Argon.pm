# BingoX::Argon
# -----------------
# $Revision: 2.9 $
# $Date: 2001/11/20 19:11:14 $
# ---------------------------------------------------------

=head1 NAME

Argon - Common methods used by many application classes.

=head1 SYNOPSIS

package MyApplication;
@MyApplication::ISA = qw(BingoX::Argon);
use BingoX::Argon;

  # $BR - Blessed Reference
  # $SV - Scalar Value
  # @AV - Array Value
  # $HR - Hash Ref
  # $AR - Array Ref
  # $SR - Stream Ref

  # $proto - BingoX::Carbon object OR sub-class
  # $object - BingoX::Carbon object

  $BR = $proto->new()
  $BR = $app->r()
  $BR = $app->dbh()
  $BR = $app->cgi()
  $BR = $app->conf()
        $app->include()
        $app->xinclude()
  $HR = $app->display_classes()
  $BR = $app->get()
  $AR = $app->list()
  $SR = $app->stream()

=head1 REQUIRES

Apache::XPP

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

BingoX::Argon is an application superclass that handles basic tasks like returning 
display objects, handling xincludes, and caching request and cgi objects.

I'm hoping it won't do too much else: Display classes have to do SOMETHING, 
don't they?

=head1 CLASS VARIABLES

=over 4

=item * %display_classes

This is how Argon will know what classes it can call. 
The keys are the name of the function and the value is the class name.

For example:
  %display_classes = (thingees => 'Application::Display::Thingee');

You can then call get_ , list_ , or stream_thingees(), passing a hashref 
of the data fields by which you want to limit your search. 

=back

=head1 METHODS

=head2 CONSTRUCTORS

=over 4

=cut

package BingoX::Argon;

use Apache::XPP;

use strict;
use vars qw($debug $AUTOLOAD);

BEGIN {
	$BingoX::Argon::REVISION	= (qw$Revision: 2.9 $)[-1];
	$BingoX::Argon::VERSION		= '1.92';
	
	$debug	= undef;

	if ($debug) {
		eval 'use Data::Dumper';
	}
}

=item C<new> ( [ \%data ] )

Creates a new Application object.

=cut
sub new {
	my $self	= shift;
	my $class	= ref($self) || $self;
	## backward compatibility: $r was traditionally the first arg passed. ##
	my $r		= (ref($_[0]) eq 'HASH') ? $class->r : shift;
	## Next comes the (optional) data ##
	my $data	= shift || { };
	$data->{'_r'} ||= $r;
	bless $data, $class;
} # END of new


=back

=head2 OBJECT METHODS

=over 4

=item C<r> (  )

returns the Display object's Apache request object. Or if for some 
reason the object doesn't have one, it creates a new one.

=cut
sub r { ref($_[0]) ? $_[0]->{'_r'} ||= Apache->request : Apache->request }


=item C<available_display_classes> (  )

Static method returns the subclass's \%display_classes.

=cut
sub display_classes {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	(defined %{"${class}::display_classes"}) ? \%{"${class}::display_classes"} : { };
} # END of display_classes


=item C<data_class> (  )

Static method returns data class defined for application subclass.  
If none is assigned, guess. :-)

=cut
sub data_class {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	${"${class}::data_class"} || $class . '::Data';
} # END of data_class


=item C<dbh> (  )

Caches and returns a reference to the app's Data Class dbh.

=cut
sub dbh {
	my $self	= shift;
	my $class	= ref($self) || return undef;
	return $self->{'_dbh'} if (ref $self->{'_dbh'});
	$self->{'_dbh'} = $self->data_class->dbh if ($self->data_class->can('dbh'));
	warn "No data classes found for $class" unless (ref $self->{'_dbh'});
	return $self->{'_dbh'};
} # END of dbh


=item C<cgi> (  )

Returns the current CGI object or creates a new one.

=cut
sub cgi { ref($_[0]) ? $_[0]->{'_cgi'} ||= CGI->new : CGI->new }


=item C<conf> (  )

Caches and returns a Conf object.
Overload this if you want to use a static Conf module.

=cut
sub conf {
	ref($_[0])
	?
	$_[0]->{'_conf'} ||= Conf->new( $_[0]->r->dir_config('conf') )
	:
	Conf->new( $_[0]->r->dir_config('conf') )
} # END of conf


=item C<query_url> ( )

Returns the path of the user's location.

=cut
sub query_url {
	return $_[0]->cgi->url( -ABSOLUTE => 1);
} # END of query_url


=item C<param> ( $name )

Returns cgi params.

=cut
sub param {
	my $self = shift;
	return $self->cgi->param( shift() );
} # END of param


=item C<escape> ( $name )

Returns cgi escape.

=cut
sub escape {
	my $self = shift;
	return $self->cgi->escape( shift() );
} # END of escape


=item C<delete> ( $name )

Deletes from the cgi params.

=cut
sub delete {
	my $self	= shift;
	my $q		= $self->cgi;
	foreach (@_) { $q->delete( $_ ) }
	return;
} # END of delete


=item C<include> ( $template )

Forwarding method:

Calls L<Apache::XPP>->include() and passes it the $template.

=cut
sub include { Apache::XPP->include( $_[1] ) }


=item C<xinclude> ( $template [, $obj ] )

Forwarding method:

Includes $obj in the $template.  
Calls L<Apache::XPP->xinclude()> and passes it the default array.

=cut
sub xinclude {
	my $self	= shift;	# shift it out 'cause we ain't passing it.
	Apache::XPP->xinclude( @_ );
} # END of xinclude


=item C<AUTOLOAD> (  )

This will first look in instance data, then go through the sub class's 
%display_classes field and see if it's in %display_classes reference.  
If it is, it will try and get it using passed params.  

Returns undef on error.

=cut
sub AUTOLOAD {
	return if $AUTOLOAD =~ /::DESTROY$/o;
	my $self	= shift;
	my $lname	= $AUTOLOAD;
	$lname		=~ s/^.*://o;				# strip fully-qualified portion

	warn("AUTOLOADing ".(ref($self)||$self)."::${lname} in BingoX::Argon")
		if $debug;

	## return instance data if it exists ##
	return $self->{ $lname } if (ref($self) && defined($self->{ $lname }));

	## try the methods ##
	my ($prefix,$name) = split(/_/, $lname, 2);	# get the type and name

	## make sure it's a "get_", "list_", or "stream_" method ##
	return unless ($prefix && $name);
	return undef unless ($prefix eq 'stream' || $prefix eq 'list' || $prefix eq 'get');
	my $method = $prefix . (($prefix eq 'get') ? '' : '_obj');
	## get the associated display class (and return if you can't find it) ##
	my $displayclass = $self->display_classes->{ $name } || return undef;
	if ($displayclass->data_class) {
		## limit it by any params they happen to pass. ##
		my $params	= shift || { };
		my $q		= $self->cgi;
		## and by anything in the CGI object. ##
		foreach (@{ $displayclass->data_class->fieldorder }) {
			## explicitly passed params override what's in the CGI object ##
			unless (exists $params->{$_}) {
				$params->{$_} = $q->param($_) if (defined $q->param($_));
				warn("$displayclass: $_ ==> $params->{$_}") if $debug > 1;
			}
		}
		warn(Data::Dumper::Dumper($params)) if $debug > 1;
		## get methods should have params of some sort ##
		return undef if ($prefix eq 'get' && !%{ $params });
		return $displayclass->$method( $self, $self->dbh, $params, @_ );
	} else {	# some display classes don't have data classes
		return $displayclass->new( @_ );
	}
} # END of AUTOLOAD

1;

__END__

=back

=head1 REVISION HISTORY

 $Log: Argon.pm,v $
 Revision 2.9  2001/11/20 19:11:14  gefilte
 AUTOLOAD()
 	- named method splitting set to '2' results.  (This was breaking names which intentionally contained underscores, since the split parts were not captured.)
 	- fully qualified left over 'Dumper' call

 Revision 2.8  2000/12/12 18:48:01  useevil
  - updated version for new release:  1.92

 Revision 2.7  2000/10/20 17:23:18  gefilte
 Removed Data::Dumper requirement.  (Only loaded if $debug is on.)

 Revision 2.6  2000/10/20 00:28:24  zhobson
 Added some useful debug messages to AUTOLOAD

 Revision 2.5  2000/09/19 23:40:00  dweimer
 Version update 1.91

 Revision 2.4  2000/08/31 21:54:18  greg
 Added COPYRIGHT information.
 Added file COPYING (LGPL).
 Cleaned up POD.
 Moved into BingoX namespace.
 References to Bingo::XPP now point to Apache::XPP.

 "To the first approximation, syntactic sugar is trivial to implement.
  To the second approximation, the first approximation is totally bogus."
    -Larry Wall

 Revision 2.3  2000/08/01 00:38:28  thai
  - added cgi accessor methods:
    query_url()
    param()
    escape()
    delete()

 Revision 2.2  2000/07/12 19:28:21  thai
  - fixed POD, cleaned up code

 Revision 2.1  2000/05/19 01:22:56  thai
  - cleaned up code
  - is the top level class for all Bingo Applications

 Revision 2.0  2000/05/02 00:54:33  thai
  - committed as 2.0


=head1 THOUGHTS, LYRICS, POEMS, CANTRIPS, RHYMES

"Ray, when someone asks you if you're a god, you say YES!"

    -Winston

=head1 SEE ALSO

perl(1).

=head1 KNOWN BUGS

None

=head1 COPYRIGHT

    Copyright (c) 2000, Cnation Inc. All Rights Reserved. This module is free
    software. It may be used, redistributed and/or modified under the terms
    of the GNU Lesser General Public License as published by the Free Software
    Foundation.

    You should have received a copy of the GNU Lesser General Public License
    along with this library; if not, write to the Free Software Foundation, Inc.,
    59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHOR

Colin Bielen <colin@cnation.com>

=cut
