
######################################################################
## $Id: TablessSelector.pm 7953 2006-10-16 19:16:56Z spadkins $
######################################################################

package App::Widget::TablessSelector;
$VERSION = (q$Revision: 7953 $ =~ /(\d[\d\.]*)/)[0];  # VERSION numbers generated by svn

use App;
use App::Widget::HierSelector;
@ISA = ( "App::Widget::HierSelector" );

use strict;

=head1 NAME

App::Widget::TablessSelector - A screen selector widget

=head1 SYNOPSIS

   use App::Widget::TablessSelector;

   $name = "get_data";
   $w = App::Widget::TablessSelector->new($name);
   print $w->html();

=cut

=head1 DESCRIPTION

This class implements a screen selector.

=cut

######################################################################
# INITIALIZATION
######################################################################

sub _init {
    my $self = shift;
    $self->SUPER::_init(@_);
    if (! $self->{selected}) {
        $self->select_first();
    }
}

sub select {
    my ($self, $nodeattrib, $value) = @_;
    my $success = $self->SUPER::select($nodeattrib, $value);
    $self->open_selected_exclusively();
    return($success);
}

sub open_exclusively {
    my ($self, $opennodenumber) = @_;
    #$self->{debug} .= "open_exclusively($opennodenumber)<br>";
    $self->SUPER::open_exclusively($opennodenumber);
    $self->select_first_open_leaf($opennodenumber);
}

######################################################################
# OUTPUT METHODS
######################################################################

sub html {
    my $self = shift;
    my ($html, $label, $icon);
    my $context = $self->{context};
    my $name    = $self->{name};
    my $node    = $self->node_list();

    my ($bgcolor, $width, $fontface, $fontsize, $fontcolor, $fontbegin, $fontend);
    my ($html_url_dir, $xgif);

    $bgcolor   = $self->{bgcolor}   || "#cccccc";
    $width     = $self->{width}     || "100%";
    $fontface  = $self->{fontface}  || "verdana,geneva,arial,sans-serif";
    $fontsize  = $self->{fontsize}  || "-2";
    $fontcolor = $self->{fontcolor} || "#ffffff";

    $bgcolor = "";

    my ($nodebase, $nodeidx, $nodenumber, $nodelabel, $parentnodenumber, $nodelevel, $opennodenumber);
    my (@nodeidx, $selected_nodenumber, $w);

    $selected_nodenumber = $self->{selected};
    @nodeidx = split(/\./,$selected_nodenumber);

    $html_url_dir = $context->get_option("html_url_dir");
    $xgif = "$html_url_dir/images/Widget/dot_clear.gif";

    $html = $self->{debug} || "";

    $nodelevel = 0;
    $nodebase = "";
    if (defined $node->{1} && !defined $node->{2}) {
        $nodelevel = 1;
        $nodebase = "1.";
    }
    my $auth = $context->authorization();
    my ($auth_name);
    for (; $nodelevel <= $#nodeidx; $nodelevel++) {
        $html .= '<table border="0" cellpadding="0" cellspacing="0" width="100%">' . "\n";
        $html .= "  <tr><td rowspan=\"3\" width=\"1%\" height=\"19\" nowrap>";

        $nodeidx = 1;
        $nodenumber = "$nodebase$nodeidx"; # create its node number
        while (defined $node->{$nodenumber}) {

            $auth_name = $node->{$nodenumber}{auth_name};
            if (!$auth_name || $auth->is_authorized("/App/SessionObject/$name/$auth_name")) {
                $label = $node->{$nodenumber}{label};
                $label = $node->{$nodenumber}{value} if (!defined $label);
                $label = "" if (!defined $label);
            }

            $nodeidx++;
            $nodenumber = "$nodebase$nodeidx"; # create its node number
        }
        $nodebase .= "$nodeidx[$nodelevel].";
        $html .= "</td>\n";
        $html .= "    <td height=16 width=\"99%\"$bgcolor><img src=transp.gif height=16 width=1></td>\n";
        $html .= "    <td height=\"16\" width=\"99%\"></td>\n";
        $html .= "  </tr>\n";
        $html .= "  <tr>\n";
        $html .= "    <td height=\"1\" width=\"99%\" bgcolor=\"#000000\"><img src=\"$xgif\" height=\"1\" width=\"1\"></td>\n";
        $html .= "  </tr>\n";
        $html .= "  <tr>\n";
        $html .= "    <td height=\"2\" width=\"99%\" bgcolor=\"#ffffff\"><img src=\"$xgif\" height=\"2\" width=\"1\"></td>\n";
        $html .= "  </tr>\n";
        $html .= "</table>\n";
    }

    $html;
}
1;

