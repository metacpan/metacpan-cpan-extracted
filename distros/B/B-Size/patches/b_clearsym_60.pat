--- ext/B/B.pm~	Sun Jul 25 23:52:41 1999
+++ ext/B/B.pm	Tue Aug  3 11:53:58 1999
@@ -113,6 +113,10 @@
     $symtable{sprintf("sym_%x", $$obj)} = $value;
 }
 
+sub clearsym {
+    %symtable = ();
+}
+
 sub objsym {
     my $obj = shift;
     return $symtable{sprintf("sym_%x", $$obj)};
--- ext/B/B/Terse.pm~	Tue Jul 20 10:17:54 1999
+++ ext/B/B/Terse.pm	Tue Aug  3 11:55:34 1999
@@ -17,6 +17,7 @@
 sub compile {
     my $order = shift;
     my @options = @_;
+    B::clearsym();
     if (@options) {
 	return sub {
 	    my $objname;
--- ext/B/B/Bblock.pm~	Sun Jul 25 23:55:09 1999
+++ ext/B/B/Bblock.pm	Tue Aug  3 11:55:52 1999
@@ -129,6 +129,7 @@
 
 sub compile {
     my @options = @_;
+    B::clearsym();
     if (@options) {
 	return sub {
 	    my $objname;
--- ext/B/B/Debug.pm~	Tue Jul 20 10:17:54 1999
+++ ext/B/B/Debug.pm	Tue Aug  3 11:56:13 1999
@@ -247,6 +247,7 @@
 
 sub compile {
     my $order = shift;
+    B::clearsym();
     if ($order eq "exec") {
         return sub { walkoptree_exec(main_start, "debug") }
     } else {
