my $conf = {
  header_template => 'myheader',
  footer_template => 'myfooter',
};

__DATA__

@@ 1.html.ep

Some Content

@@ myheader.html.ep

%= p '#myheader' => 'Mojo'

@@ myfooter.html.ep

%= p '#myfooter' => 'Slides'
