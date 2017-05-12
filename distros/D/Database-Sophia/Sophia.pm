package Database::Sophia;

use utf8;
use strict;
use vars qw($AUTOLOAD $VERSION $ABSTRACT @ISA @EXPORT);

BEGIN {
	$VERSION = 0.9;
	$ABSTRACT = "Sophia is a modern embeddable key-value database designed for a high load environment (XS for Sophia)";
	
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		SPDIR SPALLOC SPCMP SPPAGE SPGC SPGCF
		SPGROW SPMERGE SPMERGEWM SPMERGEFORCE SPVERSION
		SPO_RDONLY SPO_RDWR SPO_CREAT SPO_SYNC
		SPGT SPGTE SPLT SPLTE
	);
};

bootstrap Database::Sophia $VERSION;

use DynaLoader ();
use Exporter ();

1;


__END__

=head1 NAME

Database::Sophia - Sophia is a modern embeddable key-value database designed for a high load environment (XS for Sophia)

=head1 SYNOPSIS

 
 use Database::Sophia;
 
 my $env = Database::Sophia->sp_env();
 
 my $err = $env->sp_ctl(SPDIR, SPO_CREAT|SPO_RDWR, "./db");
 die $env->sp_error() if $err == -1;
 
 my $db = $env->sp_open();
 die $env->sp_error() unless $db;
 
 $err = $db->sp_set("login", "lastmac");
 print $db->sp_error(), "\n" if $err == -1;
 
 my $value = $db->sp_get("login", $err);
 
 if($err == -1) {
 	print $db->sp_error(), "\n";
 }
 elsif($err == 0) {
 	print "Key not found", "\n";
 }
 elsif($err == 1) {
 	print "Key found", "\n";
 	print "login: ", $value, "\n";
 }
 
 $db->sp_destroy();
 $env->sp_destroy();
 

=head1 DESCRIPTION

It has unique architecture that was created as a result of research and rethinking of primary algorithmic constraints, associated with a getting popular Log-file based data structures, such as LSM-tree.

See http://sphia.org/

This module uses Sophia v1.1. See http://sphia.org/v11.html

=head1 METHODS

=head2 sp_env

create a new environment handle

 my $env = Database::Sophia->sp_env();


=head2 sp_ctl

configurate a database

=head3 SPDIR

Sets database directory path and it's open flags to use by sp_open().

 $env->sp_ctl(SPDIR, SPO_CREAT|SPO_RDWR, "./db");

=item Possible flags are:

SPO_RDWR   - open repository in read-write mode (default)

SPO_RDONLY - open repository in read-only mode

SPO_CREAT  - create repository if it is not exists.

=back


=head3 SPCMP

Sets database comparator function to use by database for a key order determination.

 my $sub_cmp = sub {
	my ($key_a, $key_b, $arg) = @_;
 }
 
 $env->sp_ctl(SPCMP, $sub_cmp, "arg to callback");


=head3 SPPAGE

Sets database max key count in a single page. This option can be tweaked for performance.

 $env->sp_ctl(SPPAGE, 1024);


=head3 SPGC

Sets flag that garbage collector should be turn on.

 $env->sp_ctl(SPGC, 1);


=head3 SPGCF

Sets database garbage collector factor value, which is used to determine whether it is time to start gc.

 $env->sp_ctl(SPGCF, 0.5);


=head3 SPGROW

Sets new database files initial new size and resize factor. This values are used while database extend during merge.

 $env->sp_ctl(SPGROW, 16 * 1024 * 1024, 2.0);


=head3 SPMERGE

Sets flag that merger thread must be created during sp_open().

 $env->sp_ctl(SPMERGE, 1);


=head3 SPMERGEWM

Sets database merge watermark value.

 $env->sp_ctl(SPMERGEWM, 200000);


=head2 sp_open

Open or create a database

 my $db = $env->sp_open();

On success, return database object; On error, it returns undef.


=head2 sp_error

Get a string error description

 $env->sp_error();


=head2 sp_destroy

Free any handle

 $ptr->sp_destroy();


=head2 sp_begin

Begin a transaction

 $db->sp_begin();


=head2 sp_commit

Apply a transaction

 $db->sp_commit();


=head2 sp_rollback

Discard a transaction changes

 $db->sp_rollback();


=head2 sp_set

Insert or replace a key-value pair

 $db->sp_set("key", "value");


=head2 sp_get

Find a key in a database

 my $error;
 $db->sp_get("key", $error);


=head2 sp_delete

Delete key from a database

 $db->sp_delete("key");


=head2 sp_cursor

create a database cursor

 my $cur = $db->sp_cursor(SPGT, "key");

=item Possible order are:

SPGT  - increasing order (skipping the key, if it is equal)

SPGTE - increasing order (with key)

SPLT  - decreasing order (skippng the key, if is is equal)

SPLTE - decreasing order

=back

After a use, cursor handle should be freed by $cur->sp_destroy() function.


=head2 sp_fetch

Iterate a cursor

 $cur->sp_fetch();


=head2 sp_key

Get current key

 $cur->sp_key()


=head2 sp_keysize

 $cur->sp_keysize()


=head2 sp_value

 $cur->sp_value()


=head2 sp_valuesize

 $cur->sp_valuesize()


=head1 Example

=head2 sp_open

 use Database::Sophia;
 
 my $env = Database::Sophia->sp_env();
 
 my $err = $env->sp_ctl(SPDIR, SPO_CREAT|SPO_RDWR, "./db");
 die $env->sp_error() if $err == -1;
 
 my $db = $env->sp_open();
 die $env->sp_error() unless $db;

=head2 sp_error

 my $db = $env->sp_open();
 die $env->sp_error() unless $db;


=head2 sp_destroy

 $db->sp_destroy();
 $cur->sp_destroy();
 $env->sp_destroy();


=head2 sp_begin

 my $rc = $db->sp_begin();
 print $env->sp_error(), "\n" if $rc == -1;
 
 $rc = $db->sp_set("key", "value");
 print $env->sp_error(), "\n" if $rc == -1;
 
 $rc = $db->sp_commit();
 print $env->sp_error(), "\n" if $rc == -1;


=head2 sp_commit

See sp_begin


=head2 sp_rollback

 my $rc = $db->sp_begin();
 print $env->sp_error(), "\n" if $rc == -1;
 
 $rc = $db->sp_set("key", "value");
 print $env->sp_error(), "\n" if $rc == -1;
 
 $rc = $db->sp_rollback();
 print $env->sp_error(), "\n" if $rc == -1;


=head2 sp_set

 $rc = $db->sp_set("key", "value");
 print $env->sp_error(), "\n" if $rc == -1;


=head2 sp_get

 my $error;
 my $value = $db->sp_get("key", $error);
 
 if($error == -1) {
 	print $db->sp_error(), "\n";
 }
 elsif($error == 0) {
 	print "Key not found", "\n";
 }
 elsif($error == 1) {
 	print "Key found", "\n";
 	print "key: ", $value, "\n";
 }


=head2 sp_fetch

 my $cur = $db->sp_cursor(SPGT, "key");
 
 while($cur->sp_fetch()) {
 	print $cur->sp_key(), ": ", $cur->sp_value();
	print $cur->sp_keysize(), ": ", $cur->sp_valuesize();
 }
 
 $cur->sp_destroy();


=head2 sp_key

See sp_fetch


=head2 sp_keysize

See sp_fetch


=head2 sp_value

See sp_fetch


=head2 sp_valuesize

See sp_fetch


=head1 DESTROY

 undef $obj;

Free mem and destroy object.

=head1 AUTHOR

Alexander Borisov <lex.borisov@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alexander Borisov.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

See libsophia license and COPYRIGHT
http://sphia.org/


=cut
