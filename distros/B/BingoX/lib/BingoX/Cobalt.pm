# BingoX::Cobalt
# -----------------
# $Revision: 2.15 $
# $Date: 2000/12/12 18:53:36 $
# ---------------------------------------------------------

=head1 NAME

BingoX::Cobalt - Cobalt display parent class containing generic methods

=head1 SYNOPSIS

use BingoX::Cobalt;

  # $BR - Blessed Reference
  # $SV - Scalar Value
  # @AV - Array Value
  # $HR - Hash Ref
  # $AR - Array Ref
  # $SR - Stream Ref

  # $proto - BingoX::Cobalt object OR sub-class
  # $object - BingoX::Cobalt object

CONSTRUCTORS

  $BR = $proto->new( [ $app, $dbh, ] $data_object );
  $BR = $proto->get( [ $dbh, ] \%params );

STREAM CONSTRUCTOR METHODS

  $SR = $proto->stream_obj( $app [, $dbh, ] @_ );
  $SR = $proto->stream_hash( [ $dbh, ] @_ );
  $SR = $proto->stream_array( [ $dbh, ] @_ );

LIST CONSTRUCTOR METHODS

  $AR = $proto->list_obj( $app [, $dbh, ] @_ );
  $AR = $proto->list_hash( [ $dbh, ] @_ );
  $AR = $proto->list_array( [ $dbh, ] @_ );

RELATION METHODS

  $SR = $object->stream_related( $rel_display_class [, \@fields] [, \@sort] [, $unary_rev_flag ] );
  $AR = $object->list_related( $rel_display_class [, \@fields] [, \@sort] [, $unary_rev_flag ] );

OBJECT METHODS

  $BR = $object->db_obj(  );
  $BR = $object->dbh(  );
  $BR = $object->app(  );
  $BR = $proto->r(  );
  $BR = $proto->cgi(  );
  $BR = $proto->conf(  );

PARSER METHODS

  $SV = $object->include( @_ );
  $SV = $object->xinclude( @_ );

CLASS DATA ACCESSOR METHODS

  $SV = $proto->data_class(  );
  $HR = $proto->display_fields(  );
  $AR = $proto->display_order(  );

=head1 REQUIRES

BingoX::Time, CGI, Carp, strict

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

Cobalt provides the generic API for BingoX display classes.  
Cobalt uses display objects that wrap Carbon data objects 
(Cobalt mono Carbide?).

=head1 CLASS VARIABLES

Classes that inherit from Cobalt should have the following class variables:

=head2 REQUIRED

=over 4

=item * @display_order

The order in which to display fields (if one so chose to display them ;)

=back

=head2 OPTIONAL

=over 4

=item * $data_class

The name of the data class that corresponds to the display class. If this 
value is not defined, it will default to the name of the display class, with 
the first instance of "::Display::" changed to "::Data::".

=item * %display_fields

A total mystery. If this variable is not defined, eack key is an field from the 
C<@display_order> variable, and each value is 1.

=back

=head1 METHODS

=cut

package BingoX::Cobalt;


use CGI;
use Carp;
use strict;
use BingoX::Time;
use vars qw($AUTOLOAD $debug);

BEGIN {
	$BingoX::Cobalt::REVISION	= (qw$Revision: 2.15 $)[-1];
	$BingoX::Cobalt::VERSION	= '1.92';
	
	$debug	= undef;
}

=head2 CONSTRUCTORS

=over 4

=item C<new> ( [ $app ] [, $dbh ], $data_obj )

Given a data object, returns a Display object of the class B<it was called as>.  
This means you could concievably provide a data object of a totally inapproriate 
type, and this method will not compain about it.

=cut
sub new {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $app		= ref($self) ? $self->app : shift;
	my $dbh		= ref($self) ? $self->dbh : shift;
	my $data	= shift;

	bless({
			_app	=> $app,
			_date	=> BingoX::Time->new,
			_db_obj	=> $data,
			_dbh	=> $dbh
		}, $class);
} # END of new


=item C<get> ( [ $app ] [, $dbh, ] \%params )

Returns a display object.

=cut
sub get {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $app		= ref($self) ? $self->app : shift;
	my $dbh		= ref($self) ? $self->dbh : shift;
	my $params	= shift || return undef;

	my $code = $class->stream_obj( $app, $dbh, $params, @_ ) || return undef;
	my $obj = $code->();
	$code->(1);			# finish
	undef $code;
	return $obj;
} # END of get


=back

=head2 STREAM METHODS

=over 4

=item C<stream_obj> ( $app [, $dbh ], @_ )

Returns an stream (CODE ref) that will return objects (See list_obj) 
If you don't know how to use streams, use list_obj() instead.

=cut
sub stream_obj {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $app		= shift;
	my $dbh		= ref($self) ? $self->dbh : shift;
	my $stream	= $class->data_class->stream_obj( $dbh, @_ );
	return undef unless (ref $stream);
	return bless(sub {
		my $self	= bless({
								_app	=> $app,
								_db_obj	=> $stream->(@_),
								_dbh	=> $dbh
							}, $class);
		return undef unless ref($self->{'_db_obj'});
		return $self;
	}, 'BingoX::Cobalt::Stream');
} # END of stream_obj


=item C<stream_hash> ( [ $dbh, ] @_ )

Forwards to $class->data_class->stream_hash

=cut
sub stream_hash {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	$class->data_class->stream_hash( $dbh, @_ );
} # END of stream_hash


=item C<stream_array> ( [ $dbh, ] @_ )

Forwards to $class->data_class->stream_array

=cut
sub stream_array {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	$class->data_class->stream_array( $dbh, @_ );
} # END of stream_array


=back

=head2 LIST METHODS

=over 4

=item C<list_obj> ( $app [, $dbh, ] @_ )

Returns an array ref of Display objects. Used mainly by Apache::XPP (the BingoX
default parser) coders. Everyone  else is probably using $self->data_class->list_obj().

=cut
sub list_obj {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $app		= shift;
	my $dbh		= ref($self) ? $self->dbh : shift;

	my @data	= (
					map { bless({
									_app	=> $app,
									_db_obj	=> $_,
									_dbh	=> $dbh
								}, $class)
						} @{ $class->data_class->list_obj( $dbh, @_ ) || return undef }
				);
	return \@data;
} # END of list_obj


=item C<list_hash> ( [ $dbh, ] @_ )

Forwards to $class->data_class->list_hash

=cut
sub list_hash {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	return $class->data_class->list_hash( $dbh, @_ );
} # END of list_hash


=item C<list_array> ( [ $dbh, ] @_ )

Forwards to $class->data_class->list_array

=cut
sub list_array {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	return $class->data_class->list_array( $dbh, @_ );
} # END of list_array


=item C<show_obj> ( $app [, $dbh ] [, \%params ] [, $template ] )

Behaves just like list_obj() or stream_obj() but will xinclude each 
object in a passed $template. Normally called by AUTOLOAD (via a show_* call), 
but you can call it explicitly if you like. Pass $app and $dbh if it's 
called statically.

=cut
sub show_obj {
	my $self		= shift;
	my $class		= ref($self) || $self; 
	my $app			= ref($self) ? $self->app : shift;
	my $dbh			= ref($self) ? $self->dbh : shift;
	my $params		= shift || { };
	my $template	= shift || return undef;
	my $code		= $class->stream_obj( $app, $dbh, $params, @_ ) || warn "stream failed";
	while (my $obj	= $code->()) {
		$app->xinclude( $template, $obj ) || warn "Can't include object $obj in template $template";
	}
	$code->(1);
	return 1;
} # END of show_obj


=back

=head2 RELATION METHODS

=over 4

=item C<stream_related> ( $rel_display_class [, \@fields] [, \@sort] [, $unary_rev_flag ] )

Returns a stream of related display objects from the $rel_display_class class.

=cut
sub stream_related {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $app		= ref($self) ? $self->app : shift;
	my $dbh		= ref($self) ? $self->dbh : shift;
	my $rclass	= shift;
	my $rdclass	= $rclass->data_class || $rclass;	# get the display class's data class if they passed that instead.
	my $stream	= $self->db_obj->stream_related( $rdclass, @_ ) || return undef;
	return bless(sub {
		while (my $db_obj = $stream->()) {
			return bless({
							_app		=> $app,
							_db_obj		=> $db_obj,
							_dbh		=> $dbh
						}, $rclass);
		}
	}, 'BingoX::Cobalt::Stream');
} # END of stream_related


=item list_related( $rel_display_class [, \@fields] [, \@sort] [, $unary_rev_flag ] )

Returns an array ref of related display objects from the $rel_display_class class.

=cut
sub list_related {
	my $self	= shift;
	return undef unless ref($self && $self->db_obj);
	my $stream	= $self->stream_related( @_ );
	return undef unless (ref $stream);
	my @list;
	push(@list, $a) while ($a = $stream->());
	return \@list;
} # END of list_related


=back

=head2 OBJECT METHODS

=over 4

=item C<db_obj> (  )

Returns the Data object for the Display Class that it was called 
from, with the constraint being: map $q->param( $_ ) @{ $data_class->primary_keys }

=cut
sub db_obj {
	my $self = shift;
	return undef unless (ref $self);						# needs to be called as an object method
	return $self->{'_db_obj'} if (ref $self->{'_db_obj'});	# return cached object
	my $q 		= $self->cgi;
	my $params 	= { };
	foreach (@{ $self->data_class->primary_keys }) {
		return undef unless (defined $q->param( $_ ));
		$params->{ $_ } = $q->param( $_ );
	}

	return undef unless (keys %$params);					# primary key needs to exist
	my $arrayref = $self->data_class->list_obj($self->dbh, $params);
	$self->{'_db_obj'} = $arrayref->[0] if (ref $arrayref);
	$self->{'_db_obj'};
} # END of db_obj


########################  Display Methods ########################


=item C<hour_menu> ( $name [, $default ] [, $24hr ] )

Returns a Popup Menu with Hours.

=cut
sub hour_menu {
	my $self	= shift;
	my $name	= shift;
	my $default	= shift || undef;
	my $hr24	= shift || undef;
	my $date	= ref($default) ? $default : BingoX::Time->new;
	my $values;

	if ($hr24) {
		$default	= $date->hour;
		$values		= $date->hours24;
	} else {
		$values 	= $date->hours;
		if ($date->hour > 0 && $date->hour <= 12) {
			$default = $date->hour;
		} elsif ($date->hour == 0) {
			$default = '12';
		} else {
			$default = $date->hour - 12;
		}
	}

	return $self->cgi->popup_menu(	-NAME		=> $name,
									-VALUES		=> $values,
									-DEFAULT	=> sprintf("%02d", $default),
									-OVERRIDE	=> 1);
} # END of sub hour_menu


=item C<min_menu> ( $name [, $default ] )

Returns a Popup Menu with Minutes.

=cut
sub min_menu {
	my $self	= shift;
	my $name	= shift;
	my $default	= shift || undef;
	my $date	= ref($default) ? $default : BingoX::Time->new;

	return $self->cgi->popup_menu(	-NAME		=> $name,
									-VALUES		=> $date->minutes,
									-DEFAULT	=> sprintf("%02d", $date->min),
									-OVERRIDE	=> 1);
} # END of sub min_menu


=item C<am_pm_menu> ( $name [, $default ] )

Returns a Popup Menu with AM/PM menus.

=cut
sub am_pm_menu {
	my $self	= shift;
	my $name	= shift;
	my $default	= shift || undef;
	my $date	= ref($default) ? $default : BingoX::Time->new;

	if ($date->hour >= 0 && $date->hour < 12) {
		$default = 'AM';
	} else {
		$default = 'PM';
	}
	return $self->cgi->popup_menu(	-NAME 		=> $name,
									-VALUES 	=> [ 'AM', 'PM' ],
									-DEFAULT 	=> $default || '',
									-OVERRIDE 	=> 1);
} # END of sub am_pm_menu


=item C<day_menu> ( $name [, $default ] )

Returns a Popup Menu with the Days of the Month.

=cut
sub day_menu {
	my $self	= shift;
	my $name	= shift;
	my $default	= shift || undef;
	my $date	= ref($default) ? $default : BingoX::Time->new;

	return $self->cgi->popup_menu(	-NAME		=> $name,
									-VALUES		=> [ 1 .. 31 ],
									-DEFAULT	=> $date->mday,
									-OVERRIDE	=> 1);
} # END of sub day_menu


=item C<month_menu> ( $name [, $default ] )

Returns a Popup Menu with the Months of the Year.

=cut
sub month_menu {
	my $self	= shift;
	my $name	= shift;
	my $default	= shift || undef;
	my $date	= ref($default) ? $default : BingoX::Time->new;

	return $self->cgi->popup_menu(	-NAME		=> $name,
									-VALUES		=> [ 1 .. 12 ],
									-LABELS		=> $date->months,
									-DEFAULT	=> $date->mon,
									-OVERRIDE	=> 1);
} # END of sub month_menu


=item C<year_menu> ( $name [, $default ] )

Returns a Popup Menu with a list of Years up to 20 years from now.

=cut
sub year_menu {
	my $self	= shift;
	my $name	= shift;
	my $default	= shift || undef;
	my $date	= ref($default) ? $default : BingoX::Time->new;
	my $start_year = $date->year;

	return $self->cgi->popup_menu(	-NAME 		=> $name,
									-VALUES 	=> [ ($start_year - 20) .. ($start_year + 20) ],
									-DEFAULT 	=> $date->year,
									-OVERRIDE 	=> 1);
} # END of sub year_menu


=item C<errors_list> (  )

Returns list of errors in list format.

=cut
sub errors_list {
	my $self	= shift;
	my $list	= shift;
	my $q		= $self->cgi;
	my $errs	= $self->{'_errors'};
	return '' unless (keys %$errs);
	my $html = '<B>' . $self->conf->error_msg . "</B>\n" unless ($errs->{'success'});

	if ($list) {
		$html .= "<" . $list . ">\n";
		foreach (sort keys %$errs) { $html .= "<LI>" . $errs->{$_} . "\n" }
		$html .= "</" . $list . ">\n";
	} else {
		foreach (keys %$errs) { $html .= $errs->{$_} . "\n" }
	}

	return $html;
} # END of errors_list


########################  Form Methods ########################

=item C<alink> ( \%params, $text | \@text )

Returns a hyper link with the params passed to it, -HREF, -JAVASCRIPT.

=cut
sub alink {
	my $self = shift;
	return $self->cgi->a(@_);
} # END of sub alink


=item C<submit> ( $name, %params )

Returns a Submit Button with the params passed to it, -NAME, -VALUE, -JAVASCRIPT.

=cut
sub submit {
	my $self = shift;
	my $name = shift;
	return $self->cgi->submit(-NAME => $name, @_);
} # END of sub submit


=item C<image_button> ( $name, %params )

Returns a hyper link with the params passed to it, -HREF, -SRC, 
-BORDER, -ALT, -JAVASCRIPT.

=cut
sub image_button {
	my $self = shift;
	my $name = shift;
	return $self->cgi->image_button(-NAME => $name, @_);
} # END of sub image_button


=item C<textfield> ( $name, %params )

Returns a Text Field with the params passed to it, -VALUE, -SIZE, 
-OVERRIDE.

=cut
sub textfield {
	my $self = shift;
	my $name = shift;
	return $self->cgi->textfield(-NAME => $name, -DEFAULT => ($self->_get_default($name) || ''), @_);
} # END of sub textfield


=item C<hidden> ( $name, %params )

Returns a Hidden Field with the params passed to it, -VALUE.

=cut
sub hidden {
	my $self = shift;
	my $name = shift;
	return $self->cgi->hidden(-NAME => $name, @_);
} # END of sub hidden


=item C<popup_menu> ( $name, %params )

Returns a Popup Menu with the params passed to it, -VALUES, -LABELS, 
-OVERRIDE.

=cut
sub popup_menu {
	my $self = shift;
	my $name = shift;
	return $self->cgi->popup_menu(-NAME => $name, -DEFAULT => ($self->_get_default($name) || ''), @_);
} # END of sub popup_menu


=item C<checkbox> ( $name, %params )

Returns a Checkbox with the params passed to it, -VALUE, -LABEL, 
-OVERRIDE.

=cut
sub checkbox {
	my $self = shift;
	my $name = shift;
	return $self->cgi->checkbox(-NAME => $name, -DEFAULT => ($self->_get_default($name) || ''), @_);
} # END of sub checkbox


=item C<checkbox_group> ( $name, %params )

Returns a Checkbox Button Group with the params passed to it, 
-VALUES, -LABELS, OVERRIDE.

=cut
sub checkbox_group {
	my $self = shift;
	my $name = shift;
	return $self->cgi->checkbox_group(-NAME => $name, -DEFAULT => ($self->_get_default($name) || ''), @_);
} # END of sub checkbox_group


=item C<radio_group> ( $name, %params )

Returns a Radio Button Group with the params passed to it, 
-NAME, -VALUES, -LABELS, -DEFAULT, -OVERRIDE.

=cut
sub radio_group {
	my $self = shift;
	my $name = shift;
	return $self->cgi->radio_group(-NAME => $name, -DEFAULT => ($self->_get_default($name) || ''), @_);
} # END of sub radio_group


=item C<get_default> (  )

Gets the default value for the field name requested.

=cut
sub get_default {
	my $self = shift;
	return $self->_get_default(@_);
} # END of get_default


########################  Application Methods ########################


=item C<app> (  )

Returns the object's Application Object.

=cut
sub app {
	return undef unless (ref $_[0]);
	$_[0]->{'_app'};
} # END of app


=item C<dbh> (  )

Returns the object's database handle.

=cut
sub dbh {
	my $self = shift;
	return undef unless (ref $self);
	if (ref $self->app) {
		return $self->app->dbh if (ref $self->app->dbh);
	}
	$self->{'_dbh'} ||= $self->data_class->connectdb;
} # END of dbh


=item C<r> (  )

Returns Apache Request object.

=cut
sub r {
	my $self = shift;
	return undef unless (ref $self);
	if (ref $self->app && ref $self->app->r) {
		return $self->app->r;
	}
	return $self->{'_r'} ||= Apache->request;
} # END of r


=item C<cgi> (  )

Returns the display object's internal CGI object (or makes a new one)

=cut
sub cgi {
	my $self = shift;
	return undef unless (ref $self);
	if (ref $self->app && ref $self->app->cgi) {
		return $self->app->cgi;
	}
	return $self->{'_cgi'} ||= CGI->new;
} # END of cgi


=item C<conf> (  )

Returns the conf object.

=cut
sub conf {
	my $self = shift;
	return undef unless (ref $self);
	if (ref $self->app) {
		return $self->app->conf if (ref $self->app->conf);
	}
	$self->{'_conf'};
} # END of conf


=item C<date> (  )

Returns the display object's internal date object (or makes a new one)

=cut
sub date	{ 
	my $self = shift;
	return undef unless (ref $self);
	if (ref $self->app && $self->app->date) {
		return $self->app->date;
	}
	return $self->{'_date'} ||= BingoX::Time->new;
} # END of date


=back

=head2 PARSER METHODS

=over 4

=item C< include > ( @_ )

Forwards to $app->include

=cut
sub include {
	my $self = shift;
	return undef unless (ref $self);
	$self->app->include( @_ );
} # END of include


=item C< xinclude > ( @_ )

Forwards to $app->xinclude

=cut
sub xinclude {
	my $self = shift;
	return undef unless (ref $self);
	$self->app->xinclude( @_ );
} # END of xinclude


=back

=head2 CLASS VARIABLE METHODS

=over 4


=item C<adminuri> (  )

Returns class defined URI as a string.

=cut
sub adminuri {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	my $uri		= ${"${class}::adminuri"};
	unless (defined $uri) {
		$class	=~ s/::Display::/::Admin::/;
		$uri	= $class->adminuri;
	}
	return $uri;
} # END sub adminuri


=item C<data_class> (  )

Returns the data class for the current display class (from the class 
variable C<$data_class>).

=cut
sub data_class {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	my $dc = ${"${class}::data_class"};
	unless (defined $dc) {
		($dc = $class) =~ s/::Display::/::Data::/;
		${"${class}::data_class"} = $dc;
	}
	return $dc;
} # END of data_class


=item C<display_fields> (  )

Returns the class variable %{"${class}::display_fields"} as a hash reference.

=cut
sub display_fields {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	return \%{ "${class}::display_fields" } if (defined %{"${class}::display_fields"});
	return { %{ "${class}::display_fields" } = map { $_ => 1 } @{ $class->display_order || [ ] } };
} # END of display_fields


=item C<display_order> (  )

Returns the class variable @{"${class}::display_order"} as an array reference.

=cut
sub display_order {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	return [ @{ "${class}::display_order" } ] || $self->error_handler("In ${class}::display_order() not defined");
} # END of display_order


=item C<title_field> (  )

Returns the title field for the current display class (from the class 
variable C<data_class>).

=cut
sub title_field {
	return $_[0]->data_class->title_field;
} # END of title_field


=item C<date_fields> (  )

Returns the date fields for the current display class (from the class 
variable C<data_class>).

=cut
sub date_fields {
	return $_[0]->data_class->date_fields;
} # END of date_fields


=item C<content_fields> (  )

Returns the content fields for the current display class (from the class 
variable C<data_class>).

=cut
sub content_fields {
	return $_[0]->data_class->content_fields;
} # END of content_fields


=item C<relations> (  )

Returns the relations for the current display class (from the class 
variable C<data_class>).

=cut
sub relations {
	return $_[0]->data_class->relations;
} # END of relations


=item C<primary_keys> (  )

Returns the primary keys for the current display class (from the class 
variable C<data_class>).

=cut
sub primary_keys {
	return $_[0]->data_class->primary_keys;
} # END of primary_keys


=item C<foreign_keys> (  )

Returns the foreign keys for the current display class (from the class 
variable C<data_class>).

=cut
sub foreign_keys {
	return $_[0]->data_class->foreign_keys;
} # END of foreign_keys


=item C<cpkey> (  )

Returns the cpkey for the current display class (from the class 
variable C<db_obj>).

=cut
sub cpkey {
	return undef unless (ref $_[0]);
	return $_[0]->db_obj->cpkey;
} # END of cpkey


sub AUTOLOAD {
	my $self	= shift;
	return if ($AUTOLOAD =~ /::DESTROY$/);
	
	my $name	= substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);
	
	my ($data, $obj);
	if (ref($self) && ($obj = $self->db_obj) && ref($obj)) {
		$data	= $obj->$name();
	} else {
		## Pass @_ because of $dbh, etc. ##
		$data	= $self->data_class->$name( @_ ) if ($self::data_class);
	}
	return $data;
} # END of AUTOLOAD


sub _errors {
	my $self	= shift;
	my $nam		= shift;
	my $val		= shift;
	my $errors;

	if (ref $self->{'_errors'}) {
		$errors = $self->{'_errors'};
	} else {
		$errors = { };
	}
	if ($nam && $val) {
		$errors->{$nam} = $val;
		$self->{'_errors'} = $errors;
	}

	return $errors;
} # End of _errors


=begin private api

=item _get_default ( $name )

Returns the default (exitisting) value for a form field.

=end private api

=cut
sub _get_default {
	my $self = shift;
	my $name = shift;
	if (ref($self->db_obj) &&
		$self->db_obj->deffields->{ $name } &&
		$self->db_obj->$name() ne 'NULL') {
		return $self->db_obj->$name();
	} else {
		return $self->cgi->param( $name ) || undef;
	}
} # END of _get_default

package BingoX::Cobalt::Stream;

# Objects are constructed in the BingoX::Cobalt::stream_obj method above.
sub next {
	my $self	= shift;
	return $self->();
} # END sub next

sub close {
	my $self	= shift;
	return $self->(1);
} # END sub close

1;

__END__

=back

=head1 REVISION HISTORY

 $Log: Cobalt.pm,v $
 Revision 2.15  2000/12/12 18:53:36  useevil
  - updated version for new release:  1.92

 Revision 2.14  2000/10/20 00:26:40  zhobson
 stream_* now returns blessed streams a la Carbon

 Revision 2.13  2000/10/17 00:49:55  dweimer
 - added adminuri()

 Revision 2.12  2000/09/19 23:41:46  dweimer
 Version update 1.91

 Revision 2.11  2000/09/12 00:49:17  david
 Fixed several accessor methods to be pure object methods.

 Revision 2.10  2000/09/07 20:00:34  thai
  - changed all occurrances of DateTime::Date to BingoX::Time

 Revision 2.9  2000/08/31 21:54:18  greg
 Added COPYRIGHT information.
 Added file COPYING (LGPL).
 Cleaned up POD.
 Moved into BingoX namespace.
 References to Bingo::XPP now point to Apache::XPP.

 "To the first approximation, syntactic sugar is trivial to implement.
  To the second approximation, the first approximation is totally bogus."
 	-Larry Wall

 Revision 2.8  2000/08/08 22:19:51  thai
  - there were two foreign_keys() when one should be relations()

 Revision 2.7  2000/08/03 20:49:13  thai
  - added methods:
  	title_field()
 	date_fields()
 	primary_keys()
 	foreign_keys()
 	cpkey()
 	relations()
 	content_fields()

 Revision 2.6  2000/08/01 00:44:43  thai
  - changed $debug to undef

 Revision 2.5  2000/07/13 22:20:04  thai
  - added new methods:
 		date/time menus
 		HTML form methods
 		get_default()
 		_get_default()
 		date()
  - changed methods:
 		db_obj() will now iterate through primary keys
 		cgi() will try to get the cgi object from the app()
 		r() will try to get r from the app()
 		conf() will try to get conf from the app()
 		dbh() will try to get dbh from the app()

 Revision 2.4  2000/07/12 19:29:39  thai
  - fixed POD, cleaned up code

 Revision 2.3  2000/06/24 03:16:37  dougw
 Added return undef to stream_related

 Revision 2.2  2000/05/31 02:39:20  greg
 changed use of s/.*:// to substr(...) in AUTOLOAD for efficiency.

 Revision 2.1  2000/05/19 01:25:25  thai
  - cleaned up code
  - is now part of the Bingo user space

 Revision 2.0  2000/05/02 00:54:33  thai
  - committed as 2.0

 Revision 1.9  2000/04/26 23:46:19  dougw
 AUTOLOAD now checks for $self::data_class before using $self->data_class
 this fixes a problem caused when a Display class that doesn't have a
 corresponding data_class calls use on a data class.

 Revision 1.8  2000/03/27 22:12:11  zack
 display_order() and display_fields() were using the data class
 instead of the display class, so they were always returning
 emtpy lists. Wow.

 Revision 1.7  2000/03/20 22:22:02  colin
 added show_obj()

 Revision 1.6  2000/03/15 20:14:15  zack
 Allow passing of cache/sort arrayrefs (a la stream_*) to get()

 Revision 1.5  2000/03/14 21:05:36  thai
  - returns undef if data_class->list_obj() returns undef

 Revision 1.4  2000/03/14 01:40:54  thai
  - fixed list_obj() to deref whats returned from data_class->list_obj()
    or [ ], it would fail miserably if not

 Revision 1.3  2000/03/07 23:43:13  zack
 Modified data_Class() so the class field is no longer required.
 Updated documentation

 Revision 1.2  2000/02/03 03:08:23  zack
 Fixed some documentation errors and inaccuracies, documented $data_class

 Revision 1.1  1999/11/04 20:51:15  greg
 First commit of generic Display class for the bingo model.


=head1 REVISION HISTORY (Xwing: Display.pm)

 Revision 1.4  1999/10/28 21:58:35  thai
  - added more methods to handle many FORM elements
  - image_button methods added for process, destroy,
    recalculate, and so on...

 Revision 1.3  1999/10/28 00:32:12  greg
 Combined with a more complete Display class (from Gonzo). This should be moved
 into the bingo project, and kept as one distinct thing...

 Revision 1.2  1999/10/20 23:41:53  greg
 Added method r to return the Apache request object.

 Revision 1.1  1999/10/12 00:02:07  thai
  - initial commit
  - partially functional, just does nothing

    I guess you could say its a "GNDN"


=head1 SEE ALSO

perl(1).

=head1 KNOWN BUGS

None

=head1 TODO

Nothing yet... anybody have suggestions?

=head1 COPYRIGHT

    Copyright (c) 2000, Cnation Inc. All Rights Reserved. This module is free
    software. It may be used, redistributed and/or modified under the terms
    of the GNU Lesser General Public License as published by the Free Software
    Foundation.

    You should have received a copy of the GNU Lesser General Public License
    along with this library; if not, write to the Free Software Foundation, Inc.,
    59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

 Colin Bielen <colin@cnation.com>
 Greg Williams <greg@cnation.com>

=cut
