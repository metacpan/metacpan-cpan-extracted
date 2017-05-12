package Apache::Storage;

use strict;
use Apache::ModuleConfig;
use Apache::Constants qw(:common);
require DynaLoader;
require AutoLoader;
require Exporter;

use vars qw($VERSION @ISA @EXPORT);

@ISA = qw(DynaLoader Exporter);
$VERSION = '1.1';

@EXPORT = qw(set_storage get_storage get_storage_dump);

bootstrap Apache::Storage $VERSION;

sub ApacheStorageInit ($$) {
	my($cfg, $params) = @_;
	$cfg->{'longterm'} = {} unless (keys %{$cfg->{'longterm'}});
}

sub ApacheStore ($$$$) {
	my($cfg, $params, $key, $value) = @_;
	my $e_value = eval $value;
	if($@) {
		$cfg->{'longterm'}{$key} = $value
	} else {
		$cfg->{'longterm'}{$key} = $e_value;
	}

}

sub set_storage {
	my($key, $value) = @_;

	my $r = Apache->request;
	my $cfg = Apache::ModuleConfig->get($r);

	if (ref($key) eq 'HASH'){
		for(keys %$key) {
			$cfg->{'longterm'}{$_} = $key->{$_};
		}
	} else {
		$cfg->{'longterm'}{$key} = $value;
	}
}

sub get_storage {
	my($key) = @_;

	my $r = Apache->request;
	my $cfg = Apache::ModuleConfig->get($r);

	if (ref($key) eq 'ARRAY'){
		my @array;
		for(@$key) {
			push @array, $cfg->{'longterm'}{$_};
		}
		return \@array;
	} else {
		return $cfg->{'longterm'}{$key};
	}
}

sub get_storage_dump {
	my $r = Apache->request;
	my $cfg = Apache::ModuleConfig->get($r);

	return $cfg->{'longterm'};
}

# Believe it or not, this is hear for a reason
sub DESTROY {
}


1;

__END__

=head1 NAME

Apache::Storage - Storing data in Apache.

=head1 SYNOPSIS

  use Apache::Storage;

=head1 DESCRIPTION

Ever wanted to store information in Apache so
the additional requests could gain access to it?

For example, you create an object which is fairly
expensive and you don't want to have to
recreate each time, or say you just have some
information you are storing in a reference that
you want requests that follow you to see. 

This module is for you.

It has three functions described below. They allow
you to store and retrieve information from the
Apache process. The functions are fairly simple
and should make it pretty easy for you to do so
without to much hassle.

All of this works with subrequests, so unlike
pnotes, you don't need to worry about loosing
data if your request is subrequested by an outside
Apache module.

You can also use the ApacheStorage directive inside
of Apache to prime data into the Apache::Storage.

=head2 FUNCTIONS

Note

Keep in mind that data is only stored on the Apache
process itself. Different child processes all
have their own storage. Don't assume you will
get the same Apache child process when reconnecting.

Make sure you put a "PerlModule Apache::Storage" in
your httpd.conf file. Apache make core if you do
not do this.

=over 4

=item set_storage

Set functions can be called in two ways. They can be
called with a key and a reference. The reference will
then be available by calling it through a get function.
You can also pass in hash reference. The contents of
this hash will be mapped into storage based on it
original key pair. Nothing is returned by either of
these functions

=item get_storage

Get functions can be calling in two ways. They can either
be called with a single key, where they will return a 
single hash

=item get_storage_dump

This gives you a hash of the entire contents of 
what is being stored currently.


=back

=head2 Apache Directives

=over 4

=item ApacheStore

Takes two arguments, a key and a value. The value is
evaled.

=item ApacheStorageInit

Takes no values, and only needs to be used if
you don't have at least one ApacheStore 
call.

=back

=head1 Example

=over 4

=item httpd.conf

<VirtualHost 10.0.2.25:80>

    ServerAdmin root@tangent.org

    DocumentRoot /usr/local/apache/htdocs

    ServerName slash.tangent.org

    ErrorLog logs/error_log

    CustomLog logs/access_log common

    ApacheStoreINIT

</VirtualHost>

<VirtualHost 10.0.2.25:80>

    ServerAdmin root@tangent.org

    DocumentRoot /usr/local/apache/htdocs

    ServerName slash2.tangent.org

    ErrorLog logs/error_log

    CustomLog logs/access_log common

    ApacheStore foo "[qw(skdjf slkdjf lskdjf)]"

</VirtualHost>

=back

=head1 LICENSE

See the file LICENSE that this comes with.

=head1 SEE ALSO

perl(3).
mod_perl(3).

=head1 HOME

http://tangent.org/Apache-Storage/

=head1 Author

Brian Aker, brian@tangent.org

Seattle, WA.

=cut
