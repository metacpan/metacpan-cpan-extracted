<?php

$style_common = <<<STY
.header { background: #EEFFFF; border-bottom: 1px solid }
 h2 {background: #EEEEEE}
 body  { font-family: Arial,Helvetica,sans-serif;  background: #EEEEFF; }

    #tabs ul {
		list-style: none;
		padding: 0;
		margin: 0;
    }
    
	#tabs li {
		float: left;
		border: 1px solid #bbb;
		border-bottom-width: 0;
		margin: 0;
    }
    
	#tabs a {
		text-decoration: none;
		display: block;
		background: #eee;
		padding: 0.24em 1em;
		color: #00c;
		width: 4em;
		text-align: center;
    }
	
	#tabs a:hover {
		background: #ddf;
	}
	
	#tabs #selected {
		border-color: black;
	}
	
	#tabs #selected a {
		position: relative;
		top: 1px;
		background: white;
		color: black;
		font-weight: bold;
	}
	



STY;

$all_demos = array(
 "Demo1" => "d1",
 "Demo2" => "d2",
 "Demo3" => "d3",
 "Demo4" => "d4",
 "Demo5" => "d5",
 "Demo6" => "d6",
 "Demo7" => "d7",
 "Demo8" => "d8");


preg_match('/(d\d)/', $_SERVER[SCRIPT_NAME], $matches);
$current_dir = $matches[1];

$tabs = <<<HOME
<li id="" ><a href="/">Home</a></li>
<li id="" ><a href="/demo">Demo</a></li>

HOME;

foreach ($all_demos as $title => $demo) {
  $aid = ($demo == $current_dir) ? "selected" : "";
  $tabs .= <<<TAB
<li id="$aid" ><a href="/demo/$demo/demo.php">$title</a></li>

TAB;
}


function page_template($main_content) {
global $tabs;

return <<<HEADER
<div align="center">
  <div align="left" style="background: #CCEEFF; padding: 5px; border: 1px solid #CCAAFF; width: 1024px">
    <div class="header">
      <span style="font-size: 50px; font-weight: bold; ">Apache2::AuthAny</span>
      <div style="float: right; padding-right: 20px"><?= $ident_block ?></div>
      <div style="clear: both"></div>
    </div>
    <div id="tabs">
      <ul>
        $tabs
      </ul>
    </div>
    <div style="clear: both"></div>

    $main_content          

  </div>
</div>
HEADER;
}
