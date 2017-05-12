package D'oh::Year;

require 5.005;  # Need a solid overload

use strict;

=pod

=head1 NAME

D'oh::Year - Catch stupid mistakes when mucking with years, like Y2K bugs


=head1 SYNOPSIS

    use D'oh::Year;
    
    ($year) = (localtime)[5];
    print "We're going to party like its 19$year";  # No you're not.
    
    print "Welcome to the year 20$year!";   # Sorry, Buck.
    

=head1 DESCRIPTION

NO, PERL DOES NOT HAVE A Y2K BUG! but alot of people seem determined
to add it.  Perl, and most other languges through various historical
reasons, like to return years in the form of the number of years since
1900.  This has led to the false assumption that its actually
returning the last two digits of the current year (1999 => 99) and the
mistaken assumption that you can set the current year as "19$year".

This is a Y2K bug, the honor is not just given to COBOL progrmamers.

Bugs of this nature can easily be detected (most of the time) by an
automated process.  This is it.

When D'oh::Year is used, it provides special versions of localtime() and
gmtime() which return a rigged value for the year.  When used properly
(usually 1900 + $year) you'll notice no difference.  But when used for 
B<EVIL> it will die with a message about misuse of the year.

The following things are naughty (where $year is from gmtime() or
localtime()):

   "19$year",  19.$year
   "20$year",  20.$year
   "200$year", 200.$year
   $year -= 100, $year = $year - 100;

B<THE FOLLOWING ARE THE CORRECT WAYS TO MANIPULATE THE DATE>
Take note, please.

   $year += 1900;  # Get the complete year.
   $year %= 100;   # Get the last two digits of the year.
                   # ie "01" in 2001 and "99" in 1999
   

=head1 USAGE

Its simple.  Just use (do not require!) the module.  If it detects a
problem, it will cause your program to abort with an error.  If you
don't like this, you can use the module with the C<:WARN> tag like so:

    use D'oh::Year qw(:WARN);

and it will warn upon seeing a year mishandling instead of dying.

Because there is a I<slight> performance loss when using D'oh::Year, you
might want to only use it during development and testing.  A few
suggestions for use...

=over 4

=item B<Shove it down their throats>

Set up /usr/bin/perl on your development machine as a shell wrapper around
perl which always uses D'oh::Year:

    #!/bin/sh

    perl -MD::oh::Year $@

This might be a little draconian for normal usage.

=item B<Add it to your test harness>

=item B<Make a quick check>

C<perl -MD::oh::Year myprogram> 

=back


=head1 CAVEATS

This program does its checking at B<run time> not compile time.  Thus
it is not simply enough to slap D'oh::Year on a program, run it once
and expect it to find everything.  For a thourough scrubbing you must
make sure every line of code is excersied... but you already have test
harnesses set up to do that, RIGHT?!


=head1 TODO

=over 4

=item B<sort @times>

Sorting time()'s as strings is a common mistake.  I can't detect it
without some XS code to look at the op stack.

=item B<printf "19%02d", $year>

I can't handle this without being able to override printf(), but can't
do that because it has a complex prototype.  This could be handled,
but it would require a patch to pp_printf.  I can do sprintf(), but I
don't think its wise to be non-orthoganal and lead non-doc readers on
that if sprintf() is handled, printf() should be, too.

=back


=head1 AUTHOR

Original idea by Andrew Langmead

Original code by Mark "The Ominous" Dominous

Cleaned up and maintained by Michael G Schwern <schwern@pobox.com>.

=cut

use vars qw($VERSION);
$VERSION = '0.06';

sub _mk_localtime {
    my($reaction) = shift;
    
    return sub {
        return @_ ? localtime(@_) : localtime() unless wantarray;
        my @t = @_ ? localtime(@_) : localtime();
        $t[5] = D'oh::Year::year->new($t[5], $reaction);
        @t;
    }
}

sub _mk_gmtime {
    my($reaction) = shift;
    
    return sub {
        return @_ ? gmtime(@_) : gmtime() unless wantarray;
        my @t = @_ ? gmtime(@_) : gmtime();
        $t[5] = D'oh::Year::year->new($t[5], $reaction);
        @t;
    }
}

sub _mk_time {
    my($reaction) = shift;
    
    return sub {
        return D'oh::Year::time->new(time, $reaction);
    }
}


sub import {
    () = shift; # Dump the package.
    my $reaction = shift;
    my $caller = caller;
    
    $reaction = ':DIE' unless defined $reaction;

    $reaction = $reaction =~ /^:WARN/i ? 'warn' : 'die';
    
    {
        no strict 'refs';
        *{$caller . '::localtime'}  =   &_mk_localtime($reaction);
        *{$caller . '::gmtime'}     =   &_mk_gmtime($reaction);
# Didn't pan out.
#       *{$caller . '::time'}       =   &_mk_time($reaction);
    }
}


package D'oh::Year::year;

use fields qw(_Year _Reaction);

use strict;

use overload    '.'     =>  \&concat,
                '""'    =>  \&stringize,
                '0+'    =>  \&numize,
                '-'     =>  \&subtract,
                'fallback'  =>  'TRUE',
    ;


sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my($year, $reaction) = @_;

    my $self = fields::new($class);
    $self->{_Year}      = $year;
    $self->{_Reaction}  = $reaction || 'die';

    return $self;
}


sub concat {
    my ($self, $a2, $rev) = @_;

    if ($a2 =~ /(19|200?)$/ && $rev) {
        require Carp;
        if ( $self->{_Reaction} eq 'warn' ) {
            Carp::carp("Possible year misuse.");
        } else {
            Carp::croak("Possible year misuse.");
        }
    }
    
    if ($rev) {
        return $a2 . $self->{_Year};
    } else {
        return $self->{_Year} . $a2;
    }
}

sub stringize {
    return shift->{_Year};
}


sub numize {
    return shift->{_Year};
}

sub subtract {
    my($self, $num) = @_;
    if( $num == 100 ) {  # Catch $year -= 100
        require Carp;
        if ( $self->{_Reaction} eq 'warn' ) {
            Carp::carp("Possible year misuse.");
        } else {
            Carp::croak("Possible year misuse.");
        }
    }

    return $self->{_Year} - $num;
}

# I had an idea about catching C<sort time>, but it didn't pan out.
package D'oh::Year::time;

use fields qw(_Time _Reaction);

use strict;

use overload    '""'    =>  \&stringize,
                '0+'    =>  \&numize,
                'fallback'  =>  'TRUE',
    ;


sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my($time, $reaction) = @_;

    my $self = fields::new($class);
    $self->{_Time}      = $time;
    $self->{_Reaction}  = $reaction || 'die';

    return $self;
}


sub stringize {
    # XXX Need code to figure out if we're being called directly from
    # XXX a sort.
    return shift->{_Time};
}


sub numize {
    return shift->{_Time};
}



return 'sc_current_century';
