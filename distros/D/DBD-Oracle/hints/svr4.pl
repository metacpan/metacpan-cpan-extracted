my $archname = $Config::Config{archname} || die;
$att{LIBS}      ||= [];
$att{LIBS}->[0] ||= '';

# Some SVR4 systems may need to link against -lc to pick up things like
# fpsetmask, sys_nerr and ecvt.
my @libs = qw(-lsocket -lnsl -lm -ldl);	# general svr4 default

# modified by Davide Migliavacca <davide.migliavacca@inferentia.it>
if ($archname eq 'RM400-svr4') {
	@libs = qw(-lucb);
}

push @libs, '-lc';

warn "$^O LIBS attribute defaulted to '$att{LIBS}->[0]' for '$archname'";
$att{LIBS}->[0] .= " ".join(" ", @libs);	# append libs
warn "$^O LIBS attribute updated   to '$att{LIBS}->[0]'";


__END__

From doughera@lafcol.lafayette.edu Mon Aug 21 07:01:51 1995
Date: Fri, 18 Aug 1995 15:33:22 -0400 (EDT)
From: Andy Dougherty <doughera@lafcol.lafayette.edu>
Subject: Re: [MM] Re: hints file for Oracle
To: Tim Bunce <Tim.Bunce@ig.co.uk>
In-Reply-To: <9508181853.ab12333@post.demon.co.uk>
Mime-Version: 1.0
Content-Type: TEXT/PLAIN; charset=US-ASCII

On Fri, 18 Aug 1995, Tim Bunce wrote:
> > From: Alan Burlison <aburlison@cix.compulink.co.uk>
> > 
> > Tim,
> > 
> > The following hints file is required for DBD::Oracle on svr4, you might 
> > like to add it to the next release :-)
> > 
> > File: Oracle/hints/svr4.pl
> > 
> > # Some SVR4 systems may need to link against -lc to pick up things like
> > $att{LIBS} = [ '-lsocket -lnsl -lm -ldl -lc' ];
>
> Umm, 'some', 'may', 'things like'. Care to clarify?
> 
> Why _exactly_ is this needed, and why doesn't MakeMaker do this already?
> (CC'd to the MakeMaker mailing list.)

That looks like a bad editing of the ODBM_File/hints/svr4.pl:

########################## hints/svr4.pl #########################
# Some SVR4 systems may need to link against routines in -lucb for
# odbm.  Some may also need to link against -lc to pick up things like
# ecvt.
$att{LIBS} = ['-ldbm -lucb -lc'];
###################################################################

"Some" includes Unisys 6000 (or something like that).  I don't know 
if it includes anything else.  It doesn't include Unixware 2.1, but it 
might include Esix.  It's *really* hard to get accurate info.

"May" because some do and some don't, and any listing gets out of date 
quickly as vendors issue different versions, and probably more than 
half the info you *do* get about specific versions is wrong.  Hence all 
the vague weasel-words.

"Things like" is ecvt() for Unisys (for ODBM_File).  Since some linkers 
only report the first missing symbol, it's sometimes hard (and 
sometimes pointless) to get a complete list of things that you need).

Basically, there are *many* SVR4-derived systems out there, and there are 
many little idiosyncracies; the best bet is to put someone else's name 
and email address in the hint file so you can blame them :-).

    Andy Dougherty		doughera@lafcol.lafayette.edu


From: Tye McQueen <tye@metronet.com>
Subject: Re: [MM] Re: hints file for Oracle
Date: Fri, 18 Aug 1995 16:01:39 -0500 (CDT)
Cc: aburlison@cix.compulink.co.uk, perldb-interest@vix.com, 
    makemaker@franz.ww.tu-berlin.de

Excerpts from the mail message of Tim Bunce:
) > From: Alan Burlison <aburlison@cix.compulink.co.uk>
) > 
) > The following hints file is required for DBD::Oracle on svr4, you might 
) > like to add it to the next release :-)
) > 
) > File: Oracle/hints/svr4.pl
) > 
) > # Some SVR4 systems may need to link against -lc to pick up things like
) > $att{LIBS} = [ '-lsocket -lnsl -lm -ldl -lc' ];
)
) Umm, 'some', 'may', 'things like'. Care to clarify?
) 
) Why _exactly_ is this needed, and why doesn't MakeMaker do this already?
) (CC'd to the MakeMaker mailing list.)
) 
) Is anyone else using DBD::Oracle on an svr4 system (not solaris 2)?

That looks like something I wrote.  I'll take credit and blame
for it at least for the sake of the next paragraph.

So far "some" is only whatever Unisys system Alan and one other
person have used.  "may" is because, as far as I could tell from
my end, some of the dynamically loaded extensions worked okay
before this fix but one of them didn't.  "thinks like" must be
because I couldn't remember which routine was not being found
and then forgot to finish my sentence.  I think it was _ecvt().

The description is very vague because it doesn't make sense to
me why it is needed and I don't have access to a system to play
around with it if I really wanted to try to figure it out.  But
it seems to fix the few problems it addresses and have not heard
of it hurting anything yet (and I've tested it on my machines).

I'm putting together a README.svr4 for Perl that will describe this
and many other things in case people are curious or run into a
problem and need to know why some of the strange things were done.
-- 
Tye McQueen                 tye@metronet.com  ||  tye@doober.usu.edu
             Nothing is obvious unless you are overlooking something
       http://www.metronet.com/~tye/ (scripts, links, nothing fancy)

