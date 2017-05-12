package CGI::Lazy::Widget::Controller;

use strict;

use JSON;
use JavaScript::Minifier qw(minify);
use CGI::Lazy::Globals;
use base qw(CGI::Lazy::Widget);

#----------------------------------------------------------------------------------------
sub buildCheckbox {
	my $self = shift;
	my $fieldname = shift;
	my $webcontrol = shift;
	my $value = shift;

	if ($webcontrol->{value}) {
		if ($value eq $webcontrol->{value}) {
			return ($webcontrol->{value}, ' checked ');
		} else {
			return ($webcontrol->{value});
		}

	} elsif ($webcontrol->{sql}) {
		my ($query, @binds) = @{$webcontrol->{sql}};
		my $lookupvalue = $self->q->db->get($query, @binds);

		if ($value eq $lookupvalue) {
			return ($lookupvalue, ' checked ');
		} else {
			return ($lookupvalue);
		}
	}
}

#----------------------------------------------------------------------------------------
sub buildSelect {
	my $self = shift;
	my $fieldname = shift;
	my $webcontrol = shift;
	my $value = shift;

	my $list = [];

	my $vals = {};
	tie %$vals, 'Tie::IxHash';

	if ($webcontrol->{values} ) {
		if (ref $webcontrol->{values} eq 'HASH') {
			$vals->{''} = '' unless $webcontrol->{notNull};
			$vals = $webcontrol->{values};
		} elsif (ref $webcontrol->{values} eq 'ARRAY') {
			$vals->{''} = '' unless $webcontrol->{notNull};
			$vals->{$_} = $_ for @{$webcontrol->{values}};
		} else {
			return;
		}


	} elsif ($webcontrol->{sql}) {
		my ($query, @binds) = @{$webcontrol->{sql}};
		$vals->{''} = '' unless $webcontrol->{notNull};
		$vals->{$_->[0]} = $_->[1] for @{$self->q->db->getarray($query, @binds)};

	}

	foreach (keys %$vals) {
		if ($vals->{$_} eq $value) {
			push @$list, {'ITEM.LABEL' => $_, 'ITEM.VALUE' => $vals->{$_}, 'ITEM.SELECTED' => ' selected '};

		} else {
			push @$list, {'ITEM.LABEL' => $_, 'ITEM.VALUE' => $vals->{$_}};
		}
	}

	return $list;
}

#----------------------------------------------------------------------------------------
sub buildRadio {
	my $self = shift;
	my $fieldname = shift;
	my $webcontrol = shift;
	my $webname = shift;
	my $webID  = shift;
	my $value = shift;

	my $list = [];
	my $vals = {};
	tie %$vals, 'Tie::IxHash';

	if ($webcontrol->{values} ) {

		if (ref $webcontrol->{values} eq 'HASH') {
			$vals = $webcontrol->{values};
		} elsif (ref $webcontrol->{values} eq 'ARRAY') {
			$vals->{$_} = $_ for @{$webcontrol->{values}};
		} else {
			return;
		}


	} elsif ($webcontrol->{sql} ) {
		my ($query, @binds) = @{$webcontrol->{sql}};

		$vals->{$_->[0]} = $_->[1] for @{$self->q->db->getarray($query, @binds)};

	}

	foreach (sort keys %$vals) {
		if ($vals->{$_} eq $value) {
			push @$list, {
				"ID.".$fieldname 		=> $webID."-$_", 
				'NAME.'.$fieldname 		=> $webname, 
				'VALUELABEL.'.$fieldname 	=> $_, 
				'VALUE.'.$fieldname 		=> $vals->{$_}, 
				'CHECKED.'.$fieldname 		=> ' checked ',
			};

		} else {
			push @$list, {
				"ID.".$fieldname 		=> $webID."-$_", 
				'NAME.'.$fieldname 		=> $webname, 
				'VALUELABEL.'.$fieldname 	=> $_,
				'VALUE.'.$fieldname 		=> $vals->{$_},
			};

		}
	}

	return $list;
}

#----------------------------------------------------------------------------------------
sub contents {
	my $self = shift;
	my %args = @_;

	my $incoming = $args{incoming};
	my $template = $self->vars->{template};
	my $widgetID = $self->widgetID;
	my $containerID = $self->vars->{containerId};

	my $divopen = $args{nodiv} ? '' : "<div id='$widgetID'>";
	my $divclose = $args{nodiv} ? '' : "</div>";

	my $tmplvars;

	foreach my $control (@{$self->controls}) {
		my $fieldname = $control->{name};
		my $value = $incoming->{$fieldname};

		my $webname 	= "NAME.$fieldname";
		my $webID	= "ID.$fieldname";

		my $type = $control->{type};
		$tmplvars->{"LABEL.".$fieldname} = $control->{label};

		$tmplvars->{$webname} = $fieldname;
		$tmplvars->{$webID} = $fieldname;

		if ($type eq 'select') { #build variables for web controls
			$tmplvars->{"LOOP.".$fieldname} = $self->buildSelect($fieldname, $control, $value);
		} elsif ($type eq 'checkbox') {
			($tmplvars->{"VALUE.".$fieldname}, $tmplvars->{"CHECKED.".$fieldname}) = $self->buildCheckbox($fieldname, $control, $value);
		} elsif ($type eq 'radio') {
			$tmplvars->{"LOOP.".$fieldname} = $self->buildRadio($fieldname, $control, $webname, $webID, $value );
		} else {
			$tmplvars->{"VALUE.".$fieldname} = $value;
		}

	}

	my $jscontrollername = $widgetID."Controller";

	my $selectObject = to_json([map {{name => $_->{name}, required => $_->{required}}} @{$self->controls}]);

	my $javascript = <<END;
		var $jscontrollername = new controllerController('$widgetID', '$containerID', $selectObject);
END

	if ($javascript) {
		$javascript = minify(input => $javascript) unless $self->q->config->noMinify;
	}

	my $js = $self->q->jswrap($javascript);

	return $divopen.
		$js.
		$self->q->template($template)->process($tmplvars).
		$divclose;
}

#----------------------------------------------------------------------------------------
sub controls {
	my $self = shift;

	return $self->{_controls};
}

#----------------------------------------------------------------------------------------
sub display {
	my $self = shift;
	my %args = @_;

	return $self->contents(%args);
}

#----------------------------------------------------------------------------------------
sub new {
	my $class 	= shift;
	my $q 		= shift;
	my $vars 	= shift;

        my $widgetID = $vars->{id};

	my $self = {
		_q		=> $q,
		_vars		=> $vars,
		_widgetID 	=> $widgetID,
		_controls	=> $vars->{controls},
	};

	bless $self, $class;

	return $self;
}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2009 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::Widget::Control

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

			members 	=> [
                                {
                                        class           => 'controller',
                                        id              => 'parent',
                                        containerId     => 'stuff',
                                        template        => "parentController.tmpl",
                                        controls        => [
                                                {
                                                        name            => 'id',
                                                        label           => 'invoice ID',
                                                        type            => 'select',
                                                        sql             => ['select id, id from invoice'],
                                                        required        => 1,
                                                },


                                        ],

                                },

			],
		);


=cut

