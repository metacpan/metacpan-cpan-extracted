my $conf = {
  slides => 1,
  bootstrap_theme => 1,
};

__DATA__

@@ 1.html.ep

%= p 'It works!'

%= incremental ul begin
  %= li 'Hello'
  %= li 'World'
% end
