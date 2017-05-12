# ABSTRACT: Module that provides simple named locks
package App::Highlander;
$App::Highlander::VERSION = '0.003';
use strict;
use warnings;

use English qw(-no_match_vars);
use Fcntl qw(:flock);
use File::Temp qw/tempdir/; 
use Path::Tiny;

our $LOCKDIR;
sub import {
   my ($self, %args) = @_;

   _create_if_not_exists(
      $LOCKDIR = $args{LOCKDIR} // tempdir( CLEANUP => 1 )
   );
   print "LOCKDIR='$LOCKDIR'\n";
   return;
}

our $LOCKFILE;
sub get_lock {
   my ($lock_string) = @_;
   $lock_string = _build_lock_string($lock_string);
   
   open $LOCKFILE, '>>', $lock_string
      or die "Unable to create LOCKFILE '$lock_string': $!";

   my $got_lock;
   if ( $got_lock = flock($LOCKFILE, LOCK_EX|LOCK_NB) ) {
      print {$LOCKFILE} $PID;
   }
   
   return $got_lock ? $lock_string : 0;
}

sub release_lock {
   my ($lock_string) = @_;
   return unless _have_lock($lock_string); 

   $lock_string = _build_lock_string($lock_string);
   return close($LOCKFILE) && unlink($lock_string) 
      ? $lock_string 
      : 0;
}

sub _have_lock {
   my ($lock_string) = @_;
   $lock_string = _build_lock_string($lock_string);

   my $PID_PATTERN = qr/^$PID/;
   return -e $lock_string && `cat $lock_string` =~ m/$PID_PATTERN/;
}

sub _build_lock_string {
   my ($lock_string) = @_;
   $lock_string //= '';
   
   my ($normalized_programname) = $PROGRAM_NAME;
   $normalized_programname =~ s|^.*/||;
   $normalized_programname =~ s|\..*$||;
   
   my $lock_name = join ':', 
      ($lock_string || ()),"${normalized_programname}.lock";
   return path($LOCKDIR, $lock_name)->canonpath;
}

sub _create_if_not_exists {
   my ($dir) = @_;
   return if -e $dir;

   mkdir $dir, 0755
      or die "Unable to make directory '$dir': $OS_ERROR";

   return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Highlander - Module that provides simple named locks

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 use App::Highlander; 

 App::Highlander::get_lock();

 # ...

 App::Highlander::release_lock(); 

or 

 use App::Highlander; 

 my $has_lock = App::Highlander::get_lock('lockstring');
 while ( ! $has_lock ) {
    sleep 10;
    $has_lock = App::Highlander::get_lock('lockstring');
 }
 # ... code ...

 App::Highlander::release_lock('lockstring');

or

 use App::Highlander LOCKDIR => "$ENV{HOME}/.locks";
 
 ...

=head1 DESCRIPTION

Simple module that provides a named locking mechanism based on flock. Application code requests a lock, then executes, then releases the lock. Lockfiles are stored in a temporary directory created by File::Temp::tempdir( CLEANUP => 1 ) by default. You can optionally use a different LOCKDIR directory when using App::Highlander by specifying the LOCKDIR option. Keep in mind that any directory you specify needs to exist and the user running the Highlander'd script needs to have write and read permisissions on files in that directory.

App::Highlander does *not* currently (and may never) handle errors, this means that if your application dies under Highlander then it will not have released the lock. Application code will need to capture the error with eval or a sugary module like Try::Tiny then explicitly release the lock.

=head1 NAME

App::Highlander

=head1 METHODS 

=over 4

=item C<get_lock>

Attempts to get a lock on the supplied lock string. If no lock string is supplied then $PROGRAM_NAME will be used. Locks are written to a temporary directory or LOCKDIR if one was specified
Returns the name of the lock file that was created.

=item C<release_lock>

Attempts to release a lock on the suppplied lock string. If no lock string is supplied then $PROGRAM_NAME will be used. Releasing the lock will close the open filehandle is that was used for flock and delete the lockfile
Returns the name of the lock file that was destroyed.

=back

=head1 ISSUES

Issues (bugs or feature requests) should be created on the github repo: https://github.com/mcmillhj/App-Highlander/issues

=head1 AUTHOR

Hunter McMillen <mcmillhj@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Hunter McMillen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
