use Test::More tests => 4;
use Builder;


my $builder = Builder->new;
my $xm  = $builder->block( 'Builder::XML', { indent => 4, newline => 1 } );

my $expected = 
q{<body>
    <em>emphasized</em>
    <div id="mydiv">
        <bold>hello</bold>
        <em>world</em>
    </div>
</body>
};

##############################################################
# test 1
$xm->body( sub {
    $xm->em("emphasized");
    $xm->div( { id => 'mydiv' }, $xm->bold('hello'), $xm->em('world') );
});

is $builder->render, $expected, "xml pretty test 1 failed";

##############################################################
# test 2 (same as above but without anon sub)
$xm->body(
    $xm->em("emphasized"),
    $xm->div( { id => 'mydiv' }, $xm->bold('hello'), $xm->em('world') ),
);

is $builder->render, $expected, "xml pretty test 2 failed";


##############################################################
# test 3 - More complicated test extropolated from real live job
#my $h  = $builder->block( 'Builder::XML', indent => 4, newline => 1, open_newline => 0 );
my $n  = $builder->block( 'Builder::XML' );
# $h->li( { class => "ui-tabs-nav-item" }, $n->a( { href => "#fragment-1" }, $item ) );

my @issues = ('My Active Issues', 'All Active Issues', 'Unassigned Issues', 'Closed Issues' );

$xm->div( 
    { id => 'dash-actions' },
    
    $xm->h1( 'Action Planning' ),
    
    $xm->div( { id => 'myTabs' },
    
        $xm->ul( sub {
            my $count;
            for my $item ( @issues ) {
                $count++;
                $xm->li( { class => "ui-tabs-nav-item" }, $n->a( { href => "#fragment-$count" }, $item )->__render__ );
            }
        }),
        
        $xm->div( { id => 'fragment-1' }, q{
            [% INCLUDE dash_actions_table.tt 
                session.user = 'barry'
                table_id = 'table-issue-my'
                cols = [ 'id', 'created', 'last_updated', 'owner', 'priority', 'subject' ] 
            %]}
        ),
        
        $xm->div( { id => 'fragment-2' }, q{
            [% INCLUDE dash_actions_table.tt 
                table_id = 'table-issue-all'
                cols = [ 'id',  'created', 'last_updated', 'owner', 'assigned_to', 'priority', 'subject' ] 
            %]
}
        ),
        
    ),
    
    $xm->p( q{Create a <a href="[% R('NewAction') %]">new action / issue</a>} ),
);


$expected = 
q{<div id="dash-actions">
    <h1>Action Planning</h1>
    <div id="myTabs">
        <ul>
            <li class="ui-tabs-nav-item"><a href="#fragment-1">My Active Issues</a></li>
            <li class="ui-tabs-nav-item"><a href="#fragment-2">All Active Issues</a></li>
            <li class="ui-tabs-nav-item"><a href="#fragment-3">Unassigned Issues</a></li>
            <li class="ui-tabs-nav-item"><a href="#fragment-4">Closed Issues</a></li>
        </ul>
        <div id="fragment-1">
            [% INCLUDE dash_actions_table.tt 
                session.user = 'barry'
                table_id = 'table-issue-my'
                cols = [ 'id', 'created', 'last_updated', 'owner', 'priority', 'subject' ] 
            %]</div>
        <div id="fragment-2">
            [% INCLUDE dash_actions_table.tt 
                table_id = 'table-issue-all'
                cols = [ 'id',  'created', 'last_updated', 'owner', 'assigned_to', 'priority', 'subject' ] 
            %]
</div>
    </div>
    <p>Create a <a href="[% R('NewAction') %]">new action / issue</a></p>
</div>
};

is $builder->render, $expected, "xml pretty test 3 failed";



##############################################################
# test 4

my $h  = $builder->block( 'Builder::XML', { pre_indent => 4, indent => 4, newline => 1 } );
$h->one( $h->inside_one( {a => 1} ), $h->also_inside_one );
my $one = $h->__render__;

$xm->ONE( $xm->pre, $one, $xm->post );

$expected = 
q{<ONE>
    <pre />
    <one>
        <inside_one a="1" />
        <also_inside_one />
    </one>
    <post />
</ONE>
};

is $builder->render, $expected, "xml pretty test 4 failed";


