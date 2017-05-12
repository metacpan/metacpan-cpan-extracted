package App::Index;

use strict;
use warnings;

sub new {
    my($class,$self)=(shift,{@_});
    bless($self,$class);
    $self;
}

sub pre_run {
    print "Content-Type: text/html;charset=Shift_JIS\n\n";
}

sub error_mode {
}

sub teardown {
}

sub setup {
    my $self = shift;
    my $mode = shift;
    my %run_mode = (
        'index' => 'do_index',
        'next'  => 'do_next',
        'back'  => 'do_index',
    );
    return $run_mode{$mode};
}

sub inner_method {
    return "This is inner method!!";
}

sub do_index {
    my $self = shift;

    my $ret_val = $self->inner_method;

    return <<"__HTML__";
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
<title>Index page</title>
</head>
<body>
  <p>Index Page</p>
  <a href="http://localhost/cgi-bin/MyFramwork/sample/sample.cgi/Index/next">Next page</a>
  <p>$ret_val</p>
</body>
</html>
__HTML__
}

sub do_next {
    my $self = shift;
    return <<"__HTML__";
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
<title>Next page</title>
</head>
<body>
  <p>Next Page</p>
  <a href="http://localhost/cgi-bin/MyFramwork/sample/sample.cgi/Index/back">Back page</a>
</body>
</html>
__HTML__
}

1;

