package CGI::Lazy::Widget::Composite;

use strict;

use JSON;
use CGI::Lazy::Globals;
use base qw(CGI::Lazy::Widget);

# for new composite types need the following:  ajaxSelect<type>  and dbwrite<type

#----------------------------------------------------------------------------------------
sub ajaxBlank {
	my $self = shift;

	my $widgets 	= [];
	my $output 	= [];

	foreach (@{$self->memberarray}) {
		push @$widgets, $_;
		push @$widgets, $_->ajaxBlank;
	}

	return $self->ajaxReturn($widgets, $output);
}

#----------------------------------------------------------------------------------------
sub ajaxSelect {
	my $self = shift;
	my %args = @_;

	my $type = $self->type;
	$type = ucfirst $type;
	my $method = 'ajaxSelect'.$type;

	return $self->$method(%args);
}

#----------------------------------------------------------------------------------------
sub ajaxSelectManual {
	my $self = shift;
	my %args = shift;

	return;
}

#----------------------------------------------------------------------------------------
sub ajaxSelectParentChild {
	my $self = shift;
	my %args = @_;

	my $incoming = $args{incoming} || from_json(($self->q->param('POSTDATA') || $self->q->param('keywords') || $self->q->param('XForms:Model')));

        my $parent = $self->members->{$self->relationship->{parent}->{id}};

	my %parentKeys;

	foreach my $child (keys %{$self->relationship->{children}}){
		my $handle;
		$parentKeys{$self->relationship->{children}->{$child}->{parentKey}} = {handle => \$handle};

	}

	my %parentParams = (
			incoming 	=> $incoming, 
			div		=> 1,
			vars 		=> {%parentKeys},
	);

	$parentParams{searchLike} = $self->relationship->{parent}->{searchLike} if $self->relationship->{parent}->{searchLike};

        my $parentOutput = $parent->select(%parentParams); 

#	$self->q->util->debug->edump(\%parentParams);

        if ($parent->multi) {
                return $self->ajaxReturn($parent, $parentOutput);
        } else {

		my $widgets 	= [$parent];
		my $output 	= [$parentOutput];

		foreach my $child (keys %{$self->relationship->{children}}) {
			my %childParams = ($self->relationship->{children}->{$child}->{childKey} => ${$parentKeys{$self->relationship->{children}->{$child}->{parentKey}}->{handle}});

			push @$widgets, $self->members->{$child};
			
			if ($parent->empty) {
				push @$output, $self->members->{$child}->ajaxBlank();
			} else {
				push @$output, $self->members->{$child}->select(incoming => {%childParams}, div => 1);
			}
		}

		return $self->ajaxReturn($widgets, $output);
        }
}

#----------------------------------------------------------------------------------------
sub ajaxSelectSelectableDataset {
	my $self = shift;
	my %args = @_;

	my $incoming = $args{incoming} || from_json(($self->q->param('POSTDATA') || $self->q->param('keywords') || $self->q->param('XForms:Model')));
        my $parent = $self->members->{$self->relationship->{parent}->{id}};

	my $widgets 	= [$parent];
	my $output 	= [$parent->rawContents(incoming => $incoming, div => 1)];

	foreach my $child (keys %{$self->relationship->{children}}) {
		my $params = {};
		
		foreach (@{$self->relationship->{children}->{$child}}) {	
			my $value = $incoming->{$_->{parentParam}};
			my $field = $_->{childField};

			$params->{$field} = $value;
		}

        	push @$widgets, $self->members->{$child};
		push @$output, $self->members->{$child}->select(incoming => $params, div => 1);
	}

	return $self->ajaxReturn($widgets, $output);
}

#----------------------------------------------------------------------------------------
sub contents {
	my $self = shift;
	my %args = @_;

        my $standalone 		= $self->vars->{standalone};
	my $formOpenTag 	= '';
	my $formCloseTag 	= '';
        my $widgetID		= $self->vars->{id};
	my $members		= $self->memberarray;
	my $output;
	
	if ($standalone) {
		$formOpenTag = $self->vars->{formOpenTag} || $self->q->start_form({-method => 'post', -action => $self->q->url});
		$formCloseTag = $self->q->end_form;
	}
	my $divopen = $args{nodiv} ? '' : "<div id='$widgetID'>";
	my $divclose = $args{nodiv} ? '' : "</div>";

	foreach my $member (@$members) {
		$output .= $member->display(%args);
	}

	return $divopen.
		$formOpenTag.
		$output.
		$formCloseTag.
		$divclose;
}

#----------------------------------------------------------------------------------------
sub dbwrite {
	my $self = shift;
	my %args = @_;

	my $type = $self->type;
	$type = ucfirst $type;
	my $method = 'dbwrite'.$type;

	return $self->$method(%args);;

}

#----------------------------------------------------------------------------------------
sub dbwriteManual {
	my $self = shift;
	my %args = @_;
	
	return;
}

#----------------------------------------------------------------------------------------
sub dbwriteParentChild {
       	my $self = shift;
	my %args = @_;

        my $parent = $self->members->{$self->relationship->{parent}->{id}};

	my %parentKeys;
	my $parentHandle;

	foreach my $child (keys %{$self->relationship->{children}}){
		$parentKeys{$self->relationship->{children}->{$child}->{parentKey}} = {handle => $parent->recordset->primarykeyhandle};
	}

	$parent->dbwrite(insert => {%parentKeys}, update => {%parentKeys});

#	$self->q->util->debug->edump(\%parentKeys);

	foreach my $child (keys %{$self->relationship->{children}}) {
		my %childParams = ($self->relationship->{children}->{$child}->{childKey} => {
					value => ${$parentKeys{$self->relationship->{children}->{$child}->{parentKey}}->{handle}},
				},
		);

#		$self->q->util->debug->edump($child, ${$parentKeys{$self->relationship->{children}->{$child}->{parentKey}}->{handle}});

		$self->members->{$child}->dbwrite(
					insert	=> {%childParams},
					update 	=> {%childParams},
				);
	}

	return;
}

#----------------------------------------------------------------------------------------
sub dbwriteSelectableDataset {
	my $self = shift;
	my %args = @_;
	
        my $parent = $self->members->{$self->relationship->{parent}->{id}};

	my $incoming = {};

	foreach my $child (keys %{$self->relationship->{children}}) {
		
		foreach (@{$self->relationship->{children}->{$child}}) {	
			my $param = $_->{parentParam};
			my $value = $self->q->param($param);

			$incoming->{$param} = $value;
		}
	}

	my $widgets 	= [$parent];
	my $output 	= [$parent->rawContents(incoming => $incoming, div => 1)];

	foreach my $child (keys %{$self->relationship->{children}}) {
		my %childParams = ();

		foreach (@{$self->relationship->{children}->{$child}}) {	
			my $value = $incoming->{$_->{parentParam}};
			my $field = $_->{childField};

			$childParams{$field} = {value => $value};
		}

		$self->members->{$child}->dbwrite(
					insert	=> {%childParams},
					update 	=> {%childParams},
				);
	}

	return;
}

#----------------------------------------------------------------------------------------
sub display {
	my $self = shift;
	my %args = @_;

	return $self->contents(%args);
}

#----------------------------------------------------------------------------------------
sub memberarray {
	my $self = shift;

	return $self->vars->{members};
}

#----------------------------------------------------------------------------------------
sub members {
	my $self = shift;

	return $self->{_members};
}

#----------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;
	my $vars = shift;

        my $widgetID = $vars->{id};
	my $members = {};

	my $parsedMembers = [];

	foreach my $member (@{$vars->{members}}) {
		if (ref $member =~ /^CGI::Lazy::Widget/) {
			push @$parsedMembers, $member;
		} else {
			my $class = $member->{class};

			my $widget = $q->widget->$class($member);
			push @$parsedMembers, $widget;
		}
	}

	$vars->{members} = $parsedMembers;

	foreach (@{$vars->{members}}) {
		$members->{$_->widgetID} = $_;
	}

	return bless {
		_q 		=> $q, 
		_vars 		=> $vars, 
		_members 	=> $members, 
		_widgetID 	=> $widgetID,
		_type		=> $vars->{type} || 'manual',
		_relationship	=> $vars->{relationship},
	}, $class;
}

#----------------------------------------------------------------------------------------
sub recordset {
	my $self = shift;

        return $self->members->{$self->relationship->{parent}->{id}}->recordset;
}

#----------------------------------------------------------------------------------------
sub relationship {
	my $self = shift;

	return $self->{_relationship};

}

#----------------------------------------------------------------------------------------
sub type {
	my $self = shift;

	return $self->{_type};

}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::Widget::Composite

=head1 SYNOPSIS

	use CGI::Lazy;

	our $q = CGI::Lazy->new('/path/to/config/file');
	our $composite = $q->widget->composite({
			id		=> 'stuff',

			type		=> 'parentChild',

			relationship	=> {

                             parent          => {
                                                id            => 'parentWidget',

                                                searchLike      => '%?%',

                                },

                                children        => {

                                                activity        => {

                                                        parentKey       => 'advertiser.ID',

                                                        childKey        => 'advertiserID',

                                                },

                                },


			},

			members 	=> [ ... ],
		);

=head1 DESCRIPTION

Composite is a container for other widgets.  It allows you to perform actions on multiple widgets at once.  Depending on the relationship between the widgets, and how fancy you get, you may need to play with each subwidget by hand.  Otherwise, you can specify a type, and use a prebuilt type.

parentChild is a widget that has one widget as the parent, and one or more set up as its children.  Searching on the parent will return child records that match the parent's results.  Likewise dbwrite will call appropriate methods on all the children based on the widget's construction.

parentChild is pretty experimental.  The configuration given in the example works fine, but I'm not yet convinced the structure is abstracted enough to work for any given group of widgets.  Time will tell, and bugreports/comments.

=head1 METHODS

=head2 ajaxBlank ()

returns blank versions of all member widgets.

=head2 ajaxSelect ()

Runs select query on parameters incoming via ajax call for all member widgets based on widget type.  Returns results formatted for return to browser via ajax handler.

=head2 dbwrite ()

Writes to database for all member widgets based on widget type.

=head2 memberarray ()

Returns array of composite widget's members 

=head2 members ()

Returns hashref of composite widget's members

=head2 contents (args)

Generates widget contents based on args.

=head3 args

Hash of arguments.  Common args are mode => 'blank', for displaying a blank data entry form, and nodiv => 1, for sending the contents back without the surrounding div tags (javascript replaces the contents of the div, and we don't want to add another div of the same name inside the div).


=head2 display (args)

Displays the widget.  Calls $self->contents, and adds preload lookups and instance specific javascript that will not be updated on subsequent ajax calls. Print the return value of this method to STDOUT in your cgi or mod_perl handler. 

=head3 args

Hash of arguments


=head2 new (q, vars)

Constructor.

=head3 q

CGI::Lazy object.

=head3 vars

Hashref of object configs.

id			=> widget id 			(mandatory)

members 		=> arrayref of member widgets	(mandatory)

=head1 EXAMPLES

#!/usr/bin/perl

	use strict;
	use warnings;
	use CGI::Lazy;

	our $var = undef;
	our $ref = \$var; #ref to tie parts together.

	our $q = CGI::Lazy->new('/path/to/config/file');
	our $composite = $q->widget->composite({
			id		=> 'stuff',

			type		=> 'parentChild',

			relationship	=> {

                             parent          => {
                                                id            => 'parentWidget',

                                                searchLike      => '%?%',

                                },

                                children        => {

                                                activity        => {

                                                        parentKey       => 'advertiser.ID',

                                                        childKey        => 'advertiserID',

                                                },

                                },


			},

			members 	=> [

				{
					class		=> 'dataset',
					
					id		=> 'advertiser',

					type		=> 'single',

					multiType	=> 'list',

					containerId	=> 'stuff',

					template	=> 'cscAdvertiser.tmpl',

					multipleTemplate => 'cscAdvertiserMulti.tmpl',

					extravars	=> {

							advertiserID	=> {

									value => $id,

								},
					},

					recordset	=> {

								table		=> 'advertiser', 

								fieldlist	=> [

											{name => 'advertiser.ID',	label	=> 'Adv#', handle => $id},

											{name => 'advertiser.companyname',		label	=> 'Company:', 		multi	=> 1},

											{name => 'advertiser.repid',		label	=> 'Account Rep:',	multi	=> 1},

											{name => 'advertiser.address', 		label	=> 'Address:',	 	multi	=> 1},

											{name => 'advertiser.city', 		label	=> 'City:', 		multi	=> 1},

											{name => 'advertiser.state', 		label	=> 'State:'},

											{name => 'advertiser.postalcode', 		label	=> 'Zip:'},

											{name => 'advertiser.country', 		label	=> 'Country'},

											{name => 'advertiser.contactphone',	label	=> 'Phone:'},

											{name => 'advertiser.contactfax', 		label	=> 'Fax:'},

											{name => 'advertiser.contactnamefirst',	label	=> 'Contact:' },

											{name => 'advertiser.contactnamelast',	label	=> '', 			noLabel => 1},

											{name => 'advertiser.contactemail',	label 	=> 'Email:'},

											{name => 'advertiser.website',		label	=> 'Website:'},

											{name => 'advertiser.notes',	label 	=> 'Notes:'},

											{name => 'salesrep.namefirst',	noLabel => 1},

											{name => 'salesrep.namelast', 	noLabel	=> 1}

											], 

								basewhere 	=> '', 

								orderby		=> 'advertiser.ID', 

								primarykey	=> 'advertiser.ID',

								joins		=> [

											{type => 'inner', table	=> 'salesrep', field1 => 'salesrep.ID', field2 => 'advertiser.repid',},

								],

								insertadditional => {

									advertiserID	=> {

											sql => 'select LAST_INSERT_ID()',

											handle => $id,

									},



								},

							},

				},

				{
					class		=> 'dataset',

					id		=> 'activity',

					type		=> 'multi',

					template	=> "cscActivity.tmpl",

					recordset	=> {

								table		=> 'activity', 

								fieldlist	=> [

											{name => 'advertiserID', 	hidden => 1},

											{name => 'activity.ID',		label => 'Item#'},

											{name => 'sortdate', 		label => 'RunDate'},

											{name => 'issue', 		label => 'Location'},

											{name => 'page', 		label => 'Page'},

											{name => 'description', 	label => 'Description', nolabel => 1},

											{name => 'type', 		label => 'Type', nolabel => 1},

											{name => 'activity.notes', 	label => 'Notes', nolabel => 1},



											], 

								basewhere 	=> '', 

								orderby		=> 'activity.ID', 

								primarykey	=> 'activity.ID',

					},

				},
				
				],
		);


	my %nav = (

		dbwrite => \&dbwrite,

		  );

	if ($q->param('nav')) {

		$nav{$q->param('nav')}->();

	} elsif ($q->param('POSTDATA')) {

		ajaxHandler();

	} else {

		display('blank');

	}

	#----------------------------------------------------------------------------------------
	sub ajaxHandler {
		my $incoming = from_json($q->param('POSTDATA') || $q->param('keywords'));

		if ($incoming->{delete}) {

			doFullDelete($incoming);

			return;

		}

		print $q->header, $composite->select($incoming);

		return;
	}

	#----------------------------------------------------------------------------------------
	sub dbwrite {

		$composite->dbwrite();

		display('blank');
	}

	#----------------------------------------------------------------------------------------

	sub display {

		my $mode = shift;

		print $q->header,

			$q->start_html({-style => {src => '/css/style.css'}}),

			$q->javascript->modules($composite); #javascript functions needed by widget
		
		#header section
		print $q->template('sometemplate.tmpl')->process({ mainTitle => 'Main Title', secondaryTitle => 'Secondary Title', versionTitle => 'version 0.1', messageTitle => 'blah blah blah', });

		#composite widget section
		print $q->start_form({ -id => 'mainForm'}),
		      $q->hidden({-name => 'nav', -value => 'dbwrite'});

		print $composite->display(mode => $mode);
		print $composite->q->jsload('somejavascript.js');

		print $q->end_form;

		print $q->template('someothertemplate.tmpl')->process({version => $q->lazyversion});

		return;
	}

=cut

