# BingoX::Chromium 
# -----------------
# $Revision: 2.36 $
# $Date: 2001/11/14 23:12:26 $
# ---------------------------------------------------------

=head1 NAME

BingoX::Chromium - Generic BingoX Admin module

=head1 SYNOPSIS

use BingoX::Chromium;

  # $BR - Blessed Reference
  # $SV - Scalar Value
  # @AV - Array Value
  # $HR - Hash Ref
  # $AR - Array Ref
  # $SR - Stream Ref

  # $proto - BingoX::Chromium object OR sub-class
  # $object - BingoX::Chromium object

CONSTRUCTORS

  $BR = $proto->new( $r, [ $conf ] );

DISPLAY METHODS

  $SV = $proto->postmodify_handler();
  $SV = $proto->postadd_handler();
  $SV = $object->display_list();
  $SV = $object->display_view();
  $SV = $object->display_modify();
  $SV = $object->display_search();				- Not Implemented Yet!
  $SV = $object->display_row( $field );
  $SV = $object->display_list_buttons();
  $SV = $object->display_modify_buttons();
  $SV = $object->displat_start_html();
  $SV = $object->hidden_fields();

DATA METHODS

  $SV = $object->save_data();
  $HR = $object->get_data( [ $data, ] [ $fields ] );
  $SV = $object->sanity();
  $BR = $proto->dbh();
  $BR = $object->db_obj();
  $HR = $object->get_list_hash();

CLASS VARIABLE METHODS


  $SV = $proto->data_class();
  $SV = $proto->data_class_name();
  $SV = $proto->adminuri();
  $SV = $proto->classdesc();
  $SV = $proto->qfd();
  $SV = $proto->pkd();  
  $SV = $proto->prefix();  
  $SV = $proto->cpkey_params($pcpkey);
  $AR = $proto->fieldlist();
  $HR = $proto->ui();
  $AR = $proto->parents();  
  $AR = $proto->children();  
  $HR = $proto->fields();
  $SV = $proto->fieldname( $field );
  $SV = $proto->fieldtype( $field );
  $HR = $proto->fieldhtmloptions( $field );
  $SV = $proto->fieldrelclass( $field );
  $SV = $proto->fieldrelclasstype( $field );
  $HR = $proto->fieldoptions( $field );
  $HR = $proto->fieldsanity( $field );

OBJECT METHODS

  $SV = $object->flow();
  $SV = $object->cpkey();
  $SV = $object->pcpkey();
  $SV = $object->parent_class(); 
  $BR = $object->cgi();
  $SV = $object->uri();
  $SV = $object->displaymode();
  $SV = $object->section();
  $BR = $object->conf();
  $BR = $object->r();

HTML DISPLAY METHODS

  $SV = $object->HTML_date( $fieldname );
  $SV = $object->HTML_view( $fieldname );
  $SV = $object->HTML_hidden( $fieldname );
  $SV = $object->HTML_text( $fieldname );
  $SV = $object->HTML_textarea( $fieldname );
  $SV = $object->HTML_popup( $fieldname );		- Not Finished!
  $SV = $object->HTML_scrolling( $fieldname );
  $SV = $object->HTML_checkbox( $fieldname );
  $SV = $object->HTML_file( $fieldname );

=head1 REQUIRES

Time::Object, Apache, CGI, Carp

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

 BingoX::Chromium provides the generic API for BingoX admin classes.
 BingoX::Chromium uses admin objects that wrap Carbon data objects

=head1 CLASS VARIABLES

Classes that inherit from BingoX::Chromium should have the following class variables:

=over 4

=item * @fieldlist

The order in which to display fields (if one so chose to display them ;)

=item * %fields

A hash whose keys are columns (same as in the fieldlist array) and whose values 
are complex arrays. Each array index is described below.

=over 4

=item [0] Descriptive Title

A string describing the field

=item [1] HTML Entity Type

A string that contains one of the following HTML etity types:

 view
 text
 textarea
 datetime
 popup
 reference
 FIXME: more!!!

=item [2] HTML Options

A hash reference containing options for creating the HTML form field for 
this field.

=item [3] Related Classes

FIXME: I dunno

=item [4] Field Options

A hash reference containing special options for this field. The options include:

  not_null - this field cannot be NULL

=item [5] Sanity Methods

This is a list reference. Each item in the list is either a string with a 
sanity method name, or a list ref containing the method name, then any parameters 
that need to be passed to it. An example:

  [
   'sane_foo',
   ['sane_bar', 'baz'],
  ]

For more info, see L<"SANITY METHODS">.

=back

=item * $adminuri

An optional class variable, corresponds to the C<adminuri()> method.  
FIXME: Can someone who knows more about this elaborate?

=item * $classdesc

A simple one- or two-word description of the class being administered.

=back

=item * $data_class

The name of the data class that corresponds to the admin class. If this 
value is not defined, it will default to the name of the admin class, with 
the first instance of "::Admin::" changed to "::Data::".

=back

=head1 METHODS

=over 4

=cut

package BingoX::Chromium;

use Apache;
use Apache::Constants qw(:response);
use BingoX::Time;

use Carp;
use strict;
use vars qw($AUTOLOAD $debug);

BEGIN {
	$BingoX::Chromium::REVISION	= (qw$Revision: 2.36 $)[-1];
	$BingoX::Chromium::VERSION	= '1.92';

	$debug	= undef;

	if ($debug) {
		require Data::Dumper;
	}
}

=item C<handler> ( $r )

Apache handler gets a new display object object of the class B<it was called 
as> and calls flow against it.

=cut

sub handler ($$) {
	warn "\n******************** BEGIN CLICK ************************\n\n" if ($debug);

	my $class	= shift;
	my $r		= shift;

	# Prepare request handler for uncached HTML response
	$r->content_type('text/html');
	$r->no_cache(1);

	my $self		= $class->new( $r );
	my $response	= $self->flow;

	warn "\n******************** END CLICK **************************\n\n" if ($debug);
	return $response;
} # END sub handler

=back

=head2 CONSTRUCTORS

=over 4

=item C<new> ( $r [, $conf [, $mode ] ] )

Given an apache request object, returns an Admin object of the class 
B<it was called as>.  It also sets the data_class, data_class_name, cgi, 
uri, displaymode (from $q), and section (from $q).

=cut

sub new {
	my ($class, $r, $conf, $mode, $cgi) = @_;
	my $q = $cgi || new CGI;
	my $self = {
					_data_class			=> $class->data_class(),
					_data_class_name	=> $class->data_class_name(),
					_cgi				=> $q,
					_conf				=> $conf || undef,
					_uri				=> $r->uri,
					_r					=> $r,				# Apache request object
					_displaymode		=> lc($q->param('displaymode')) || $mode || '',
					_errors				=> { },
					_section			=> $q->param('section') || '',
				};
	if ($q->param('parent_pcpkey')) {
		my $parentclass = "${1}::Admin::" . substr($q->param('parent_pcpkey'),0,index($q->param('parent_pcpkey'),$class->qfd));
		$self->{'_parent_class'} = $parentclass;
		$self->{'_selection'} = $parentclass->cpkey_params($q->param('parent_pcpkey'));
	}
	bless $self, $class;
	return $self
} # END sub new


=back

=head2 FLOW

=over 4

=item C<flow> (  )

Decides what display method (or save_data) to call based on the displaymode, 
and submit_type (found in the query object).

?? Is this the best order to check ??

=cut

sub flow {
	my $self	= shift;
	return $self->failure('Method flow called as static.') unless ref($self);
	my $class	= ref($self);
	my $q		= $self->cgi;


	my $other_class;
	if ($other_class = (grep { /^child##(.+)$/ } ($q->param))[0]) {
		$q->delete($other_class);
		$other_class = substr($other_class,7);

		warn "flow - displaymode child\n" if ($debug > 1);

		my $pcpkey = $q->param('cpkey');
		$q->param('parent_pcpkey',$pcpkey);
		my $new_class = $class;
		substr($new_class,rindex($new_class,':')+1) = $other_class;	

		my $new_admin = $new_class->new($self->r,undef,undef,$q);
		$new_admin->flow;

	} elsif ($other_class = (grep { /^parent##(.+)$/ } ($q->param))[0]) {
		$q->delete($other_class);
		$other_class = substr($other_class,8);		warn "flow - displaymode parent\n" if ($debug > 1);

		my $new_class = $class;
		substr($new_class,rindex($new_class,':')+1) = $other_class;	
		$q->delete('parent_pcpkey');
		my $new_admin = $new_class->new($self->r,undef,undef,$q);
		$new_admin->flow;

	} elsif ($self->displaymode eq 'modify') {
		$self->{'_displaymode'} = 'modify';
		warn "flow - displaymode modify\n" if ($debug > 1);
		if ($q->param('submit_type') eq 'Save') {
			if ($self->save_data) {
				warn "flow modify modify after MODIFY\n" if ($debug > 1);
				$self->{'_displaymode'} = 'view';
				$self->postmodify_handler('display_view');
			} else {
				warn "flow modify modify MODIFY FAILED\n" if ($debug > 1);
				$self->display_modify;
			}
		} elsif ($q->param('submit_type') eq 'Cancel') {
			$self->{'_displaymode'} = 'view';
			$self->postmodify_handler('display_view');
		} else {
			$self->failure('Not a valid submit type.');
		}

	} elsif ($self->displaymode eq 'view') {
		warn "flow - displaymode view\n" if ($debug > 1);
		if ($q->param('submit_type') eq 'Modify') {
			$self->{'_displaymode'} = 'modify';
			$self->display_modify;
		} elsif ($q->param('submit_type') eq 'Remove') {
			if ($self->db_obj->rm) {
				$self->postmodify_handler('display_list');
			} else {
				$self->{'_errors'}->{'General Database Error'} = $self->dbh->errstr;
				$self->display_modify;
			}
		} elsif ($q->param('submit_type') eq 'Return to List') {
			$self->postmodify_handler('display_list');
		} else {
			$self->failure('Not a valid submit type.');
		}

	} elsif ($self->displaymode eq 'add') {
		warn "flow - displaymode add\n" if ($debug > 1);
		if ($q->param('submit_type') eq 'Save') {
			if ($self->save_data) {
				warn "flow add add after ADD\n" if ($debug > 1);
				$self->{'_displaymode'} = 'view';
				$self->postadd_handler('display_view');
			} else {
				warn "flow add add ADD FAILED\n" if ($debug > 1);
				$self->display_modify;
			}
		} else {
			$self->postadd_handler('display_list');
		}

	} else {
		warn "flow - displaymode none\n" if ($debug > 1);

		if ($q->param('submit_type') eq 'View') {
			warn "flow - displaymode none - submit_type view\n" if ($debug > 1);
			if (ref $self->db_obj) {
				warn "flow - displaymode none - submit_type view - we have db_obj\n" if ($debug > 1);
				$self->{'_displaymode'} = 'view';
				$self->display_view;
			} else {
				warn "no db_obj\n" if ($debug > 1);
				$self->{'_displaymode'} = 'list';
				$self->display_list;
			}
		} elsif ($q->param('submit_type') eq 'Remove') {
			warn "flow - displaymode none - submit_type Remove\n" if ($debug > 1);
			if ($self->db_obj->rm) {
				warn "flow - displaymode none - submit_type Remove SUCCEED\n" if ($debug > 1);			
				$self->{'_displaymode'} = 'list';
				$self->display_list;
			} else {
				warn "flow - displaymode none - submit_type Remove FAIL\n" if ($debug > 1);			
				$self->{'_errors'}->{'General Database Error'} = $self->dbh->errstr;
				$self->{'_displaymode'} = 'list';
				$self->display_list;
			}
		} elsif ($q->param('submit_type') eq 'Modify') {
			warn "flow - displaymode none - submit_type modify\n" if ($debug > 1);
			if (ref $self->db_obj) {
				warn "flow - displaymode none - submit_type modify - we have db_obj\n" if ($debug > 1);
				$self->{'_displaymode'} = 'modify';
				$self->display_modify;
			} else {
				warn "no db_obj\n" if ($debug > 1);
				$self->{'_displaymode'} = 'list';
				$self->display_list;
			}
		} elsif ($q->param('submit_type') eq 'Add') {
			warn "flow - displaymode none - submit type: add\n" if ($debug > 1);
			$q->delete('cpkey'); #sometimes it sticks around if users select something in "display_list" and hit "new".
			$self->{'_displaymode'} = 'add';
			$self->display_modify;
		} else {
			$self->display_list;
		}
	}
} # END sub flow


sub failure {
	my $self = shift;
	return SERVER_ERROR unless ref($self);
	my $message = shift || return SERVER_ERROR;
	my $q = $self->cgi;
	my $content = $q->starthtml(-title=>'Chromium Error')
				. "<H2 ALIGN=center>Chromium Error</H2><BR>\n"
				. "Error in Chromium-based Admin class: <FONT COLOR='blue'>" . ref($self) . "</FONT><BR>\n"
				. "<FONT COLOR='red'>" . $message . "</FONT><BR>\n"
				. $q->endhtml . "\n";
	$self->r->custom_response(SERVER_ERROR => $content);
	return SERVER_ERROR;
}

=item C<postmodify_handler> ( $method_name, [ $method_name_args ] )

This method decides what happens after you leave the "Modify" 
screen. It normally works by passing a method that gets called, but 
it's meant to be overloaded as a hook when flow() finishes saving data 
(or if you hit Cancel).  That way you can save something and go 
somewhere else besides display_view().  It currently will always call 
$method against $self, so no static methods, please...

=cut

sub postmodify_handler {
	my $self	= shift;
	my $method	= shift || 'display_view';
	$self->$method( @_ );
} # END sub postmodify_handler


=item C<postadd_handler> ( $method_name, [ $method_name_args ] )

Behaves exactly like postmodify_handler() (see above), but is called after 
the user exits the "Add a new <whatever>" screen.

=cut

sub postadd_handler {
	my $self	= shift;
	my $method	= shift || 'display_view';
	$self->$method( @_ );
} # END sub postadd_handler


=back

=head2 DISPLAY METHODS

=over 4

=item C<display_list> (  )

Prints an HTML page meant for listing all objects in class.

=cut

sub display_list {
	my $self	= shift;
	my $q		= $self->cgi;
	$self->{'_displaymode'} = 'list';
	my $r		= $self->r;
	my $ui		= $self->ui;

	unless (ref $r) {
		print $q->header;
	}

	print $self->display_start_html({	-TITLE		=> 'Admin '. $self->classdesc,
										-BGCOLOR	=> $ui->{'page_bg'}
									});

	my $hashref = $self->get_list_hash;
	print $q->startform(	-ACTION	=> $self->adminuri || $self->uri,
							-METHOD	=>'POST'
						)
		. $q->p . "\n"
		. $q->center
		. $q->start_table({	-BORDER			=> 0,
							-CELLSPACING	=> 0,
							-CELLPADDING	=> 1,
							-WIDTH			=> 500,
							-BGCOLOR		=> $ui->{'table_border'}
						})
		. $q->start_Tr
		. $q->start_td
		. $q->start_table({	-BORDER			=> 0,
							-CELLSPACING	=> 1,
							-CELLPADDING	=> 4,
							-WIDTH			=> 500,
							-BGCOLOR		=> 'white'
						})
		. $q->start_Tr
		. $q->start_td({ -ALIGN		=> 'center', -BGCOLOR => $ui->{'table_header' }})
		. $q->start_b
		. $q->start_font({
				-FACE => $ui->{'font_header'}->{'-face'},
				-SIZE => 5
			})
		. $self->display_admin_name . "List "
		. $self->classdesc . "<BR>\n";

	if ($q->param('parent_pcpkey')) {
		my $parent_class	= $self->parent_class;
		my $pclass_tfield	= $parent_class->data_class->title_field;
		print $q->font(	{ -SIZE => 4 },
						"For " . $parent_class->classdesc . ": " 
						. $q->font(	{ -COLOR => 'blue' },
									$parent_class->data_class->get(
											$self->dbh,
											$parent_class->cpkey_params(
													$q->param('parent_pcpkey')
											)
									)->$pclass_tfield()
						)
			) . "<BR>\n";
	}
	print $q->end_font . $q->br . $q->a(
											{ -HREF => $self->main_index },
											[ 'Back to Main Index' ]
								) . "<BR>\n"
		. $q->end_b
		. $q->end_td
		. $q->end_Tr

		. $q->start_Tr
		. $q->start_td({	-ALIGN		=> 'center',
							-BGCOLOR	=> $ui->{'row_value'}
						}) . "\n"
		. $q->p . "\n"
		. $q->scrolling_list(	-NAME		=>'cpkey',
								-VALUES		=> [ sort { $hashref->{$a} cmp $hashref->{$b} } keys %$hashref ],
								-LABELS		=> $hashref,
								-SIZE		=> 15,			# should be setable
								-MULTIPLE	=> 'true',		# should be setable (why true?)
								-OVERRIDE	=> 1
							) . "\n"
		. $q->br
		. $q->font($ui->{'font_footer'}, "Select an item and press View.  <BR>Or press Add to add a new item\n")

		. $q->end_td
		. $q->end_Tr 

		. $q->start_Tr
		. $q->start_td({	-ALIGN		=> 'center',
							-BGCOLOR	=> $ui->{'table_footer'}
						})

		. $q->start_table({	-WIDTH			=> '100%',
							-BORDER			=> 0,
							-CELLPADDING	=> 0,
							-CELLSPACING	=> 0
						})
		. $q->start_Tr
		. $q->start_td({	-WIDTH	=> '35%',
							-ALIGN	=> 'left'
						
						})
		. $q->end_td
		. $q->start_td({	-WIDTH	=> '30%',
							-ALIGN	=> 'center'
						})

		. $self->display_list_buttons

		. $q->end_td
		. $q->start_td({	-WIDTH	=> '35%',
							-ALIGN	=>'right',
							-VALIGN	=>'bottom'
						})
		. $q->font({	-FACE	=> 'verdana,arial,helvetica',
						-SIZE	=> 1
					},
					'Powered by: BingoX')

		. $q->end_td
		. $q->end_Tr
		. $q->end_table

		. $q->end_td
		. $q->end_Tr
		. $q->end_table

		. $q->end_td
		. $q->end_Tr
		. $q->end_table
		. $q->hidden(	-NAME		=> 'displaymode',
						-VALUE		=> $self->displaymode,
						-OVERRIDE	=> 1
					) . "\n"
		. $q->hidden(	-NAME		=> 'section',
						-VALUE		=> $self->section,
						-OVERRIDE	=> 1
					) . "\n"
		. $q->hidden(	-NAME		=> 'parent_pcpkey')
		. $self->hidden_fields
		. $q->endform . "\n"
		. $q->end_center
		. $q->end_html . "\n";

	return OK;
} # END sub display_list


=item C<display_list_buttons> (  )

Displays the buttons for display_list().  
Easy to overload if you want more buttons!

=cut

sub display_list_buttons {
	my $self	= shift;
	return undef unless (ref $self);
	my $q		= $self->cgi;
	my $html = "<CENTER>";
	if ($self->parents) {
		foreach (@{ $self->parents }) {
			$html .= $q->submit(-NAME => "parent##$_", -VALUE => "Back to ${_}");
		}
		$html .= '<BR>';
	}
	if ($self->children) {
		foreach (@{ $self->children }) {
			$html .= $q->submit(-NAME => "child##$_", -VALUE => "Show ${_}");
		}
		$html .= '<BR>';
	}

	return $html
		. $q->submit(	-NAME		=> 'submit_type',
						-VALUE		=> 'Remove',
						-onClick	=> "if (confirm('Are you sure you want to remove this record?')) { return true } else { return false }"
					)
		.	$q->submit(	-NAME		=> 'submit_type',
						-VALUE		=> 'Add'
					)
		.	$q->submit(	-NAME		=> 'submit_type',
						-VALUE		=> 'View'
					)
		.	$q->submit(	-NAME		=> 'submit_type',
						-VALUE		=> 'Modify'
					)
		.	"</CENTER>\n"
} # END sub display_list_buttons


=item C<display_modify_buttons> (  )

Displays the buttons for display_modify().  
Easy to overload if you want more buttons!  
Just like display_list buttons.

=cut

sub display_modify_buttons {
	my $self	= shift;
#	return undef unless ref($self);
	my $q		= $self->cgi;
	return	"<CENTER>"
		.	$q->submit(	-NAME	=> 'submit_type',
						-VALUE	=> 'Cancel'
					)
		.	$q->submit(	-NAME	=> 'submit_type',
						-VALUE	=> 'Save'
					)
		.	"</CENTER>\n"
} # END sub display_modify_buttons


=item C<display_view> (  )

Prints an HTML page meant for viewing an object.  Itterates through fieldlist 
calling display_row for each element.

=cut

sub display_view {
	my $self	= shift;
	my $q		= $self->cgi;
	my $fields	= $self->fields;
	my $r		= $self->r;
	my $ui		= $self->ui;
	$self->{'_displaymode'} = 'view';

	unless (ref $r) {
		print $q->header;
	}

	print $self->display_start_html({	-TITLE		=> 'Admin '. $self->classdesc,
										-BGCOLOR	=> $ui->{'page_bg'}
									})
		. $q->startform(	-ACTION	=> $self->adminuri || $self->uri,
							-METHOD	=> 'POST',
							-NAME	=> 'displayform'
						)
		. $q->start_center
		. $q->start_table({	-BORDER			=> 0,
							-CELLSPACING	=> 0,
							-CELLPADDING	=> 1,
							-WIDTH			=> 500,
							-BGCOLOR		=> $ui->{'table_border'}
						})
		. $q->start_Tr
		. $q->start_td
		. $q->start_table({	-BORDER			=> 0,
							-CELLSPACING	=> 1,
							-CELLPADDING	=> 4,
							-WIDTH			=> 500,
							-BGCOLOR		=> 'white'
						})
		. $q->start_Tr
		. $q->start_td({	-COLSPAN	=> 2,
							-BGCOLOR	=> $ui->{'table_header'}
						})
		. $q->b($q->font($ui->{'font_header'},$q->center($self->display_admin_name . "View " . $self->classdesc. "<BR>\n")))
		. $q->end_td
		. $q->end_Tr;

	foreach (@{ $self->fieldlist }) {
		$self->display_row( $_ );		# here's where the magic happens
	}

	print $q->start_Tr
		. $q->start_td({	-COLSPAN	=> 2,
							-ALIGN		=> 'center',
							-BGCOLOR	=> $ui->{'table_footer'}
						})

		. $q->start_table({	-WIDTH			=> '100%',
							-BORDER			=> 0,
							-CELLPADDING	=> 0,
							-CELLSPACING	=> 0
						})

		. $q->start_Tr
		. $q->start_td({	-WIDTH	=>'35%',
							-ALIGN	=> 'left'
						})
		. $q->end_td
		. $q->start_td({	-WIDTH	=> '30%',
							-ALIGN	=> 'center'
						})
		. $self->display_view_buttons()

		. $q->end_td
		. $q->start_td({	-WIDTH	=> '35%',
							-ALIGN	=> 'right',
							-VALIGN	=> 'bottom'
						})

		. $q->font({	-FACE	=> 'verdana,arial,helvetica',
						-SIZE	=> 1
					},
					'Powered by: BingoX')
		
		. $q->end_td
		. $q->end_Tr
		. $q->end_table

		. $q->end_td
		. $q->end_Tr
		. $q->end_table

		. $q->end_td
		. $q->end_Tr
		. $q->end_table
		
		. $q->hidden(	-NAME		=> 'section',
						-VALUE		=> $self->section,
						-OVERRIDE	=> 1
					)
		. $q->hidden(	-NAME		=> 'cpkey',
						-VALUE		=> $self->pcpkey,
						-OVERRIDE	=> 1
					)
		. $q->hidden(	-NAME		=> 'displaymode',
						-VALUE		=> 'view',
						-OVERRIDE	=> 1
					)
		. $q->hidden(	-NAME		=> 'parent_pcpkey')
		. $self->hidden_fields
		. $q->endform . "\n"
		. $q->end_center
		. $q->end_html . "\n";

	return OK;
} # END sub display_view


=item C<display_view_buttons> ( )

Displays the buttons for display_view().
Easy to overload if you want more buttons!
Just like display_list buttons.

=cut

sub display_view_buttons {
	my $self = shift;
#	return undef unless ref($self);
	my $q	= $self->cgi;
	return	"<CENTER>"
		.	$q->submit(	-NAME		=> 'submit_type',
						-VALUE		=> 'Remove',
						-onClick	=> "if (confirm('Are you sure you want to remove this record?')) { return true } else { return false }"
					)
		.	$q->submit(	-NAME	=> 'submit_type',
						-VALUE	=> 'Modify'
					)
		.	$q->br
		.	$q->submit(	-NAME	=> 'submit_type',
						-VALUE	=> 'Return to List'
					)
		.	"</CENTER>\n"
} # END sub display_view_buttons

 
=item C<display_modify> ( )

Prints an HTML page meant for modifying an object.  Itterates through fieldlist 
calling display_row for each element.

=cut

sub display_modify {
	my $self		= shift;
	my $q			= $self->cgi;
	my $errors		= shift;
	my $db_errors	= $self->db_obj ? $self->db_obj->errors : '';
	my $r			= $self->r;
	my $ui			= $self->ui;

	unless (ref $r) {
		print $q->header;
	}

	print $self->display_start_html({	-TITLE		=> 'Admin '. $self->classdesc,
										-BGCOLOR	=> $ui->{'page_bg'}
									})
		. $q->start_multipart_form(	-ACTION	=> $self->adminuri || $self->uri,
									-METHOD	=> 'POST')
		. $q->start_center
		. $q->start_table({	-BORDER			=> 0,
							-CELLSPACING	=> 0,
							-CELLPADDING	=> 1,
							-WIDTH			=> 500,
							-BGCOLOR		=> $ui->{'table_border'}
						})
		. $q->start_Tr
		. $q->start_td
		. $q->start_table({	-BORDER			=> 0,
							-CELLSPACING	=> 1,
							-CELLPADDING	=> 4,
							-WIDTH			=> 500,
							-BGCOLOR		=> 'white'
						})
		. $q->start_Tr
		. $q->start_td({	-COLSPAN	=> 2,
							-BGCOLOR	=> $ui->{'table_header'}
						})
		. $q->b(
			$q->font(
				$ui->{'font_header'},
				$q->center(
					$self->display_admin_name . (
													($self->displaymode eq 'add')
													? "Add "
													: "Modify "
												) . $self->classdesc. "<BR>\n"
				)
			)
		);

	if (%{ $self->{'_errors'} }) {
		print $q->p . $q->font($ui->{'font_key'},"There are errors in the following fields:\n")
			. '<BR><UL>';
		if (ref $self->{'_errors'} eq 'HASH') {
			foreach (keys %{ $self->{'_errors'} }) {
				print $q->li($q->font($ui->{'font_error'}, ($self->fieldname($_) || $_) . ': ' . $self->{'_errors'}->{$_}));
			}
		} else {
			print $q->li($q->font($ui->{'font_error'},$self->fieldname($_) . ': ' . $self->{'_errors'}));
		}
#		map { print  "<LI>" . $_ . "\n"} keys %{$self->{'_errors'}};
		print "</UL><br>\n";
	} elsif (ref $db_errors) {
		print $q->p . $q->font($ui->{'font_key'},"The following errors occured:\n")
			. '<BR><UL>';
		foreach (keys %{ $db_errors }) {
			print $q->li . $q->font($ui->{'font_error'},$_ . ': ' . $db_errors->{$_} . "\n");
		}
		print "</UL><br>\n";
	} else {
		print $q->font($ui->{'font_key'},'<P ALIGN="CENTER">An asterisk ("<B>*</B>") denotes a required field.</P>');
	}

	print $q->end_td
		. $q->end_Tr;

	foreach (@{ $self->fieldlist }) {
		next if (($self->displaymode eq 'add') && ($_ eq $self->data_class->primary_keys->[0]));
		$self->display_row( $_ );
	}

	print $q->start_Tr
		. $q->start_td({	-COLSPAN	=> 2,
							-ALIGN		=> 'center',
							-BGCOLOR	=> $ui->{'table_footer'}
						})

		. $q->start_table({	-WIDTH			=> '100%',
							-BORDER			=> 0,
							-CELLPADDING	=> 0,
							-CELLSPACING	=> 0
						})
		. $q->start_Tr
		. $q->start_td({	-WIDTH	=> '35%',
							-ALIGN	=> 'center'
						})
		. $q->end_td
		. $q->start_td({	-WIDTH	=> '30%',
							-ALIGN	=> 'center'
						})

		. $self->display_modify_buttons

		. $q->end_td
		. $q->start_td({	-WIDTH	=> '35%',
							-ALIGN	=> 'right',
							-VALIGN	=> 'bottom'
						})
		. $q->font({	-FACE	=> 'verdana,arial,helvetica',
						-SIZE	=> 1
					},
					'Powered by: BingoX')

		. $q->end_td
		. $q->end_Tr
		. $q->end_table

		. $q->end_td
		. $q->end_Tr
		. $q->end_table

		. $q->end_td
		. $q->end_Tr
		. $q->end_table
		. $q->hidden(	-NAME		=> 'cpkey',
						-VALUE		=> $self->pcpkey,
						-OVERRIDE	=> 1
					)
		. $q->hidden(	-NAME		=> 'section',
						-VALUE		=> $self->section,
						-OVERRIDE	=> 1
					)
		. $q->hidden(	-NAME		=> 'displaymode',
						-VALUE		=> $self->displaymode,
						-OVERRIDE	=> 1
					)
		. $q->hidden(	-NAME		=> 'parent_pcpkey')
		. $self->hidden_fields
		. $q->endform . "\n"
		. $q->end_center
		. $q->end_html . "\n";

	return OK;
} # END sub display_modify


=item C<display_admin_name> (  )

Returns class defined Class description as a string.

=cut

sub display_admin_name {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $q		= $self->cgi;
	warn "display_admin_name ==> " . $class->admin_name . "\n" if ($debug > 3);
	return defined($class->admin_name) ? $class->admin_name . $q->br : undef;
} # END sub admin_name


=item C<hidden_fields> (  )

A stub called by display_view() and display_modify() 
that you can overload in your subclass if you want 
the view or modify/add screens to have a custom title.

=cut

sub admin_name { }


=item C<hidden_fields> ( \%fields )

A stub called by display_view() and display_modify() 
that you can overload in your subclass if you want 
the view or modify/add screens to have extra hidden fields.

Or you can pass it a hash ref of hidden fields, 
were key = field name and value = field value

=cut

sub hidden_fields {
	my $self	= shift;
	my $fields	= shift;
	ref($fields) || return undef;
	my $string;
	foreach (keys %$fields) {
		$string .= $self->cgi->hidden(	-NAME	=> $_,
							-VALUE	=> $fields->{$_});
	}
	return $string;
} # END sub admin_name


=item display_start_html( \%params )

Accessor method to $self->cgi->start_html();  
Put into params exactly what you'd put in  CGI::start_html().  
Overload this in your admin class if you want to set any special 
BG,text,link colors, or anything else you want to pass to start_html()

=cut

sub display_start_html {
	my $self	= shift;
	my $options	= shift || { };
	my $ui		= $self->ui;
	$options->{'-bgcolor'}	||= $ui->{'page_bg'};
	$options->{'-text'}		||= $ui->{'text_color'};
	$options->{'-link'}		||= $ui->{'link_color'};
	$options->{'-vlink'}	||= $ui->{'vlink_color'};
	$options->{'-alink'}	||= $ui->{'alink_color'};
	return $self->cgi->start_html(%{ $options });
} # END sub display_start_html


=item C<display_search> (  )

Prints an HTML page meant for limiting what appears on the display_list page.

Not Implimented Yet.

=cut

sub display_search {
	warn "display_search method not implimented yet!";
	return undef;
} # END sub display_search


=item C<display_row> ( $field )

Takes a column (field) name and prints a 2 columned table row where the left 
column has the fields descriptive name ($self->fieldname($field)) and the right 
column has the output of that fields method ($self->$field)

=cut

sub display_row {
	my $self	= shift;
	return undef unless ref $self;
	my $q		= $self->cgi;
	my $field	= shift;
	my $ui		= $self->ui;

	return undef if ($self->fieldtype($field) eq 'hidden');

	## Is this field required? (i.e. not null?) ##
	my $req = %{$self->fieldoptions($field) || { }}->{not_null} || 0;

	if (($self->fieldtype($field) eq 'row')) {
		print $self->$field();
	} elsif ($self->fieldtype($field) eq 'textarea') {
		print $q->Tr({ },
				$q->td({	-VALIGN		=> 'top',
							-COLSPAN	=> 2,
							-ALIGN		=> 'center',
							-WIDTH		=> 100,
							-BGCOLOR	=> $ui->{'row_key'}
						},
						$q->font(
							$ui->{'font_key'},
							$q->b(
								($req ? '* ' : '') . $self->fieldname( $field ) . ':'
							)
						)
					)
				)."\n"
			. $q->Tr({ },
				$q->td({	-VALIGN		=> 'top',
							-COLSPAN	=> 2,
							-BGCOLOR	=> $ui->{'row_value'}
						},
						$q->font(
							$ui->{'font_value'},
							($self->$field() ? $self->$field() : '&nbsp;')
						)
					)
				) . "\n";
	} elsif (($self->fieldtype($field) eq 'password') && ($self->displaymode() ne 'view')) {
		# Once to enter
		print $q->Tr({ },
				$q->td({	-VALIGN		=> 'top',
							-ALIGN		=> 'right',
							-WIDTH		=> 100,
							-BGCOLOR	=> $ui->{'row_key'}
						},
						$q->font(
							$ui->{'font_key'},
							$q->b(
								($req ? '* ' : '') . $self->fieldname( $field ) . ':'
							)
						)
					)
			.	$q->td({	-VALIGN		=> 'top',
							-WIDTH		=> 400,
							-BGCOLOR	=> $ui->{'row_value'}
						},
						$q->font(
							$ui->{'font_value'},
							$self->$field()
						)
					)
			) . "\n"
		# again to verify
			. $q->Tr({ },
				$q->td({	-VALIGN		=> 'top',
							-ALIGN		=> 'right',
							-WIDTH		=> 100,
							-BGCOLOR	=> $ui->{'row_key'}
						},
						$q->font(
							$ui->{'font_key'},
							$q->b(
								($req ? '* ' : '') . $self->fieldname( $field ) . ':'
							)
							. '<br/>(for verification)'
						)
					)
			.	$q->td({	-VALIGN		=> 'top',
							-WIDTH		=> 400,
							-BGCOLOR	=> $ui->{'row_value'}
						},
						$q->font(
							$ui->{'font_value'},
							$self->$field()
						)
					)
			) . "\n"
	} else {
		print $q->Tr({ },
				$q->td({	-VALIGN		=> 'top',
							-ALIGN		=> 'right',
							-WIDTH		=> 100,
							-BGCOLOR	=> $ui->{'row_key'}
						},
						$q->font(
							$ui->{'font_key'},
							$q->b(
								($req ? '* ' : '') . $self->fieldname( $field ) . ':'
							)
						)
					)
			.	$q->td({	-VALIGN		=> 'top',
							-WIDTH		=> 400,
							-BGCOLOR	=> $ui->{'row_value'}
						},
						$q->font(
							$ui->{'font_value'},
							($self->$field() ? $self->$field() : '&nbsp;')
						)
					)
			) . "\n";
	}
} # END sub display_row


=back

=head2 DATA METHODS

=over 4

=item C<save_data> ( [ \%data ] )

 Goes through the process of calling sanity, then get_data (to get the data out 
of the query object) and then db_obj->modify.
 Optionally takes data hashref as returned by get_data(), otherwise calls get_data() itself.  (This makes extension of save_data() possible without having to call get_data() twice.)

=cut

sub save_data {
	my $self	= shift;
	return undef unless ref $self;
	my $dbh		= $self->dbh();
	my $data	= shift || $self->get_data();

	warn 'save_data after get_data data: ' . Data::Dumper::Dumper($data) . "\n" if ($debug > 1);
	return undef unless (ref($data) eq 'HASH');
	return undef unless ($self->sanity($data));

	my $newself;
	warn 'save data==> ' . Data::Dumper::Dumper($data) . "\n" if ($debug);
	if ($self->displaymode eq 'add') {
		if ($newself = $self->data_class->new( $dbh, $data )) {
			warn "save_data - new succeeded\n" if ($debug > 1);
			$self->{'_db_obj'} = $newself;
			warn 'save_data - after new - new self ==> ' . Data::Dumper::Dumper($self->{'_db_obj'}) if ($debug > 1);
		} else {
			warn "save_date - new failed\n" if ($debug > 1);
			$self->{'_errors'}->{'General Database Error'} = $dbh->errstr || $self->data_class->errors;
			return undef;
		}
	} else {
		if ($newself = $self->db_obj->modify( $data )) {
			warn "save_data - modify succeeded\n" if ($debug > 1);
			$self->{'_db_obj'} = $newself;
			warn 'save_data - after modify - new self ==> ' . Data::Dumper::Dumper($self->{'_db_obj'}) if ($debug > 1);
		} else {
			warn "save_date - modify failed\n" if ($debug > 1);
			$self->{'_errors'}->{'General Database Error'} = $dbh->errstr || $self->db_obj->errors;
			return undef;
		}
	}
	return 1;
} # END sub save_data


=item C<get_data> ( [ $data, ] [ $fields ] )

Takes the fields hash (returned by $self->fields()) and the CGI object and 
returns a data hashref which can be sent to Carbon's new or modify 
You can optionaly pass a $data hash and a $fields hash which it will use.

B<OPTIMIZE>

=cut

sub get_data {
	my $self	= shift;
	return undef unless ref $self;
	my $data	= shift || { };
	my $fields	= shift || $self->fields;
	my $q		= $self->cgi;
	my $db_obj	= $self->db_obj;
	warn 'Admin:get_data q ==> ' . Data::Dumper::Dumper($q) . "\n" if ($debug > 2);
	warn 'Admin:get_data fields ==> ' . Data::Dumper::Dumper($fields) . "\n" if ($debug > 2);
	warn 'Admin:get_data db_obj ==> ' . Data::Dumper::Dumper($db_obj) . "\n" if ($debug > 2);

	foreach (keys %$fields) {
		my $qfieldname	= $self->qfieldname( $_ );
		my $foptions	= $self->fieldoptions( $_ );
		my $qoptions	= $self->fieldhtmloptions( $_ ) || { };
#		if (!$foptions->{not_null} && ($q->param( $qfieldname ) =~ /^NULL$/i)) {
#			warn "Null option selected.";
#			$q->param( $qfieldname, undef );
#			last;
#		}
		if ($self->fieldrelclass( $_ )) {
			warn "reclass - $_ ==> " . $self->fieldrelclass($_) . " qfieldname ==> $qfieldname - q ==> " . Data::Dumper::Dumper($q->param( $qfieldname )) ."\n" if ($debug > 1);
			if ($self->fieldrelclasstype($_)) {
				$data->{$self->fieldrelclass($_)} = [ $q->param( $qfieldname ) ];
			} else {
				warn "no classtype $_\n" if ($debug > 1);
				if ($q->param( $qfieldname ) eq 'NULL') {
					$data->{$_} = undef;
				} else {
					$data->{$_} = $q->param( $qfieldname ) unless (ref $db_obj && ($db_obj->$_() eq $q->param( $qfieldname )));
					warn Data::Dumper::Dumper( $data->{$_} ) if ($debug > 1);
				}
			}
		} elsif ($self->fieldtype($_) eq 'checkbox') {
			unless (defined $q->param( $qfieldname )) {
				$q->param(-NAME => $qfieldname, -VALUE => '0');
			}
			$data->{$_} = $q->param( $qfieldname )
				unless (ref $db_obj && ($db_obj->$_() eq $q->param( $qfieldname )));
		} elsif ($self->fieldtype($_) eq 'date') {
			next unless ($q->param( $qfieldname.'_year' ));
		
			my $date = BingoX::Time->new;
			warn "date field => $qfieldname\n" if ($debug > 1);

			## Year ##
			my $year	= $q->param( $qfieldname.'_year' );
			if (length($year) <= 2) {
				$self->{'_errors'}->{$_} = "Invalid Date Entered: be compliant and the use full year";
				return undef;
			}

			## Month ##
			my $month;
			my $mon		= $q->param( $qfieldname.'_mon' );
			if ($mon	=~ /\D/) {
				$self->{'_errors'}->{$_} = "Invalid Date Entered: must be of the value [ 1 .. 12 ]";
				return undef;
			} else {
				$month = $date->months->{ $mon };
			}

			## Day ##
			my $day		= $q->param( $qfieldname.'_day' );
			my $lday	= $date->last_days->{ $mon - 1 };
			if ($day < 1 || $day > 31) {
				$self->{'_errors'}->{$_} = "Invalid Date Entered: day is out of range";
				return undef;
			} elsif ($day =~ /\D/) {
				$self->{'_errors'}->{$_} = "Invalid Date Entered: must be of the value [ 1 .. last day ]";
				return undef;
			} elsif ($day > $lday) {
				$day = $lday;
			}

			## Hour ##
			my $hour	= $q->param( $qfieldname.'_hour' );
			my $am_pm	= $q->param( $qfieldname.'_ampm' );
			unless ($qoptions->{'-SHOW_24HOURS'}) {
				if ($am_pm eq 'PM') {
					$hour += 12 unless ($hour == 12);
				} else {
					$hour = 0 if ($hour == 12);
				}
			}

			## Minute ##
			my $min		= $q->param( $qfieldname.'_min' ) || '00';

			## Jun 04 1998 21:09:55 ##
			my $string		= sprintf("%s %2d %4d %02d:%02d:00", $month, $day, $year, $hour, $min);
			my $timelocal	= $self->data_class->str2time( $string );
			my $new_date	= BingoX::Time->new( $timelocal );
			$data->{$_}		= $new_date->strftime( $self->data_class->date_format )
				unless (ref $db_obj && ($db_obj->$_() eq $new_date));

			warn 'get_data date ==> ' . Data::Dumper::Dumper($data->{$_}) . "\n" if ($debug > 1);
		} else {
			warn "qfieldname ==> $qfieldname\n" if ($debug > 1);
			next if ($self->fieldtype( $_ ) eq 'view');

			## Verify that password fields match verification
			if ($self->fieldtype($_) eq 'password') {
				my @pw_values = $q->param( $qfieldname );
				if ($pw_values[0] ne $pw_values[1]) {
					$q->param( $qfieldname, '' );
					$self->{'_errors'}->{$_} = 'passwords do not match.';
				}
			}
			if ($q->param( $qfieldname ) eq 'NULL') {
				$data->{$_} = undef;
			} else {
				$data->{$_} = $q->param( $qfieldname )
					unless (ref $db_obj && ($db_obj->$_() eq $q->param( $qfieldname )));
			}
		}
	}
	warn 'get_data ==> ' . Data::Dumper::Dumper($data) ."\n" if ($debug > 2);
	return $data;
} # END sub get_data


=item C<sanity> (  )

Populates the _errors data instance in the case that the data does not conform 
to what is allowed to be entered into the database.

=cut

sub sanity {
	my $self		= shift;
	my $data_hash	= shift;
	ref($data_hash) || return undef;
	my $q			= $self->cgi;
	my $qfield;

	## Step through each field, calling all the necessary sanity methods ##
	foreach my $field (@{ $self->fieldlist }) {
		my $sanity = $self->fieldsanity( $field );
		my $req = %{ $self->fieldoptions( $field ) || { } }->{'not_null'} || 0;
		unless (ref($sanity) eq 'ARRAY' || $req) {
			warn "BingoX::Chromium::fieldsanity('$field') is not an array ref\n" if ($debug);
			next;
		}

		$qfield	 = $self->qfieldname( $field );

		my @errors = ( );
		my $data = (exists $data_hash->{ $field })
					? $data_hash->{$field}
					: (	$self->displaymode eq 'add'
						? ''
						: $self->db_obj->$field());
		## Is this a required field? If it's empty,	##
		## we can complain here and move on...		##
		if ($req && !$data) {
			$self->{'_errors'}{$field} ||= 'This field is required.';
			next;
		}

		## Check each sanity method for this field ##
		foreach my $sane (@$sanity) {
			if (ref $sane) {	# listref, call the method, passing paramters
				my $method	= shift @$sane;
				my $err		= $self->$method($data, @$sane);
				warn("SANITY ERROR: $err") if ($err && $debug);
				push(@errors, $err) if $err;
			} else {			# not a ref, call the method only
				my $err = $self->$sane( $data );
				warn("SANITY ERROR: $err") if ($err && $debug);
				push(@errors, $err) if $err;
			}
		}
		$self->{'_errors'}{$field} = join('<BR>', @errors) if @errors;
	}

	## Parlance -- true result means "sane" ##
	(%{ $self->{'_errors'} }) ? 0 : 1;
} # END sub sanity

sub qfd		{ return "#" }
sub pkd		{ return $_[0]->data_class->pkd }
sub prefix	{ return $_[0]->data_class_name . $_[0]->qfd }


=item C<cpkey> ( [ $db_obj ] )

Returns a string representing a single composite primary key joined by $self->qfd.

=cut

sub cpkey {
	my $self	= shift;
	my $obj		= shift || $self->db_obj;
	return undef unless (ref($self) && ref($obj));
	return $obj->cpkey;
} # END sub cpkey


=item C<cpkey_params> ($cpkey) 

Returns a params hash from the cpkey string passed.

=cut

sub cpkey_params {
	my $self	= shift;
	my $cpkey	= shift || return undef;
	$cpkey		= (split( $self->qfd,$cpkey ))[-1];
	return $self->data_class->cpkey_params( $cpkey );
} # END sub cpkey_param


=item C<pcpkey> (  )

Returns a cpkey with a class name + $qfd in front of it.

=cut

sub pcpkey {
	my $self	= shift;
	my $obj		= shift || $self->db_obj;
	return undef unless (ref($self) && ref($obj));
	return $self->prefix . $obj->cpkey;
} # END sub pcpkey


=item C<dbh> (  )

Returns the object's database handle.

B<OPTIMIZE>  Needs work.  Doesn't appear to use Carboniums dbh method thus 
thus doesn't use cached dbh.

=cut

sub dbh {
	my $self		= shift;
	return $self->{'_dbh'} if (ref($self) && ref($self->{'_dbh'}));
	my $data_class	= $self->data_class;
	my $dbh			= $data_class->dbh;
	$self->{'_dbh'}	= $dbh if (ref $self);
	my $r			= $self->r;
	if (ref $r) {
		$r->register_cleanup(sub { $data_class->purge_dbh }) unless ($r->notes('chromium_cleanup'));
		$r->notes('chromium_cleanup', 1);
	}
	return $dbh;
} # END sub dbh


=item C<get_list_hash> ( [ $selection ] )

*** NEEDS TO BE REMOVED ***

Returns a hash ref of all the objects in the class it was called against.  
The hash is built from the C<pcpkey>, and the data class' C<title_field>, 
substr()'d to the data class' C<title_size> or by default 80 chars.

B<OPTIMIZE>

=cut

sub get_list_hash {
	my $self		= shift;
	my $class		= ref($self) || $self;
	my $selection	= shift || $self->selection;
	my $title_size	= $self->data_class->title_size || 80;
	my $title_field	= $self->data_class->title_field;
	my $fields		= $self->data_class->primary_keys;
	my $sort		= [ ];
	unless ($self->data_class->content_fields->{ $title_field }) {
		push(@$fields, $title_field);
		$sort		= [ $title_field ];
	}

	my $stream		= $self->data_class->stream_obj(
								$self->dbh,
								$selection,
								$fields,
								$sort
					);

	my $hash = { };
	return undef unless ref $stream;
	while (my $obj = $stream->()) {
		$hash->{ $self->pcpkey( $obj ) }
					= length($obj->$title_field()) > $title_size
					? substr($obj->$title_field(), 0, ($title_size - 3)) . '...'
					: $obj->$title_field();
	}

	warn Data::Dumper::Dumper( $hash ) if ($debug > 2);
	return $hash;
} # END sub get_list_hash


=item C<db_obj> (  )

Retrieves and caches encapsolated DATA object based on whats in the query 
obect.   Looks for pcpkey query param first and then for each primary 
key individually.

B<OPTIMIZE>

=cut

sub db_obj {
	my $self	= shift;
	return undef unless ref($self);
	return $self->{'_db_obj'} if ref($self->{'_db_obj'});
	my $q		= $self->cgi;
	my $params	= { };

	warn "CGI ==> " . Data::Dumper::Dumper( $q ) . "\n" if ($debug > 3);
	if ($q->param('cpkey')) {		# should be here most of the time
		warn "pkey ==> " . $q->param('cpkey') . "\n"  if ($debug > 3);
		$params = $self->cpkey_params( $q->param('cpkey') );
		warn 'params ==> ' . Data::Dumper::Dumper( $params ) . "\n" if ($debug > 3);
	} elsif ($q->param('ID')) {		# BAD BAD BAD DOG!  Just in case.
		$params->{ $self->data_class->primary_keys->[0] } = $q->param('ID');
	} else {						# If the primary keys are specified individually.
		foreach (@{ $self->data_class->primary_keys }) {
			return undef unless $q->param($_);
			my $prefix = $self->prefix;
			$q->param($_) =~ /^$prefix(.*)/;
			$params->{$_} = $1;
		}
	}

	## get it from the database. Should we be using get? ##
	$self->{'_db_obj'} = $self->data_class->get( $self->dbh, $params );
} # END sub db_obj


=back

=head2 CLASS VARIABLE METHODS

=over 4

=item C<data_class> (  )
=item C<db_class> (  )

Returns the data class for the current display class (from the class 
variable C<$data_class>).

=cut

sub data_class {
	my $self	= shift;
	return $self->{'_data_class'} if (ref $self);
	my $class	= ref($self) || $self;
	no strict 'refs';
	my $dc = ${"${class}::data_class"};
	unless (defined $dc) {
		($dc = $class) =~ s/::Admin::/::Data::/;
		${"${class}::data_class"} = $dc;
	}
	return $dc;
} # END of data_class
*db_class = \&data_class;				# Backward compatibility


=item C<data_class_name> (  )
=item C<db_class_name> (  )

Returns the rightmost part of the db_class name (thats the text right of the ::)

=cut

sub data_class_name {
	my $self		= shift;
	return $self->{'_data_class_name'} if (ref $self);
	$self->data_class	=~ /^.*:(.*)/;
	return $1;
} # END sub data_class_name
*db_class_name = \&data_class_name;		# Backward compatibility


=item C<ui> (  )

This method is a fallback method for the user interface for BingoX::Chromium.  
ui() contains the default colors for the forms created by BingoX::Chromium.  
To create a custom color scheme for a specific class or entire admin area 
create a ui() method in either the Admin class or the subclass 
and modify the details to your preference.

=cut

sub ui {
	my $self	= shift;
	return $self->{'_ui'} if (ref($self) && ref($self->{'_ui'}));
	my $options	= shift			|| { };
	$options->{'text_color'}	||= '#000000';
	$options->{'link_color'}	||= '#0000FF';
	$options->{'vlink_color'}	||= '#660099';
	$options->{'alink_color'}	||= '#FF0000';
	$options->{'page_bg'}		||= '#FFFFFF';
	$options->{'table_border'}	||= '#000000';
	$options->{'row_key'}		||= '#EEEEDE';
	$options->{'row_value'}		||= '#FFFFFF';
	$options->{'table_header'}	||= '#FFFFEE';
	$options->{'table_footer'}	||= '#FFFFEE';
	$options->{'font_header'}	||= { -FACE => 'verdana,arial,helvetica', -SIZE => '5' };
	$options->{'font_footer'}	||= { -FACE => 'verdana,arial,helvetica', -SIZE => '1' };
	$options->{'font_error'}	||= { -FACE => 'verdana,arial,helvetica', -SIZE => '2', -COLOR => "#FF0000" };
	$options->{'font_key'}		||= { -FACE => 'verdana,arial,helvetica', -SIZE => '2' };
	$options->{'font_value'}	||= { -FACE => 'times', -SIZE => '3' };
	return (ref($self) ? $self->{'_ui'} = $options : $options);
} # END sub ui


=item C<children> (  )

Returns class defined children as an arrayref.

=cut

sub children {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return [ @{"${class}::children"} ] || undef;
} # END sub children


=item C<parents> (  )

Returns class defined parents as an arrayref.

=cut

sub parents {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return [ @{"${class}::parents"} ] || undef;
} # END sub children


=item C<parent_class> (  )

Returns cached parent class

=cut

sub parent_class {
	return $_[0]->{'_parent_class'};
} # END of parent_class


=item C<adminuri> (  )

Returns class defined URI as a string.

=cut

sub adminuri {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	warn 'adminuri ==> ' . ${"${class}::adminuri"} . "\n" if ($debug > 3);
	return ${"${class}::adminuri"} || undef;
} # END sub adminuri


=item C<classdesc> (  )

Returns class defined Class description as a string.

=cut

sub classdesc {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	warn 'classdesc ==> ' . ${"${class}::classdesc"} . "\n" if ($debug > 3);
	return ${"${class}::classdesc"} || undef;
} # END sub classdesc


=item C<adminclass> (  )

NEEDS POD

=cut

sub adminclass {
	my $proto	= shift;
	my $class	= shift;
	my $lclass	= $class;
	no strict 'refs';
	my @ISA		= @{ "${class}::ISA" };
	while ($ISA[0] ne __PACKAGE__) {
		$lclass = shift(@ISA);
		unshift( @ISA, @{ "${lclass}::ISA" } );
		return undef unless (@ISA);
	}
	return $lclass;
} # END sub adminclass


=item C<fieldlist> (  )

Returns the class defined fieldlist as an arrayref.

=cut

sub fieldlist {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return \@{"${class}::fieldlist"};
} # END sub fieldlist


=item C<fields> (  )

Returns class defined fields hashref.

=cut

sub fields {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return \%{"${class}::fields"};
} # END sub fields


=item C<fieldname> ( $field )

Takes a column name and returns a string with that field's pretty 
name as defined in the class defined field hash.  This is the [0] 
element of that keys array value.

=cut

sub fieldname {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $field	= shift;
	my $fields	= $class->fields();
	return undef unless (defined %$fields);
	return $fields->{$field}[0];
} # END sub fieldname


=item C<fieldtype> ( $field )

Takes a column name and returns a string with that field's HTML 
type as defined in the class defined field hash.  This is the [1] 
element of that keys array value.

=cut

sub fieldtype {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $field	= shift;
	my $fields	= $class->fields();
	return undef unless (defined %$fields);
	return $fields->{$field}[1];
} # END sub fieldtype


=item C<fieldhtmloptions> ( $field )

Takes a column name and returns a hashref with that field's HTML 
options as defined in the class defined field hash.  This is the 
[2] element of that keys array value.

=cut

sub fieldhtmloptions {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $field	= shift;
	my $fields	= $class->fields();
	return undef unless (defined %$fields);
	return $fields->{$field}[2];
} # END sub fieldhtmloptions


=item C<fieldrelclass> ( $field )

Takes a column name and returns a string with that field's related 
class (if it exists) as defined in the class defined field hash.  
This is the [3] element of that keys array value.

=cut

sub fieldrelclass {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $field	= shift;
	my $fields	= $class->fields();
	return undef unless (defined(%$fields) && exists($fields->{$field}[3]));
	return $fields->{$field}[3][0];
} # END sub fieldrelclass

=item C<fieldrelclasstype> ( $field )

Takes a column name and returns a string with that field's related 
class (if it exists) as defined in the class defined field hash.  
This is the [3] element of that keys array value.

=cut

sub fieldrelclasstype {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $field	= shift;
	my $fields	= $class->fields();
	return undef unless (defined(%$fields) && exists($fields->{$field}[3]));
	return $fields->{$field}[3][1];
} # END sub fieldrelclasstype


=item C<fieldoptions> ( $field )

Takes a column name and returns a hashref with that field's options 
information as defined in the class defined field hash.  
This is the [4] element of that keys array value.

=cut

sub fieldoptions {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $field	= shift;
	my $fields	= $class->fields();
	return undef unless (defined %$fields);
	return $fields->{$field}[4];
} # END sub fieldoptions


=item C<fieldsanity> ( $field )

Takes a column name and returns a listref with that field's sanity 
information as defined in the class defined field hash.  
This is the [5] element of that keys array value.

=cut

sub fieldsanity {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $field	= shift;
	my $fields	= $class->fields();
	return undef unless (defined %$fields);
	return $fields->{$field}[5];
} # END sub fieldsanity


=back

=head2 OBJECT METHODS

=over 4

=item C<uri> (  )

Returns the cached uri object.

=item C<cgi> (  )

Returns the cached cgi object.

=item C<conf> (  )

Returns the cached conf object (set in new).

=item C<section> (  )

Returns the cached section (set in new).

=item C<displaymode> (  )

Returns the cached uri displaymode (set in new).

=cut

sub uri				{ $_[0]->{'_uri'}			}
sub cgi				{ $_[0]->{'_cgi'}			}
sub conf			{ $_[0]->{'_conf'}			}
sub section			{ $_[0]->{'_section'}		}
sub displaymode		{ $_[0]->{'_displaymode'}	}


=item C<r> (  )

Object Method:
Returns Apache Request object.

=cut

sub r {
	return undef unless (defined $ENV{'MOD_PERL'} && ref $_[0]);
	$_[0]->{'_r'} ||= Apache->request;
} # END sub r


=item C<selection> ( [ \%hash ] )

Returns a hash reference containing the parameters that specify the current 
selection. If a new value is passed, it sets the selection to that value.

=cut

sub selection {
	my $self	= shift;
	my $value	= shift;
	if (ref $self) {
		$self->{'_selection'} = $value if (defined $value);
		return $self->{'_selection'} || { };
	} else {
		return { };
	}
} # END sub selection


=back

=head2 HTML DISPLAY METHODS

=over 4


=item C<qfieldname> ( $fieldname )

Object Method:
 
Returns the fieldname to be used in the FORM INPUT NAME field.  When 
overloading Administration field variables, use this to get the INPUT TYPE NAME.

ie.  <INPUT TYPE="text" NAME="$self->qfieldname('username')">

=cut

sub qfieldname {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qfieldname	= '';
	$qfieldname		= $self->cpkey . $self->qfd if ($self->displaymode eq 'modify');
	$qfieldname		.= $self->prefix . $fieldname;
	return $qfieldname;
} # END of qfieldname


=item C<main_index> (  )

Object Method:
 
Returns the Main Index Path.

=cut

sub main_index {
	my $self	= shift;
	my $path	= $self->r->dir_config('AdminMainIndex') || '/';
	return $path;
} # END of main_index


=item C<HTML_time> ( $fieldname [, $qoptions ] )

Object Method:
 
Generic Hours Form Tag.  Called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns a 
set of date form fields or in viewable format if the displaymode is 'view'.

=cut

sub HTML_time {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname ) || { };
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );

	my $hr24		= $qoptions->{'-SHOW_24HOURS'};

	my $date_obj;
	$date_obj		= $self->db_obj->$fieldname() unless ($self->displaymode eq 'add');
	if (!ref($date_obj)) {
		return undef if ($self->displaymode eq 'view');
		$date_obj	= BingoX::Time->new();
	}

	my ($hour, $minute, $ampm);
	## get hour from the date object ##
	$hour			= $date_obj->hour;
	## get minute from the date object ##
	$minute			= $date_obj->min;
	unless ($hr24) {
		$ampm = ($hour >= 12 ? 'PM' : 'AM');
		$hour -= 12 if ($hour > 12);
		$hour = 12  if ($hour == 0);
	}

	return ($hour . ':' . $minute . ' ' . $ampm ,
			$q->hidden(-NAME => $qfieldname.'_hour', -VALUE => $hour)
		.	$q->hidden(-NAME => $qfieldname.'_min',  -VALUE => $minute)
		.	$q->hidden(-NAME => $qfieldname.'_ampm', -VALUE => $ampm))
		if ($self->displaymode eq 'view' || $qoptions->{'-TYPE'} =~ /view/i);
	
	if ($qoptions->{'-TYPE'} =~/view/io) {
		return	$q->hidden(	-NAME	=> $qfieldname.'_hour',
							-VALUE	=> $hour)
			.	$q->hidden(	-NAME	=> $qfieldname.'_min',
							-VALUE	=> $minute)
			.	$q->hidden(	-NAME	=> $qfieldname.'_ampm',
							-VALUE	=> $ampm);
	} elsif ($qoptions->{'-TYPE'} =~/text/io) {
		return	$q->textfield(	-NAME		=> $qfieldname.'_hour',
								-SIZE		=> $qoptions->{'-HR_SIZE'}		|| 2,
								-MAXLENGTH	=> $qoptions->{'-HR_MAXLENGTH'}	|| 2,
								-OVERRIDE	=> $qoptions->{'-HR_OVERRIDE'}	|| 1,
								-DEFAULT	=> sprintf("%02d", $q->param( $qfieldname.'_hour' )	|| $hour)
							)
			.	' : '
			.	$q->textfield(	-NAME		=> $qfieldname.'_min',
								-SIZE		=> $qoptions->{'-MIN_SIZE'}			|| 2,
								-MAXLENGTH	=> $qoptions->{'-MIN_MAXLENGTH'}	|| 2,
								-OVERRIDE	=> $qoptions->{'-MIN_OVERRIDE'}		|| 1,
								-DEFAULT	=> sprintf("%02d", $q->param( $qfieldname.'_min' )	|| $minute)
							)
			.	($hr24 ? '' :
				'&nbsp;' . $q->popup_menu(	-NAME		=> $qfieldname.'_ampm',
											-VALUES		=> [ 'AM', 'PM' ],
											-DEFAULT	=> ($q->param( $qfieldname.'_ampm' )	|| $ampm),
											-OVERRIDE	=> $qoptions->{'-AMPM_OVERRIDE'}		|| 1
										));
	} else {
		return $q->popup_menu(	-NAME		=> $qfieldname.'_hour',
								-VALUES		=> ($hr24 ? $date_obj->hours24 : $date_obj->hours),
								-DEFAULT	=> sprintf("%02d", $hour),
								-OVERRIDE	=> $qoptions->{'-HR_OVERRIDE'} || 1
							)
			. '&nbsp;:&nbsp;'
			. $q->popup_menu(	-NAME		=> $qfieldname.'_min',
								-VALUES		=> $date_obj->minutes,
								-DEFAULT	=> sprintf("%02d", $q->param( $qfieldname.'_min' )	|| $minute),
								-OVERRIDE	=> $qoptions->{'-MIN_OVERRIDE'} || 1
							)
			. ($hr24 ? '' :
				'&nbsp;' . $q->popup_menu(	-NAME		=> $qfieldname.'_ampm',
											-VALUES		=> [ 'AM', 'PM' ],
											-DEFAULT	=> ($q->param( $qfieldname.'_ampm' )	|| $ampm),
											-OVERRIDE	=> $qoptions->{'-AMPM_OVERRIDE'}		|| 1
										));
	}					
} # END sub HTML_time


=item C<HTML_day> ( $fieldname [, $qoptions ] )

Object Method:

Generic Day Form Tag.  Called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns a 
set of date form fields or in viewable format if the displaymode is 'view'.

=cut

sub HTML_day {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname ) || { };
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );
	
	my $date_obj;
	$date_obj		= $self->db_obj->$fieldname() unless ($self->displaymode eq 'add');
	if (!ref($date_obj)) {
		return undef if ($self->displaymode eq 'view');
		$date_obj	= BingoX::Time->new();
	}

	return $date_obj->mday if ($self->displaymode eq 'view');

	if ($qoptions->{'-TYPE'} =~/view/io) {
		return ( $date_obj->mday 
				,$q->hidden(	-NAME	=> $qfieldname.'_day',
								-VALUE	=> $date_obj->mday));
	} elsif ($qoptions->{'-TYPE'} =~/text/io) {
		return $q->textfield(	-NAME		=> $qfieldname.'_day',
								-SIZE		=> $qoptions->{'-DAY_SIZE'}			|| 2,
								-MAXLENGTH	=> $qoptions->{'-DAY_MAXLENGTH'}	|| 2,
								-OVERRIDE	=> $qoptions->{'-DAY_OVERRIDE'}		|| 1,
								-DEFAULT	=> $q->param( $qfieldname.'_day' )	|| $date_obj->mday
							);
	} else {
		return $q->popup_menu(	-NAME		=> $qfieldname.'_day',
								-VALUES		=> [ 1 .. 31 ],
								-OVERRIDE	=> $qoptions->{'-DAY_OVERRIDE'}		|| 1,
								-DEFAULT	=> $q->param( $qfieldname.'_day' )	|| $date_obj->mday
							);
	}
} # END sub HTML_day


=item C<HTML_month> ( $fieldname [, $qoptions ] )

Object Method:

Generic Month Form Tag.  Called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns a 
set of date form fields or in viewable format if the displaymode is 'view'.

=cut

sub HTML_month {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname ) || { };
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );

	my $format		= $qoptions->{'-FORMAT'} || "%B %e %Y";
	my $date_obj;
	$date_obj		= $self->db_obj->$fieldname() unless ($self->displaymode eq 'add');
	if (!ref($date_obj)) {
		return undef if ($self->displaymode eq 'view');
		$date_obj	= BingoX::Time->new();
	}

	return $date_obj->mon if ($self->displaymode eq 'view');

	if ($qoptions->{'-TYPE'} =~/view/io) {
		return ($date_obj->mon,
				$q->hidden(	-NAME	=> $qfieldname.'_mon',
							-VALUE	=> $date_obj->mon));
	} elsif ($qoptions->{'-TYPE'} =~/text/io) {
		return $q->textfield(	-NAME		=> $qfieldname.'_mon',
								-SIZE		=> $qoptions->{'-MON_SIZE'}			|| 2,
								-MAXLENGTH	=> $qoptions->{'-MON_MAXLENGTH'}	|| 2,
								-OVERRIDE	=> $qoptions->{'-MON_OVERRIDE'}		|| 1,
								-DEFAULT	=> $q->param( $qfieldname.'_mon' )	|| $date_obj->mon
							);
	} else {
		return $q->popup_menu(	-NAME		=> $qfieldname . '_mon',
								-VALUES		=> [ 1 .. 12 ],
								-LABELS		=> ($format =~ /\%B/o ? $date_obj->months_full : $date_obj->months),
								-OVERRIDE	=> $qoptions->{'-MON_OVERRIDE'}		|| 1,
								-DEFAULT	=> $q->param( $qfieldname.'_mon' )	|| $date_obj->mon
							);
	}
} # END sub HTML_month


=item C<HTML_year> ( $fieldname [, $qoptions ] )

Object Method:

Generic Year Form Tag.  Called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns a 
set of date form fields or in viewable format if the displaymode is 'view'.

=cut

sub HTML_year {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname ) || { };
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );

	my $format		= $qoptions->{'-FORMAT'} || "%B %e %Y";
	my $date_obj;
	$date_obj		= $self->db_obj->$fieldname() unless ($self->displaymode eq 'add');
	if (!ref($date_obj)) {
		return undef if ($self->displaymode eq 'view');
		$date_obj	= BingoX::Time->new();
	}
	my $start		= $qoptions->{'-YEAR_START'}		|| 20;
	my $end			= $qoptions->{'-YEAR_END'}			|| 20;
	my ($values, $year, $size, $max);
	if ($format =~ /\%Y/o) {
		$year		= $date_obj->year;
		$values		= [ ($year - $start) .. ($year + $end) ];
		$size		= 4;
		$max		= 4;
	} else {
	### THERE IS NO REASON TO USE NON-COMPLIANT YEARS ###
		$size		= 2;
		$max		= 2;
		$year		= substr($date_obj->year, -2, 2);
		my $yr		= $year;
		$values		= [ $year ];
		$start		= 49 if ($start >= 50);		# can only display 100 years at a time in two digit format
		foreach (1 .. $start) {
			$yr = 100 if ($yr == 0);			# can't have negative years
			unshift(@$values, sprintf("%02d", --$yr));
		}
		$yr			= $year;
		foreach (1 .. $start + 1) {
			push(@$values, sprintf("%02d", ++$yr));
		}
	}

	return $year if ($self->displaymode eq 'view');

	if ($qoptions->{'-TYPE'} =~/view/io) {
		return ($year ,$q->hidden(	-NAME	=> $qfieldname.'_year',
									-VALUE	=> $year));
	} elsif ($qoptions->{'-TYPE'} =~/text/io) {
		return $q->textfield(	-NAME		=> $qfieldname.'_year',
								-SIZE		=> $size, 
								-MAXLENGTH	=> $max, 
								-OVERRIDE	=> $qoptions->{'-YEAR_OVERRIDE'}	|| 1,
								-DEFAULT	=> $q->param( $qfieldname.'_year' )	|| $year
							);
	} else {
		return $q->popup_menu(	-NAME		=> $qfieldname.'_year',
								-VALUES		=> $values,
								-OVERRIDE	=> $qoptions->{'-YEAR_OVERRIDE'}	|| 1,
								-DEFAULT	=> $q->param( $qfieldname.'_year' )	|| $year
							);
	}
} # END sub HTML_year


=item C<HTML_date> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns a 
set of date form fields or in viewable format if the displaymode is 'view'.

B<Needs to be less Sybase Dependant and handle Time>

=cut

sub HTML_date {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname ) || { };
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );

	my $showhrs		= $qoptions->{'-SHOW_HOURS'}	|| $qoptions->{'-SHOW_24HOURS'};	# Show the hours flag
	my $format		= $qoptions->{'-FORMAT'}		|| "%B %e %Y";						# format for date strings
	my $delim		= $qoptions->{'-DELIMITER'}		|| '/';								# delimiter for text dates

	my ($day, $dhidden)		= $self->HTML_day(	$fieldname, $qoptions );
	my ($mon, $mhidden)		= $self->HTML_month($fieldname, $qoptions );
	my ($year, $yhidden)	= $self->HTML_year(	$fieldname, $qoptions );
	my ($time, $thidden)	= $self->HTML_time(	$fieldname, $qoptions );

	my $date_obj;
	$date_obj		= $self->db_obj->$fieldname() unless ($self->displaymode eq 'add');
	if (!ref($date_obj)) {
		return undef if ($self->displaymode eq 'view');
		$date_obj	= BingoX::Time->new();
	}

	## if in display view mode get the date object from the scalar values ##
	if ($self->displaymode eq 'view') {
		if ($qoptions->{'-FORMAT'}) {
			return $date_obj->strftime( $format ) . $dhidden . $mhidden . $yhidden . $thidden;
		} elsif ($qoptions->{'-DELIMITER'}) {
			return "$mon $delim $day $delim $year" . ($showhrs ? " $time" : '');
		} else {
			return "$mon  $day  $year" . ($showhrs ? "  $time" : '');
		}
	}

	my $html;
	if ($qoptions->{'-TYPE'} =~/view/io) {
		$html = "$mon  $day  $year";
	} elsif ($qoptions->{'-TYPE'} =~/text/io) {
		$html = "$mon $delim $day $delim $year";
	} else {
		$html = $mon . $day . $year;
	}
	$html .= "<BR>$time" if ($showhrs);

	## should take care of time here. ##
	return $html;
} # END sub HTML_date


=item C<HTML_view> ( $fieldname )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns the value 
in viewable format.

=cut

sub HTML_view {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );
	(defined($q->param( $qfieldname ))
		?	$q->param( $qfieldname )
		:	(($self->displaymode ne 'add') ? $self->db_obj->$fieldname() : '')) 
	. "\n";
} # END sub HTML_view

=item C<HTML_hidden> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns the value 
as a hidden input field.

=cut

sub HTML_hidden {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname );
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );
	$qfieldname		= $fieldname unless (defined $q->param( $qfieldname ));
	($self->displaymode eq 'view')
	? $self->db_obj->$fieldname()
	: $q->hidden(	-NAME		=> $qfieldname,
					-OVERRIDE	=> $qoptions->{'-OVERRIDE'} || 1,
					-DEFAULT	=> (defined($q->param( $qfieldname ))
									?	$q->param( $qfieldname )
									:	(($self->displaymode eq 'modify')
										? $self->db_obj->$fieldname()
										: ($qoptions->{'-DEFAULT'} || '')))
				) . "\n";
} # END sub HTML_hidden


=item C<HTML_text> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns the value 
in a text input field or in viewable format if the displaymode is 'view'.

=cut

sub HTML_text {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname );
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );
	($self->displaymode eq 'view')
	? $self->db_obj->$fieldname()
	: $q->textfield(	-NAME		=> $qfieldname,
						-SIZE		=> $qoptions->{'-SIZE'}		|| 50,
						-MAXLENGTH	=> $qoptions->{'-MAXLENGTH'}|| 200,
						-OVERRIDE	=> $qoptions->{'-OVERRIDE'} || 1,
						-DEFAULT	=> (defined($q->param( $qfieldname ))
										?	$q->param( $qfieldname )
										:	(($self->displaymode eq 'modify')
											? $self->db_obj->$fieldname()
											: ($qoptions->{'-DEFAULT'} || '')))
						) . "\n";
} # END sub HTML_text

=item C<HTML_password> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns the value 
in a password input field with a corresponding or in an obscured format if the displaymode is 'view'.

=cut

sub HTML_password {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname );
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );
	($self->displaymode eq 'view')
	? '&lt;NOT DISPLAYED&gt;'
	: $q->password_field(-NAME		=> $qfieldname,
						 -SIZE		=> $qoptions->{'-SIZE'}		|| 50,
						 -MAXLENGTH	=> $qoptions->{'-MAXLENGTH'}|| 200,
						 -OVERRIDE	=> $qoptions->{'-OVERRIDE'} || 1,
						 -DEFAULT	=> (defined($q->param( $qfieldname ))
										?	$q->param( $qfieldname )
										:	(($self->displaymode eq 'modify')
											? $self->db_obj->$fieldname()
											: ($qoptions->{'-DEFAULT'} || '')))
						) . "\n";
} # END sub HTML_password


=item C<HTML_textarea> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns 
the value in a text input field or in viewable format if the 
displaymode is 'view'.

=cut

sub HTML_textarea {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname );
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );

	if ($self->{'_displaymode'} eq 'view') {
		my $content = $self->db_obj->$fieldname();
		$content =~ s/(\r\n)|[\n\r]/<BR>/go;
		return $content;
	}
	$q->textarea(	-NAME		=> $qfieldname, 
					-ROWS		=> $qoptions->{'-ROWS'}		|| 6,
					-COLS		=> $qoptions->{'-COLS'}		|| 50,
					-WRAP		=> $qoptions->{'-WRAP'}		|| 'VIRTUAL',
					-OVERRIDE	=> $qoptions->{'-OVERRIDE'}	|| 1,
					-DEFAULT	=> (defined($q->param( $qfieldname ))
									?	$q->param( $qfieldname )
									:	(($self->displaymode eq 'modify')
										? $self->db_obj->$fieldname()
										: ($qoptions->{'-DEFAULT'} || '')))
				) . "\n";
} # END sub HTML_textarea


=item C<HTML_popup> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns the value 
in a popup field or in viewable format if the displaymode is 'view'.

Note: Not used yet because its not easy to populate the 
vaules & labels fields. USually always overloaded in the subclasses.

B<OPTIMIZE>

=cut

sub HTML_popup {
	my $self		= shift;
	my $class		= ref($self) || return undef;
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname );
	my $foptions	= $self->fieldoptions( $fieldname );
	my $q			= $self->cgi;

	## if modify then grab the actual values of the primary keys of the obect				##
	## and prepend the fieldname with them.  This will allow people to modify multiple		##
	## objects on the same page.   Always put the classname and the fieldname at the end	##
	## of the fieldname.																	##
	my $qfieldname				= $self->qfieldname( $fieldname );
	my $relclass				= $class->fieldrelclass( $fieldname );
	my $relclass_title_field	= $relclass->title_field;
	$relclass					=~ /(.+)::Data::(.+)$/;
	my $reladminclass			= "${1}::Admin::${2}";

	## show all of the objects as text. ##
	if ($self->displaymode eq 'view') {
		my $obj		= @{ $relclass->list_obj(
							$self->dbh,
							{
								$relclass->primary_keys->[0] => $self->db_obj->$fieldname()
							}
					) || [ ] }->[0];
		(ref($obj) ? return $obj->$relclass_title_field() : return 'None Selected') . "\n";

	## get all of the objects with get_list_hash. ##
	} else {
		my $hashref	= $relclass->get_list_hash( $self->dbh );

		## Allows null value for popups ##
		if (!$foptions->{'not_null'} && $foptions->{'null_label'}) {
			$hashref->{'NULL'} = $foptions->{'null_label'};
		}

#		## if the displaymode isn't add, then highlite the already related objects. ##
#		my $selected = ($self->displaymode eq 'add')
#					? [ ]
#					: $self->db_obj->list_related( $relclass );
#		warn "Too Many Related" if ($selected->[1] && $debug);

		## default - if there's already data in the query object, highlite those objects,			##
		## otherwise if the displaymode if modify, show the data in the scrolling list where the	##
		## keys are composit primary keys seperated by $self->pkd and the									##
		## values are the title_fields of the objects, else don't highlite anything.				##
		$q->popup_menu(	-NAME		=> $qfieldname,
						-VALUES		=> [ sort { $hashref->{$a} cmp $hashref->{$b} } keys %$hashref ],	# need to fill in info later
						-LABELS		=> $hashref,														# need to fill in info later
						-DEFAULT	=> (defined($q->param( $qfieldname ))
									?	$q->param( $qfieldname )
									:	(($self->displaymode eq 'modify')
										? (defined($self->db_obj->$fieldname())
											? $self->db_obj->$fieldname()
											: ($foptions->{'null_label'}
												? 'NULL'
												: $qoptions->{'-DEFAULT'} || ''))
		## The trinary below is for parent child relationships.  Basically, if	##
		## we're adding a new object and this pop-up represents a list of our	##
		## parent fields, we should default to the parent we came through.		##
										: ((($self->displaymode eq 'add') && ($reladminclass eq $self->parent_class) && ($q->param('parent_pcpkey'))) 
											? (substr($q->param('parent_pcpkey'),rindex($q->param('parent_pcpkey'),$self->qfd)+1))
											: ($qoptions->{'-DEFAULT'} || ''))))
						) . "\n";
	}
} # END sub HTML_popup


=item C<HTML_radio> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns the value 
in a group of radio buttons or in viewable format if the displaymode is 'view'.

=cut

sub HTML_radio {
	my $self		= shift;
	my $class		= ref($self) || return undef;
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname );
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );

	my $relclass	= $class->fieldrelclass( $fieldname );
	my $relclass_title_field = $relclass->title_field;

	## show all of the objects as text. ##
	if ($self->displaymode eq 'view') {
		my $obj		= @{ $relclass->list_obj(	$self->dbh,
												{
													$relclass->primary_keys->[0] => $self->db_obj->$fieldname()
												}
											) || [ ] }->[0];
		(ref($obj) ? return $obj->$relclass_title_field() : return 'None Selected') . "\n";

	## get all of the objects with get_list_hash. ##
	} else {
		my $hashref = $relclass->get_list_hash( $self->dbh );
		
		## if the displaymode isn't add, then highlite the already related objects. ##
		my $selected = ($self->displaymode eq 'add')
					? [ ]
					: $self->db_obj->list_related( $relclass );

		warn "Too Many Related" if ($selected->[1] && $debug);

		$q->autoEscape(0) if ($qoptions->{'-NOESCAPE'});
		my $val = $q->radio_group(
									-NAME		=> $qfieldname,
									-VALUES		=> [ keys %$hashref ],				# need to fill in info later
									-LABELS		=> $hashref,						# need to fill in info later
									-LINEBREAK	=> $qoptions->{'-LINEBREAK'} || 'true',
									-DEFAULT	=> (defined($q->param( $qfieldname ))
												?	$q->param( $qfieldname )
												:	(($self->displaymode eq 'modify')
													? $self->db_obj->$fieldname()
													: ($qoptions->{'-DEFAULT'} || '')))
								);
		$q->autoEscape(1) if ($qoptions->{'-NOESCAPE'});
		return $val;
	}
} # END sub HTML_radio


=item C<HTML_scrolling> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns the value 
in a scrolling list field or in viewable format if the displaymode is 'view'.

Note: Not used yet because its not easy to populate the 
vaules & labels fields. USually always overloaded in the subclasses.

B<OPTIMIZE>

=cut

sub HTML_scrolling {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname );
	my $q			= $self->cgi;

	## if modify then grab the actual values of the primary keys of the obect				##
	## and prepend the fieldname with them.  This will allow people to modify multiple		##
	## objects on the same page.   Always put the classname and the fieldname at the end	##
	## of the fieldname.																	##
	my $qfieldname	= $self->qfieldname( $fieldname );

	my $relclass	= $self->fieldrelclass( $fieldname );
	my $relclass_title_field = $relclass->title_field;

	## show all of the objects as text. ##
	if ($self->displaymode eq 'view') {
		my $code = $self->db_obj->stream_related( $relclass );
		my $list;
		if (ref $code) {
			while (my $obj = $code->()) {
				$list .= $obj->$relclass_title_field() . "<BR>\n";
			}
		}
		## NEED AN ELSE AS AN ERROR CHECK! ##
		($list ? return $list : return 'None Selected') . "\n";
	## get all of the objects with get_list_hash. ##
	} else {
		my $hashref = $relclass->get_list_hash( $self->dbh );

		## if the displaymode isn't add, then highlite the already related objects. ##
		my $selected = ($self->displaymode eq 'add')
					? [ ]
					: $self->db_obj->list_related( $relclass );

		## default - if there's already data in the query object, highlite those objects,			##
		## otherwise if the displaymode if modify, show the data in the scrolling list where the	##
		## keys are composit primary keys seperated by $self->pkd and the									##
		## values are the title_fields of the objects, else don't highlite anything.				##
		return $q->scrolling_list(
					-NAME		=> $qfieldname,
					-OVERRIDE	=> $qoptions->{'-OVERRIDE'}	|| 1,
					-SIZE		=> $qoptions->{'-SIZE'}		|| 6,
					-MULTIPLE	=> $qoptions->{'-MULTIPLE'}	|| 'true',
					-VALUES		=> [ keys %{$hashref} ],
					-LABELS		=> $hashref,
					-DEFAULT	=> ($q->param( $qfieldname )
								?	[ $q->param( $qfieldname ) ]
								:	(($self->displaymode eq 'modify')
										?	[
												map {
														$_->cpkey()
													} @$selected
											]
										: ($qoptions->{'-DEFAULT'} || [ ])))
				) . "\n";
	}
} # END sub HTML_scrolling


=item C<HTML_checkbox> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns the value 
in a checkbox field or in viewable format if the displaymode is 'view'.

Note: Not used yet because its not easy to populate the 
vaules & labels fields. USually always overloaded in the subclasses.

=cut

sub HTML_checkbox {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname );
	my $q			= $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );
	($self->displaymode eq 'view')
	? $self->db_obj->$fieldname()
	: $q->checkbox(
			-NAME		=> $qfieldname,
			-CHECKED	=> $self->displaymode eq 'modify'
						?	$self->db_obj->$fieldname()
						:	$qoptions->{'-CHECKED'},
			-VALUE		=> $qoptions->{'-VALUE'} || '1',
			-LABEL		=> $qoptions->{'-LABEL'} || ''
		);
} # END sub HTML_checkbox


=item C<HTML_file> ( $fieldname [, $qoptions ] )

Object Method:

Generic form field method called by AUTOLOAD.  
Gets the default field params based on the fieldname and returns the value 
in a form file upload field or in viewable format if the displaymode is 'view'.

=cut

sub HTML_file {
	my $self		= shift;
	return undef unless ref($self);
	my $fieldname	= shift;
	my $qoptions	= shift || $self->fieldhtmloptions( $fieldname );
	my $q = $self->cgi;
	my $qfieldname	= $self->qfieldname( $fieldname );
	($self->displaymode eq 'view')
	? $self->db_obj->$fieldname()
	: $q->filefield(
			-NAME		=> $qfieldname,
			-SIZE		=> $qoptions->{'-SIZE'}			|| 40,
			-MAXLENGTH	=> $qoptions->{'-MAXLENGTH'}	|| 200,
			-OVERRIDE	=> 1,
			-DEFAULT	=> ''	# browsers null defaults in upload fields anyway
		);
} #END sub HTML_file


=back

=head2 SANITY METHODS

These methods can be overridden at any level to provide customized sanity 
checking. These methods always return an error message on failure, and an 
empty string on success.

=over 4

=item C<sane_regex> ( $data, $regex [, $error ] )

If C<$data> matches the regular expression in C<$regex>, returns an empty 
string. Otherwise, returns C<$error> or a default error message.

=cut

sub sane_regex {
	my $self	= shift;
	my $data	= shift;
	my $regex	= shift;
	my $error	= shift || 'Not correctly formatted.';
	warn("sane_regex('$data', '$regex', '$error')\n") if $debug > 2;
	return $error unless $data =~ /$regex/;
	return "";
} #END sub sane_regex


=item C<sane_maxlength> ( $data, $length )

Makes sure that C<$data> is no more than C<$length> characters long. Returns 
an error message on failure, an empty string on success.

=cut

sub sane_maxlength {
	my $self	= shift;
	my $data	= shift;
	my $length	= shift;
	warn("sane_maxlength('$data', $length)\n") if $debug > 2;
	return "Exceeds $length characters in length." unless (length($data) <= $length);
	return "";
} #END sub sane_maxlength


=item C<sane_minlength> ( $data, $length )

Makes sure that C<$data> is at least C<$length> characters long. Returns an 
error message on failure, an empty string on success.

=cut

sub sane_minlength {
	my $self	= shift;
	my $data	= shift;
	my $length	= shift;
	warn("sane_minlength('$data', $length)\n") if $debug > 2;
	return "Must be at least $length characters." unless (length($data) >= $length);
	return "";
} #END sub sane_minlength


=item C<AUTOLOAD> (?????)

AUTOLOAD method - Figures out what method was being called by stripping the 
fully qualified portion of $AUTOLOAD out as $name.  This method is expected to be 
a column name (an element of fieldlist).  It then figures out what that 
columns fieldtype is from fieldtype($name).  It then calls that type 
of HTML display method and passed $name to it.

=cut

sub AUTOLOAD {
	return if $AUTOLOAD =~ /::DESTROY$/;
	my $self	= shift;
	my $name	= substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);	# strip fully-qualified portion 
	
	return undef unless $self->fieldtype( $name );	# need better error
	my $meth = 'HTML_' . $self->fieldtype( $name );
	$self->$meth( $name );							# call one of the private fieldtype methods above
} # END sub AUTOLOAD


1;

__END__

=back

=head1 REVISION HISTORY

 $Log: Chromium.pm,v $
 Revision 2.36  2001/11/14 23:12:26  gefilte
 save_data() - now optionally takes \%data, the result of get_data().

 RATIONALE :
 	Consider a case when you want to override save_data() in a method which
 calls SUPER::save_data() (arguably a very useful feature.)  Now suppose that
 your save_data() method needs to see the result of get_data(), or possibly even
 manipulate those results (although that should be accomplished by overriding
 get_data()), before calling SUPER::save_data(). Before this change, the
 (arguably expensive) call to get_data() would need to be repeated.  With this
 change, passing a \%data to save_data() will circumvent the need for the
 second call.
 	I considered using instance data to cache the results of get_data(), but
 since get_data() can be optionally called with a preset \%data hash this
 feature, while solving the efficiency problem, would open the door to more bugs.

 	"Did you make sure the NO_BUGS flag is on?  Well that's your problem!"
 		- Colin Bielen (paraphrase)

 Revision 2.35  2001/11/14 22:53:49  gefilte
 Fixed some POD

 Revision 2.34  2001/10/19 22:23:54  gefilte
 HTML_scrolling() - now sets -DEFAULT properly to what is in the database
 	(don't know if this ever worked right, but it didn't when I tried it. check out the tiny diff :-)

 Revision 2.33  2001/10/12 00:50:34  gefilte
 display_modify() - fixed output of 'li' tags (cosmetic)

 Added support for fields of type 'password' :
 	- added method HTML_password()
 	- added special case to display_row() which displays the password field twice (for verification purposes) unless displaymode is 'view'
 	- get_data() verifies that the two fields are alike, otherwise it sets and _error and blanks the field out (so it doesn't persist)
 	- sanity() doesn't set the 'required' error if an error is already set

 N.B. - get_data() is setting an error state, normally only done by sanity(). This may not be the right approach, but I couldn't think of a more efficient one than this, since the field being verified (essentially the second password field) will not be examined by sanity().

 Revision 2.32  2001/10/05 01:31:31  gefilte
 HTML_checkbox() - made slightly MORE useful than the last revision!

 Revision 2.31  2001/10/04 23:28:00  gefilte
 get_data()
 	- fixed procedures for parsing dates and checkboxes so that they
 	  do NOT add to the %$data hashref unless the data has in fact changed
 	  from what is in the $db_obj.

 HTML_checkbox() - made more usable :-)

 	"If only there were evil people somewhere insidiously committing evil deeds and it were necessary only to separate them from the rest of us and destroy them.  But the line dividing good and evil cuts through the heart of every human being.  And who is willing to destroy a piece of his own heart?"
 		- Aleksandr Isaevich Solzhenitsyn, novelist, Nobel laureate (1918-)

 Revision 2.30  2001/09/29 00:29:22  gefilte
 db_class(), db_class_name() - renamed to data_class(), data_class_name()
 	- this is consistent with Cobalt's naming scheme
 	- left symbolrefs to old names for backward compatibility
 	- changed ALL calls and documentary references to these methods to new names
 	- changed procedure to ascertain data_class to FIRST look at new class data member (below), then try using the standard BingoX class naming scheme

 added class data $data_class so that you can set an arbitrary class as your Carbon-based data class

 new() - uses data_class() methods to populate class data instead of figuring it out on its own

 fieldname(), fieldtype(), fieldhtmloptions(), fieldsrelclass(), rieldrelclasstype(), fieldoptions(), fieldsanity()
 	- now verify the existence of array elements before attempting to read them (who thought you could get away with not doing this????)

 HTML_time(), HTML_day(), HTML_month(), HTML_year(), HTML_date()
 	- now return undef if displaymode() is 'view' and referenced datetime field is empty

 fixed some documentation typos

 Revision 2.29  2001/09/27 18:10:22  gefilte
 save_data() - cleaned up $data prep
 	($data was verified twice! sanity() was being called twice! INSANITY!)

 Revision 2.28  2000/12/12 18:51:57  useevil
  - updated version for new release:  1.92

 Revision 2.27  2000/10/20 00:24:15  zhobson
 Minor changes to synopsis of new() in the docs

 Revision 2.26  2000/10/17 00:57:47  dweimer
 - corrected POD for main_index()
 - changed main_index()

 Revision 2.25  2000/09/20 21:03:27  dweimer
 Merged one last portion from the old tree.

 Revision 2.24  2000/09/20 21:00:22  dweimer
 Merged David's changes.
 His comment:
 handler() method now sets up Apache response settings instead of display_*() methods.

 Revision 2.23  2000/09/20 00:31:59  zhobson
 Fixed a scope warning in flow() (used "my $other_class" twice in the same scope)

 Revision 2.22  2000/09/19 23:40:59  dweimer
 Version update 1.91

 Revision 2.21  2000/09/13 20:58:27  adam
  - in get_data, changed how dates are handled if SHOW_24HOURS is off

 Revision 2.20  2000/09/12 16:03:35  david
 Made Data::Dumper optional -- only called when $debug is activated.  Changed all of its calls to Data::Dumper::Dumper().
 Caused handler to return result of flow(), flow ends up returning results of display_*(), display_*() methods now return Apache response constants.

 Revision 2.19  2000/09/08 22:06:24  colin
  - get_data - if the field is a date it makes sure there is at least
    the year in the query object.  Before it would break if you had a year
    in your %fields hash, but were not submitting that datefield in your
    add or modify form.  get_data would blindly try and build a date.

 Revision 2.18  2000/09/08 21:31:23  thai
  - cleaned up the code

 Revision 2.17  2000/09/08 05:19:38  thai
  - turned off debug

 Revision 2.16  2000/09/08 03:19:09  adam
  GENERAL
    Added parent/child relationship functionality, where each class can
    specify parent and child classes.  These are used to display buttons
    at the bottom of the display list screens to access your parents or
    children based on the selected item in the list.

  - updated POD
  - new
      - now accepts a CGI as an optional 4th param.
      - sets the selection from the $q->param('parent_pcpkey');
      - sets the parent_class object var from the $q->param('parent_pcpkey')
  - flow
      - checks to see if you are entering from a parent or child and sets
        $q->param('parent_pcpkey') with whats passed.
      - Gets the desired child or parent admin object and calls flow against it.
      - added debugging
  - changed all occurances of $q->startform to try and print $self->adminuri
    as the ACTION.  If there is no adminuri it uses uri as before.
  - display_list
      - displays information at the top of the page about what parent you
        came from (if there is a parent)
  - all forms now include hidden for parent_pcpkey
  - display_list_buttoms
  - displays buttons to view the display list page of any child or
           parent classes you might have.
  - pcpkey
    - renamed qkey to pcpkey
    - changed all occurances of qkey to pcpkey
  - cpkey
    - cpkey now just calls cpkey against the db_obj
  - cpkey_params
    - calls cpkey_params against your data_class
  - added children and parents class var accessor methods
  - HTML_popup
    - if your displaymode is add and you have a parent_pcpkey it attempts to
      select the parent in the pop-up menu.

 Revision 2.15  2000/09/07 22:49:03  thai
  - changed line 1200 to use BingoX::Time

 Revision 2.14  2000/09/07 20:00:02  thai
  - changed all occurances of DateTime::Date to BingoX::Time

 Revision 2.13  2000/08/31 21:54:18  greg
 Added COPYRIGHT information.
 Added file COPYING (LGPL).
 Cleaned up POD.
 Moved into BingoX namespace.
 References to Bingo::XPP now point to Apache::XPP.

 "To the first approximation, syntactic sugar is trivial to implement.
  To the second approximation, the first approximation is totally bogus."
 	-Larry Wall

 Revision 2.12  2000/08/10 21:10:55  thai
  - added qkey() to get the prefix and the cpkey
  - changed occurrances where primary keys were being iterated to use
    cpkey()
  - added prefix() method to return the correct prefix combination

 Revision 2.11  2000/08/09 21:25:03  thai
  - changed get_list_hash() to be more Carbon friendly

 Revision 2.10  2000/08/07 23:10:25  thai
  - added main_index() method to return the main index url
  - changed regex pattern for HTML_textarea()

 Revision 2.9  2000/08/07 17:59:32  thai
  - added remove and modify to the display_list_buttons() method
    and to flow

 Revision 2.8  2000/08/03 20:48:09  thai
  - addd qfd() method to handle qfds
  - fixed bug in HTML_date() that would create a new date object when
    displaymode was 'view'
  - the sub pkd() now calls data_class->pkd()

 Revision 2.7  2000/08/01 00:43:51  thai
  - changed db_obj->errstr to dbh->errstr on line 305
  - moved all the $qfieldname stuff to the qfieldname() method
  - removed the fieldtype eq 'custom' from line 1174 in get_data()

 Revision 2.6  2000/07/14 19:27:05  dougw
 save_data returns undef if it can't ref get_data's return value, should be a hashref.
 Small typo fix, hidden_fields returns a string as it should.

 Revision 2.5  2000/07/12 19:30:17  thai
  - fixed POD, cleaned up code

 Revision 2.4  2000/07/07 01:20:43  dougw
  - Added 1 instead of Turned On for the check box value. Who ever thought 
    of that?  Changed the comparisons for hashrefs. Beware !%$hashref is 
    different than ref $hashref ne 'HASH'

 Revision 2.3  2000/05/31 02:39:20  greg
 changed use of s/.*:// to substr(...) in AUTOLOAD for efficiency.

 Revision 2.2  2000/05/24 20:47:25  thai
  - added more sanity when dereferencing, @{ $code->() || [ ] }
  - added warning when creating new date objects fail

 Revision 2.1  2000/05/19 01:25:11  thai
  - cleaned up code
  - is now part of the Bingo user space

 Revision 2.0  2000/05/02 00:54:33  thai
  - committed as 2.0

 Revision 1.38  2000/03/21 02:00:23  dougw
 Fixed a bug introduced recently that broke adding new object when
 the identity key was in the fields list. This is so wierd. (zack)

 Revision 1.37  2000/03/17 21:09:00  dougw
 Allowed hidden values to be used in HTML_date for -TYPE=>'view'
 Fixed checkbox undef error

 Revision 1.36  2000/03/15 22:26:17  zack
 Added HTML_radio() and modified new() to allow passing a display mode.

 Revision 1.35  2000/03/15 19:25:43  colin
 -HTML_popup now sorts options alphabetically

 Revision 1.34  2000/03/14 21:45:08  dougw
 Fixed get_data->save_data problems (thanks dave).
 Removed spurious comments.

 Revision 1.33  2000/03/14 20:58:10  dougw
 Modified HTML_popup to allow a NULL selection. Use the fieldoption -null_label
 to specify what you want the option to be named. The option must not have the
 -not_null option set for obvious reasons.

 Revision 1.32  2000/03/10 01:57:54  colin
 made display_list()'s hash sorter even cooler (thanks doug)

 Revision 1.31  2000/03/10 01:18:02  colin
 -display_list() now sorts its entries alphabetically.

 Revision 1.30  2000/03/09 18:58:23  colin
 -fixed a bug in HTML_date() where $qfieldname was being used as a global.
 -fixed similar bugs in HTML_day(),HTML_month(),and HTML_year()
 -one can now pass a hashref to hidden_fields(). If one wanted to.

 Revision 1.29  2000/03/09 00:45:32  colin
 -(thai) fixed a bug in HTML_date() where it wasn't passing fieldnames to its helper methods.
 -HTML_date() now checks the -TYPE it's passed in fieldoptions

 Revision 1.28  2000/03/08 03:09:32  thai
  - parsed out HTML_date() to HTML_day(), HTML_month(), HTML_year(),
    and HTML_time()

 Revision 1.27  2000/02/25 20:24:17  colin
 corrected some minor ui bugs in display_list() and display_modify()

 Revision 1.26  2000/02/18 23:38:56  colin
 - altered sanity() so that it now accepts a passed \%data hashref instead
   of looking for things in the query object. this way the data is already
   formatted and we don't have to format data again (especially useful because
   we don't have to re-sort all the date fields, etc)

 Revision 1.25  2000/02/17 23:37:43  colin
 -get_data() now gives meaningful error messages when users enter invalid info in date fields

 Revision 1.24  2000/02/17 03:46:27  dougw
 Small modifications to take advantage of DateTime changes.
 Using $obj instead of $obj->time_local;

 Revision 1.23  2000/02/11 18:52:00  colin
 - (doug) HTML_* methods now use DateTime to manage date info.
 - (colin) Changed ui() so that a) it caches the hasref if called as an object method and b)
   allows you to override default settings (and add others) when calling the method, as
   opposed to calling SUPER::ui() and then re-setting the resulting hashref.

 Revision 1.22  2000/02/08 03:34:31  zack
 - documented the %fields class variable
 - added not_null to field options (index [4])
 - implemented flexible sanity checking
   - added sane_regex()
   - added sane_minlength() and sane_maxlength()
 - updated docs for fieldoptions() and fieldsanity()
 - HTML_textarea(): 'WRAP' defaults to 'VIRTUAL'

 Revision 1.21  2000/02/04 19:48:28  derek
  - Fixed two instances where $ui wasn't being accessed to include font tags

 Revision 1.20  2000/02/04 19:28:45  derek
  - Changed Cancel button on View page to Return to List and modified flow
    to reflect the change
  - Added tons of CGI HTML code to make the Chromium interface look better
  - Added ui method that has defaults for colors and fonts that are used
    in the newly designed skin-like interfaces
  - Added Greg's adminclass method to return the project specific admin
    super class
  - Fixed display bug in HTML_textarea where content fields weren't being
    broken up into paragraphs in View mode
  - Added flow to display_row method to check for content fields and break
    them into two rows for the key/value pair

 Revision 1.19  2000/02/03 03:42:35  zack
 Documentation fixes and updates

 Revision 1.18  2000/01/31 02:00:19  adam
  - dbh was using a GLOBAL flag to see if had already set the
   $r->register_cleanup.  That was bad since the global was living beyond
   each hit.  In the end, the DBH wasn't being cleared after every hit.
   So now it uses the Apache notes to store the flag.
 - display_row() - oops...  thats not the variable name!

 "The best laid plans..."

 Revision 1.17  2000/01/30 04:30:46  adam
  - using an HTMl fieldtype of 'row' makes display_row() not print table
   tags, it just prints the results of the method $_().

 Revision 1.16  2000/01/27 22:12:17  colin
 Added cgi() and marked CGI_obj() as deprecated (evil music here).
 Added some \%qoptions to HTML_file

 Revision 1.15  2000/01/27 01:17:14  colin
 - finished HTML_file(). Also, due to popular request, display_modify() now uses
   $q->start_multipart_form() instead of $q->startform().
 - Well, it actually wasn't a *popular* request, but when the email went out asking
   if anyone had problems with it there was no response. 
 Ever. And that's good enough for me!

 Revision 1.14  2000/01/25 20:55:48  colin
 added:
 postmodify_handler()
 postadd_handler()
 hidden_fields()
 display_list_buttons()
 display_modify_buttons()

 HooHah!

 Revision 1.13  2000/01/24 22:19:39  dougw
 Adam added adminuri

 Revision 1.12  2000/01/24 22:11:03  colin
 added some Center tags.

 Revision 1.11  2000/01/21 22:08:24  colin
 added display_start_html().

 Revision 1.9  2000/01/21 21:35:26  colin
 took out an extra warn(). my bad.

 Revision 1.6  2000/01/12 22:43:35  adam
  - removed Carbon::debug

 Revision 1.5  2000/01/11 02:30:19  zack
 HTML_textarea() now accepts a -WRAP option (default 'NONE')
 HTML_checkbox() works with "add" functionality

 Revision 1.4  1999/12/21 00:51:57  zack
 implemented selections. added selection()

 Revision 1.3  1999/12/05 04:05:38  greg
 new - fixed _db_class to be generic instead of hard coded to 'Mogwai'
 dbh - now handles the cleanup of cached dbh instead of Data

 Revision 1.2  1999/12/04 23:48:08  greg
 fixed POD errors

 Revision 1.1.1.1  1999/12/03 20:10:40  adam
 START


=head1 SEE ALSO

perl(1).

=head1 KNOWN BUGS

None

=head1 TODO

=over 4

=item * HTML_checkbox - needs work

=item * HTML_checkboxes (for multiple checkboxes)

=item * HTML_radio

=item * HTML_file - needs work

=item * HTML_popup - should support getting a hashref or a coderef as the LABELS or VALUES

=item * HTML_date - Only supports PST (hardcoded text)

=item * HTML_date - should it be some DateTime dependant? Is there a way to make it more universal?

=item * HTML_date - Needs to be able to show hours and minutes in a flexable way.

=item * HTML_date - Needs ability to display time in 24 hour time. (Fix in get_data as well).

=item * display_modify, view, list - need class data to control HTML options like title, table sizes etc...

=item * get_data - needs to be able to get times as well as dates in 24hr and 12hr formats.

=item * %fields - figure out how fields hash would pass other options to HTML methods

=item * %fields - figure out how to structure relationship info (many2many vs. many2one)

=item * %fields - figure out how to structure sanity information in hash 

=item * Should flow be broken up into different methods based on displaymode.

=item * Flow should be controllable with class data.  ie. to View before Modify.  Search before List.

=item * display_search() - needs to be added.

=item * Apache error page (nicer then Server Error)

=item * New class variable for adminpath (Where that thing can be administered).

=item * Add seperator method (for drawing HRs) between column edit things.

=item * HTML_scrolling (or any method that relates) - Can link to that methods view page for that object.

=item * HTML methods should use options hash from fields hash.

=item * HTML_popup - doesn't totally work because I don't know how one 2 many carbon relationships 
   work.  I am also not sure if I want to structure the class data the way I did.  It also 
   doesn't support composite primary keys (how would it?)

=item * need HTML_popupwindow method which lets users select related items from a js pop-up window. 
   (See Derek's Code or CyberStore Code)

=item * have AUTLOAD create dynamic methods

=item * dbh() - doesn't use Carboniums dbh.  Doesn't cache dbh object.  Should just 
   call Carboniums dbh. (or uses object's dbh.)

=back

=head1 COPYRIGHT

    Copyright (c) 2000, Cnation Inc. All Rights Reserved. This module is free
    software. It may be used, redistributed and/or modified under the terms
    of the GNU Lesser General Public License as published by the Free Software
    Foundation.

    You should have received a copy of the GNU Lesser General Public License
    along with this library; if not, write to the Free Software Foundation, Inc.,
    59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

 Adam Pisoni <adam@cnation.com>

=cut
