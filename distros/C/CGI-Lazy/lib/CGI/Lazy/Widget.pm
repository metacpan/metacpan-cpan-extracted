package CGI::Lazy::Widget;

use strict;

use JSON;
use Tie::IxHash;
use CGI::Lazy::Globals;
use CGI::Lazy::Widget::Dataset;
use CGI::Lazy::Widget::DomLoader;
use CGI::Lazy::Widget::Composite;
use CGI::Lazy::Widget::Controller;

#----------------------------------------------------------------------------------------
sub ajaxBlank {
	my $self = shift;
	my %args = @_;

	$args{mode} = 'blank';

	return $self->rawContents(%args);
}

#----------------------------------------------------------------------------------------
sub ajaxReturn {
	my $self = shift;
	my $widgets = shift;
	my $data = shift;

	my @widgetlist = ref $widgets  eq 'ARRAY' ? @$widgets : ($widgets);
	my @datalist = ref $data eq 'ARRAY' ? @$data : ($data);

	my $outgoingdata;
       	$outgoingdata .= $_ for @datalist;

	my $validator = {};

	$validator->{$_->widgetID} = $_->validator for @widgetlist;

	my $json = to_json($validator);

        return '{"validator" : '.$json.', "html" : "'.$outgoingdata .'"}';

}

#----------------------------------------------------------------------------------------
sub ajaxSelect {
	my $self = shift;
	my %args = @_;

        my $output = $self->select(%args); 

	return $self->ajaxReturn($self, $output);
}

#----------------------------------------------------------------------------------------
sub composite {
	my $self = shift;
	my $vars = shift;
	
	return CGI::Lazy::Widget::Composite->new($self->q, $vars);
}

#----------------------------------------------------------------------------------------
sub config {
	my $self = shift;

	return $self->q->config;
}

#----------------------------------------------------------------------------------------
sub controller {
	my $self = shift;
	my $vars = shift;

	return CGI::Lazy::Widget::Controller->new($self->q, $vars);
}

#----------------------------------------------------------------------------------------
sub dataset {
	my $self = shift;
	my $vars = shift;

	return CGI::Lazy::Widget::Dataset->new($self->q, $vars);
}

#----------------------------------------------------------------------------------------
sub db {
	my $self = shift;

	return $self->q->db;
}

#----------------------------------------------------------------------------------------
sub dbwrite {
	my $self = shift;
	my %args = @_;

	if (ref $self eq 'CGI::Lazy::Widget::Composite') {
		foreach (@{$self->memberarray}) {
			$_->dbwrite;
		}
		return;
	}

	my %deleteargs = %{$args{delete}} if $args{delete};
	delete $args{delete};
	my %updateargs = %{$args{update}} if $args{update};
	delete $args{update};
	my %insertargs = %{$args{insert}} if $args{insert};
	delete $args{insert};

	$deleteargs{$_} = $args{$_} for keys %args;
	$updateargs{$_} = $args{$_} for keys %args;
	$insertargs{$_} = $args{$_} for keys %args;

	$self->rundelete(%deleteargs);
	$self->update(%updateargs);
	$self->insert(%insertargs);


	return;
}

#----------------------------------------------------------------------------------------
sub displaySelect {
	my $self = shift;
	my %args = @_;

	my $vars = $args{vars};

	my @fields;
	my $binds = [];

#	$self->q->util->debug->edump($incoming);

	foreach my $field (grep {!/vars/} keys %args) {
		unless ($field =~ /['"&;]/) {
			if ($args{$field}) {
				push @fields, $field." = ? ";
				if (ref $args{$field}) {
					push @$binds, ${$args{$field}};
				} else {
					push @$binds, $args{$field};
				}
			}
		}
	}
	
	my $bindstring = join ' and ', @fields;	
	
	$self->recordset->where($bindstring);

#	$self->q->util->debug->edump("bindstring: $bindstring binds: @$binds");

	return $self->display(mode => 'select', binds => $binds, vars => $vars );
}

#----------------------------------------------------------------------------------------
sub deletes {
	my $self = shift;

	if (ref $self eq 'CGI::Lazy::Widget::Composite') {
		foreach (@{$self->memberarray}) {
			$_->deletes;
		}
		return;
	}

        my $data;
	my $widgetID = $self->vars->{id};

        foreach my $key (grep {/^$widgetID-:DELETE:/} $self->q->param) {
                if ($key =~ /^($widgetID-:DELETE:)(.+)-:-(.+)::(\d+)$/) {
			my ($pre, $fieldname, $ID, $row) = ($1, $2, $3, $4);
			$data->{$ID}->{$fieldname} = $self->q->param($key) if $self->q->param($key);
		} elsif ($key =~ /^($widgetID-:DELETE:)(.+)-:-(.+)$/) {
			my ($pre, $fieldname, $ID) = ($1, $2, $3);
			$data->{$ID}->{$fieldname} = $self->q->param($key) if $self->q->param($key);
		}
        }
        return $data;
}

#----------------------------------------------------------------------------------------
sub deleteIds {
	my $self = shift;

	my @deletes = sort keys %{$self->deletes};

	if (wantarray) {
		return @deletes;
	} else {
		return \@deletes;
	}
}

#----------------------------------------------------------------------------------------
sub displayblank {
	my $self = shift;

	return $self->display(mode => 'blank'); #run display function with blank argument
}

#----------------------------------------------------------------------------------------
sub domload {
	my $self = shift;

	my $objectJs;

        foreach my $object (keys %{$self->vars->{objects};}) {
		$objectJs .= "var $object = JSON.parse('".to_json($self->vars->{objects}->{$object})."');\n";
        }

        $objectJs = $self->q->jswrap($objectJs) if $objectJs;

	return $objectJs;
}

#----------------------------------------------------------------------------------------
sub domloader {
	my $self = shift;
	my $vars = shift;

	return CGI::Lazy::Widget::DomLoader->new($self->q, $vars);
}

#----------------------------------------------------------------------------------------
sub insert {
	my $self = shift;
	my %vars = @_;

	if (ref $self eq 'CGI::Lazy::Widget::Composite') {
		foreach (@{$self->memberarray}) {
			$_->insert(%vars);
		}
		return;
	}

	$self->recordset->insert($self->inserts, \%vars);
	return;
}

#----------------------------------------------------------------------------------------
sub inserts {
	my $self = shift;

	if (ref $self eq 'CGI::Lazy::Widget::Composite') {
		foreach (@{$self->memberarray}) {
			$_->inserts;
		}
		return;
	}

        my $data = {};
	tie %{$data}, 'Tie::IxHash';

	my $widgetID = $self->vars->{id};

        foreach my $key (sort _byWidgetRow grep {/^$widgetID-:INSERT:/} $self->q->param) {
		if ($key =~ /^($widgetID-:INSERT:)(.+)--$/) {
#			$self->q->util->debug->edump($key);
			my ($pre, $field) = ($1, $2);
			$data->{1}->{$field} = $self->q->param($key) if $self->q->param($key);
		} elsif ($key =~ /^($widgetID-:INSERT:)(.+)--(\d+)$/) {
			my ($pre, $field, $row) = ($1, $2, $3);
			$data->{$row}->{$field} = $self->q->param($key) if $self->q->param($key);
#			$self->q->util->debug->edump($field, $self->q->param($key)) if $self->q->param($key);
		} 
        }

#	$self->q->util->debug->edump($data);
        return $data;
}

#----------------------------------------------------------------------------------------
sub _byWidgetRow {

	my $rowa;
	my $rowb;

	if ($a =~ /^(.+-:INSERT:)(.+)--(\d+)$/) {
		$rowa = $3;
	}

	if ($b =~ /^(.+-:INSERT:)(.+)--(\d+)$/) {
		$rowb = $3;
	}
	
	return $rowa <=> $rowb;
}

#----------------------------------------------------------------------------------------
sub insertIds {
	my $self = shift;

	my @inserts = sort keys %{$self->inserts};

	if (wantarray) {
		return @inserts;
	} else {
		return \@inserts;
	}
}

#----------------------------------------------------------------------------------------
sub jsonescape {
	my $self = shift;
	my $target = shift;

	if (ref $target eq 'HASH') {
		foreach (keys %$target) {
			foreach (values %{$target->{$_}}) {
				s/'//g;
			}
		}

	} elsif (ref $target eq 'ARRAY') { #finish this
		foreach (@$target) {
			
		}

	} else {

	}
}

#----------------------------------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

#----------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	return bless {_q => $q }, $class;
}

#----------------------------------------------------------------------------------------
sub postdata {
        my $self = shift;

	if (ref $self eq 'CGI::Lazy::Widget::Composite') {
		foreach (@{$self->memberarray}) {
			$_->postdata;
		}
		return;
	}

        my $data;
	my $widgetID = $self->vars->{id};

        foreach my $key (grep {/^$widgetID/} $self->q->param) {
                $key =~ /^($widgetID-)(.+)(\d*)$/;
                my ($pre, $field, $row) = ($1, $2, $3);
                $data->{$row}->{$field} = $self->q->param($key) if $self->q->param($key);
        }

        return $data;
}

#----------------------------------------------------------------------------------------
sub preloadLookup {
	my $self = shift;

	my $preloadLookupJs;
        my $lookups = $self->vars->{lookups};
        my %lookuptype = (
                        hash            => 'gethash',
                        hashlist        => 'gethashlist',
                        array           => 'getarray',
                        );

        foreach my $queryname (keys %$lookups) {
                if ($lookups->{$queryname}->{preload}) {
                        my $query = $lookups->{$queryname}->{sql};
                        my $binds = $lookups->{$queryname}->{binds};
                        my $output = $lookups->{$queryname}->{output};

                        my $orderby = $lookups->{$queryname}->{orderby};

			if ($orderby) {
				$query .= " order by ".  join ',', @$orderby;
			}

                        my $results;

                        if ($lookuptype{$output} eq 'gethash') {
                                $results = $self->db->gethash($query, $lookups->{$queryname}->{primarykey}, @$binds);
                        } else {
                                my $type = $lookuptype{$output};
                                $results = $self->db->$type($query, @$binds);
                        }

                        $results = [] unless ref $results;
                        $self->jsonescape($results);

                        $preloadLookupJs .= "var $queryname = JSON.parse('".to_json($results)."');\n";
                }
        }
        $preloadLookupJs = $self->q->jswrap($preloadLookupJs) if $preloadLookupJs;

	return $preloadLookupJs;
}

#----------------------------------------------------------------------------------------
sub rawContents {
	my $self = shift;
	my %args = @_;

	my $output = $self->contents(%args);
	$output =~ s/\\/\\\\/g;
	$output =~ s/"/\\"/g;
	$output =~ s/[\t\n]//g;

	return $output;
}

#----------------------------------------------------------------------------------------
sub recordset {
	my $self = shift;

	return $self->{_recordset};
}

#----------------------------------------------------------------------------------------
sub rundelete {
	my $self = shift;
	my %vars = @_;

	if (ref $self eq 'CGI::Lazy::Widget::Composite') {
		foreach (@{$self->memberarray}) {
			$_->rundelete(%vars);
		}
		return;
	}

	$self->recordset->delete($self->deletes);

	return;
}

#----------------------------------------------------------------------------------------
sub select {
	my $self = shift;
	my %args = @_;

        $args{searchLike} = $self->vars->{searchLike} if $self->vars->{searchLike};
        $args{searchLikeVars} = $self->vars->{searchLikeVars} if $self->vars->{searchLikeVars};

	my $incoming = $args{incoming} || from_json(($self->q->param('POSTDATA') || $self->q->param('keywords') || $self->q->param('XForms:Model')));
	my $div = $args{div};
	my $vars = $args{vars};
	my $like = $args{searchLike};
	my $likevars = $args{searchLikeVars};


	my $widgetID = $self->widgetID;
	my @fields;
	my $bind;
	my $binds = [];

#	$self->q->util->debug->edump($incoming);

	if ($incoming->{noSearchLike}) {
		$like = undef;
		delete $incoming->{noSearchLike};
	}

	delete $incoming->{CGILazyID}; #key/value pair only used at cgi level, will cause problems here (set automatically by Dataset with name of widget)

	if ($like) {
		$bind = " like ? ";

	} else {
		$bind = " = ? ";
	}

	my %likemap = (
			'%?%'	=> sub {return '%'.$_[0].'%';},
			'?%'	=> sub {return $_[0].'%';},
			'%?'	=> sub {return '%'.$_[0];},

	);

	foreach my $field (keys %$incoming) {
		unless ($field =~ /['"&;]\(\)/) {
			if ($incoming->{$field}) {
				(my $fieldname = $field) =~ s/^$widgetID-//;
				push @fields, $fieldname.$bind;
				if (ref $incoming->{$field}) {
					if ($likevars) {
						my $value = $likemap{$likevars}->(${$incoming->{$field}});
						push @$binds, $value;
					} else {
						push @$binds, ${$incoming->{$field}};
					}
				} else {
					if ($like) {
						my $value = $likemap{$like}->($incoming->{$field});
						push @$binds, $value;
					} else {
						push @$binds, $incoming->{$field};
					}
				}
			}
		}
	}
	
	my $bindstring = join ' and ', @fields;	
	
	$self->recordset->where($bindstring);

#	$self->q->util->debug->edump("bindstring: $bindstring binds: @$binds");

	my %parameters = (
			mode => 'select', 
			binds => $binds, 
			vars => $vars, 
			);

	$parameters{nodiv} = 1 unless $div; #pass the div tag if we prefer

	return $self->rawContents(%parameters);
}

#----------------------------------------------------------------------------------------
sub update {
	my $self = shift;
	my %vars = @_;

	if (ref $self eq 'CGI::Lazy::Widget::Composite') {
		foreach (@{$self->memberarray}) {
			$_->update(%vars);
		}
		return;
	}

#	$self->q->util->debug->edump('fromupdate', $self->updates, \%vars);
	$self->recordset->update($self->updates, \%vars);

	return;
}

#----------------------------------------------------------------------------------------
sub updates {
	my $self = shift;

	if (ref $self eq 'CGI::Lazy::Widget::Composite') {
		foreach (@{$self->memberarray}) {
			$_->updates;
		}
		return;
	}

        my $data;
	my $widgetID = $self->widgetID;

        foreach my $key (grep {/^$widgetID-:UPDATE:/} $self->q->param) {
                if ($key =~ /^($widgetID-:UPDATE:)(.+)-:-(.+)::(\d+)$/) {
			my ($pre, $fieldname, $ID, $row) = ($1, $2, $3, $4);
			$data->{$ID}->{$fieldname} = $self->q->param($key);# if $self->q->param($key); #if this is set, won't blank fields deliberately left blank
		} elsif ($key =~ /^($widgetID-:UPDATE:)(.+)-:-(.+)$/) {
			my ($pre, $fieldname, $ID) = ($1, $2, $3);
			$data->{$ID}->{$fieldname} = $self->q->param($key);# if $self->q->param($key);
		}
        }
#	$self->q->util->debug->edump($data);
        return $data;
}

#----------------------------------------------------------------------------------------
sub updateIds {
	my $self = shift;

	my @updates = sort keys %{$self->updates};

	if (wantarray) {
		return @updates;
	} else {
		return \@updates;
	}
}

#----------------------------------------------------------------------------------------
sub validator {
	my $self = shift;

	return $self->{_validator};
}

#----------------------------------------------------------------------------------------
sub vars {
	my $self = shift;

	return $self->{_vars};
}

#----------------------------------------------------------------------------------------
sub widgetID {
	my $self = shift;

	return $self->{_widgetID};
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

CGI::Lazy::Widget

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new('/path/to/config');

	my $widget = $q->widget->dataset({...});

=head1 DESCRIPTION

CGI::Lazy::Widget is an abstract class for widgets such as Dataset, Composite, and Domloader.

Its methods are called internally by its child classes.  There are, at present, no real uses for the class by itself.

=head1 METHODS

=head2 ajaxReturn ( widgets, data )

Wraps data (presumably from widget) in json format with validator from widgets for returning to browser in response to an ajax reqeust

=head2 ajaxSelect (args )

Returns result of select method in a json format suitable for returning to the browser

=head3 args

see select( args) for details

=head3 widgets

List of widgets to be parsed for validators

=head3 data

Widget html output

=head2 jsonescape ( var )

traverses variable and strips out single quotes to prevent JSON parser blowing up.

Strips them out rather than escaping them, as at present I can't figure out how to just add a single fracking backslash to them.  s/'/\\'/g gives 2 backslashes, and s/'/\'/g gives none.  grr.  problem seems to be in either JSON or JSONPARSER

=head3 var

whatever variable you're going to convert to json and then parse


=head2 preloadLookup

Runs queries for lookup tables and parses then into JSON wrapped in javascript suitable for loading into the DOM of a page.

Useful only for tables that are intended to be preloaded into a page at load. 

=head2 ajaxBlank ()

Convenience method.  Returns blank widget output

=head2 select (args)

Runs select based on args and returns output.  

=head3 args

Hash of select parameters.  Expects to see a key called 'incoming' that contains the incoming parameters in widgetID-fieldname => value format.  

Widgets such as Dataset will also have a parameter called CGILazyID which will contain the name of the widget (for doing different things at the cgi level based on which widget is talking to the app). This key/value will be stripped automatically.

The rest of the hash supports the following options:

	div 		=> 1  #By default will be sans enclosing div tags, but div can be included if you pass div => 1.  This is useful for members of composite widgets.
	
	searchLike		=> '%?%' # search will be like %value%, in other words anything containing 'value'. Like is applied only to searches coming in from web, not vars added to the search in the cgi

	searchLike	 	=> '?%'  # search will be on value%

	searchLike		=> '%?'  # search on %v

	vars 		=> {fieldname => {optionname => optionvalue}}

	vars 		=> {fieldname => {value => 'bar'}} #extra search parameter.

	vars		=> {foo => {handle => $ref}}} # when retrieved $$ref will have the value of field foo. ('handle' is a 'handle' on that value for use in tying things together.)
	
	searchLikeVars	=> '%?%' # search will be like %value%, in other words anything containing 'value'.  like is applied to vars specified from the cgi. Basically this means you can do a like on variables hardcoded in the cgi independantly from things coming in from the web.

	searchLikeVars 	=> '?%'  # search will be on value%

	searchikeVars	=> '%?'  # search on %v


