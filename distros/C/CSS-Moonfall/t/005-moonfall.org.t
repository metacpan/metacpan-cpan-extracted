use strict;
use warnings;
use Test::More tests => 1;

my $out = Moonfall::Org->filter(<<'INPUT');
body { 
       font-family:'Trebuchet MS', sans-serif;
       }

#site_container { 
                  color: black;
                  background-color: white;
                  width: [page_width];
                  min-width: [page_width];
                  }

#top_container { 
                 width: [page_width];
                 height: 60px;
                 margin-bottom: 60px;
                 }

#logo {  
        width: [logo_width];
        float: left;
        }

#pushdown { 
            [header_div_attrs]
            background-color: #D68003;
            width: [$header_top_widths->{pushdown}];
            }

#spacer { 
          [header_div_attrs]
          background-color: #D6AD44;
          width: [$header_bottom_widths->{spacer}];
          }

#contact { 
           [header_div_attrs]
           background-color: #AF9256;
           width: [$header_bottom_widths->{contact}];
           }

#contact a { 
             [nav_link_attrs]
             }

#list { 
        [header_div_attrs]
        background-color: #663300;
        width: [$header_bottom_widths->{list}];
        }

#list a { [nav_link_attrs] }


#download { 
            [header_div_attrs]
            background-color: #660000;
            width: [$header_bottom_widths->{download}];
            }

#download a { 
              [nav_link_attrs]
              }


#example { 
           [header_div_attrs]
           background-color: #996633;
           width: [$header_bottom_widths->{example}];
           }

#example a { 
             [nav_link_attrs]
             }

.question {
            color: #660000;
            font-weight: bold;
            margin-left: [side_margin];
            margin-right: [side_margin];
            font-size: [large_em];
            }

.answer { 
          margin-bottom: 80px;
          margin-left: [side_margin];
          margin-right: [side_margin];
          font-size: [medium_em];
          }

.accent { 
          margin-left: [side_margin];
          margin-right: [side_margin];
          font-size: [large_em];
          font-weight:bold;
          color: #663300;
          }

/* so internal anchors aren't cut short when jumping */
#bottom_space { 
                float: left;
                height: 1000px;
                }


ol em { 
        color: red;
        }
INPUT

# note: hash keys come out in arbitrary order, so we sort them.  use an array
# ref if you want to define your own order
is($out, <<"EXPECTED", "moonfall.org css works");
body { 
       font-family:'Trebuchet MS', sans-serif;
       }

#site_container { 
                  color: black;
                  background-color: white;
                  width: 1000px;
                  min-width: 1000px;
                  }

#top_container { 
                 width: 1000px;
                 height: 60px;
                 margin-bottom: 60px;
                 }

#logo {  
        width: 300px;
        float: left;
        }

#pushdown { 
            border: solid 1px white;
            float: left;
            height: 30px;
            background-color: #D68003;
            width: 696px;
            }

#spacer { 
          border: solid 1px white;
          float: left;
          height: 30px;
          background-color: #D6AD44;
          width: 300px;
          }

#contact { 
           border: solid 1px white;
           float: left;
           height: 30px;
           background-color: #AF9256;
           width: 97px;
           }

#contact a { 
             color: white;
             float: right;
             font-size: 1.1em;
             line-height: 40px;
             margin-right: 5px;
             }

#list { 
        border: solid 1px white;
        float: left;
        height: 30px;
        background-color: #663300;
        width: 97px;
        }

#list a { color: white; float: right; font-size: 1.1em; line-height: 40px; margin-right: 5px; }


#download { 
            border: solid 1px white;
            float: left;
            height: 30px;
            background-color: #660000;
            width: 97px;
            }

#download a { 
              color: white;
              float: right;
              font-size: 1.1em;
              line-height: 40px;
              margin-right: 5px;
              }


#example { 
           border: solid 1px white;
           float: left;
           height: 30px;
           background-color: #996633;
           width: 97px;
           }

#example a { 
             color: white;
             float: right;
             font-size: 1.1em;
             line-height: 40px;
             margin-right: 5px;
             }

.question {
            color: #660000;
            font-weight: bold;
            margin-left: 20px;
            margin-right: 20px;
            font-size: 1.2em;
            }

.answer { 
          margin-bottom: 80px;
          margin-left: 20px;
          margin-right: 20px;
          font-size: 1.1em;
          }

.accent { 
          margin-left: 20px;
          margin-right: 20px;
          font-size: 1.2em;
          font-weight:bold;
          color: #663300;
          }

/* so internal anchors aren't cut short when jumping */
#bottom_space { 
                float: left;
                height: 1000px;
                }


ol em { 
        color: red;
        }
EXPECTED

BEGIN
{
    package Moonfall::Org;
    use CSS::Moonfall;

    our $page_width = 1000;
    our $large_em = "1.2em";
    our $medium_em = "1.1em";

    our $side_margin = 20;

    our $nav_link_attrs = {
        float => "right",
        line_height => 40,
        margin_right => 5,
        font_size => $medium_em,
        color => "white",
    };

    our $header_div_attrs = {
        float => "left",
        border => "solid 1px white",
        height => 30,
    };

    our $logo_width = 300;

    our $header_top_widths = fill
    {
        total => $page_width,
        borders_dummy => 4, # dummy to make room for borders
        logo => $logo_width,
        pushdown => undef,
    };

    our $header_bottom_widths = fill
    {
        total => $page_width,
        borders_dummy => 10, # dummy to make room for borders
        logo => $logo_width,
        spacer => 300,
        example => undef,
        contact => undef,
        list => undef,
        download => undef,
    };
}

