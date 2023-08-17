# A script that listen for commands on STDIN and responds with JSON data on
# STDOUT. To test the JsonTool module.

my %data;

$data{hello} = <<EOF;
{
  "foo": "bar",
  "bin" : [ "test1", "test2" ],
  "baz" : { "key": "value" }
}
EOF

$data{other} = <<EOF;
{
  "text": "more text"
}
EOF

# The input there contains space, tabs, etc.
$data{with_blank} = <<EOF;
{
  "text": "some text"
}
   
	

EOF

$data{two_messages} = <<EOF;
{
  "count": 1
}
{
  "count": 2
}
EOF

$data{quit} = <<EOF;
{
  "cmd": "bye!"
}
EOF



# unbuffer STDOUT
binmode(STDOUT, ':unix');

while (<>) {
  chomp;
  #print STDERR "Fake tool received: ${_}\n";
  #print STDERR "Fake tool sending: ${data{$_}}\n";
  print $data{$_};
  exit if /^quit$/;
}
