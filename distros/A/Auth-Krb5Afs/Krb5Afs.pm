#! /usr/bin/perl -w
# Auth::Krb5Afs - get krb5 and afs tokens
# Noel Burton-Krahn <noel@bkbox.com>
# Dec 14, 2003
#
# see the pos docs at the __END__
# 
# Copyright (C) 2003 Noel Burton-Krahn <noel@bkbox.com>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package Auth::Krb5Afs;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our $VERSION = '1.0';

sub new {
    bless({}, shift);
}

sub shell_esc {
    my($s) = @_;
    $s =~ s/'/'"'"'/g;
    $s = "'$s'";
    return $s;
}

sub authenticate {
    my($self) = shift;
    my($user, $pass, $service) = @_;
    my($s, $err, $pid);
    my(%pwent);

    TRY: {
	unless( @pwent{qw(name passwd uid gid
			  quota comment gcos home 
			  shell expire)} = getpwnam($user) ) {
	    $err->{user} = "no such user: $user";
	    last;
	}

	$pid = open(W, "|kinit -r 10h -l 20m " . shell_esc($user) . " >/dev/null 2>&1");
	print(W "$pass\n");
	close(W);
	if( $? ) {
	    $s =~ s/kinit.*?://;
	    $err->{pass} = "unknown user or wrong password";
	    last;
	}
	
	$s = `aklog -setpag 2>&1`;
	if( $? ) {
	    $err->{pass} = "aklog failed: $s";	
	}

	# set the environment (remember to set the uid last)
	$ENV{USER} = $pwent{name};
	$ENV{HOME} = $pwent{home};
	$ENV{SHELL} = $pwent{shell};
	
	if( $> == 0 ) {
	    if( -f $ENV{KRB5CCNAME} ) {
		chown($pwent{uid}, $pwent{gid}, $ENV{KRB5CCNAME}) or die("chown $ENV{KRB5CCNAME}: $!");
	    }
	    $( = $) = $pwent{gid};
	    my $id = `id -G '$pwent{name}'`;
	    $( = $pwent{gid};
	    $) = "$pwent{gid} $id";
	    $< = $> = $pwent{uid};
	}

	# done ok
	$err = undef;
    }
    return wantarray ? ($err, \%pwent) : $err;
}

1;

__END__


=pod

=head1 NAME

Auth::Krb5Afs - get Krb5 and OpenAFS tokens

=head1 SYNOPSIS

 use Auth::Krb5Afs;
 my ($err, $pwent) = Auth::Krb5Afs->authenticate($user, $pass);

=head1 DESCRIPTION

invokes kinit and aklog to get Kerberos 5 and OpenAFS tickets

=head1 METHODS

=over 4

=item $auth = Auth::Krb5Afs->new();

Create a new instance.  You could also use
Auth::Krb5Afs->authenticate() without an instance variable.

=item ($err, $pwent) = $auth->authenticate($user, $pass);

invokes "kinit" and "aklog" to get krb5 and afs tokens.  By
default, the krb5 ticket is good for 20 minutes, renewable up to
10 hours.

If successful, sets the USER, HOME, and SHELL environment variables,
the current uid and gid, and chdirs to HOME.

In an array context, returns an array ref to the result from getpwuid($afs_uid).

In a scalar context, returns error strings in a hash like 
$err->{pass} = "unknown user or wrong password";

=back

=head1 TESTING

The bin/authkrb5afs program behaves like one of courier's authlib
modules.  It reads password etc from file descriptor 3, then invokes
the rest of its command line as the user.

 printf 'imap\nlogin\ntest_user\ntest_pass\n' | 
 KRB5CCNAME=/tmp/t$RANDOM.krb5cc authkrb5afs klist 3<&1

=head1 AUTHOR

 Noel Burton-Krahn <noel@bkbox.com>
 Dec 14, 2002

=head1 SEE ALSO

kinit(1), alog(1), authlib(7), Apache::AuthKrb5Afs(3)

=head1 COPYRIGHT

Copyright (C) 2003 Noel Burton-Krahn <noel@bkbox.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
