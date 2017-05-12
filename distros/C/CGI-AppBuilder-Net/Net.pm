package CGI::AppBuilder::Net;

use warnings;
use Net::Rexec 'rexec'; 

# require Exporter;
@ISA = qw(Exporter CGI::AppBuilder);
our @EXPORT = qw();
our @EXPORT_OK = qw(exec_cmd
    );
our %EXPORT_TAGS = (
  all      => [@EXPORT_OK],
  exec     => [qw(exec_cmd)],
);
$CGI::AppBuilder::Message::VERSION = 0.12;

=head1 NAME

CGI::AppBuilder::Net - Methods used for remote commands and network

=head1 SYNOPSIS

    my $self = bless {}, "main";
    use CGI::AppBuilder::Net;
    $self->debug_level(2);   # set debug level to 2
    # The level 3 message will not be displayed
    $self->echo_msg("This is level 1 message.", 1);
    $self->echo_msg("This is level 2 message.", 2);
    $self->echo_msg("This is level 3 message.", 3);  

=head1 DESCRIPTION

The package contains the modules can be used for executing UNIX commands
or initiate network connections.

=head2 new (ifn => 'file.cfg', opt => 'hvS:')

This is a inherited method from CGI::AppBuilder. See the same method
in CGI::AppBuilder for more details.

=cut

sub new {
  my ($s, %args) = @_;
  return $s->SUPER::new(%args);
}

=head2 exec_cmd ($cmd, $pr)

Input variables:

  $cmd - a full unix command with paraemters and arguments
  $pr  - parameter hash ref
    remote_host - Remote host name or ip address
    local_host  - local host name or ip address
    remote_usr  - Remote user name
    remote_pwd  - Remote user password

Variables used or routines called:

  get_params - get values for multiple parameters

How to use:

  use CGI::AppBuilder::Net qw(:all);
  # Case 1: hosts are different and without id and password 
  my $cmd = "cat /my/dir/file.txt"; 
  my $pr = {datafax_host=>'dfsvr',local_host='svr2'};  
  my @a = $self->exec_cmd($cmd,$pr);   # uses rsh to run the cmd 

  # Case 2: different hosts with id and password 
  my $pr = {datafax_host=>'dfsvr',local_host='svr2',
     datafax_usr=>'fusr', datafax_pwd=>'pwd' };  
  my @a = $self->exec_cmd($cmd,$pr);   # uses rexec  

  # Case 3: hosts are the same and just open a file
  my $pr = {datafax_host=>'dfsvr',local_host='dfsvr'};  
  my $ar = $self->exec_cmd('/my/file.txt',$pr); # case 2:  

  # Case 4: hosts are the same and run a program
  my $pr = {datafax_host=>'dfsvr',local_host='dfsvr'};  
  my $ar = $self->exec_cmd('cat /my/file.txt',$pr); # case 2:  


Return: array or array ref 

This method opens a file or runs a command and return the contents
in array or array ref.

=cut

sub exec_cmd {
    my $s = shift;
    my ($cmd, $pr) = @_;
    my $vs='remote_host,local_host,remote_usr,remote_pwd';
    my ($dfh,$lsv,$usr,$pwd) = $s->get_params($vs,$pr);
    $lsv = `hostname` if ! $lsv;
    my ($rc, @a);
    if ($dfh ne $lsv) { 
        # croak "ERR: no user name for remote access.\n" if ! $usr;
        # croak "ERR: no password for user $usr.\n"      if ! $pwd;
#        if ($usr && $pwd) {    # use rexec
#            $s->echo_msg("CMD: $cmd at $dfh for user $usr..."); 
#            ($rc, @a) = rexec($dfh, $cmd, $usr, $pwd);
#            $rc == 0 || $s->echo_msg("WARN: could not run $cmd on $dfh.");
#        } else {               # use rsh  
            my $u  = "rsh $dfh $cmd |";
            my $fh = new IO::File;
            $fh->open("$u")||$s->echo_msg("WARN: could not run $u: $!.");
            @a=<$fh>; close($fh);
#        }
    } else {                   # use perl module 
        $s->echo_msg("CMD: $cmd at $lsv...", 1); 
        my $fh = new IO::File;
        my @b = split /\s+/, $cmd; 
        $cmd .= '|' if $#b > 0;
        $fh->open("$cmd") || $s->echo_msg("WARN: could not run $cmd: $!.");
        @a=<$fh>; close($fh);
    }
    return wantarray ? @a : \@a; 
}

1;


=head1 CODING HISTORY

=over 4

=item * Version 0.10

Extracted exec_cmd from DataFax::StudySubs. 

=item * Version 0.11

No there yet.

=back

=head1 FUTURE IMPLEMENTATION

=over 4

=item * no plan yet 

=back

=head1 AUTHOR

Copyright (c) 2007 Hanming Tu.  All rights reserved.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

