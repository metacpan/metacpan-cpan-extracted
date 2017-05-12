package DWH_File;

use warnings;
use strict;
use vars qw( $VERSION $default_dbm );

use DWH_File::Work;

$VERSION = 0.24;

BEGIN { defined( $default_dbm ) or $default_dbm = 'AnyDBM_File' }

sub import
{
    my $class = shift;
    ( $default_dbm ) = @_;
    unless ( defined( $default_dbm ) and $default_dbm ) {
	$default_dbm = 'AnyDBM_File';
    }
    require "$default_dbm.pm" or die "Couldn't use $default_dbm.pm: $!";
}

sub TIEHASH {
    my $class = shift;

    my $worker = DWH_File::Work->TIEHASH( @_ );
    my $self = \$worker;
    bless $self, $class;
    return $self;
}

sub FETCH { ${ $_[ 0 ] }->FETCH( $_[ 1 ] ) }

sub STORE { ${ $_[ 0 ] }->STORE( @_[ 1, 2 ] ) }

sub FIRSTKEY { ${ $_[ 0 ] }->FIRSTKEY }

sub NEXTKEY { ${ $_[ 0 ] }->NEXTKEY( $_[ 1 ] ) }

sub EXISTS { ${ $_[ 0 ] }->EXISTS( $_[ 1 ] ) }

sub DELETE { ${ $_[ 0 ] }->DELETE( $_[ 1 ] ) }

sub CLEAR { ${ $_[ 0 ] }->CLEAR }

sub DESTROY {
    ${ $_[ 0 ] }->wipe;
    ${ $_[ 0 ] } = undef;
}

1;

__END__

=head1 NAME

DWH_File 0.22 - data and object persistence in deep and wide hashes

=head1 SYNOPSIS

    use DWH_File qw/ GDBM_File /;
    # the use argument set the DBM module used

    tie( %h, DWH_File, 'myFile', O_RDWR|O_CREAT, 0644 );

    untie( %h ); # essential!

=head1 DESCRIPTION

Note: the files produced by DWH_File 0.22 are in a different format
and are incompatible with the files produced by previous versions.

DWH_File is used in a manner resembling NDBM_File, DB_File etc. These
DBM modules are limited to storing flat scalar values. References to data
such as arrays or hashes are stored as useless strings and the data in the
referenced structures will be lost.

DWH_File uses one of the DBM modules (configurable through the parameters
to C<use()>), but extends the functionality to not only save referenced data
structures but even object systems.

This is why I made it. It makes it extremely simple to achieve persistence in
object oriented Perl programs and you can skip the cumbersome interaction with
a conventional database.

DWH_File tries to make the tied hash behave as much like a standard Perl hash
as possible. Besides the capability to store nested data structures DWH_File
also implements C<exists()>, C<delete()> and C<undef()> functionality like
that of a standard hash (as opposed to all the DBM modules).

=head2 MULTIPLE DBM FILES

It is possible to distribute for instance an object system over several files
if wanted. This might be practical to avoid huge single files and may also
make it easier make a reasonable structure in the data. If this feature is
used the same set of files should be tied each time if any of the contents
that may refer across files is altered. See L<MODELS>.

=head2 GARBAGE COLLECTION

DWH_File uses a garbage collection scheme similar to that of Perl itself.
This means that you actually don't have to worry about freeing anything
(see the cyclic reference caveat though).
Just like Perl DWH_File will remove entries that nothing is pointing to (and
therefore noone can ever get at). If you've got a key whose value refers to an
array for instance, that array will be swept away if you assign something else
to the key. Unless there's a reference to the array somewhere else in the
structure. This works even across different dbm files when using multiple
files.

The garbage collection housekeeping is performed at untie time - so it is 
mandatory to call untie (and if you keep any references to the tied object
to undef those in advance). Otherwise you'll leave the object at the mercy
of global destruction and garbage won't be properly collected.

=head2 MUTUAL EXCLUSION

Ealier versions had some specialized locking schemes to deal with
concurrency in eg. web-applications. I havn't put any into this
version, and I think I'll leave them out to avoid scope creep.

The reason for having those features were that locking dbm-files
isn't as straightforward as locking ordinary files. I find now, that
the best solution is to use some of the generalized mechanisms for
handling concurrency. There are some fine perl modules for
facilitating the use of semaphores for instance.

=head2 LOGGING

Earlier versions had a logging feature. I haven't put it into
this new generation of DWH_File yet. If you need it, send me a mail.
That might tempt me.

=head2 FURTHER INFORMATION

http://www.orqwood.dk/perl5/dwh/ - home of the DWH_File.

As of this writing, there's nothing much there, but I hope to find
time to make a series of examples and templates to show just how
beautiful life can be if you only remember to

   use DWH_File;

=head1 MODELS

=head2 A typical script using DWH_File

    use Fcntl;
    use DWH_File;
    # with no extra parameters to use() DWH_File defaults to:
    # AnyDBM_File
    tie( %h, DWH_File, 'myFile.dbm', O_RDWR|O_CREAT, 0644 );

    # use the hash ... 

    # cleanup
    # (necessary whenever reference values have been tampered with)
    untie %h;

=head2 A script using data in three different files

The data in one file may refer to that in another and even that
reference will be persistent.

    use Fcntl;
    use DWH_File;
    tie( %a, DWH_File, 'fileA', O_RDWR|O_CREAT, 0644 );
    tie( %b, DWH_File, 'fileB', O_RDWR|O_CREAT, 0644 );
    tie( %c, DWH_File, 'fileC', O_RDWR|O_CREAT, 0644 );

    $a{ doo } = [ qw(doo bi dee), { a => "ah", u => "uh" } ];
    $b{ bi } = $a{ doo }[ 3 ];
    # this will work

    print "$b{ bi }{ a }\n";
    # prints "ah";

    $b{ bi }{ a } = "I've changed";
    print "$a{ doo }[ 3 ]{ a }\n"; # prints "I've changed"

    # note that if - in another program - you tie %g to 'fileB'
    # without also having tied some other hash variable to 'fileA')
    # then $g{ bi } will be undefined. The actual data is in 'fileA'.
    # Moreover there will be a high risk of corrupting the data.

    # cleanup
    # (necessary whenever reference values have been tampered with)
    untie %a;
    untie %b;
    untie %c;

Earlier versions of DWH_File used a tag in each individual data file
to identlify it in the context of other file. From 0.22 a file-URI
is used in stead. This removes some problems related to the tagging
scheme, but it introduces an obligation that your data files don't
move around.

=head2 A persistent class

Earlier versions of DWH_File demanded, that the package defining a
class set a special variable to a special value for the class to be
persistent in DWH_File.

The intention was to avoid weird results of trying to save objects
of classes which didn't know about DWH_File and thus would not work
properly when retrieved (because they didn't define methods to restore
state that DWH_File couln't restore automatically - like open
files etc.).

I've removed this limitation, so DWH_File has become more sticky.
I'm thinking of a new and more elegant way, like demanding that
classes have DWH_File::Object in their heritage. Something may
appear later.

=head1 NOTES

=head2 PLATFORMS

This version of DWH_File seems to work on all unices and I
expect it to work on Windows too. I'm eager to hear from anybody
who's tested it on anything.

=head2 MLDBM

It appears that DWH_File does much of the same stuff that the MLDBM
module from CPAN does. There are substantial differences though, which
means that both modules outperform the other in certain
situations. DWH_Files main attractions are (a) it only has to load the
data actually acessed into memory (b) it restores all referential
identity (MLDBM sometimes makes duplicates) (c) it has an approach to
setting up dynamic state elements (like sockets, pipes etc.) of
objects at load time.

Also at this point, MLDBM is a near-canon part of institutionalized
Perl-culture. It may be expected to be thouroughly tested and stable.
DWH_File is just the work of a single mind (one that you have no
particular reason to trust), and to my surprise it hasn't gained
much acceptance since I first put it on CPAN sometime 2000 (I think).

=head2 (IN)COMPATIBILITY

This version cannot share files with versions 0.01 to 0.21 of DWH_File.
If you have legacy data that you'd really like to convert to the new
format, send me an email. I may write a convertion facility if
persuaded. I don't need one myself, so if nobody asks for it, I
probably won't make it.

=head1 CAVEATS

=over 4

=item REMEMBER UNTIE

It is very important that untie be called at the end of any script
that changes data referenced by the entries in the hash. Otherwise the
file will be corrupted. Also remember to remove any references to the
tied object before untieing.

=item BEWARE OF DBM

Using DWH_File with NDBM_File I found that arrays wouldn't hold more
than a few hundred entries. Assignment seemed to work OK but when
global destruction came along (and the data should be flushed to disk)
a segmentation error occured. It seems to me that this must be a
NDBM_File related bug. I've tried it with DB_File (under linuxPPC) -
100000 entries no problem :-)

At all times be aware of the limitations to data size imposed by the
DBM module you use. See AnyDBM_File(3) for specs of the various DMB
modules.  Also some DBM modules may not be complete (I had trouble
with the EXIST method not existing in NDBM_File).

=item BEWARE OF CYCLIC REFERENCES

Your data may contain cyclic references which mean that the
reference count is above zero eventhough the data is unreachable. This
will defeat the DWH_File garbage collection scheme an thus may cause
your file to swell with useless unreachable data.

    # %h being tied to DWH_File $h{ a } = [ qw( foo bar ) ];
    push @{ $h{ a } }, $h{ a };
    # the anonymous array pointed
    # to by $h{ a } now contains a
    # reference to itself
    $h{ a } = "Gone with the wind";
    # so it's refcount will now # be 1 and it won't be garbage
    # collected

To avoid the problem, break the self reference before losing touch:

    # %h being tied to DWH_File
    $h{ a } = [ qw( foo bar ) ];
    push @{ $h{ a } }, $h{ a };
    # now break the reference
    $h{ a }[ 2 ] = '';
                              
    $h{ a } = "Gone with the wind";
    # the anonymous array will be
    # garbage collected at untie time

Currently I don't have the time to try to work out a better garbage
collection scheme for DWH_File. Sorry.

=item DON'T MOVE DATA FILES AROUND

From version 0.22 the DWH_File instances use file URIs to identify
themselves amongst one another. This means that if you have more than
one tied hash and there are references to data across tied hashes,
these references will become invalid if the files change location.
This may be solved if you must move a file by adding a symbolic link
to the file at its original path and then tie to that link.

=item REFERENCES USED AS KEYS REMAIN LIVE REFERENCES

This is certainly a feature, but it is a deviation from the way standard
hashes work. Also it means, that an object which is used as hash key
anywhere will not be garbage collected because it's reference count
will remain at least one.

I made it this way in 0.22 in order to fulfill the aim af DWH_File to
practically eliminate the differences between multiple and a single
invocation of the code using the hash. Here's an example:

If a perl program goes:

    # %h being an empty standard hash
    $h{ batman } = 12000;
    print "$h{ batman }\n";

- then it'll output

    12000

But if you split this in to two portions, se one program says

    $h{ batman } = 12000;

and another program which incidentally is run the next day goes

    print "$h{ batman }\n";

- then nothing but the newline is printed (to standard out anyway)

Well, if the hash %h had been tied to DWH_File on the same file, your
data would be persistent, so putting the two statements in two
different invocations would make no difference. You'd get your

    12000

- in the latter case too.

Now if the key is a reference:

    # this has happened at some time
    $h{ some } = [ qw( hoo do you love ) ];
    # and then someone decides to use the array ref as a key:
    $h{ $h{ some } } = "koochi koochi";
    print "$h{ $h{ some } }\n";

- then converting the array reference to a string based on the address
of the references item (as standard hashes do) will mean, that $h{ some }
will most likely constitute a different key in a different invocation.
Thus if I split off the print statement into a different program and
run it another day, I won't get the intended result.

By using actual references as keys, I solve this problem. But it has a
couple of consequences. Eg this code:

   for ( keys %h ) { $_->bingo }

might make sense if the %h is tied to DWH_File, because the keys may
actually be objects of a class which implements the method bingo().
This code would not make sense if %h is a plain hash, since all the
keys would surely be strings.

There's an issue, which I haven't tested, but I suspect, that if you
use an object of a class that overloads operator "" as a key in a regular
hash, then you'll get the result of the overload operation as a key
(and not just that standard string based on the address).

If the stringifying method yealds a different result depending on
eg. the state of the object (or the environment), then

    $h{ $some_object } = "Slot one";
    $some_object->change_state_which_alters_string_representation;
    $h{ $some_object } = "Slot two";

will store the two strings as the values for two different keys in the
hash if $some_object is stringified before being used as a key (as in
a standard hash) while "Slot two" will simply overwrite the first
assignment if the actual reference (which is unchanged form line one
to line three of the program) is used as key (as in a DWH_File tied
hash).

It's not hard to work around this (quite unlikely) problem - but you've
got to know that it's there.

It may even be possible to correct DWH_File to use the stringification
if the overload is present - I may look into it later (oh and do mail
me if you know how this can be done - the checking if the "" operator
is overloaded, that is).

=item LIMITATION 1

Data structures saved to disk using DWH_File must not be tied to
any other class. DWH_File needs to internally tie the data to some
helper classes - and Perl does not allow data to be tied to more than
one class at a time.

At one point I dreamed up at workaround for this, but as of this writing
I have no plans for trying to implement it. You have a go if you want.

=item LIMITATION 2

You're not allowed to assign references to constants in the DWH
structure as in (%h being tied to DWH_File)

    $h{ statementref } = \"I am a donut";
    # won't wash

You can't do an exact equivalent, but you can of course say

    $r = "All men are born equal";
    $h{ statementref } = \$r;

=item LIMITATION 3

Autovivification doen't always work. This may depend on the DBM module
used. I haven't really investigated this problem but it seems that
the problems I have experienced using DB_File arise either from some
quirks in either DB_File or Perl itself.

This means that if you say

    %h = ();
    $h{ a }[ 3 ]{ pie } = "Apple!";

you can't be sure that the implicit anonymous array and hash "spring
into existence" like they should. You'll have to make them exist first:

    %h = ( a =E<gt> [ undef, undef, undef, {} ] );
    $h{ a }[ 3 ]{ pie } = "Apple!";

Strangely though I have found that often autovivification does actually work
but I can't find the pattern.

I don't plan on trying to fix this right now because it appears to be quite
mysterious and that I can't really do anything about it on DWH_File's side.

=item LIMITATION 4

DWH_File hashes store straight scalars and references (blessed or not)
to scalars, hashes and arrays - in other words: data. File handles and 
subrutine (CODE) references are not stored.

These are the only known limitations. If you encounter any others please
tell me.

=back

=head1 BUGS

Please let me know if you find any.

As the version number indicates this is an early beta state
piece of software. Please contact me if you have any comments or
suggestions - also language corrections or other comments on the
documentation.

=head1 COPYRIGHT

Copyright (c) Jakob Schmidt/Orqwood Software 2003

The DWH_File distribution is free software and may be used
and distributed under the same terms as Perl itself.

=head1 AUTHOR(S)

    Jakob Schmidt <schmidt@orqwood.dk>

=cut

CVS-log (non-pod)

    $Log: DWH_File.pm,v $
    Revision 1.9  2003/03/31 18:08:04  schmidt
    Ready for release 0.24

    Revision 1.8  2003/01/25 21:11:39  schmidt
    Version bumped up to 0.23

    Revision 1.7  2003/01/04 23:30:54  schmidt
    Info on new features and their consequences in the .pod

    Revision 1.6  2002/12/18 21:47:39  schmidt
    New version label and slight comments correction

    Revision 1.5  2002/11/02 22:45:10  schmidt
    Release version 0.21

    Revision 1.4  2002/10/25 14:25:35  schmidt
    Enabled use of specific DBM module (as in documentation)

    Revision 1.3  2002/10/07 20:48:18  schmidt
    Style correction

    Revision 1.2  2002/09/29 23:05:33  schmidt
    Made a few changes to get ready for release version 0.1 on CPAN

    Revision 1.1.1.1  2002/09/27 22:41:49  schmidt
    Imported

