=head1 NAME

CGI::Widget::Tabs::Style - Stylesheets for CGI::Widget::Tabs


=head1 SYNOPSIS

None.


=head1 DESCRIPTION

This module is designed to work with CGI::Widget::Tabs. 

=cut

package CGI::Widget::Tabs::Style;

# pragmata
use strict;
use vars qw(@EXPORT @ISA $VERSION);

# CPAN Modules
use Exporter;

# package variables
@ISA = qw(Exporter);
@EXPORT = qw(css_styles);

$VERSION = "1.00";

=head1 EXPORTED FUNCTIONS

=head2 css_styles

Returns CSS styles

=cut

sub css_styles {

    my @styles = (
                  { descr  => "Google look-a-like",
                    author => "" ,
                    style  => <<EOT
table.my_tab     { border-spacing: 0; border-bottom: solid thin #C0D4E6; text-align: center }
td.my_tab        { no-wrap; padding: 2 12 2 12; width: 80; background-color: #FAFAD2 }
td.my_tab_actv   { padding: 2 12 2 12; width: 80; background-color: #C0D4E6; font-weight: bold }
td.my_tab_spc    { width: 5 }
td.my_tab_ind    { width: 15 }
EOT
                  },


                  { descr  => "Dark green-light green, heavy rule",
                    author => "" ,
                    style  => <<EOT
a  { color: #aa00ff }
table.my_tab     { no-wrap; border-spacing: 0; border-bottom: medium solid #6FA579; margin-bottom: 6px }
td.my_tab_actv   { padding: 2 15 2 15; background-color: #6FA579; text-align: center; font-weight: bold }
td.my_tab        { padding: 2 15 2 15; background-color: #8CCF98; text-align: center; font-weight: bold }
td.my_tab_spc    { width: 10 }
td.my_tab_ind    { width: 15 }
EOT
                  },


                  { descr  => "Light purple-dark purple, heavy rule",
                    author => "" ,
                    style  => <<EOT
a  { color: White }
table.my_tab     { no-wrap; border-spacing: 0; border-bottom: medium solid #8b0a50; margin-bottom: 6px }
td.my_tab_actv   { padding: 2 15 2 15; background-color: #ee1289; text-align: center; font-weight: bold }
td.my_tab        { padding: 2 15 2 15; background-color: #8b0a50; text-align: center; font-weight: bold }
td.my_tab_spc    { width: 10 }
td.my_tab_ind   { width: 15 }
EOT
                  },


                  { descr  => "Light purple-grey, heavy rule",
                    author => "" ,
                    style  => <<EOT
a  { color: White }
table.my_tab     { no-wrap; border-spacing: 0; border-bottom: medium solid #cf0f76; margin-bottom: 6px }
td.my_tab_actv   { padding: 2 15 2 15; background-color: #cf0f76; text-align: center; font-weight: bold }
td.my_tab        { padding: 2 15 2 15; background-color: DarkGrey; text-align: center; font-weight: bold }
td.my_tab_spc    { width: 10 }
td.my_tab_ind    { width: 15 }
EOT
                  },


                  { descr  => "Brown-blue, heavy rule",
                    author => "" ,
                    style  => <<EOT
a  { color: White }
table.my_tab     { no-wrap; border-spacing: 0; border-bottom: medium solid #00688b; margin-bottom: 6px }
td.my_tab_actv   { padding: 2 15 2 15; background-color: #cd8162; text-align: center; font-weight: bold }
td.my_tab        { padding: 2 15 2 15; background-color: #00688b; text-align: center; font-weight: bold }
td.my_tab_spc    { width: 10 }
td.my_tab_ind    { width: 15 }
EOT
                  },


                  { descr  => "Bold font-light font, dark blue, heavy rule",
                    author => "" ,
                    style  => <<EOT
a  { color: Yellow }
table.my_tab     { no-wrap; border-spacing: 0; border-bottom: medium solid #000080; margin-bottom: 6px }
td.my_tab_actv   { padding: 2 15 2 15; background-color: #000080; text-align: center; font-weight: bold }
td.my_tab        { padding: 2 15 2 15; background-color: #000080; text-align: center; font-weight: normal }
td.my_tab_spc    { width: 10 }
td.my_tab_ind    { width: 15 }
EOT
                  },


                  { descr  => "Red frame, grey, thin rule",
                    author => "" ,
                    style  => <<EOT
a  { color: Black }
table.my_tab     { no-wrap; border-spacing: 0; border-bottom: thin solid Grey; margin-bottom: 6px }
td.my_tab_actv   { padding: 2 15 2 15; background-color: Grey; text-align: center; font-weight: bold ; border: thin solid red }
td.my_tab        { padding: 2 15 2 15; background-color: Grey; text-align: center; font-weight: bold }
td.my_tab_spc    { width: 10 }
td.my_tab_ind    { width: 15 }
EOT
                  },


                  { descr  => "Red top line,  grey, thin rule",
                    author => "" ,
                    style  => <<EOT
a  { color: Black }
table.my_tab     { no-wrap; border-spacing: 0; border-bottom: thin solid #bebebe; margin-bottom: 6px }
td.my_tab_actv   { padding: 2 15 2 15; background-color: #bebebe; text-align: center; font-weight: bold ; border-top: medium solid red }
                    td.my_tab        { padding: 2 15 2 15; background-color: #bebebe; text-align: center; font-weight: bold ; border-top: medium solid #bebebe }
td.my_tab_spc    { width: 1 }
td.my_tab_ind    { width: 15 }
EOT
                  },


                  { descr  => "Yellow/black top line, grey, thin rule",
                    author => "" ,
                    style  => <<EOT
a  { color: Black }
table.my_tab     { no-wrap; border-spacing: 0; border-bottom: thin solid #bebebe; margin-bottom: 6px }
td.my_tab_actv   { padding: 2 15 2 15; background-color: #bebebe; text-align: center; font-weight: bold ; border-top: medium solid Yellow }
td.my_tab        { padding: 2 15 2 15; background-color: #bebebe; text-align: center; font-weight: bold ; border-top: medium solid black }
td.my_tab_spc    { width: 1 }
td.my_tab_ind    { width: 15 }
EOT
                  },


                  { descr  => "Blue underline, grey underline",
                    author => "" ,
                    style  => <<EOT
a  { color: Black }
table.my_tab     { no-wrap; border-spacing: 0; margin-bottom: 6px }
td.my_tab_actv   { padding: 2 15 2 20; text-align: center; font-weight: bold ; border-bottom: medium solid MediumBlue }
td.my_tab        { padding: 2 15 2 20; text-align: center; font-weight: bold ; border-bottom: medium solid Grey }
td.my_tab_spc    { width: 1 }
td.my_tab_ind    { width: 15 }
EOT
                  }
                 );
}

1;
