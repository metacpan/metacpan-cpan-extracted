# --*-Perl-*--
# $Id: HistoryList.pm 10 2004-11-02 22:14:09Z tandler $
#

package PBibTk::HistoryList;
use 5.006;
use strict;
use warnings;
#use English;

# for debug:
#use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 10 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#use YYYY;
#use vars qw(@ISA);
#@ISA = qw(YYYY);

# used modules
use TK::BrowseEntry;

# used own modules
use PBibTk::SearchDialog;


# module variables
#use vars qw($mmmm);
# or
#our($mmm);

#
#
# constructor
#
#

sub new {
  my ($self, $ui, $label, $varRef, $list) = @_;
  my $hist = {
  	'ui' => $ui,
  	'label' => $label,
  	'varRef' => $varRef,
  	'list' => $list,
  	'count' => 0,
  	'history' => {},
  	};

  my $class = ref($self) || $self;
  $self = bless $hist, $class;
  $self->createList() unless $list;
  $self->loadQueryHistory();
  return $self;
}

sub createList {
	my ($self) = @_;
	my $cmd = [ $self, 'query' ];
	my $var;
	my $varRef = $self->varRef()
	unless( $varRef ) {
		$varRef = \$var;
		$self->{'varRef'} = $varRef;
	}
	$list = $bf1->BrowseEntry(-label => $self->label(),
		-variable => $varRef,
	#	-choices => \@queryAuthorHistory,
		-listcmd => [ $self, 'updateList' ],
		-browsecmd => $cmd,
		);
	$list->bind('<Return>' => $cmd);
	$self->{'list'} = $list;
	return $list;
}

#
#
# destructor
#
#

#sub DESTROY ($) {
#  my $self = shift;
#}



#
#
# UI access methods
#
#

sub widget { return shift->list(); }

#
#
# access methods
#
#

sub varRef ( return shift->{'varRef'}; )
sub value ( my ($self) = @_;
	return ${$self->varRef()};
)

sub ui ( return shift->{'ui'}; )
sub label ( return shift->{'label'} || "Query"; )
sub list { return shift->{'list'}; }
sub count { return shift->{'count'}; }
sub history { return shift->{'history'}; }


#
#
# methods
#
#

sub query {
	print "query $queryAuthorItem\n";
	unshift @queryAuthorHistory, $queryAuthorItem;
	$self->queryAuthorList()->insert(0, $queryAuthorItem);
	my $q = new PbibTk::SearchDialog ($self->ui(),
		"Search Author: $queryAuthorItem",
		"%$queryAuthorItem%",
		['Author']);
	$q->show();
}

sub insert { my ($self, $item) = @_;
	$self->{'count'} ++;
	my $hist = $self->history();
	if( exists $hist->{$item} ) {
		my $entry = $hist->{$item};
		$entry->[0] ++;
		$entry->[1] = time();
	} else {
		$hist->{$item} = [1, time()];
	}
}

sub updateList {
	my ($self) = @_;

# add last 10 items and 10 most often used items to list (& sort by name)
	
	$self->list()->insert(0, $item);
}


#
#
# class methods
#
#


1;

#
# $Log: HistoryList.pm,v $
# Revision 1.3  2004/03/30 19:14:17  krugar
# refactored: 
# 	LitUIRefDialog -> LitUI::RefDialog 
#	LitUISearchDialog -> LitUI::SearchDialog 
#

#
# Revision 1.2  2003/04/14 09:44:17  ptandler
# uncomplete ...
#
# Revision 1.1  2002/06/24 10:47:31  Diss
# started work to refactor LitUI a wee bit
#

