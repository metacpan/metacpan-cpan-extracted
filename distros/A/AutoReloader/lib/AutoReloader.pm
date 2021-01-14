=head1 NAME

AutoReloader - Lazy loading and reloading of anonymous subroutines

=head1 SYNOPSIS

    use AutoReloader;
    my $sub = AutoReloader -> new ($file, $checksub, $autoprefix);
    $result = $sub -> (@args);

    $sub -> check (0);           # turn source file checking off for $sub
    $sub -> checksub ($coderef); # provide alternative checking routine

    use AutoReloader qw (AUTOLOAD);
    AutoReloader -> check (1);      # turn source file checking on
    $result = somefunc (@args);
    *somefunc{CODE}->check(0);   # turn off checking for this named sub

=head1 DESCRIPTION

AutoReloader provides lazy loading like AutoLoader, but for function files
which return an anonymous subroutine upon require. 

Before requiring that file, it is checked via some subroutine returning
a value (default is mtime). The returned value is remembered. At each 
call to that sub the check subroutine is run again, and if the returned
value changed, the source file is reloaded.

Importing the AUTOLOAD method provides for lazy loading of anonsubs as 
named subs. The wrapped anonsub will be assigned to a symbol table entry
named after the filename root of the function source file.

=head1 METHODS

=over 4

=item new ($file, $checksubref, $autoprefix)

subroutine constructor. $file can be the path to some function file or
a function name which will be expanded to $autoprefix/__PACKAGE__/$function.al
and searched for in @INC. $checksubref and $autoprefix are optional.
If they are not provided, the default class settings are used. 

=item auto ($autoprefix)

set or get the default autoprefix. Default is 'auto', just as with AutoLoader:
for e.g. POSIX::rand the source file would be auto/POSIX/rand.al . AutoReloader
lets you replace the 'auto' part of the path with something else. Class method
(for now).

=item suffix ($suffix)

set or get the suffix of your autoloaded files (e.g. '.al', '.pl', '.tmpl')
as a package variable.

=item check (1)

set or get the check flag. Turn checking on by setting this to some true value.
Default is off. Class and object method, i.e. AutoReloader->check(1) sets the
default to on, $sub->check(1) sets checking for a subroutine. For now, there's
no way to inculcate the class default on subs with a private check flag.

=item checksub ($coderef)

set the checking subroutine. Class and object method. This subroutine will be
invoked with a subroutines source filename (full path) every time the sub for
which it is configured - but only if check for that subroutine is true -, and
should return some value special to that file.
Default is 'sub { (stat $_[0]) [9] }', i.e. mtime.

=back

=head1 SEE ALSO

 AutoLoader, AutoSplit, DBIx::VersionedSubs

=head1 BUGS

AutoReloader subroutines are always reported as __ANON__ (e.g. with Carp::cluck),
even if they are assigned to a symbol table entry. Which might not be a bug.

There might be others.

=head1 Author

 shmem <shmem@cpan.org>

=head1 CREDITS

Many thanks to thospel, Corion, diotalevi, tye and chromatic (these are their
http://perlmonks.org nicks) for review and most valuable hints.

=head1 COPYRIGHT

Copyright 2007 - 2021 by shmem <shmem@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package AutoReloader;

use strict;
use warnings;
use Scalar::Util;
use File::Spec;

our $VERSION   = 0.03;

use vars qw($Debug %AL);
$Debug = 0;

sub new {
    my $class  = shift;
    my $caller = caller;
    my $sub    = gensub ($caller,@_);

    bless $sub, $class;
}

sub auto {
    shift if __PACKAGE__ || $_[0] eq (caller(0))[0];
    $AL {'auto'} = shift if @_;
    $AL {'auto'};
}

sub check {
    my $self = shift;
    if(ref($self)) {
        ${ $AL {'Sub'} -> {Scalar::Util::refaddr ($self)} -> {'check'} }
	    = shift if @_;
        ${ $AL {'Sub'} -> {Scalar::Util::refaddr ($self)} -> {'check'} };
    }
    else {
        $AL {'check'}  = shift;
        $AL {'check'};
    }
}

sub checksub {
    my $self = shift;
    if(ref($self)) {
        ${ $AL {'Sub'} -> {Scalar::Util::refaddr ($self)} -> {'checksub'} }
	    = shift if @_;
	${ $AL {'Sub'} -> {Scalar::Util::refaddr ($self)} -> {'checksub'} };
    }
    else {
        $AL {'checksub'} = shift if @_;
        $AL {'checksub'};
    }
}
sub suffix {
    shift if __PACKAGE__ || $_[0] eq (caller(0))[0];
    $AL {'suffix'} = shift if @_;
    $AL {'suffix'};
} 
# default check subroutine
checksub ( __PACKAGE__, sub { (stat $_[0]) [9] } );
# default is not checking
check    ( __PACKAGE__,  0);

# gensub - returns an anonymous subroutine.
# Parameters:
# if one:  filename (full path)
# if more: package, filename [, checkfuncref [, auto ]]

sub gensub {
    my $package = scalar(@_) == 1 ? caller : shift;
    my $file    = shift;
    my $chkfunc = shift || $AL {'checksub'};
    my $auto    = shift || $AL {'auto'} || 'auto';
    my $function;

    {
        ($function = pop (@{[ File::Spec->splitpath($file) ]}) ) =~ s/\..*//;
        
        $file .= $AL {'suffix'} || '.al' unless $file =~ /\.\w+$/;
        unless (-e $file) {
	    my ($filename, $seen);
	    {
		$filename = File::Spec -> catfile ($auto, $package, $file);
		foreach my $d ('.',@INC) { # check current working dir first
		    my $f = File::Spec -> catfile ($d,$filename);
		    if (-e $f) {
			$file = $f;
			last;
		    }
		}
		last if $seen;
		unless (-e $file) {
		    # redo the search with a truncated filename
		    $file =~ s/(\w{12,})(\.\w+)$/substr($1,0,11).$2/e;
		    $seen++;
		    redo;
		}
	    } 
	    die
	      "Can't locate function file '$filename' for package '$package'\n"
		unless -e $file;
	}
    }

    if (my $addr = $AL {'Inc'} -> {"$package\::$function"} ) {
        return $AL {Sub} -> {$addr} -> {'outer'};
    }
    else {
        # file not known yet
        my $inner;
        my $h        = {};
        my $cr       = $chkfunc -> ($file);
        my $subname  = "$package\::$function";

        $h = {
            file     => $file,
            check    => \$AL {'check'},
            checksub => \$chkfunc,
            checkref => \$cr,
            function => $subname,
        };

        my $outer          = load ($package, $file, $h) or die $@;
        my $outeraddr      = Scalar::Util::refaddr ($outer);

        $h -> {'outer'} = $outer;
        Scalar::Util::weaken ($h -> {'outer'});

        $AL{Sub} -> {$outeraddr} = $h;
        $AL{Inc} -> {$subname}   = $outeraddr;
        return bless $outer, __PACKAGE__;
    }
};
{
    my $load = \&load;
    sub load {
	my ($package, $file, $h) = @_;
	delete $INC {$file};
	my $ref = eval "package $package; require '$file'";
	#warn $@ if $@;
	return undef if $@;
	{
	    # just in case the require dinn' return a ref -
	    # then a named subroutine has been loaded.
	    # All other cases are errors.
	    unless (
	      Scalar::Util::reftype($ref)
	                 and
	      Scalar::Util::reftype($ref) eq 'CODE') {
		$ref = \&{$h -> {'function'}};
		no strict 'refs';
		no warnings 'redefine';
		*{$h -> {'function'} } = $h ->{'outer'} if $h -> {'outer'};
	    }
	    ${$h->{inner}} = $ref;
    
	    my $sub = sub {
		my $cr = $h -> {'checkref'};
		if( ${ $h -> {'check'} } and ${ $h-> {'checksub'} }
					and
		( my $c = ${ $h->{checksub} } -> ($file) ) != $$cr) {
		    warn "reloading $file" if $Debug;
		    $$cr = $c;
		    $load -> ($package, $file, $h);
		}
		goto ${ $h -> {'inner'} };
	    };
	}
    }
}

sub DESTROY {
    my $outeraddr = Scalar::Util::refaddr ($_[0]);
    my $h = $AL {'Sub'} -> {$outeraddr};
    delete  $AL {'Inc'} -> { $h -> {'function'}};
    delete  $AL {'Sub'} -> {$outeraddr};
}

sub AUTOLOAD {
    no strict;
    my $sub = $AUTOLOAD;
    my ($pkg, $func, $filename);
    {
        ($pkg, $func) = ($sub =~ /(.*)::([^:]+)$/);
        $pkg = File::Spec -> catdir (split /::/, $pkg);
    }
    my $save = $@;
    local $!; # Do not munge the value. 
    my $ref;
    eval { local $SIG{__DIE__}; $ref = gensub ($pkg, $func, '', $AL{'auto'} || 'auto'); };
    if ($@) {
        if (substr ($sub,-9) eq '::DESTROY') {
            no strict 'refs';
            *$sub = sub {};
            $@ = undef;
        }
        if ($@){
            my $error = $@;
            require Carp;
            Carp::croak($error);
        }
    }
    $@ = $save;
    return unless $ref;
    no warnings 'redefine';
    *$AUTOLOAD = $ref;
    goto $ref;
}

# below are shameless plugs from AutoLoader 5.63

sub import {
    my $pkg     = shift;
    my $callpkg = caller;
    if ($pkg eq 'AutoReloader') {
	if ( @_ and $_[0] =~ /^&?AUTOLOAD$/ ) {
	    no strict 'refs';
	    *{ $callpkg . '::AUTOLOAD' } = \&AUTOLOAD;
	    *{ $callpkg . '::can'      } = \&can;
	} 
    } 
} 

sub unimport {
    my $callpkg = caller;

    no strict 'refs';

    for my $exported (qw( AUTOLOAD can )) {
        my $symname = $callpkg . '::' . $exported;
        undef *{ $symname } if \&{ $symname } == \&{ $exported };
        *{ $symname } = \&{ $symname };
    }
}

sub can {
    my ($self, $func) = @_;
    my $parent        = $self->SUPER::can( $func );
    return $parent if $parent;
    my $pkg           = ref( $self ) || $self;
    local $@;
    my $ref;
    $ref = eval { local $SIG{__DIE__}; $ref = gensub ($pkg, $func, '', $AL{'auto'} || 'auto'); }
	or return undef;
    no strict 'refs';
    no warnings 'redefine';
    *{ $pkg . '::' . $func } = $ref;
    $ref;
} 
1;
__END__
