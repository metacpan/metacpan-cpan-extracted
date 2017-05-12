# Data::Report::Plugin::Html.pm -- HTML plugin for Data::Report
# RCS Info        : $Id: Html.pm,v 1.8 2008/08/18 09:51:23 jv Exp $
# Author          : Johan Vromans
# Created On      : Thu Dec 29 15:46:47 2005
# Last Modified By: Johan Vromans
# Last Modified On: Mon Aug 18 11:45:39 2008
# Update Count    : 83
# Status          : Unknown, Use with caution!

package Data::Report::Plugin::Html;

use strict;
use warnings;
use base qw(Data::Report::Base);

################ API ################

my $html_use_entities = 0;

sub start {
    my ($self) = @_;
    $self->_argcheck(0);
    eval {
	require HTML::Entities;
	$html_use_entities = 1;
    };
    $self->SUPER::start();
    $self->{used} = 0;
}

sub finish {
    my ($self) = @_;
    $self->_argcheck(0);
    if ( $self->{used} ) {
	$self->_print("</table>\n");
    }
    $self->SUPER::finish();
}

sub add {
    my ($self, $data) = @_;

    my $style = delete($data->{_style});

    $self->SUPER::add($data);

    return unless %$data;

    if ( $style and my $t = $self->_getstyle($style) ) {
	return if $t->{ignore};
    }

    $self->{used}++;

    $self->_checkhdr;

    $self->_print("<tr", $style ? " class=\"r_$style\"" : (), ">\n");

    foreach my $col ( @{$self->_get_fields} ) {
	my $fname = $col->{name};
	my $value = defined($data->{$fname}) ? $data->{$fname} : "";

	# Examine style mods.
	my $t = $self->_getstyle($style, $fname);
	next if $t->{ignore};

	my $class = $t->{class} || "c_$fname";

	$self->_print("<td ", _align($col->{align}),
		      "class=\"$class\">",
		      $value eq ""
		      ? "&nbsp;"
		      : $t->{raw_html}
		        ? $value
		        : $self->_html($value),
		      "</td>\n");
    }

    $self->_print("</tr>\n");
}

################ Pseudo-Internal (used by Base class) ################

sub _std_heading {
    my ($self) = @_;
    $self->_argcheck(0);

    $self->_print("<table class=\"main\">\n");

    $self->_print("<tr class=\"head\">\n");
    foreach ( @{$self->_get_fields} ) {

	# Examine style mods.
	my $t = $self->_getstyle("_head", $_->{name});
	next if $t->{ignore};

	my $class = $t->{class} || "h_" . $_->{name};

	$self->_print("<th ", _align($_->{align}),
		      "class=\"$class\">",
		      $self->_html($_->{title}), "</th>\n");
    }
    $self->_print("</tr>\n");

}

################ Internal methods ################

sub _align {
    return 'align="right" '  if $_[0] eq '>';
    return 'align="left" '   if $_[0] eq '<';
    return 'align="center" ' if $_[0] eq '|';
    ""
}

sub _html {
    shift;
    if ( $html_use_entities ) {
	return HTML::Entities::encode(shift);
    }

    my ($t) = @_;
    $t =~ s/&/&amp;/g;
    $t =~ s/</&lt;/g;
    $t =~ s/>/&gt;/g;
    $t =~ s/\240/&nbsp;/g;
    $t =~ s/\x{eb}/&euml;/g;	# for IVP.
    $t;
}

1;
