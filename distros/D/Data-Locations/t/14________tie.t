#!perl -w

package AnyWillDo;

use strict;
no strict "vars";

use Data::Locations;
use FileHandle;
use IO::File;

# ======================================================================
#   $location->tie("FILEHANDLE");
# ======================================================================

$err = '';
$handler_1 = sub { $err = join('', @_); };
$handler_2 = sub { print STDERR @_; };

$nonzero = 1;  $empty    = 0;
$unlink  = 1;  $preserve = 0;
$reopen  = 1;  $closed   = 0;

print "1..92\n";

$n = 1;

$self = $0;
$self =~ s!^.*[^0-9a-zA-Z_\.]!!;

$temp =
    $ENV{'TMP'} || $ENV{'TEMP'} || $ENV{'TMPDIR'} || $ENV{'TEMPDIR'} || '/tmp';
$temp =~ s!/+$!!;

$file = "$temp/$self.$$";

unlink($file);
unless (-f $file)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&write_file();

&check_file($empty,$unlink,$reopen);

print FILE "This is some dummy text.";

&check_file($nonzero,$preserve,$closed);

&read_file();
$txt = join('', <FILE>);
close(FILE);

if ($txt eq "This is some dummy text.")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unlink($file);
unless (-f $file)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&write_file();

$loc = Data::Locations->new();

if (tied(*{$loc}) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print $loc "First";

$loc->reset();
if (join('|', <$loc>) eq 'First')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->tie("FILE");

if (tied(*FILE) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print FILE "Second";

$loc->reset();
if (join('|', <$loc>) eq 'First|Second')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$SIG{__WARN__} = $handler_1;

$err = '';

untie(*FILE);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print FILE "Double-check...";

&check_file($nonzero,$preserve,$closed);

&read_file();
$txt = join('', <FILE>);
close(FILE);

if ($txt eq "Double-check...")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unlink($file);
unless (-f $file)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&write_file();

$loc->tie(*FILE);

if (tied(*FILE) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = select(FILE); print "Third"; select($temp);

$loc->reset();
if (join('|', <$loc>) eq 'First|Second|Third')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';

untie(*FILE);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&check_file($empty,$unlink,$reopen);

$loc->tie(\*FILE);

if (tied(*FILE) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print FILE "Fourth";

$loc->reset();
if (join('|', <$loc>) eq 'First|Second|Third|Fourth')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';

untie(*FILE);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&check_file($empty,$unlink,$reopen);

$loc->tie(*{FILE});

if (tied(*FILE) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (tied(*AnyWillDo::FILE) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*main::FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print FILE "Fifth";

$loc->reset();
if (join('|', <$loc>) eq 'First|Second|Third|Fourth|Fifth')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';

untie(*FILE);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*AnyWillDo::FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*main::FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&check_file($empty,$unlink,$reopen);

no strict "refs";
$loc->tie(*{'FILE'});
use strict "refs";

if (tied(*FILE) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print FILE "Sixth";

$loc->reset();
if (join('|', <FILE>) eq 'First|Second|Third|Fourth|Fifth|Sixth')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';

untie(*FILE);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&check_file($empty,$unlink,$reopen);

$loc->tie(\*{main::FILE});

if (tied(*main::FILE) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*AnyWillDo::FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print main::FILE "Seventh";

$loc->reset();
if (join('|', <$loc>) eq 'First|Second|Third|Fourth|Fifth|Sixth|Seventh')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';

untie(*main::FILE);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*main::FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*AnyWillDo::FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$FileHandle = FileHandle->new();
$loc->tie($FileHandle);

if (tied(*{$FileHandle}) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print $FileHandle "Eighth";

$loc->reset();
if (join('|', <$loc>) eq 'First|Second|Third|Fourth|Fifth|Sixth|Seventh|Eighth')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';

untie(*{$FileHandle});

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*{$FileHandle}))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$IO_File = IO::File->new();
$loc->tie($IO_File);

if (tied(*{$IO_File}) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print $IO_File "Nineth";

$loc->reset();
if (join('|', <$IO_File>) eq 'First|Second|Third|Fourth|Fifth|Sixth|Seventh|Eighth|Nineth')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';

untie(*{$IO_File});

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*{$IO_File}))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->tie(*STDIN);

if (tied(*STDIN) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->reset();

$txt = <STDIN>;
if ($txt eq 'First')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print STDIN "Tenth";

$txt = <STDIN>;
if ($txt eq 'Second')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (join('|', <STDIN>) eq 'Third|Fourth|Fifth|Sixth|Seventh|Eighth|Nineth|Tenth')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';

untie(*STDIN);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*STDIN))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->delete();
$temp = select($loc); print "Dummy"; select($temp);

$loc->reset();
if (join('|', <$loc>) eq 'Dummy')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->tie('STDOUT');
print "via STDOUT";
$loc->reset();
$txt = join('|', <STDOUT>);
$err = '';
untie(*STDOUT);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($txt eq 'Dummy|via STDOUT')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->tie('STDERR');

if (tied(*STDERR) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print STDERR "via STDERR";

$loc->reset();
if (join('|', <STDERR>) eq 'Dummy|via STDOUT|via STDERR')
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$SIG{__WARN__} = $handler_2;

warn "This is a dummy warning";

$loc->reset();
$txt = join('|', <STDERR>);
if ($txt =~ /^Dummy\|via STDOUT\|via STDERR\|(?:#\s+)?This is a dummy warning\b/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$SIG{__WARN__} = $handler_1;

$err = '';

untie(*STDERR);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*STDERR))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$loc->delete();
print $loc "Last test";

$loc->reset();
if (join('|', <$loc>) eq "Last test")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

tie(*FILE, 'Data::Locations', $loc);

if (tied(*FILE) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (tied(*AnyWillDo::FILE) eq $loc)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*main::FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

print FILE "tied via built-in operator";

$loc->reset();
if (join('|', <$loc>) eq "Last test|tied via built-in operator")
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$err = '';

untie(*FILE);

if ($err =~ /untie attempted while 1 inner references still exist/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

unless (defined tied(*FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*AnyWillDo::FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (defined tied(*main::FILE))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&check_file($empty,$unlink,$closed);

exit;

sub write_file
{
    unless (open(FILE, ">$file"))
    {
        die "$self: can't write '$file': \L$!\E\n";
    }
}

sub read_file
{
    unless (open(FILE, "<$file"))
    {
        die "$self: can't read '$file': \L$!\E\n";
    }
}

sub check_file
{
    my($nonzero,$unlink,$reopen) = @_;

    close(FILE);
    if (-f $file)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($nonzero)
    {
        if (-s $file > 0)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    else
    {
        if (-s $file == 0)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    if ($unlink)
    {
        unlink($file);
        unless (-f $file)
        {print "ok $n\n";} else {print "not ok $n\n";}
        $n++;
    }
    if ($reopen)
    {
        &write_file();
    }
}

__END__

