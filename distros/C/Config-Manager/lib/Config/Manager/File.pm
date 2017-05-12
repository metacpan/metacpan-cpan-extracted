
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

package Config::Manager::File;

use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw(
    Normalize
    MakeDir
    UniqueTempFileName
    ConvertFromHost
    ConvertToHost
    CompareFiles
    CopyFile
    MoveByCopying
    MD5Checksum
    ReadFile
    WriteFile
    AppendFile
    ConvertFileWithCallback
    SerializeSimple
    Semaphore_Passeer
    Semaphore_Verlaat
    GetNextTicket
);

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '1.7';

use Symbol;
use Fcntl qw(:DEFAULT :flock);

use Config::Manager::Base qw( $SCOPE );
use Config::Manager::Conf;
use Config::Manager::Report qw(:ALL); # also import Normalize and MakeDir
use File::Compare;
use File::Copy;
use Digest::MD5;

#######################################
## Internal configuration constants: ##
#######################################

my @TEMPDIR = ('DEFAULT', 'TEMPDIRPATH');
my @MAXLEN  = ('COBOL',   'Maximum_Line_Length');

my $DEFAULT_MAXLEN = 66;

my $TMPEXT = 'tmp';

#######################
## Static variables: ##
#######################

my $Counter = 0;
my @TempFileList = ();

########################
## Private functions: ##
########################

END
{
    my($file);
    foreach $file (@TempFileList)
    {
        if (-f $file and not unlink($file))
        {
            print STDERR "Please remove temporary file '$file' manually: $!\n";
        }
    }
}

#######################
## Public functions: ##
#######################

# sub Normalize; # imported from Config::Manager::Report

# sub MakeDir;   # imported from Config::Manager::Report

sub UniqueTempFileName
{
    my($path,$error,$file);

    unless (defined ($path = Config::Manager::Conf->get(@TEMPDIR)))
    {
        if ($^O =~ /Win32/i)
        {
            $path = $ENV{'TEMP'} || $ENV{'TMP'} || "C:\\Temp";
        }
        else
        {
            $path = $ENV{'TEMP'} || $ENV{'TMP'} || "/tmp";
        }
        $error = Config::Manager::Conf->error();
        $error =~ s!\s+$!!;
        Config::Manager::Report->report(@WARN,
            "Unable to determine directory for temporary files:",
            $error,
            "Using '$path' instead...");
    }
    $path =~ s![/\\]+$!!;
    $path .= "/$SCOPE";
    $file = sprintf
    (
        "%s_%03d%02d%02d%02d_%d_%d.%s",
        $path,
        (localtime(time))[7,2,1,0],
        $$,
        ++$Counter,
        $TMPEXT
    );
    push( @TempFileList, $file );
    return $file;
}

sub ConvertFromHost
{
    my($target,$source,$lines,$purge,$kludge) = @_;
    my($error,$line);
    local($/) = "\n";
    local($.);
    local($!);

    unless (-f $source && -s $source)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$source' not found or empty");
        return undef;
    }
    unless (open(SOURCE, "<$source"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't read file '$source': $!");
        return undef;
    }
    unless (open(TARGET, ">$target"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't write file '$target': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        return undef;
    }
    $error = 0;
    while (defined ($line = <SOURCE>))
    {
        if ($purge) { $line =~ s!\s+$!!; }
        else        { $line =~ s![\x0D\x0A]+$!!; }
        if ($lines)
        {
            $error = 1 unless ($line =~ s!^\d\d\d\d\d\d!!);
        }
        # Translate ÜíÖùä!üß => ![\]{|}~
        $line =~ tr/\xDC\xED\xD6\xF9\xE4\x21\xFC\xDF/\x21\x5B\x5C\x5D\x7B\x7C\x7D\x7E/ if ($kludge);
        print TARGET "$line\n";
    }
    if ($error)
    {
        Config::Manager::Report->report(@WARN,
            "There were lines not beginning with 6 digits in file '$source'!");
    }
    unless (close(TARGET))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't close file '$target': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        return undef;
    }
    unless (close(SOURCE))
    {
        Config::Manager::Report->report(@WARN,
            "Can't close file '$source': $!");
    }
    return 1;
}

sub ConvertToHost
{
    my($target,$source,$lines,$purge,$check,$kludge) = @_;
    my($maxlen,$error,$line);
    local($/) = "\n";
    local($.);
    local($!);

    unless (-f $source && -s $source)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$source' not found or empty");
        return undef;
    }
    unless (open(SOURCE, "<$source"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't read file '$source': $!");
        return undef;
    }
    unless (open(TARGET, ">$target"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't write file '$target': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        return undef;
    }
    if ($check)
    {
        unless (defined ($maxlen = Config::Manager::Conf->get(@MAXLEN)))
        {
            $maxlen = $DEFAULT_MAXLEN;
            $error = Config::Manager::Conf->error();
            $error =~ s!\s+$!!;
            Config::Manager::Report->report(@WARN,
                "Unable to determine maximum COBOL line length:",
                $error,
                "Using '$maxlen' instead...");
        }
    }
    $error = 0;
    while (defined ($line = <SOURCE>))
    {
        if ($purge) { $line =~ s!\s+$!!; }
        else        { $line =~ s![\x0D\x0A]+$!!; }
        if ($check && (length($line) > $maxlen))
        {
            $error = 1;
        }
        # Translate ![\]{|}~ => ÜíÖùä!üß
        $line =~ tr/\x21\x5B\x5C\x5D\x7B\x7C\x7D\x7E/\xDC\xED\xD6\xF9\xE4\x21\xFC\xDF/ if ($kludge);
        $line = sprintf("%05d0%s", $., $line) if ($lines);
        print TARGET "$line\n";
    }
    if ($error)
    {
        Config::Manager::Report->report(@WARN,
            "Maximum COBOL line length ($maxlen) exceeded in file '$source'!");
    }
    unless (close(TARGET))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't close file '$target': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        return undef;
    }
    unless (close(SOURCE))
    {
        Config::Manager::Report->report(@WARN,
            "Can't close file '$source': $!");
    }
    return 1;
}

sub CompareFiles
{
    my($source,$target) = @_;
    my($rc);
    local($!);

    # returns true  (1) if both files have identical contents,
    #         false (0) if their contents differ,
    #     and undef     if there was any error.

    unless (-f $source)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$source' does not exist!");
        return undef;
    }
    unless (-f $target)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$target' does not exist!");
        return undef;
    }
    if (($rc = compare($source,$target)) < 0)
    {
        Config::Manager::Report->report(@ERROR,
            "Error while comparing files '$source' and '$target': $!");
        return undef;
    }
    return ($rc == 0) ? 1 : 0;
}

sub CopyFile
{
    my($source,$target) = @_;
    local($!);

    unless (-f $source)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$source' does not exist!");
        return undef;
    }
    unless (copy($source,$target))
    {
        Config::Manager::Report->report(@ERROR,
            "Error while copying file '$source' to '$target': $!");
        return undef;
    }
    return 1;
}

sub MoveByCopying
{
    my($source,$target) = @_;
    local($!);

    unless (-f $source)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$source' does not exist!");
        return undef;
    }
    unless (copy($source,$target))
    {
        Config::Manager::Report->report(@ERROR,
            "Error while copying file '$source' to '$target': $!");
        return undef;
    }
    unless (unlink($source))
    {
        Config::Manager::Report->report(@ERROR,
            "Could not unlink file '$source': $!");
        return undef;
    }
    return 1;
}

sub MD5Checksum
{
    my($source) = @_;
    my($md5,$checksum);
    local($!);

    unless (-f $source)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$source' does not exist!");
        return undef;
    }
    unless (open(SOURCE, "<$source"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't read file '$source': $!");
        return undef;
    }
    $md5 = Digest::MD5->new();
#   $md5->reset(); # obsolete, same as new()
    $md5->addfile(*SOURCE);
    $checksum = $md5->hexdigest();
    unless (close(SOURCE))
    {
        Config::Manager::Report->report(@WARN,
            "Can't close file '$source': $!");
    }
    return $checksum;
}

sub ReadFile
{
    my($source) = @_;
    my(@text);
    local($/) = "\n";
    local($!);

    unless (-f $source)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$source' does not exist!");
        return undef;
    }
    unless (open(SOURCE, "<$source"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't read file '$source': $!");
        return undef;
    }
    @text = <SOURCE>;
    unless (close(SOURCE))
    {
        Config::Manager::Report->report(@WARN,
            "Can't close file '$source': $!");
    }
    return \@text;
}

sub WriteFile
{
    my($target) = shift;
    my($item,$line);
    local($!);

    unless (open(TARGET, ">$target"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't write file '$target': $!");
        return undef;
    }
    foreach $item (@_)
    {
        if (ref($item))
        {
            if (ref($item) eq 'ARRAY')
            {
                foreach $line (@{$item})
                {
                    print TARGET $line;
                }
            }
            else
            {
                Config::Manager::Report->report
                (
                    @FATAL,
        "Illegal parameter '$item': neither a SCALAR nor an ARRAY reference"
                );
                return undef;
            }
        }
        else
        {
            print TARGET $item;
        }
    }
    unless (close(TARGET))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't close file '$target': $!");
        return undef;
    }
    return 1;
}

sub AppendFile
{
    my($target,$source) = @_;
    my($size,$buffer,$read,$offset,$written);
    local($!);

    unless (-f $source)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$source' does not exist!");
        return undef;
    }
    unless (open(SOURCE, "<$source"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't read file '$source': $!");
        return undef;
    }
    unless (binmode(SOURCE))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't set binmode for file '$source': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        return undef;
    }
    unless (open(TARGET, ">>$target"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't append to file '$target': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        return undef;
    }
    unless (binmode(TARGET))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't set binmode for file '$target': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        unless (close(TARGET))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$target': $!");
        }
        return undef;
    }
    $size = -s SOURCE;
    $size = 1024 if ($size < 512);
    $size = 32768 if ($size > 32768);
    CYCLE:
    while (1)
    {
        unless (defined ($read = sysread(SOURCE,$buffer,$size)))
        {
            Config::Manager::Report->report(@ERROR,
                "Can't read from file '$source': $!");
            unless (close(SOURCE))
            {
                Config::Manager::Report->report(@WARN,
                    "Can't close file '$source': $!");
            }
            unless (close(TARGET))
            {
                Config::Manager::Report->report(@WARN,
                    "Can't close file '$target': $!");
            }
            return undef;
        }
        last CYCLE unless ($read > 0);
        for ( $offset = 0; $offset < $read; $offset += $written )
        {
            unless (defined ($written = syswrite(TARGET,$buffer,$read-$offset,$offset)))
            {
                Config::Manager::Report->report(@ERROR,
                    "Can't write to file '$target': $!");
                unless (close(SOURCE))
                {
                    Config::Manager::Report->report(@WARN,
                        "Can't close file '$source': $!");
                }
                unless (close(TARGET))
                {
                    Config::Manager::Report->report(@WARN,
                        "Can't close file '$target': $!");
                }
                return undef;
            }
        }
    }
    unless (close(TARGET))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't close file '$target': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        return undef;
    }
    unless (close(SOURCE))
    {
        Config::Manager::Report->report(@WARN,
            "Can't close file '$source': $!");
    }
    return 1;
}

sub ConvertFileWithCallback
{
    my($target,$source,$callback) = @_;
    my($line);
    local($/) = "\n";
    local($.);
    local($!);

    unless (defined $callback && ref($callback) && ref($callback) eq 'CODE')
    {
        Config::Manager::Report->report(@FATAL,
            "Parameter '$callback' is not a valid CODE reference!");
        return undef;
    }
    unless (-f $source)
    {
        Config::Manager::Report->report(@ERROR,
            "File '$source' does not exist!");
        return undef;
    }
    unless (open(SOURCE, "<$source"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't read file '$source': $!");
        return undef;
    }
    unless (open(TARGET, ">$target"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't write file '$target': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        return undef;
    }
    while (defined ($line = <SOURCE>))
    {
        if (defined ($line = &{$callback}($line,$.))) { print TARGET $line; }
    }
    unless (close(TARGET))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't close file '$target': $!");
        unless (close(SOURCE))
        {
            Config::Manager::Report->report(@WARN,
                "Can't close file '$source': $!");
        }
        return undef;
    }
    unless (close(SOURCE))
    {
        Config::Manager::Report->report(@WARN,
            "Can't close file '$source': $!");
    }
    return 1;
}

sub SerializeSimple
{
    my($varname,$object) = @_;
    my($result) = [];

    push( @{$result}, "\$$varname =" );
    &SerializeStruct($object,0,1,$result);
    ${$result}[$#{$result}] .= ";";
    foreach $object (@{$result}) { $object .= "\n"; }
    return $result;
}

sub SerializeStruct
{
    my($object,$indent,$append,$result) = @_;
    my($ref,$fill,$index,$more,$max,$key,$len,$scalar);

    $ref = '';
    $fill = ' ' x $indent;
    while ((ref($object) eq 'REF') || (ref($object) eq 'SCALAR'))
    {
        $ref .= "\\";
        $object = ${$object};
    }
    if (ref($object) eq 'ARRAY')
    {
        if (($max = @{$object}) == 0)
        {
            if ($append) { ${$result}[$#{$result}] .= " ${ref}\[\]"; }
            else         { push( @{$result}, "${fill}${ref}\[\]" ); }
        }
        else
        {
            push( @{$result}, "${fill}${ref}\[" );
            $more = 0;
            $index = 0;
            while ($index < $max)
            {
                ${$result}[$#{$result}] .= "," if ($more);
                &SerializeStruct(${$object}[$index++],$indent+4,0,$result);
                $more = 1;
            }
            push( @{$result}, "${fill}\]" );
        }
    }
    elsif (ref($object) eq 'HASH')
    {
        if (keys(%{$object}) == 0)
        {
            if ($append) { ${$result}[$#{$result}] .= " ${ref}\{\}"; }
            else         { push( @{$result}, "${fill}${ref}\{\}" ); }
        }
        else
        {
            $max = 0;
            foreach $key (keys(%{$object}))
            {
                $len = length($key);
                $max = $len if ($len > $max);
            }
            push( @{$result}, "${fill}${ref}\{" );
            $more = 0;
            foreach $key (sort keys(%{$object}))
            {
                ${$result}[$#{$result}] .= "," if ($more);
                $len = length($key);
                push( @{$result}, "${fill}    '$key'" . ' ' x ($max-$len) . " =>" );
                &SerializeStruct(${$object}{$key},$indent+4,1,$result);
                $more = 1;
            }
            push( @{$result}, "${fill}\}" );
        }
    }
    else
    {
        if (defined $object)
        {
            $scalar = "$object";
            unless ($scalar =~ /^-?(?:[1-9]\d*|0)(?:\.\d+)?$/)
            {
                $scalar =~ s!\\!\\\\!g;
                $scalar =~ s!\$!\\\$!g;
                $scalar =~ s!\n!\\n!g;
                $scalar =~ s!\t!\\t!g;
                $scalar =~ s!"!\\"!g;
                $scalar =~ s!@!\\@!g;
                $scalar =~ s!([\x00-\x1F\x7F-\xFF])!sprintf("\\x%.02X",ord($1))!eg;
                $scalar = "\"$scalar\"";
            }
        }
        else { $scalar = "undef"; }
        if ($append) { ${$result}[$#{$result}] .= " ${ref}$scalar"; }
        else         { push( @{$result}, "${fill}${ref}$scalar" ); }
    }
}

sub Semaphore_Passeer
{
    my($semaphore) = @_; # this is a filename!
    my($wait,$pid);
    local($!);

    $wait = 1;
    # Wait for semaphore:
    WAIT:
    while ($wait)
    {
        # Wait for semaphore to be released (if set):
        while (-f $semaphore) { sleep(1); }
        # When semaphore is gone, create own one:
        unless (open(SEMAPHORE, ">$semaphore"))
        {
            Config::Manager::Report->report(@ERROR,
                "Can't write semaphore '$semaphore': $!");
            unless (unlink($semaphore))
            {
                Config::Manager::Report->report(@WARN,
                    "Could not unlink semaphore '$semaphore': $!");
            }
            next WAIT;
        }
        print SEMAPHORE "$$\n";
        close(SEMAPHORE);
        # Check wether semaphore is our's or was created
        # in the meantime by a different process:
        unless (open(SEMAPHORE, "<$semaphore"))
        {
            Config::Manager::Report->report(@ERROR,
                "Can't read semaphore '$semaphore': $!");
            unless (unlink($semaphore))
            {
                Config::Manager::Report->report(@ERROR,
                    "Could not unlink semaphore '$semaphore': $!");
            }
            next WAIT;
        }
        $pid = <SEMAPHORE>;
        close(SEMAPHORE);
        $pid =~ s!^\s+!!;
        $pid =~ s!\s+$!!;
        # Loop if semaphore isn't our's:
        $wait = ($pid != $$);
        Config::Manager::Report->report(@WARN,
            "Waiting for process '$pid' to release semaphore '$semaphore'...")
        if ($wait);
    }
}

sub Semaphore_Verlaat
{
    my($semaphore) = @_;
    local($!);

    # Release semaphore:
    unless (unlink($semaphore))
    {
        Config::Manager::Report->report(@ERROR,
            "Could not unlink semaphore '$semaphore': $!");
        return undef;
    }
    return 1;
}

sub GetNextTicket
{
    my($lock,$file,$count_min,$count_max) = @_;
    my($ok,$error,$counter);
    local($!);
    local($@);

    $ok = 0;
    $file = Normalize($file);
    $lock = Normalize($lock) if ($lock);
    my $FH_FILE = gensym();
    unless (sysopen($FH_FILE, $file, O_RDWR|O_CREAT))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't open ticket file '$file': $!");
        return undef;
    }
    eval
    {
        $ok = flock($FH_FILE, LOCK_EX);
    };
    if ($@)
    {
        if ($@ =~ /\bunimplemented\b/)
        {
            &Semaphore_Passeer($lock) if ($lock);
            $ok = 1;
        }
        else
        {
            $error = $@;
            $error =~ s!\s+! !g;
            $error =~ s!\(.*$!!;
            $error =~ s!\s+at\s.*$!!;
            $error =~ s!\s+$!!;
            Config::Manager::Report->report(@ERROR,
                "Can't flock ticket file '$file': $error");
            close($FH_FILE);
            return undef;
        }
    }
    else
    {
        if ($ok)
        {
            $lock = '';
        }
        else
        {
            Config::Manager::Report->report(@ERROR,
                "Can't flock ticket file '$file': $!");
            close($FH_FILE);
            return undef;
        }
    }
    unless (seek($FH_FILE, 0, 0))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't seek ticket file '$file': $!");
        close($FH_FILE);
        &Semaphore_Verlaat($lock) if ($lock);
        return undef;
    }
    if (defined ($counter = <$FH_FILE>))
    {
        $counter =~ s!^\s+!!;
        $counter =~ s!\s+$!!;
        if ($counter =~ /^[0-9a-zA-Z]+$/)
        {
            $counter = $count_min if (($counter eq $count_max) || (++$counter gt $count_max));
        }
        else
        {
            $counter = $count_min;
            Config::Manager::Report->report(@WARN,
                "No valid ticket number found in file '$file'!",
                "Resetting the counter to value '$counter'.");
        }
    }
    else
    {
        $counter = $count_min;
        Config::Manager::Report->report(@WARN,
            "No ticket number found in file '$file'!",
            "Setting the counter to value '$counter'.");
    }
    unless (truncate($FH_FILE, 0))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't truncate ticket file '$file': $!");
        close($FH_FILE);
        &Semaphore_Verlaat($lock) if ($lock);
        return undef;
    }
    unless (seek($FH_FILE, 0, 0))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't seek ticket file '$file': $!");
        close($FH_FILE);
        &Semaphore_Verlaat($lock) if ($lock);
        return undef;
    }
    unless (print($FH_FILE "$counter\n"))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't print ticket file '$file': $!");
        close($FH_FILE);
        &Semaphore_Verlaat($lock) if ($lock);
        return undef;
    }
    unless (close($FH_FILE))
    {
        Config::Manager::Report->report(@ERROR,
            "Can't close ticket file '$file': $!");
        &Semaphore_Verlaat($lock) if ($lock);
        return undef;
    }
    &Semaphore_Verlaat($lock) if ($lock);
    return $counter;
}

1;

__END__

=head1 NAME

Config::Manager::File - Basic File Utilities (for Tools)

=head1 SYNOPSIS

  use Config::Manager::File
  qw(
        Normalize
        MakeDir
        UniqueTempFileName
        ConvertFromHost
        ConvertToHost
        CompareFiles
        CopyFile
        MoveByCopying
        MD5Checksum
        ReadFile
        WriteFile
        AppendFile
        ConvertFileWithCallback
        SerializeSimple
        Semaphore_Passeer
        Semaphore_Verlaat
        GetNextTicket
  );

  use Config::Manager::File qw(:all);

  $dir = Normalize($dir);

  ($drv,$dir) = Normalize($dir);

  $error = MakeDir($dir);

  $tempfilename = &UniqueTempFileName();

  &ConvertFromHost($targetfile,$sourcefile,$linenumbering,$purgeblanks);

  &ConvertToHost($targetfile,$sourcefile,$linenumbering,$purgeblanks,$checklength);

  $same = &CompareFiles($file1,$file2);

  &CopyFile($source,$target);

  &MoveByCopying($source,$target);

  $checksum = &MD5Checksum($source);

  $arrayref = &ReadFile($source);

  &WriteFile($target,@contents);

  &AppendFile($target,$source);

  &ConvertFileWithCallback($target,$source,$callback);

  $printable = &SerializeSimple("varname",$datastructure);

  Semaphore_Passeer($lockfile);

  Semaphore_Verlaat($lockfile);

  $ticket = GetNextTicket($lockfile,$ticketfile,$count_min,$count_max);

=head1 DESCRIPTION

=over 2

=item *

C<$dir = Normalize($dir);>

C<($drv,$dir) = Normalize($dir);>

Normalizes a given path (which may include a filename part),
i.e., substitutes "\" with "/", removes multiple slashes,
removes "../" and "./" where possible, etc.

This function accepts absolute as well as relative paths.
Any trailing slash(es) will be removed.

If called in list context, this function returns a possible
drive letter and the path (without leading slash this time)
separately.

The "drive" return value will contain a dot (".") if the
given path was a relative one.

In scalar context, the function returns C<"$drive/$path">.
(Again, the "drive" will be a dot (".") if the path is
relative.)

If the given path does not contain a drive letter and
the path is absolute, the "drive" part will be empty
(i.e., contain the empty string).

So this function works for Unix and Win32 alike,
but not for other operating systems with different
path separator characters that aren't slash ("/") or
backslash ("\"), such as MacOS, for example, which
uses a colon (":").

=item *

C<$error = MakeDir($dir);>

This function recursively creates the given (absolute)
path (note that the path is normalized using the
"Normalize()" function above before being created).

The function returns an empty string in case of success
and a string containing an error message in case of an
error.

=item *

C<$tempfilename = &UniqueTempFileName();>

Generates a unique temporary file name with an absolute path
(in the temporary directory which has been configured in
the user's or the global configuration file).

The file itself is B<NOT> created by this function.

The file name is composed of the "scope" (as passed to the
"Config::Manager::Conf::init()" method during global initialization)
followed by the day of year (000 to 364 or 365), the hour,
minutes, seconds, the process ID, a running number and terminates
with "C<.tmp>".

All temporary files created in this manner are automatically
deleted at shutdown time of the Perl interpreter (if they
still exist). So you need not worry about deleting any
of your temporary files, but you may do so if you wish.

=item *

C<&ConvertFromHost($targetfile,$sourcefile,$linenumbering,$purgeblanks);>

Converts the given input file after it has been fetched from a
mainframe.

The original input file is B<NEVER> altered in any way. A new file
(whose name "C<$targetfile>" is given) is written instead.

"C<$targetfile>" must be a valid filename; beware that it will
be overwritten if it already exists!

"C<$sourcefile>" is the input file's name (and path),
"C<$linenumbering>" is a flag (0 = "no", 1 = "yes")
indicating whether line numbers shall be removed from the
beginning of each line, and "C<$purgeblanks>" is a flag
(0 = "no", 1 = "yes") indicating whether trailing whitespace
is to be purged from each line.

Any sequences of "Carriage Return" and "Line Feed" characters
(ASCII hexadecimal 0x0D and 0x0A) at the end of lines are converted
to the end-of-line character sequence of the current operating system.

Returns true on success or "undef" in case of error (error messages
are written to the log file and put on hold for possible output
to the screen).

Possible warning messages will also be written to the log file and
to STDERR.

This happens for instance if a line does not begin with 6 digits
when the "C<$linenumbering>" option is enabled, or if there was a
problem closing the input file, or if a needed configuration constant
was unavailable.

=item *

C<&ConvertToHost($targetfile,$sourcefile,$linenumbering,$purgeblanks,$checklength);>

Converts the given input file so that it can be sent to a host
mainframe.

The original input file is B<NEVER> altered in any way. A new file
(whose name "C<$targetfile>" is given) is written instead.

"C<$targetfile>" must be a valid filename; beware that it will
be overwritten if it already exists!

"C<$sourcefile>" is the input file's name (and path),
"C<$linenumbering>" is a flag (0 = "no", 1 = "yes")
indicating whether line numbers shall be prepended to
each line, "C<$purgeblanks>" is a flag (0 = "no",
1 = "yes") indicating whether trailing whitespace is to
be removed from each line, and "C<$checklength>" is
a flag (0 = "no", 1 = "yes") signaling whether lines
should be checked for correct length (a warning message
will be issued if the maximum COBOL line length (66 columns)
is exceeded by any line).

Any sequences of "Carriage Return" and "Line Feed" characters
(ASCII hexadecimal 0x0D and 0x0A) at the end of lines are converted
to the end-of-line character sequence of the current operating system.

Returns true on success or "undef" in case of error (error messages
are written to the log file and put on hold for possible output
to the screen).

Possible warning messages will also be written to the log file and
to STDERR.

This happens for instance if a line is longer than the maximum permitted
number of characters per line (66) or if there was a problem closing the
input file, or if a needed configuration constant was unavailable.

=item *

C<$same = &CompareFiles($file1,$file2);>

Compares the contents of two files.

Returns "true" (1) if the files are the same, "false" (0) if they differ,
and "undef" in case of any error.

The corresponding error message will be written to the log file and
put on hold (for subsequent display on the screen, if desired) in the
latter case.

=item *

C<&CopyFile($source,$target);>

Copies file "C<$source>" to "C<$target>". Returns "true" (1) on success
and "undef" in case of any error.

The corresponding error message will be written to the log file and
put on hold (for subsequent display on the screen, if desired) in the
latter case.

=item *

C<&MoveByCopying($source,$target);>

Copies file "C<$source>" to "C<$target>", then deletes file
"C<$source>" if the copy was successful. Returns "true" (1)
on success and "undef" in case of any error.

The corresponding error message will be written to the log file and
put on hold (for subsequent display on the screen, if desired) in the
latter case.

Note that moving B<WITHOUT> copying is performed with Perl's built-in
"rename()" function!

BEWARE that moving without copying is not possible across file system
boundaries on most Unix systems!

So whenever you are unsure whether you are actually trying to move across
a file system boundary or not, better use "MoveByCopying()"!

Otherwise, this can easily lead to sudden errors when directory locations
are changed in the configuration!

YOU HAVE BEEN WARNED!

=item *

C<$checksum = &MD5Checksum($source);>

Determines the MD5 checksum for file "C<$source>". Returns the checksum
(a 16 digit hexadecimal string) on success and "undef" in case of any error.

The corresponding error message will be written to the log file and
put on hold (for subsequent display on the screen, if desired) in the
latter case.

MD5 is used in cryptography for "fingerprints"; it is guaranteed to
differ strongly for slightly altered input (but the reverse is not
necessarily true!).

In combination with the file's length, this can be used to uniquely
identify files, for instance in the recursive processing of certain
files, in order to avoid infinite recursion.

For example as follows ("C<$file>" contains the name and path of the
file in question, and "C<$checksum>" contains its checksum):

  if (defined $filesig{-s $file}{$checksum})
  {
      # file already known
  }
  else
  {
      # file not encountered yet
  }
  $filesig{-s $file}{$checksum}{$file} = 1; # add file to list

=item *

C<$arrayref = &ReadFile($source);>

Returns a reference to a Perl array containing the lines of the
given file (the input separator "C<$/>" is set to "\n" (line mode)
locally before the file is read).

Returns "undef" in case of any error.

The corresponding error message will be written to the log file and
put on hold (for subsequent display on the screen, if desired) in the
latter case.

BEWARE that the lines returned still have their terminating newline
character ("\n"), which you may need to get rid of (e.g. with "chomp")!

=item *

C<&WriteFile($target,@contents);>

Writes the given lines of text (or binary data) to the given file.

It is your responsibility to provide newline characters ("\n")
as necessary, the lines of text are simply concatenated (without
any intervening characters!) and written to the file.

(Therefore this routine is also suitable for binary data!)

You may at your option provide scalars as parameters (which will
be written to the file "as is"), or array references, whose contents
will be written to the file (also "as is"), or both (mixed).

Example:

  @msg = ();
  push( @msg, "1st line\n" );
  push( @msg, "2nd line\n" );
  &WriteFile( $target, "Messages:\n\n", \@msg );

Returns "true" (1) on success and "undef" in case of any error.

The corresponding error message will be written to the log file and
put on hold (for subsequent display on the screen, if desired) in the
latter case.

=item *

C<&AppendFile($target,$source);>

Appends file "C<$source>" to file "C<$target>" using binary mode.

Returns "true" (1) on success and "undef" in case of any error.

The corresponding error message will be written to the log file and
put on hold (for subsequent display on the screen, if desired) in the
latter case.

=item *

C<&ConvertFileWithCallback($target,$source,$callback);>

This is the most flexible method for reading a file, modifying its
contents, and writing them to another file.

The file "C<$source>" is read line by line (the input separator "C<$/>"
is set to "\n" (line mode) locally before the file is opened), and for
each line, a callback function (provided by you) is called.

Your callback function should expect two parameters: First, the line
just read, and second, this line's line number (you may not need the
line number, though, and can safely ignore it).

After processing the line, your callback function should return the
modified line or "undef".

The returned value is then written to the given "C<$target>" file,
provided that the return value is not "undef". If the callback function's
return value is "undef", nothing is printed to the output file. (This way,
you can delete certain lines from a file!)

BEWARE that the lines passed to the callback function still have their
terminating newline character ("\n"), which you may need to get rid of
(e.g. with "chomp") first and back on before returning the line!

Example of use:

  $cb = sub { my($l) = @_; $l =~ s!\s+$!!; "$l\n"; };
  &ReportErrorAndExit unless
      (defined &ConvertFileWithCallback($target,$source,$cb));

The function returns "true" (1) on success and "undef" in case of any error.

The corresponding error message will be written to the log file and
put on hold (for subsequent display on the screen, if desired) in the
latter case.

=item *

C<$printable = &SerializeSimple("varname",$datastructure);>

This function takes the name of a variable and the variable itself
as arguments, the latter of which is usually a reference to some
data structure.

The function returns a reference to an array which contains lines
that can be printed to the screen or a file. This reference can
also be passed to the "C<WriteFile()>" function, which will
automatically write the lines in the array to the indicated
file.

Note that the elements of this array already B<DO> have "newline"
characters ("C<\n>") at the end of each line.

As the name of this function indicates, it can only handle simple
data structures consisting of SCALARs, ARRAYs, HASHes and REFerences
thereof, but no objects, regular expressions, closures or external
data structures.

(See L<Data::Dumper(3)> for a more complete solution.)

Moreover, it cannot handle self-references and will enter an infinite
loop if any self-references are encountered (this will provoke a
"deep recursion" warning message printed to the screen).

The printable lines returned are valid Perl code which can be
read back in later from a file using "C<require>" or "C<eval>".

The name of the variable provided here will then determine which
variable the data structure will be assigned to.

Note that you can set this variable name to anything you like (but
your program which reads back the data structure will have to know
in advance which variable name to expect), and remember that you
can always fully qualify this variable name in order to force it
into any given package you want.

=item *

C<Semaphore_Passeer($lockfile);>

Protect critical sections in your code with this relatively
simple yet usually sufficient file locking mechanism.

The given file may not be used for anything else, as it will
be created and deleted and its contents rewritten.

In case of an error, the corresponding error message is
written to the default logfile and sent to the screen,
but the function will keep on trying infinitely.

There is no specific return value on success.

=item *

C<Semaphore_Verlaat($lockfile);>

Leave critical sections in your code by calling this function
with the same argument you called "Semaphore_Passeer()" (see
immediately above) before the critical section.

In case of an error, the corresponding error message is
written to the default logfile and sent to the screen,
and "undef" is returned.

In case of success a true value is returned.

=item *

C<$ticket = GetNextTicket($lockfile,$ticketfile,$min,$max);>

Get ticket numbers, protected by (true) file locking.

The ticket number is created automatically if it doesn't exist
yet (and initialized to the "C<$min>" value given).

Ticket number values may contain the characters [0-9a-zA-Z]
(in any combination).

The ticket number is incremented automatically at each call of
this function (using Perl's "magic" incrementation if the value
contains alphanumeric characters).

When the ticket number exceeds the given "C<$max>" value, it
is reset to "C<$min>" (i.e., the function implements automatic
wrapping).

In case file locking is not implemented on your machine, this
function uses "Semaphore_Passeer()" and "Semaphore_Verlaat()"
(see above) instead, provided that a non-empty lockfile name
has been given. Otherwise (if the lockfile name is undefined
or empty) no file locking will be performed at all.

Note that this function will always attempt to unlink
(i.e., delete) this lockfile if it is specified before
returning.

Thus it is advantageous to leave the lockfile name undefined
or empty if you know that your program will always run on
machines which support file locking.

Note also that the lockfile and the ticketfile must be
distinct of course.

In case of an error, the corresponding error message is
written to the default logfile and sent to the screen,
execution of the function is aborted and "undef" is
returned.

In case of success the new ticket number is returned.

=back

=head1 SEE ALSO

Config::Manager(3),
Config::Manager::Base(3),
Config::Manager::Conf(3),
Config::Manager::PUser(3),
Config::Manager::Report(3),
Config::Manager::SendMail(3),
Config::Manager::User(3).

=head1 VERSION

This man page documents "Config::Manager::File" version 1.7.

=head1 AUTHORS

 Steffen Beyer <sb@engelschall.com>
 http://www.engelschall.com/u/sb/download/
 Gerhard Albers

=head1 COPYRIGHT

 Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.
 All rights reserved.

=head1 LICENSE

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., under the terms of
the "Artistic License" or the "GNU General Public License".

Please refer to the files "Artistic.txt" and "GNU_GPL.txt"
in this distribution, respectively, for more details!

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

