package B::LexInfo;

use strict;
use DynaLoader ();
use B ();
#use B::Asmdata qw(@specialsv_name);
use Symbol ();
use Data::Dumper qw(Dumper);

eval {
    require Tie::IxHash;
};

use vars qw($TmpDir $DiffCmd);

{
    no strict;
    @ISA = qw(DynaLoader);
    $VERSION = '0.02';
    __PACKAGE__->bootstrap($VERSION);
}

$TmpDir  ||= "/tmp";
unless ($DiffCmd) {
    for (split ":", $ENV{PATH}) {
	$DiffCmd = "$_/diff";
	last if -x $DiffCmd;
    }
    $DiffCmd .= " -u";
}

my $SPECIAL = 0;

sub new { bless {}, shift }

sub addr {
    my $sv = shift;
    sprintf "0x%lx", $$sv;
}

sub lexinfo {
    my $cv = shift;
    my $obj = B::svref_2object($cv);
    if ($obj->PADLIST->isa('B::SPECIAL')) {
	my $name = join '::', $obj->GV->STASH->NAME, $obj->GV->NAME;
	return { ALIAS => $name };
    }
    my($padnames, $padvals) = $obj->PADLIST->ARRAY;
    my @names = $padnames->ARRAY;
    my @vals = $padvals->ARRAY;

    my %info = ();

    for (my $i = 1; $i <= $padnames->FILL; $i++) {
	my $val = $vals[$i]->lexval;
	$val->{TYPE} = B::class($vals[$i]);
	$val->{ADDRESS} = addr($vals[$i]);
	$info{ $names[$i]->lexname } = $val;
    }

    if(defined %Tie::IxHash::) {
	my %sorted;
	tie %sorted, "Tie::IxHash";
	%sorted = map { $_, $info{$_} } sort keys %info;
	return \%sorted;
    }

    \%info;
}

sub stash_cvlexinfo {
    my($self, $stash) = @_;
    no strict;
    $self->cvlexinfo(map { "$stash\::$_" } grep { 
	defined &{"$stash\::$_"} 
    } keys %{"$stash\::"});
}

sub cvrundiff {
    my $self = shift;
    my $name = shift;
    my $before = B::LexInfo->cvlexinfo($name);
    (\&{$name})->(@_);
    my $after = B::LexInfo->cvlexinfo($name);
    return B::LexInfo->diff($before, $after);
}

sub cvlexinfo {
    my $self = shift;
    my @objs = @_;
    my @retval = ();
    for my $name (@objs) {
	$SPECIAL = 0;
	$name = "main::$name" unless $name =~ /::/;
	push @retval, { $name => lexinfo(\&{$name}) };
    }
    \@retval;
}

sub dumper {
    my $self = shift;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    \Data::Dumper::Dumper(@_);
}

sub saveobj {
    my($self, $file, $obj) = @_;
    my $fh = Symbol::gensym();
    open $fh, ">$file" or die "open $file: $!";
    print $fh ${ $self->dumper($obj) };
    close $fh;
}

sub diff {
    my($self, $before, $after, $name) = @_;
    $name ||= "B_LexInfo_$$";
    my $file_b = "$TmpDir/$name.before";
    my $file_a = "$TmpDir/$name.after";
    $self->saveobj($file_b, $before);
    $self->saveobj($file_a, $after);

    my $cmd = "$DiffCmd $file_b $file_a";
    if ($cmd =~ /^([^<>|;]+)$/) {
	$cmd= $1;
    } 
    else {
	die "TAINTED data in `$cmd'";
    }

    my $pipe = Symbol::gensym();
    local $ENV{PATH};
    open $pipe, "$cmd|" or do {
	unlink $file_b, $file_a;
	die "diff: $!";
    };
    local $/;
    my $retval = \<$pipe>;
    close $pipe;

    unlink $file_b, $file_a;

    $retval;
}

sub B::PV::lexname {
    shift->PV;
}

sub B::SPECIAL::lexname {
    my $sv = shift;
    #$specialsv_name[$$sv];
    "__SPECIAL__" . ++$SPECIAL;
}

sub B::RV::lexval {
    my $sv = shift;
    #my $rv = $sv->RV;
    +{ RV => sprintf "0x%lx", $$sv }
}

sub B::PV::lexval {
    my($sv) = @_;
    +{ map { $_, $sv->$_() } qw(LEN CUR PV) }
}

sub B::AV::lexval {
    my($sv) = @_;
    +{ map { $_, $sv->$_() } qw(FILL MAX) }
}

sub B::HV::lexval {
    my($sv) = @_;
    +{ map { $_, $sv->$_() } qw(FILL MAX KEYS) }
}

sub B::IV::lexval {
    my($sv) = @_;
    +{ IV => $sv->IV }
}

sub B::NV::lexval {
    my($sv) = @_;
    +{ NV => $sv->NV }
}

sub B::PVIV::lexval {
    my($sv) = @_;
    my $info = $sv->B::PV::lexval;
    $info->{IV} = $sv->IV;
    $info;
}

sub B::PVNV::lexval {
    my($sv) = @_;
    my $info = $sv->B::PV::lexval;
    $info->{NV} = $sv->NV;
    $info;
}

sub B::NULL::lexval {
    my($sv) = @_;
    +{ NULL => sprintf "0x%lx", $$sv }
}
    
sub B::SPECIAL::lexval {
    my($sv) = @_;
    +{ SPECIAL => sprintf "0x%lx", $$sv }
}

1;

__END__

=head1 NAME

B::LexInfo - Show information about subroutine lexical variables

=head1 SYNOPSIS

  use B::ShowLex ();
  my $lexi = B::ShowLex->new;

=head1 DESCRIPTION

Perl stores lexical variable names and values inside a I<padlist>
within the subroutine.  Certain lexicals will maintain certain
attributes after the the variable "goes out of scope".  For example,
when a scalar is assigned a string value, this value remains after the 
variable has gone out of scope, but is overridden the next time it is
assigned to.  Lexical Arrays and Hashes will retain their storage
space for the maximum number of entries stored at any given point in
time.

This module provides methods to record this information, which can be
dumped out as-is or to compare two "snapshots".  The information
learned from these snapshots can be valuable in a number of ways.

=head1 METHODS

=over 4

=item new

Create a new I<B::LexInfo> object:

 my $lexi = B::LexInfo->new;

=item cvlexinfo

Create a padlist snapshot from a single subroutine:

  my $info = $lexi->cvlexinfo('Foo::bar');

=item stash_cvlexinfo

Create a list of padlist snapshots for each subroutine in the given
package:

  my $info = $lexi->stash_cvlexinfo('Foo');

=item dumper

Return a reference to a stringified padlist snapshot:

  print ${ $lexi->dumper($info) }

=item diff

Compare two padlist snapshots and return the difference:

 my $before = $lexi->stash_cvlexinfo(__PACKAGE__);
 ... let some code run
 my $after = $lexi->stash_cvlexinfo(__PACKAGE__);

 my $diff = B::LexInfo->diff($before, $after);
 print $$diff;

NOTE: This function relies on the I<diff -u> command.  You might need
to configure B<$B::LexInfo::TmpDir> and/or B<$B::LexInfo::DiffCmd> to
values other than the defaults in I<LexInfo.pm>.

=item cvrundiff

Take a padlist snapshot of a subroutine, run the subroutine with the
given arguments, take another snapshot and return a diff of the
snapshots.

 my $diff = $lexi->cvrundiff('Foo::bar', "arg1", $arg2);
 print $$diff;

Complete example:

 package Foo;
 use B::LexInfo ();

 sub bar {
     my($string) = @_;
 }

 my $lexi = B::LexInfo->new;
 my $diff = $lexi->cvrundiff('Foo::bar', "a string");
 print $$diff;

Produces:

 --- /tmp/B_LexInfo_1848.before  Mon Jun 28 19:48:41 1999
 +++ /tmp/B_LexInfo_1848.after   Mon Jun 28 19:48:41 1999
 @@ -2,8 +2,10 @@
    {
      'Foo::bar' => {
        '$string' => {
 -        'TYPE' => 'NULL',
 -        'NULL' => '0x80efd58'
 +        'TYPE' => 'PV',
 +        'LEN' => 9,
 +        'PV' => 'a string',
 +        'CUR' => 8
        },
        '__SPECIAL__1' => {
          'TYPE' => 'NULL',

=back

=head1 SNAPSHOT INFO

Snapshots are built using Perl structures and stringified using
I<Data::Dumper>.  Hash key order is sorted and preserved if you you
the I<Tie::IxHash> module installed.  Entry names are that of the
variable itself or I<__SPECIAL__$n> for entries that are used by Perl
internally.  The key/value pairs for each entry depends on the
variable type and state.  Docs on that to come, in the meantime, study:
http://gisle.aas.no/perl/illguts/

=head1 SEE ALSO

B(3), Apache::RegistryLexInfo(3), Devel::Peek(3)

=head1 AUTHOR

Doug MacEachern
