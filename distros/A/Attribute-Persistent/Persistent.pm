package Attribute::Persistent;
use strict;
our $VERSION = "1.1";

my $key;

require Digest::MD5;
local *IN;
if (-e $0 and open IN, $0) {
    local $/;
    my $x = <IN>;
    $key = Digest::MD5::md5_hex($x);
    close IN;
} else {
    $key = "Persistent$0";
}

1;

package UNIVERSAL;
use Attribute::Handlers::Prospective;
use File::Spec::Functions (':ALL');
BEGIN { @AnyDBM_File::ISA = qw(DB_File GDBM_File NDBM_File) }
use AnyDBM_File;
use MLDBM qw(AnyDBM_File);

no strict; # Attributes do evil things
sub persistent :ATTR(RAWDATA) {
    my $name = *{$_[1]}{NAME};
    $name =~ /LEXICAL\((.*)\)/ or do {
        require Carp;
        croak("Can only define :persistent on lexicals");
    };
    my $origname = $1;
    $name = $origname;
    my $type;
    $name =~ s/^\$/S-/ 
        and do { require Carp; croak ("Can't persist scalars yet"); };
    $name =~ s/^\%/H-/ and $type = '%';
    $name =~ s/^\@/A-/ and $type = '@';
    # But ...
    if ($_[4] ne "undef") { $name = $_[4]; }
    $name =~ s/\W+/-/g;
    my $filename = catdir(tmpdir(),"$key-$_[0]-$name");
    tie (($type eq "%" ? %{$_[2]} : @{$_[2]}), "MLDBM", $filename)
    or do {require Carp; croak("Couldn't tie $origname to $filename - $!")};
}

1;

=head1 NAME

Attribute::Persistent - Really lazy persistence

=head1 SYNOPSIS

    use Attribute::Persistent;

    my %hash :persistent;
    $hash{counter}++; # Value retained between calls to the program.

    my %hash2 :persistent(SessionTable); # Explicitly provide a filename.

=head1 DESCRIPTION

This module provides a way of abstracting away persistence of array and
hash variables. 

It's useful for quick hacks when you don't care about pulling in the
right DBM library and calling C<tie> and so on. Its job is to reduce
fuss for the lazy programmer at the cost of flexibility.

It uses C<MLDBM>, so you can use complex data structures in your arrays
and hashes. It uses C<AnyDBM_File>, so if you really care about which
DBM you get, you can modify C<AnyDBM_File::ISA> in a C<BEGIN> block
B<after> loading this module.

It works out which DBMs belong to it by taking an md5 sum of the source
code. This means that if you change your code, you lose your data. 
If you like to keep your data while messing about with your code, you
need to explicitly give C<Attribute::Persistent> a key, like this:

    BEGIN { $Attribute::Persistent::KEY = "MyProgram"; }
    use Attribute::Persistent; # Order is important.

This uniquely identifies your program, meaning that the module doesn't
have to grub around with C<$0> and md5 sums.

But hell, it's not supposed to be this complex. Just use the module and
slap C<:persistent> onto your lexicals where appropriate, and it just
works. That's all most people need to care about.

=head1 AUTHOR

Originally by Simon Cozens, C<simon@cpan.org>

Maintained by Scott Penrose, C<scott@cpan.org>

=head1 LICENSE

Artistic and GPL.
