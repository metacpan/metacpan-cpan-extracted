<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en" dir="ltr">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>ASP4 Installed</title>
  <style type="text/css">
  HTML, BODY {
    margin: 0px;
    padding: 0px;
    border: 0px;
    font-size: 14px;
    font-family: Verdana, Arial, Sans-Serif;
    background-color: #333333;
    color: #000000;
    width: 100%;
    height: 100%;
  }
  
  #header {
    background-color: #FFFFFF;
    height: 35px;
    border-bottom: solid 1px #000000;
  }
  
  #header-container {
    width: 950px;
    margin-left: auto;
    margin-right: auto;
    padding: 5px;
    font-size: 20px;
    font-weight: bold;
    color: #000000;
    line-height: 20px;
    text-align: center;
  }
  
  #container {
    width: 950px;
    margin-left: auto;
    margin-right: auto;
    background-color: #FFFFFF;
    height: 92%;
  }
  
  .clear {
    clear: both;
  }
  
  #leftnav {
    float: left;
    width: 198px;
  }
  
  UL {
    margin: 0px;
    padding: 0px;
    list-style: none;
  }
  
  UL LI {
    line-height: 28px;
  }
  
  UL LI A {
    border-right: solid 2px #FF0000;
    padding-left: 10px;
    display: block;
    clear: both;
    color: #FF0000;
  }
  
  UL LI A:hover {
    background-color: #EFEFEF;
    color: #000000;
    border-right: solid 2px #000000;
  }
  
  #contents {
    float: left;
    width: 740px;
    padding: 5px;
    background-color: #FFFFFF;
  }
  
  PRE {
    background-color: lightyellow;
    height: 300px;
    overflow: auto;
    padding: 5px;
    border: solid 1px #CCCCCC;
  }

  </style>
</head>
<body>
<div id="header">
  <div id="header-container">
<%
  require ASP4;
%>
    ASP4 v<%= $ASP4::VERSION %> Installed // Date: <%= scalar(localtime(time)) %>
  </div>
</div>
<div id="container">
  <div id="leftnav">
    <ul>
      <li class="active"><a href="">Home</a></li>
      <li><a href="http://search.cpan.org/dist/ASP4/">ASP4 Documentation</a></li>
      <li><a href="http://www.cpanforum.com/dist/ASP4">ASP4 Forum</a></li>
      <li><a href="http://rt.cpan.org/Public/Dist/Display.html?Name=ASP4">ASP4 Bug Tracker</a></li>
      <li><a href="http://www.devstack.com/">ASP4 Developer</a></li>
    </ul>
    <div class="clear"></div>
  </div>
  <div id="contents">
    <h2>ASP4 Is Running on this Server</h2>
    <p>
      For more information about ASP4, please used the links provided on the left.
    </p>
    <p>
      <b>Loaded ASP4 Modules:</b>
      <pre><%= join "\n", map { $_ =~ s{/}{::}g; $_ =~ s/\.pm$//; $_ } sort grep { m{^ASP4/} } keys %INC %></pre>
    </p>
  </div>
</div>
</body>
</html>
