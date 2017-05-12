###########################################################################
## Copyright (c) 2000 David Lowe
##
## Backhand.pm
##
## The perl side of the Apache::Backhand module
###########################################################################
package Apache::Backhand;

use strict;

$Apache::Backhand::VERSION = '0.02';

use Exporter;

require DynaLoader;
require AutoLoader;

@Apache::Backhand::ISA = qw(DynaLoader Exporter);

@Apache::Backhand::EXPORT_OK = qw(MAXSERVERS
                                  MAXSESSIONSPERSERVER
                                  SERVER_TIMEOUT
                                  load_serverstats
                                  load_personal_arriba);

bootstrap Apache::Backhand $Apache::Backhand::VERSION;

1;

__END__

=head1 NAME

Apache::Backhand - Bridge between mod_backhand and mod_perl

=head1 SYNOPSIS

 (in httpd.conf)
 PerlModule Apache::Backhand
 ...
 BackhandFromSO libexec/byPerl.so byPerl Package::function

 (in Package.pm)
 sub function {
     my ($r, $s)   = @_;
     my (@servers) = @{$s};
     my $serverstats     = Apache::Backhand::load_serverstats();
     my $personal_arriba = Apache::Backhand::load_personal_arriba();

     # modify @servers...
 
     return(\@servers);
 }

 (the following constants are also provided...)
 Apache::Backhand::MAXSERVERS;
 Apache::Backhand::MAXSESSIONSPERSERVER;
 Apache::Backhand::SERVER_TIMEOUT;

=head1 DESCRIPTION

Apache::Backhand ties mod_perl together with mod_backhand, in two major ways.
First, the Apache::Backhand module itself provides access to the global and
shared state information provided by mod_backhand (most notably serverstats).
Second, the byPerl C function (which is not part of the Apache::Backhand
module, but is distributed together with it) allows you to write candidacy
functions in Perl.

Apache::Backhand will crash your perl interpreter if you attempt to load it
into a perl binary which isn't also part of apache, with both mod_perl and
mod_backhand loaded.  You'll get 'unresolved symbol' errors, or whatever their
equivalent is on your system.  This may seem obvious, but it has a less obvious
side effect, which is that you cannot load Apache::Backhand until *after*
mod_backhand is loaded.  That is, the 'PerlModule Apache::Backhand' line must
come after 'LoadModule backhand_module libexec/mod_backhand.so'.

Here are the two major functions provided by Apache::Backhand:

=over 3

=item B<load_serverstats>

This function returns a reference to an array of MAXSERVERS references to
hashes, the keys of which are:

=over 3

=item mtime

Last modification time of this stat structure (the last time we heard from
the server - used to decide if the server is alive)

=item arriba

Speed of the server

=item aservers

Number of available apache servers

=item nservers

Number of running apache servers

=item load

Load average (multiplied by 1000)

=item load_hwm

The supremim integral power of 2 of the load seen thus far

=item cpu

CPU idle time (multiplied by 1000)

=item ncpu

Number of CPU

=item tmem

Total memory in bytes

=item amem

Available memory in bytes

=item numbacked

Number of requests backhanded

=item tatime

Averages time (in milliseconds) to serve a backhanded request

=back

This structure sounds worse than it is.  It's really quite simple to use:

  foreach my $server ($serverstats) {
      print $server->{'mtime'}, "\n";
      $server->{'load'} += 1;
  }

Note that each of the elements of the hashes is magically tied directly (for
both reads and writes) into the shared memory segment where serverstats
resides.  You can call load_serverstats() once, and use the returned structure
as much as you want - it will always reflect the contents of the underlying
shared structure.  This has one drawback, however, which is that you cannot
call load_serverstats() until after the shared memory segment has been created
and attached.  I recommend a PerlChildInit handler to do load_serverstats()
into a global variable.

=item B<load_personal_arriba>

This function returns a reference to a scalar variable which is magically
tied to the global mod_backhand_personal_arriba integer.  This contains the
arriba speed of the local machine.

=back

=head1 CAVEATS

As explained above, you cannot PerlModule or use() or require()
Apache::Backhand until *after* mod_backhand (and mod_perl, of course) are
linked into the server.

As explained above, you cannot call load_serverstats() until *after* the
shared memory segment has been created and attached.  The best place to do
this is the child init phase.

It's easy to make mod_backhand coredump by doing Bad Things to serverstats
(e.g. 'foreach (@{$serverstats}) { $_->{'mtime'} = time() }'...)
Even though I've provided the magic to make serverstats writeable, this should
be treated with care.

There is necessarily going to be a small amount of overhead when calling perl
candidacy functions.  I highly recommend calling byAge *before* calling any
perl candidacy functions, because converting the server list into a perl array
and back again is one of the most expensive operations byPerl has to perform,
and byAge tends to knock out a lot of unnecessary work.

=head1 BUGS

Hopefully none.

=head1 AUTHOR

J. David Lowe, dlowe@pootpoot.com

=head1 SEE ALSO

perl(1)

=cut
