#!/bin/false
# not to be used stand-alone
#
# helper function to setup test-files and -directories:

sub _chmod($$)
{
    my $mode = shift;
    while (local $_ = shift)
    {
	$_ = TMP_PATH . $_;
	chmod $mode, $_  or  die "can't chmod $mode $_: $!";
    }
}

sub _remove_dir($)
{
    my $dir = shift;
    if (-e $dir)
    {	rmdir $dir  or  die "can't rmdir $dir: $!";   }
}

sub _remove_file($)
{
    local $_ = shift;
    $_ = TMP_PATH . $_;
    if (-e)
    {	unlink $_  or  die "can't unlink $_: $!";   }
}

sub _remove_link($)
{
    my ($sym_link) = @_;
    not -l $sym_link  or  unlink $sym_link  or  die "can't unlink $sym_link: $!";
}

sub _setup_dir($)
{
    local $_ =  shift;
    $_ = TMP_PATH . $_;
    -d  or  mkdir $_  or  die "can't mkdir $_: $!";
}

sub _setup_file($;@)
{
    my $file = shift;
    $file = TMP_PATH . $file;
    unless (-f $file)
    {
	open my $fh, '>', $file  or  die "can't create $file: $!";
	local $_;
	say $fh $_ foreach @_;
	close $fh;
    }
}

sub _setup_link($$)
{
    my ($sym_link, $dest) = @_;
    _remove_link($sym_link);
    symlink $dest, $sym_link  or  die "can't link $sym_link to $dest: $!";
}

1;
