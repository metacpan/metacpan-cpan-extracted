package App::tmblr;

use WWW::Tumblr;

our $VERSION = '0.04';

our $skellington = <<'END';
$blog = '???.tumblr.com';
$tokens = {
  consumer_key => '',
  secret_key => '',
  token => '',
  token_secret => ''
};
END

sub init {
  our ($blog, $tokens);
  my $path = shift || "$ENV{HOME}/.tmblr";
  $blog = shift;
  do $path or warn("unable to parse $path") if -f $path;
  if(!$tokens || !$blog) {
    say STDERR "put your blog name and your silly tokens in $path";
    if(!-f $path) {
      open(my $fh, ">", $path);
      say $fh $skellington;
      close($path);
    }
    exit(1);
  }
  my $tumblr = WWW::Tumblr->new($tokens);
  return $tumblr->blog($blog);
}

sub gulp {
  my $name = shift;
  my $content;
  if($name) {
    if($name eq "-") {
      $content = join('', <STDIN>);
    } else {
      open my $fh, "<", $name;
      $content = join('', <$fh>);
      close($fh);
    }
  } else {
    my $tmp = tmpnam();
    system($ENV{EDITOR} || "ed", $tmp);
    open my $fh, '<', $tmp or die "couldn't open temporary file: $!\n";
    $content = join('', <$fh>);
    close $fh;
  }
  return $content;
}

1;
