<%
  # This example script uses Apache::ASP, which allows embedding perl in HTML
  # or other text files, see http://search.cpan.org/perldoc?Apache::ASP

  use Color::Calc::WWW;
  $Response->{'ContentType'} = 'text/css; charset=utf-8';

  $col1 = '#EEE';
  $col2 = '#908';

  $bkg = $col1;
  $fg  = color_contrast(color_grey($bkg));

  $bk2 = $col2;
  $fg2 = color_contrast(color_grey($bk2));
%>

body		      {
			background:	<%= $bkg %>;
			color:		<%= $fg %>;
		      }

h1 		      {	
			background:	<%= $bk2 %>;
			color:		<%= $fg2 %>;
		      }
