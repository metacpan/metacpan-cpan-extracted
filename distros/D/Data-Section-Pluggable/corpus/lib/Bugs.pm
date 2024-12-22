package Bugs;

BEGIN { die "this should not compile" }

__DATA__
@@ foo.txt
Hello World!
__END__
