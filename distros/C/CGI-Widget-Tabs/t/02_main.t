# $Id: 02_main.t,v 1.7 2002/11/09 14:22:24 koos Exp $
use strict;
use Test;
use CGI::Widget::Tabs;

BEGIN { plan tests => 11 };

my $cgi;
if ( $cgi = cgi_available() ) {
    ok(1); # If we made it this far, we're ok.

    # --- First the simple headings

    ok( active_simple( { headings => ["Tab 1", "Tab 2"],
                         cgi      => $cgi } ),
        "Tab 1" );


    ok( active_simple( { headings => ["Tab 1", "Tab 2"],
                         default  => "Tab 2",
                         cgi      => $cgi } ),
        "Tab 2");


    ok( active_simple( { headings => ["Tab 1", "Tab 2", "Tab 3"],
                         default  => "Tab 2",
                         query    => "Tab 3",
                         cgi      => $cgi } ),
        "Tab 3" );


    ok( active_simple( { headings => [ "-t1" => "Tab 1", "-t2" => "Tab 2"],
                         cgi      => $cgi } ),
        "-t1" );


    ok( active_simple( { headings => [ "-t1" => "Tab 1", "-t2" => "Tab 2"],
                         default  => "-t2",
                         cgi      => $cgi } ),
        "-t2" );


    ok( active_simple( { headings => ["-t1" => "Tab 1", "-t2" => "Tab 2", "-t3" => "Tab 3"],
                         default  => "-t2" ,
                         query    => "-t3",
                         cgi      => $cgi } ),
        "-t3" );


    # --- Now the OO headings

    ok( active_oo( { headings => [ { text => "Tab 1" },
                                   { text => "Tab 2" } ],
                     cgi      => $cgi } ),
        "Tab 1" );



    ok( active_oo( { headings => [ { text => "Tab 1" },
                                   { text => "Tab 2" } ] ,
                     query    => "Tab 2",
                     cgi      => $cgi } ),
        "Tab 2" );


    ok( active_oo( { headings => [ { text => "Tab 1",
                                     key  => "t1" } ,
                                   { text => "Tab 2",
                                     key  => "t2" },
                                   { text => "Tab 3",
                                     key  => "t3" } ] ,
                     default  => "t2",
                     cgi      => $cgi } ),
       "t2" );


    ok( active_oo( { headings => [ { text => "Tab 1",
                                     key  => "t1" },
                                   { text => "Tab 2",
                                     key  => "t2" },
                                   { text => "Tab 3",
                                     key  => "t3" } ],
                     default  => "t2",
                     query    => "t3",
                     cgi      => $cgi } ),
        "t3" );

}


############################################################


# -------------------------------------
sub active_simple {
# -------------------------------------
    my $args     = shift;
    my @headings = @{ $args->{headings} };
    my $default  = $args->{default};
    my $query    = $args->{query};
    my $cgi      = $args->{cgi};

    my $tab = CGI::Widget::Tabs->new;
    $tab->cgi_object($cgi);
    $tab->cgi_param('t');
    # --- reset any sticky/remaining values
    ( ref $cgi eq "CGI" ) && do {
        $cgi->delete($tab->cgi_param());
        $cgi->param(-name => $tab->cgi_param(), -value => $query);
    };
    ( ref $cgi eq "CGI::Minimal" ) && do {
        $cgi->param($tab->cgi_param() => undef);
        $cgi->param($tab->cgi_param() => $query);
    };
    $tab->headings(@headings);
    $tab->default($default) if $default;
    return $tab->active();
}


# -------------------------------------
sub active_oo {
# -------------------------------------
    my $args     = shift;
    my @headings = @{ $args->{headings} };
    my $default  = $args->{default};
    my $query    = $args->{query};
    my $cgi      = $args->{cgi};

    my $tab = CGI::Widget::Tabs->new;
    $tab->cgi_object($cgi);
    $tab->cgi_param('t');
    # --- reset any sticky/remaining values
    ( ref $cgi eq "CGI" ) && do {
        $cgi->delete($tab->cgi_param());
        $cgi->param(-name => $tab->cgi_param(), -value => $query);
    };
    ( ref $cgi eq "CGI::Minimal" ) && do {
        $cgi->param($tab->cgi_param() => undef);
        $cgi->param($tab->cgi_param() => $query);
    };
    $cgi->param($tab->cgi_param() => $query);
    my $h;
    foreach ( @headings ) {
        $h = $tab->heading;
        $h->text( $_->{text} );
        $h->key( $_->{key} ) if $_->{key};
    }
    $tab->default($default) if $default;
    return $tab->active();
}


# -------------------------------------
sub cgi_available {
# -------------------------------------
    if  ( (eval {require CGI; $cgi = CGI->new} ) or
          (eval {require CGI::Minimal; $cgi = CGI::Minimal->new} ) ) {
        print "Found ".(ref $cgi)." and using it.\n";
        return $cgi;
    } else {
        warn "##\n";
        warn "## Unable to load CGI or CGI::Minimal. Skipping tests...\n";
        warn "## Note that eventually you do need CGI or CGI::Minimal.\n";
        warn "##\n";
        return 0;
    }
}
