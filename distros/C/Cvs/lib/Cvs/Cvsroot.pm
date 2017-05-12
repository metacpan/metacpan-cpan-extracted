package Cvs::Cvsroot;

use strict;
use File::Temp;
use base qw(Class::Accessor);

Cvs::Cvsroot->mk_accessors(qw(cvsroot method password fingerprint passphrase));

sub new
{
    my($proto, $cvsroot, %conf) = @_;

    return unless defined $cvsroot;
    my $class = ref $proto || $proto;
    my $self = {};
    bless($self, $class);

    $self->{cvsroot} = $cvsroot;

    if($cvsroot =~ /^\//)
    {
        $self->{method} = 'filesystem';
    }
    elsif($cvsroot =~ /^\:pserver\:/)
    {
        $self->{method} = 'pserver';
        $self->{password} = $conf{password};
    }
    elsif($cvsroot =~ /^(?:.*\@)?.+:.*$/)
    {
        $conf{'remote-shell'} ||= 'ssh';
        if($conf{'remote-shell'} =~ /(ssh|rsh)$/)
        {
            $self->{'remote-shell'} = $conf{'remote-shell'};
            $self->{method} = $1;
            if($self->{method} eq 'ssh')
            {
                $self->{password} = $conf{password};
                $self->{fingerprint} = $conf{fingerprint};
                $self->{passphrase} = $conf{passphrase};
            }
        }
        else
        {
            warn 'unknown remote-shell: ' . $conf{'remote-shell'};
            return;
        }
    }
    else
    {
        warn "not implemented cvsroot method: $cvsroot";
        return;
    }

    return $self;
}

sub bind
{
    my($self, $cmd) = @_;

    my $debug = $cmd->cvs->debug();
    if($debug)
    {
        print STDERR "Binding CVSROOT handlers\n";
        print STDERR "CVSROOT access method is: $self->{method}\n";
    }
    my $init_context = $cmd->initial_context();

    if(defined $self->{'remote-shell'})
    {
        $ENV{CVS_RSH} = $self->{'remote-shell'};
    }

    if($self->{method} eq 'pserver')
    {
        $init_context->push_handler
        (
         qr/^cvs .*: used empty password; /, sub
         {
             if(defined $self->{password})
             {
                 if($cmd->cvs->login->success())
                 {
                     # The former command failed because it wasn't
                     # logged. So we need to relaunch it internally
                     $cmd->restart();
                 }
                 else
                 {
                     $cmd->err_result('pserver login failure');
                     return $init_context->finish();
                 }
             }
             else
             {
                 $cmd->err_result('you have to login.');
                 return $init_context->finish();
             }
         }
        );
    }
    elsif($self->{method} eq 'ssh')
    {
        # without pty, ssh call the ssh-askpass program to grab needed
        # informations from user. In batch mode it's not possible, so
        # we rewrite an ssh-askpass in a shell script stored in a
        # temporary file and we tell ssh to call it.
        my($fh, $file) = File::Temp::tmpnam()
          or die "can't create a temporary file";
        print STDERR "Creating askpass script `$file'\n"
          if $debug;
        chmod(0700, $file);
        $fh->print("#!/bin/sh\n");
        $fh->print("echo \$1|grep -iq password&&echo $self->{password}&&exit\n");
        $fh->print("echo \$1|grep -iq passphrase&&echo $self->{passphrase}&&exit\n");
        $fh->print("echo yes\n");
        $fh->close();
        $cmd->push_cleanup(sub
        {
            print STDERR "Deleting askpass script `$file'\n"
              if $debug;
            unlink $file
        });
        $ENV{SSH_ASKPASS} = $file;
        # ssh doesn't tell ssh-askpass until the DISPLAY environment
        # isn't set, so we have to set it to something (see ssh's
        # manual for more details).
        $ENV{DISPLAY} = '';

        my $ssh_context = $cmd->new_context();
        my $fingerprint;

        # building a combo pattern for all ssh error starting with the
        # string "ssh: "
        my $error_patterns = join
          ('|',
           '.*: Name or service not known',
           'connect to address [\d.]+ port \d+: Connection refused',
          );
        $init_context->push_handler
        (
         qr/^ssh: (?:$error_patterns)/, sub
         {
             $cmd->err_result(shift->[0]);
             return $init_context->finish();
         }
        );

        $init_context->push_handler
        (
         qr/Could not create directory/, sub
         {
             # Hint: this can happened where the home directory isn't writable
         }
        );
        $init_context->push_handler
        (
         qr/^Enter passphrase for key/, sub
         {
             $cmd->send($self->{passphrase});
         }
        );

        $init_context->push_handler
        (
         # maybe ssh version defendant...
         qr/'s password:/, sub
         {
             $cmd->send("$self->{password}\n");
         }
        );
        $init_context->push_handler
        (
         qr/Permission denied/, sub
         {
             $cmd->err_result('ssh: authentication failure');
             return $init_context->finish();
         }
        );
        $init_context->push_handler
        (
         qr/^The authenticity of host .* can't be established\./, sub
         {
             return $ssh_context;
         }
        );
        $ssh_context->push_handler
        (
         qr/key fingerprint is ([a-f\d:]+)\./, sub
         {
             $fingerprint = shift->[1];
         }
        );
        $ssh_context->push_handler
        (
         qr/^Are you sure you want to continue connecting/, sub
         {
             if(defined $fingerprint && defined $self->{fingerprint})
             {
                 if($fingerprint eq $self->{fingerprint})
                 {
                     $cmd->send("yes\n");
                 }
                 else
                 {
                     $cmd->send("no\n");
                 }
             }
             else
             {
                 $cmd->send("yes\n");
             }
         }
        );
        $ssh_context->push_handler
        (
         qr/Host key verification failed\./, sub
         {
             $cmd->err_result('ssh: '.shift->[0]);
             return $ssh_context->finish();
         }
        );
        $ssh_context->push_handler
        (
         qr/Warning: Permanently added .* to the list of known hosts\./, sub
         {
             # fallback to initial context
             return $init_context;
         }
        );
    }
}

1;
=pod

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=head1 COPYRIGHT

Copyright (C) 2003 - Olivier Poitrey

