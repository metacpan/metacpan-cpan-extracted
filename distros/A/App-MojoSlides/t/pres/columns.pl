my $config = {
  last => 1,
};

__DATA__

@@ 1.html.ep

%= row begin
  %= column 6 => begin
    %= p 'Column w 6'
  % end
  %= column [3, 'offset-3'] => begin
    %= p 'Column w 3 o 3'
  % end
% end
