package Daemonise;

use 5.008008;
use strict;
use warnings;
use POSIX qw(setsid);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.0-1';

sub daemonise {
    chdir '/'                 or die "Can't chdir to /: $!";
    umask 0;
    open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
    #open STDOUT, '>/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>/dev/null' or die "Can't write to /dev/null: $!";    
    defined(my $pid = fork)   or die "Can't fork: $!";
    exit if $pid;
    setsid                    or die "Can't start a new session: $!";    
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Daemonise - Perl extension for convenience to daemonise a script

=head1 SYNOPSIS

  use Daemonise;
  my $daemon = Daemonise;
  $daemon->daemonise;
  

=head1 DESCRIPTION

Include daemonisation code to a script. I wrote lots of projects
which required daemonisation, so I created this module out of convenience.

=head2 EXPORT

None by default.



=head1 SEE ALSO

www.google.com

=head1 AUTHOR

Andy Dixon, <lt>ajdixon@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Andy Dixon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
