#!/usr/bin/perl
package Cvs::Simple::Hook;
use strict;
use warnings;

{
my(%PERMITTED) = (
    'All'      => '',
    'add'      => '',
    'checkout' => '',
    'commit'   => '',
    'update'   => '',
    'diff'     => '',
    'status'   => '',
);
sub PERM_REQ () {
    my($patt) = join '|' => keys %PERMITTED;
    return qr/$patt/;
}

sub permitted ($) {
    return exists $PERMITTED{$_[0]} ? 1 : 0;
}

sub get_hook ($) {
    my($cmd)      = shift;

    my($PERM_REQ) = PERM_REQ;

    if(($cmd)=~/\b($PERM_REQ)\b/) {
        return $1;
    }
    else {
        return;
    }
}

}

1;

package Cvs::Simple;
use strict;
use warnings;
use Carp;
use Class::Std::Utils;
use Cvs::Simple::Config;
use FileHandle;

use vars  qw($VERSION);
use version; $VERSION = version->new( 0.06 );

{
    my(%cvs_bin_of);
    my(%external_of);
    my(%callback_of);
    my(%repos_of);

    sub new {
        my($class) = shift;
        my($self) = bless anon_scalar(), $class;
        $self->_init(@_);
        return $self;
    }

    sub _init {
        my($self) = shift;
        my(%args) = @_;

        if(exists $args{cvs_bin}) {
            $self->cvs_bin($args{cvs_bin});
        }
        else {
           $self->cvs_bin(Cvs::Simple::Config::CVS_BIN);
        }

        if(exists $args{external}) {
            $self->external($args{external});
        }
        elsif (Cvs::Simple::Config::EXTERNAL) {
            $self->external(Cvs::Simple::Config::EXTERNAL);
        }
        else {
            ();
        }

        if(exists $args{callback}) {
            $self->callback($args{callback});
        }
    }

    sub callback {
        my($self) = shift;
        my($hook) = shift;
        my($func) = shift;

        # If 'hook' is not supplied, callback is global, i.e. apply to all.
        $hook ||= 'All';

        unless(Cvs::Simple::Hook::permitted($hook)) {
            croak "Invalid hook type in callback: $hook.";
        }

        if(defined($func)) {
            UNIVERSAL::isa(($func), 'CODE') or do {
                croak "Argument supplied to callback() should be a coderef.";
            };
            $callback_of{ident $self}{$hook} = $func;
        }

        if(exists $callback_of{ident $self}{$hook}) {
            return $callback_of{ident $self}{$hook};
        }
        else {
            return;
        }
    }

    sub unset_callback {
        my($self) = shift;
        my($hook) = shift;

        unless(Cvs::Simple::Hook::permitted($hook)) {
            croak "Invalid hook type in unset_callback: $hook.";
        }

        return delete $callback_of{ident $self}{$hook};
    }

sub cvs_bin {
    my($self) = shift;

    if(@_==1) {
        $cvs_bin_of{ident $self} = shift; 
    }

    return $cvs_bin_of{ident $self};
}

sub cvs_cmd {
    my($self) = shift;
    my($cmd)  = shift;

    croak "Syntax: cvs_cmd(cmd)" unless (defined($cmd) && $cmd);

    STDOUT->autoflush;

    my($hook)= Cvs::Simple::Hook::get_hook $cmd;

    my($fh) = FileHandle->new("$cmd 2>&1 |");
    defined($fh) or croak "Failed to open $cmd:$!";

    while(<$fh>) {
        if(defined($hook)) {
            if($self->callback($hook)) {
                $self->callback($hook)->($cmd,$_);
            } 
            else {
                print STDOUT $_;
            }
        }
        else {
            if($self->callback('All')) {
                $self->callback('All')->($cmd, $_);
            }
            else {
                print STDOUT $_;
            }
        }
    }

    $fh->close;

    return 1;
}

sub merge {
# merge(old_rev,new_rev,file);
    my($self) = shift;
    my(@args) = @_;

    croak "Syntax: merge(old_rev,new_rev,file)"
        unless (@args && scalar(@args)==3);

    my($cmd) = $self->_cmd('-q update');
    $cmd .= sprintf("-j%s -j%s %s", @args);

    return $self->cvs_cmd($cmd);
}

sub undo {
    goto &backout;
}

sub backout {
# Revert to previous revision of a file, i.e. backout/undo change(s).
# backout(current_rev,revert_rev,file);
    my($self) = shift;
    my(@args) = @_;

    unless (@args && scalar(@args)==3) {
        croak <<SYN;
Syntax: backout(current_rev,revert_rev,file)
        undo   (current_rev,revert_rev,file)
SYN
    }

    return $self->merge(@args);
}

sub external {
    my($self)  = shift;

    if(@_==1) {
        $repos_of{ident $self} = shift;
    }
    return $repos_of{ident $self};
}

sub _cmd {
    my($self) = shift;
    my($type) = shift;

    my($cvs)  = $self->cvs_bin;

    my($cmd) = 
        $self->external  ?   sprintf("%s -d %s %s ", $cvs,$self->external,$type)
                         :   sprintf("%s %s ",       $cvs,$type);

    return $cmd;
}

sub add {
#   Can only be called as:
#    cvs add file1 [, .... , ]
    my($self) = shift;
    my(@args) = @_;

    croak "Syntax: add(file1, ...)" unless(@args);

    my($cmd) = $self->_cmd('add');

    if(@args) {
        $cmd .= join ' ' => @args;
    }

    return $self->cvs_cmd($cmd);
}

sub add_bin {
# Can only be called as :
#    cvs add -kb file1 [, .... , ]
    my($self) = shift;
    my(@args) = @_;

    croak "Syntax: add_bin(file1, ...)" unless (@args);

    my($cmd) = $self->_cmd('add -kb');

    if(@args) {
        $cmd .= join ' ' => @args;
    }

    return $self->cvs_cmd($cmd);
}

sub checkout {
# Can be called as:
#  cvs co module
#  cvs co -r tag module
#  Calling signature is checkout(tag,module) or checkout(module).
    my($self) = shift;
    my(@args) = @_;

    unless (@args && (scalar(@args)==2 || scalar(@args)==1)) {
    croak <<SYN;
Syntax: co(tag)
        co(module)
        checkout(tag)
        checkout(module)
SYN

    }

    my($cmd) = $self->_cmd('co');

    $cmd    .= @args==2         ?   sprintf("-r %s %s", @args)
                                :   sprintf("%s", @args);

    return $self->cvs_cmd($cmd);
}

sub co {
    goto &checkout;
}

sub _pattern {
    return join '' => ('%s ' x @{$_[0]});
}

sub commit {
# Can be called as :
# commit()
# commit([file_list])
# commit(tag1)
# commit(tag1, [file_list])
    my($self) = shift;
    my(@args) = @_;

    my($cmd) = $self->_cmd('commit -m ""');
    if(scalar(@args)==0) { # 'cvs commit -m ""'
        return $self->cvs_cmd($cmd);
    }
    elsif(@args==2) { # 'cvs commit -m "" -r TAG file(s)'
        croak "Syntax: commit([rev],[\@filelist])"
            unless (UNIVERSAL::isa($args[1], 'ARRAY'));
        my($pattern) = join '' => '-r %s ', _pattern($args[1]);
        $cmd .= sprintf($pattern, $args[0], @{$args[1]});
        return $self->cvs_cmd($cmd);
    }
    elsif(@args==1) { # 'cvs commit -m "" -r TAG' or 
                      # 'cvs commit -m "" file(s)'
        my($pattern);
        if(UNIVERSAL::isa($args[0], 'ARRAY')) {
            $pattern = sprintf(_pattern($args[0]), @{$args[0]});
        }
        else {
            $pattern = sprintf('-r %s', $args[0]);
        }

        $cmd .= $pattern;

        return $self->cvs_cmd($cmd);
    }
    else { # Anything else is an error
        croak <<SYN
Syntax: commit([rev],[\@filelist])
        ci    ([rev],[\@filelist])
SYN

    }
}

sub ci {
    goto &commit;
}

sub diff {
# Can be called as :
# diff(file_or_dir)
# diff(tag1,tag2,file_or_dir)
    my($self) = shift;
    my(@args) = @_;

    croak "Syntax: diff(file) or diff(tag1,tag2,file)"
        unless (@args && (scalar(@args)==1 || scalar(@args)==3));

    my($cmd) = $self->_cmd('diff -c');

    $cmd .=     @args==3    ?   sprintf("-r %s -r %s %s", @args)
                            :   sprintf("%s"            , @args);

    return $self->cvs_cmd($cmd);
}

sub status {
# status()
# status(file1, ... )
    my($self) = shift;
    my(@args) = @_;

    my($cmd) = $self->_cmd('status -v');

    if(@args) {
        $cmd .= join ' ' => @args;
    }

    return $self->cvs_cmd($cmd);
}

sub upd {
    goto &update;
}

sub update {
# update() -> update workspace (cvs -q update -d).
# update(file) -> update file  (cvs -q update file [file ... ]).
# Doesn't permit -r.
    my($self) = shift;
    my(@args) = @_;

    my($cmd) = $self->_cmd('-q update');

    $cmd .= @args   ? join ' ' => @args
                    : '-d';

    return $self->cvs_cmd($cmd);
}

    sub up2date {
    # Checks workspace status. No args.
        my($self) = shift;

        my($cmd) = $self->_cmd('-nq update -d');

        return $self->cvs_cmd($cmd);
    }

    sub DESTROY {
        my($self) = shift;
        delete($cvs_bin_of {ident $self});
        delete($external_of{ident $self});
        delete($callback_of{ident $self});

        return;
    }

}
1;
__END__
=pod

=head1 NAME

Cvs::Simple - Perl interface to cvs

=head1 SYNOPSIS

  use Cvs::Simple;

  # Basic usage:
  chdir('/path/to/sandbox')
    or die "Failed to chdir to sandbox:$!";
  my($cvs) = Cvs::Simple->new();
  $cvs->add('file.txt');
  $cvs->commit();

  # Callback

  my($commit_callback);
  my($commit) = 0;
  {
    my($file) = 'file.txt';
    ($commit_callback) = sub {
      my($cmd,$arg) = @_;
      if($arg=~/Checking in $file;/) { ++$commit }
    };
  }
  my($cvs) = Cvs::Simple->new();
  $cvs->callback(commit => $commit_callback);
  $cvs->add('file.txt');
  $cvs->commit();
  croak "Failed to commit file.txt" unless($commit);
  $cvs->unset_callback('commit');


=head1 DESCRIPTION

C<Cvs::Simple> is an attempt to provide an easy-to-use wrapper that allows cvs
commands to be executed from within a Perl program, without the programmer having to
wade through the (many) cvs global and command-specific options.

The methods provided follow closely the recipes list in "Pragmatic Version
Control with CVS" by Dave Thomas and Andy Hunt (see
L<http://www.pragmaticprogrammer.com/starter_kit/vcc/index.html>).

=head2 UTILITY METHODS

=over 4

=item new ( [ CONFIG_ITEMS ] )

Creates an instance of Cvs::Simple.

CONFIG_ITEMS is a hash of configuration items.  Recognised configuration items are:

=over 8

=item cvs_bin

=item external

=item callback

=back

See the method descriptions below for details of these.   If none are
specified, CVS::Simple will choose some sensible defaults.

=item callback ( CMD, CODEREF )

Specify a function pointed to by CODEREF to be executed for every line output
by CMD.  

Permitted values of CMD are C<All> (executed on every line of
output), C<add>, C<commit>, C<checkout>, C<diff>, C<update>.  CMD is also
permitted to be undef, in which case, it will be assumed to be C<All>.

cvs_cmd passes two arguments to callbacks:  the actual command called, and the
line returned by CVS.

See the tests for examples of callbacks.

=item 

=item unset_callback ( CMD )

Remove the callback set for CMD.

=item cvs_bin ( PATH ) 

Specifies the location and name of the CVS binary.  Default to
C</usr/bin/cvs>.

=item cvs_cmd ( )

cvs_cmd() does the actual work of calling the equivalent CVS command.  If any
callbacks have been set, they will be executed for every line received from
the command.  If no callbacks have been set, all output is to STDOUT.

=item external( REPOSITORY )

Specify an "external" repository.  This can be a genuinely remote
repository in C<:ext:user@repos.tld:/path/to/cvsroot> format, or an
alternative repository on the local host.  This will be passed to the C<-d>
CVS global option.

=back

=head2 CVS METHODS 

=over 4

=item add     ( FILE1, [ .... , FILEx ] )

=item add_bin ( FILE1, [ .... , FILEx ] )

Add a file or files to the repository; equivalent to C<cvs add file1, ....>,
or C<cvs add -kb file1, ...> in the case of add_bin().

=item co ( TAG, MODULE )

  Alias for checkout()

=item checkout ( MODULE )

=item checkout ( TAG, MODULE )

  Note that co() can be used as an alias for checkout().

=item ci

  Alias for commit().

=item commit ( )

=item commit ( FILELIST_ARRAYREF )

=item commit ( TAG )

=item commit ( TAG, FILELIST_ARRAYREF )

These are the equivalent of C<cvs commit -m "">, C<cvs commit -m "" file1, file2, ...., fileN>, C<cvs commit -r TAG -m ""> and C<cvs commit -r TAG -m "" file1, file2, ....,
fileN> respectively.

Note that ci() can be used as an alias for commit().

=item diff ( FILE_OR_DIR )

=item diff ( TAG1, TAG2, FILE_OR_DIR )

FILE_OR_DIR is a single file, or a directory, in the sandbox.

Performs context diff: equivalent to C<cvs diff -c FILE_OR_DIR> or C<cvs
diff -c -rTAG1 -rTAG2 FILE_OR_DIR>.

=item merge ( OLD_REV, NEW_REV, FILENAME )

This is the equivalent of C<cvs -q update -jOLD_REV -jNEW_REV FILENAME>.  Note
for callback purposes that this is actually an update().

=item backout ( CURRENT_REV, REVERT_REV, FILENAME )

=item undo ( CURRENT_REV, REVERT_REV, FILENAME )

Reverts from CURRENT_REV to REVERT_REV.  Equivalent to C<cvs update
-jCURRENT_REV -jREVERT_REV FILENAME>.

Note that backout() can be used as an alias for undo().

Note that for callback purposes this is actually an update().

=item upd 

  Alias for update().

=item update ( )

=item update ( FILE1, [ ...., FILEx ] );

Equivalent to C<cvs -q update -d> and C<cvs -d update file1, ..., filex>.

Note that updates to a specific revision (C<-r>) and sticky-tag resets (C<-A>) are not currently supported.

Note that upd() is an alias for update().

=item up2date ( )

Short-hand for C<cvs -nq update -d>.

=item status ( )

=item status( file1 [, ..., ... ] )

Equivalent to C<cvs status -v>.

=back

=head2 EXPORT

None by default.

=head1 LIMITATIONS AND CAVEATS

=over 4

=item 1. Note that C<Cvs::Simple> carries out no input validation; everything is
passed on to CVS.  Similarly, the caller will receive no response on the
success (or otherwise) of the transaction, unless appropriate callbacks have
been set.

=item 2. The C<cvs_cmd> method is quite simplistic; it's basically a pipe from
the equivalent CVS command line (with STDERR redirected).  If a more
sophisticated treatment, over-ride C<cvs_cmd>, perhaps with something based on
C<IPC::Run> (as the L<Cvs> package does).

=item 3. This version of C<Cvs::Simple> has been developed against cvs version
1.11.19.  Command syntax may differ in other versions of cvs, and
C<Cvs::Simple> method calls may fail in unpredictable ways if other versions
are used.   Cross-version compatibiility is something I intend to address in a
future version.

=item 4. The C<diff>, C<merge>, and C<undo> methods lack proper tests.  More
tests are required generally.

=back

=head1 SEE ALSO

cvs(1), L<Cvs>, L<VCS::Cvs>

=head1 AUTHOR

Stephen Cardie, E<lt>stephenca@ls26.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007,2008 by Stephen Cardie

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
