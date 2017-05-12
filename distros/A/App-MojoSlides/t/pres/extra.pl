use Mojo::Base -strict;

my $conf = {
  last      => 2,
  extra_js  => 'myjs.js',
  extra_css => ['mycss1.css', 'mycss2.css'],
  finally => sub { shift->defaults( finally => 1  ) }
};

__DATA__

@@ 1.html.ep
%= p 'Hi'

@@ 2.html.ep
%= p '#finally' => begin
  %= stash('finally') ? 'Works' : 'Broken'
% end

