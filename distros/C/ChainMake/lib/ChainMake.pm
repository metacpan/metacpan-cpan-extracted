package ChainMake;

use strict;
use warnings;
use Data::Dumper;
use Clone qw(clone);
use Fcntl (qw/:flock O_RDONLY O_CREAT/); # import LOCK_* constants
use Tie::File;

our $VERSION = '0.9.0';

our %DEFAULTS = (
    verbose         => 1,
    silent          => 0,
    timestamps_file => '.chainstamps',
    symbols         => [qr/\$t_name/,qr/\$t_base/,qr/\$t_ext/],
);

our %TARGETTYPE_PARAMS=(
    requirements => sub { (ref shift eq 'ARRAY') },
    insistent    => sub { 
        my $p=shift;
        return (($p == 0) || ($p == 1));
    },
    handler      => sub { (ref shift eq 'CODE') },
    timestamps   => sub {
        my $p=shift;
        return ( (ref $p eq 'ARRAY') || ($p eq 'once') );
    },
);

sub new {
    my $proto=shift;
    my %args=@_;
    my $self = bless {
        targettypes => [],
    }, ref($proto) || $proto;
    $self->configure(%args);
    return $self;
}

sub configure {
    my ($self,%args)=@_;
    $self->{$_}=
        defined($args{$_})   ? $args{$_}   :
        defined($self->{$_}) ? $self->{$_} :
        $DEFAULTS{$_}
    foreach (keys %DEFAULTS);
    return 1;
}

sub targets {
    # add one target_type
    my ($self,$targets,%target_t)=@_;
    $targets=[$targets] unless (ref $targets eq 'ARRAY');

    # check if some parameters are given at all
    unless ((@{$targets} > 0) && (keys %target_t)) {
        $self->_diag(0,"at least one targetname and some parameters please\n");
        return 0 ;
    }
    # only params from %TARGETTYPE_PARAMS allowed
    for (keys %target_t) {
        unless (defined $TARGETTYPE_PARAMS{$_}) {
            $self->_diag(0,"unknown parameter $_\n");
            return 0;
        }
        # perform pseudo type check
        unless ( &{$TARGETTYPE_PARAMS{$_}}($target_t{$_}) ) {
            $self->_diag(0,"illegal value in parameter $_\n");
            return 0;
        }
    }            
    # extra necessities
    unless (defined($target_t{requirements}) || defined($target_t{handler})) {
        $self->_diag(0,"at least requirements or handler must be supplied\n");
        return 0;
    }
    if (defined($target_t{timestamps}) && !defined($target_t{handler})) {
        $self->_diag(0,"timestamps cannot be supplied without handler\n");
        return 0;
    }

    $target_t{targets}=$targets;
    push (@{$self->{targettypes}},\%target_t);
}

sub chainmake {
    # returns 0 oder youngest
    # 0 means failure
    my ($self,$t_name)=@_;
    unless ($t_name) {
        $self->_diag(0,"Usage: $0 Target\nType '$0 help' for more info\n\n");
        return 0;
    }

    # Target "instanziieren", d.h. Targetnamen ($t_name etc.) anwenden
    my $target=clone($self->_match_target($t_name));
    unless($target) {
        if ($t_name eq 'help') {
            print "Available targets\n-----------------\n".$self->available_targets();
        }
        else {
            $self->_diag(0,"Don't know how to make $t_name. Maybe a typo?\n");
        }
        return 0;
    }
    # split target name into base and extension, handmade
    my $t_base=$t_name;
    my $t_ext='';
    if ($t_name =~ /^(.+)\.([^\.]+)$/) {
        $t_base = $1;
        $t_ext = $2;
    }
    # apply symbols in timestamps and requirements
    for (
        (ref $target->{timestamps} eq 'ARRAY') ? @{$target->{timestamps}} : (),
        (ref $target->{requirements} eq 'ARRAY') ? @{$target->{requirements}} : (),
    ){
        s/$self->{symbols}->[0]/$t_name/g;
        s/$self->{symbols}->[1]/$t_base/g;
        s/$self->{symbols}->[2]/$t_ext/g;
    }

    # muss Handler ausführen / kann Handler wegen fehlender Req nicht ausführen
    my ($must_make,$cannot_make);

    # Rausfinden, wie alt das älteste File von timestamps ist (=> $oldest)
    # und ob vielleicht sogar eines fehlt (=> $must_make=1)
    # Generelles Designproblem ist Auflösung des Timestamps=1s (Fat32: 2s)
    my $oldest;
    if ((defined $target->{timestamps}) &&
        (ref $target->{timestamps} eq 'ARRAY') &&
        (@{$target->{timestamps}} > 0)
    ) {
        (my $yy,$oldest,my $missing)=$self->_check_file_timestamps($target->{timestamps});
        if ($missing) {
            $must_make=1;
            undef $oldest;
        }
    }
    elsif ((defined $target->{timestamps}) &&
           ($target->{timestamps} eq 'once')) {
        my $ts=$self->_get_timestamp($t_name);
        if ($ts) {
            $oldest=$ts;
        }
        else {
            $must_make=1;
        }
    }
    # timestamps gibts nicht / unverständlich
    else {
        $must_make=1;
    }
    
    # Alle Requirements daraufhin prüfen (d.h. chainmake() darauf ausführen),
    # ob eines der Requirements jünger als unser ältestes timestamps-File ($oldest) ist
    my $youngest_req;
    if (ref $target->{requirements} eq 'ARRAY') {
        $youngest_req=$self->_check_requirements($target->{requirements},$target->{insistent},$target->{parallel});
        if ($youngest_req) {
            #print "$t_name - y: $youngest_req, o: $oldest ".(($youngest_req > $oldest) ? "younger (must make)\n": "older\n");
            $must_make=1 if ($oldest && ($youngest_req > $oldest));
        }
        else {
            $cannot_make=1;
        }
    }
    
    # From here on we potentially return from the method
    # to avoid too deeply nested if if ifs.
    
    # Irgendwas nicht erfolgreich?
    if ($cannot_make) {
        $self->_diag(2,"Cannot make '$t_name' due to missing requirements\n");
        return 0;
    }
    
    # Muss nix machen
    unless ($must_make) {
        $self->_diag(2,"Nothing to do for target '$t_name'.\n");
        if ((ref $target->{timestamps} eq 'ARRAY') && (@{$target->{timestamps}} > 0)) {
            (my $youngest,my $ol,my $missing)=$self->_check_file_timestamps($target->{timestamps});
            if ($missing) {
                $self->_diag(0,"This should not happen. Timestamps file '$missing' is still missing\n");
                return 0;
            }
            return $youngest;
        }
        # auto timestamps
        elsif ($target->{timestamps} eq 'once') {
            return $oldest; # hat sich nicht geändert
        }
        # timestamps gibts nicht / unverständlich
        else {
            return 1;
        }
    }
    
    # Kein Handler?
    unless (ref $target->{handler} eq 'CODE') {
        $self->_diag(2,"Nothing else to do for target '$t_name'\n");
        return 1;
    }
    
    # Handler ausführen
    # und dann rausfinden,
    # wie jung das jüngste File von timestamps jetzt ist
    $self->_diag(2,"\nMaking target $t_name\n");
    my $success=&{$target->{handler}}($t_name, $t_base, $t_ext, $youngest_req || undef, $oldest || undef);

    my $youngest;
    if ($success) {
        my $make_time=time;
        no warnings;
        if ((ref $target->{timestamps} eq 'ARRAY') && (@{$target->{timestamps}} > 0)) {
            ($youngest,my $ol,my $missing)=$self->_check_file_timestamps($target->{timestamps});
            if ($missing) {
                $self->_diag(0,"Timestamps file '$missing' is still missing. Looks like an error in your target handler\n");
                $youngest=0;
            }
        }
        elsif ($target->{timestamps} eq 'once') {
            $self->_write_timestamp($t_name => $make_time);
            $youngest=$make_time;
        }
        else {
            # timestamps gibts nicht / unverständlich
            $youngest=$make_time;
        }
        use warnings;
    }
    else {
        # make nicht erfolgreich
        $self->_diag(2,"Making $t_name was not successfull\n");
        # evtl. vorhandene timestamps files löschen
        if ((ref $target->{timestamps} eq 'ARRAY') && (@{$target->{timestamps}} > 0)) {
            for my $timestamps (@{$target->{timestamps}}) {
                if (-e $timestamps) {
                    $self->_diag(2,"Removing timestamps file $timestamps\n");
                    unlink $timestamps or $self->_diag(0,"Removing timestamps file $timestamps was not successfull\n");
                }
            }
        }
    }
        
    return $youngest || 0;
}

sub execute_system {
    my ($self,%cmd)=@_;
    my $cmd;
    if ($^O =~ /MSWin32/) {
       $cmd=$cmd{Windows} || $cmd{All};
    }
    else {
        $cmd=$cmd{Linux} || $cmd{All};
    }# there are no other OS in the world so far

    $self->_diag(1,"> $cmd\n");
    system($cmd);
    if ($? == -1) {
    	$self->_diag(0,"failed to execute: $!\n");
    }
    elsif ($? & 127) {
	    $self->_diag(0,sprintf "child died with signal %d, %s coredump\n",
            ($? & 127),  ($? & 128) ? 'with' : 'without');
    }
    else {
	    my $value=$? >> 8;
        return ($value == 0);
    }
    return undef;    
}

sub execute_perl {
    my ($self,$cmd)=@_;
    print "> $cmd\n";
    system("$^X $cmd");
    if ($? == -1) {
    	$self->_diag(0,"failed to execute: $!\n");
    }
    elsif ($? & 127) {
	    $self->_diag(0,sprintf "child died with signal %d, %s coredump\n",
            ($? & 127),  ($? & 128) ? 'with' : 'without');
    }
    else {
	    my $value=$? >> 8;
        return ($value == 0);
    }
    return undef;    
}

sub available_targets {
    my $self=shift;
    my $list;
    for (@{$self->{targettypes}}) {
        my @targets=@{$_->{targets}};
        my $col=0;
        while (@targets) {
            $list.=sprintf "%-30.30s", shift @targets;
            $list.="\n" if $col++==3;
            $col%=3;
        }
        $list.="\n";
    }
    return $list;
}   

sub _check_requirements {
    # Alle Requirements checken (d.h. make darauf ausführen),
    # und Timestamp des jüngsten zurückgeben.
    # serieller Modus
    my ($self,$req,$insistent,$parallel)=@_;
    my ($cannot_make,$cannot_make_name)=(0,'');
    my $youngest;
    REQUIREMENTS:
    for my $dep (@$req) {
        my $age;
        # ist es der Name eines Targets?
        if ($self->_match_target($dep)) {
            $age=$self->chainmake($dep);
            unless ($age) {
                $self->_diag(1,"Requirement '$dep' failed.\n");
                $cannot_make=1;
                $cannot_make_name=$dep;
                last REQUIREMENTS unless ($insistent);
            }
        }
        # oder der Name einer Datei?
        elsif (-e $dep) {
            $age=(stat($dep))[9];
        }
        # Requirement nicht auffindbar
        else {
            $self->_diag(1,"Missing requirement '$dep'.\n");
            $cannot_make=1;
            $cannot_make_name=$dep;
            last REQUIREMENTS unless ($insistent);
        }

        # ist dieses Requirement jünger als das bisher Jüngste?
        if (!($youngest) || (($age) && ($age > $youngest))) {
            $youngest=$age;
        }
    }
    return ($cannot_make ? 0 : $youngest);# $cannot_make_name kann er auch noch returnen
}

sub _match_target {
    my ($self,$t_name)=@_;
    for my $t (@{$self->{targettypes}}) {
        for my $name (@{$t->{targets}}) {
            my $match;
            if (ref($name) eq 'Regexp') {
                $match=$t_name =~ $name;
            }
            else {
                $match=$t_name eq $name;
            }
            if ($match) {
                return $t;
            }
        }
    }
    return undef;
}
    
sub _check_file_timestamps {
    my ($self,$ver)=@_;
    my ($oldest,$youngest,$missing);
    for my $timestamps (@{$ver}) {
        if (-e $timestamps) {
            my $mtime = (stat($timestamps))[9];
            $youngest=$mtime unless (($youngest) && ($youngest >= $mtime));
            $oldest=$mtime unless (($oldest) && ($oldest <= $mtime));
        }
        else {
            $missing=$timestamps;
        }
    }
    return ($oldest,$youngest,$missing);
}

sub _get_timestamp {
    my ($self,$target)=@_;
    my $ts;
    my $tie=tie(my @array, 'Tie::File', $self->{timestamps_file}, memory => 0, mode => O_RDONLY | O_CREAT ) or die "Kann Datei $$self{timestamps_file} nicht zum Lesen verbinden";
    $tie->flock(LOCK_SH);
    for (@array) {
        my ($t,$v)=split "\t";
        if ($t eq $target) {
            $ts=$v;
            last;
        }
    }
    undef $tie;
    untie @array;
    
    return $ts;
}

sub _write_timestamp {
    my ($self,$target,$val) = @_;

    my $tie=tie(my @array, 'Tie::File', $self->{timestamps_file}, memory => 0 ) or die "Kann Datei $$self{timestamps_file} nicht zum Lesen verbinden";
    $tie->flock(LOCK_EX);

    for my $n (0 .. $#array) {
        my ($t,$v) = split "\t", $array[$n];
        next unless $t eq $target;
        splice @array, $n, 1;
        last;
    }
    push(@array,"$target\t$val");
    undef $tie;
    untie @array;
}

sub delete_timestamp {
    my ($self,$target) = @_;
    my $ret=0;

    my $tie=tie(my @array, 'Tie::File', $self->{timestamps_file}, memory => 0 ) or die "Kann Datei $$self{timestamps_file} nicht zum Lesen verbinden";
    $tie->flock(LOCK_EX);

    for my $n (0 .. $#array) {
        my ($t,$v) = split "\t", $array[$n];
        if ($t eq $target) {
            splice(@array, $n, 1);
            $ret=1;
            last;
        }
    }
    
    undef $tie;
    untie @array;
    return $ret;
}

sub unlink_timestamps {
    my $self=shift;
    unlink $self->{timestamps_file};
    return 1;
}

sub _diag {
    my ($self,$type,$msg)=@_;
    if    ($type == 0) { # error
        print $msg unless ($self->{silent})}
    elsif ($type == 1) { # progress
        print $msg unless ($self->{silent});
    }
    elsif ($type == 2) { # verbose
        print $msg if ($self->{verbose} && !($self->{silent}));
    }
}

1;

__END__

=head1 NAME

ChainMake - Make targets with dependencies

=head1 SYNOPSIS

  # this example uses the function-oriented interface
  use ChainMake::Functions ':all';

  # this target is to generate example.dvi from example.tex
  target 'example.dvi', (
      timestamps     => ['$t_name'],
      requirements => ['$t_base.tex'],
      handler => sub {
          my ($t_name,$t_base,$t_ext)=@_;
          execute_system(
              All => "latex $t_base.tex",
          );
      }
  );

  # this target is to generate example.ps from example.dvi
  # and another.ps from another.dvi
  targets ['example.ps','another.ps'], (
      timestamps   => ['$t_name'],
      requirements => ['$t_base.dvi'],
      handler => sub {
          my ($t_name,$t_base,$t_ext)=@_;
          execute_system(
              All => "dvips -q -t a5 $t_base.dvi",
          );
      }
  );

  # this target is to generate a *.pdf from a *.ps
  target qr/^[^\.]+\.pdf$/, (
      timestamps   => ['$t_name'],
      requirements => ['$t_base.ps'],
      handler => sub {
          my ($t_name,$t_base,$t_ext)=@_;
          execute_system(
              All => "ps2pdf $t_base.ps $t_base.pdf",
          );
      }
  );

  target 'clean', (
      handler => sub {
          unlink qw/example.aux example.dvi example.log example.pdf example.ps/;
          1;
      }
  );

  target [qw/all All/], requirements => ['example.pdf','clean'];

  chainmake(@ARGV);

=head1 DESCRIPTION

This module helps with driving data through process chains. It can be a better alternative
to C<make> in some use cases.

 TODO: More bla here:

 * separation of target name from timestamp file
 
 * 'auto' timestamps, for targets that don't create files
   (i.e. xml validation)
 
 * write perl script in perl, not makefile in makefile lingo
 
 * typically for processing files (xml, images etc.)
   through several process steps (i.e. latex, xslt, pbmtools)
   
 * not so much for compiling and installing software,
   i.e. principally possible,
   but no luxury (libpath etc.) provided so far
  
 * in summary it is a better alternative for use cases
   that 'make' is not really intended for,
   but still widely used

A script that uses this module will typically L<create one ChainMake object|/new>,
add some L</targets> to it and then call the L</chainmake> method, potentially with
user supplied parameters.

For a more declarative look-and-feel,
script authors may also consider using the function-oriented
interface provided by L<ChainMake::Functions|ChainMake::Functions> .

=head1 METHODS

=head2 new

  my $cm=new ChainMake(%options);

Creates a new ChainMake object. Options C<%options> are the same as for configure.

=head2 configure

  $cm->configure(
    timestamps_file => '.timestamps_file',
    symbols     => [ qr/\$t_name/, qr/\$t_base/, qr/\$t_ext/ ],
    verbose     => 1,
    silent      => 0,
  );

Configures the ChainMake object. Available options are discussed below. Default values are shown above.

=over 2

=item timestamps_file

C<timestamps_file> is a filename that will be used for automatic timestamps as discussed under
L</timestamps>.

=item symbols

C<symbols> is a list of three regular expressions that are used for referring
to the current target name. See L</requirements> below.

=item verbose

Usage of C<verbose> is under development and will change.

=item silent

Usage of C<silent> is under development and will change.

=back

=head2 targets

  $cm->targets( ['all', 'document'],
      requirements => ['document.html', 'document.pdf']
  );

Adds a new target type. A human readable explanation will be given below.

For reference, this is a pseudo formal form of the syntax:

  $target_names = targetname | regexp | [targetname | regexp, ...]
  
  %description = (
      requirements => [ targetname | filename, ... ] | (),
      insistent    => 0 | 1,
      parallel     => 0 | number,
      handler      => coderef | (),
      timestamps   => [ filename, ... ] | 'once' | (),
  );
  
  $cm->targets( $target_names, %description );

These are examples in perl:

  $cm->targets( ['all', 'document'],
      requirements => ['document.html', 'document.pdf']
  );

  $cm->targets( qr/^[^\.]+\.html?$/,
      requirements => ['$t_base.xml'],
      handler      => sub { ... },
      timestamps   => ['$t_base.$t_ext'],
  );

=over 2

=item target names

The first argument of the C<targets> method is for supplying one or more
targets names. Target names can be strings or regular expressions.

The C<targets> method declares a target type that is used
for all targets that match any of the supplied target names.

=item requirements

  %description = (
      requirements => ['index.txt', '$t_base.dat'],
  }

The C<requirements> field lists things that need to be done before the target can
be made. The C<requirements> field is optional, but either C<requirements> or a C<handler>
must be specified.

Requirements may be given as targets or filenames. If a given requirement does not match
a target it is regarded a filename. Filenames should include a path if necessary.

The C<requirements> strings may contain any of the three C<symbols> specified with L</configure>.
The symbols will be replaced with the current target's full name, base name (without extension)
and extension respectively. Assuming that you haven't defined different C<symbols>
the following will be replaced in the C<requirements> of a target 'index.html':

  $t_name -> index.html
  $t_base -> index
  $t_ext  -> html

=item handler

  %description = (
      handler => sub {
          my ($t_name, $t_base, $t_ext) = @_;
          execute_system(
              All => "dvips -q -t a5 $t_base.dvi",
          );
      }
  }

The C<handler> field can be used to supply a subroutine that will be
executed to build the target. The return value of this subroutine should indicate
whether the build has been successfull.

Three parameters will be passed to the subroutine: The full name of the target to make,
only the base part of this name (minus the extension), and the extension of the target name.
These three variables equal the replacement C<symbols> discussed under L</requirements>
and should convienently be named equally, i.e. C<$t_name>, C<$t_base>, C<$t_ext>.

If no C<handler> is supplied, the target will always be considered successfull.

=item timestamps

  %description = (
      timestamps   => ['index.html'],
  }
  
  %description2 = (
      timestamps   => 'once',
  }

The C<timestamps> field defines how to check whether the target is up-to-date.
Either one or more filenames or the string C<once> may be supplied.

The separation of the timestamps from the target name is an important difference
between this module and C<make>.

If the C<timestamps> field is supplied, the C<handler> field must be supplied as well.

If the C<timestamps> is missing, each time that C<chainmake()> is performed on the target
all C<requirements> will be checked and the C<handler> will be executed.

=over 4

=item filename based timestamps

In case one or more filenames are given, the timestamp (age) of the oldest
of these files is determined. This timestamp is compared to the timestamps of all
of the C<requirements> to find out if the target is outdated or not.

The filenames may be identical to target names, but, as opposed to C<make>,
does not need to be. The filename is given with a path relative to the current
directory. For a filename that matches the target name use
C<timestamps =E<gt> ['$t_name']>.

The file should typically be a file that the C<handler> produces from at least some
of the C<requirements>. The C<handler> must at least C<touch> the file to make this
form of timestamps work. If this is not the case, use C<'once'>.

If the C<handler> fails, any remaining files listed under C<timestamps> will be removed.

=item automatic timestamps using 'once'

The string C<once> may be supplied instead of a list reference. This turns on automatic
bookkeeping of the target's status.

The data necessary for the C<once> automatism is stored in a file with the name that
has been defined with the L</timestamps_file> option.

=back

=item insistent

  %description = (
      insistent    => 1,
  );

The C<insistent> field defines if remaining requirements should still still be checked
after one requirement failed. Default behaviour is to stop.

When a target has several requirements they will be all be checked (and built if necessary)
before this target can be built. If one of the requirements fails, i.e. does not exist
or fails to built, the remaining requirements may still be checked (C<insistent =E<gt> 1>)
or the attempt to build the target may aborted immediately (C<insistent =E<gt> 0>).

=back

=head2 chainmake

  $cm->chainmake($target);

Makes the target C<$target>.

This is a simplified schematic of the algorithm in use:

=over 2

=item *

Find matching target type

=item *

See, if all L</timestamps> files are present and how old the oldest one is (C<$oldest>)

=item *

Go through all L</requirements>:

=over 4

=item *

For the ones that are targets, call C<chainmake()> on each of
them to learn about their age (recursion here)

=item *

For the ones that are files, check their age

=item *

Compare all these ages with C<$oldest>
to see if one requirement is younger than the target C<$target>.
If so, we'll have to run the L</handler>

=item *

If any requirement is missing: we cannot make C<$target>;
Continue with examining the remaining requirements if L</insistent> == 1

=item *

The youngest of all the seen requirements is C<$youngest_requirement>, as passed to the handler.

=item *

Entire loop done in parallel threads by L<ChainMake::Parallel>

=back

=item *

Run the handler if necessary

=item *

Return the age of the youngest file in L</timestamps>

=back

=head2 available_targets

  print $cm->avaliable_targets();

Returns a formatted string listing the available targets.
This will maybe change.

=head2 delete_timestamp

  $cm1->delete_timestamp('document.validation')

Deletes the automatic (C<'once'>) timestamp for the given target.

=head2 unlink_timestamps

Unlinks the timestamps file.

=head2 execute_system

Under development.

=head2 execute_perl

Under development, i.e. too lazy to document right now.

=head1 CAVEATS/BUGS

None known. In the Rakudo way: It passes almost 300 tests.

=head1 SEE ALSO

My search for similar modules has returned the following

=over

=item L<TinyMake>

Very minimalistic. Syntax tries to mimic makefile syntax.

=item L<File::Maker>

Uses some sort of database. Difficult-to-read documentation.

=back

=head1 AUTHOR/COPYRIGHT

This is $Id: ChainMake.pm 1231 2009-03-15 21:23:32Z schroeer $.

Copyright 2008-2009 Daniel Schröer (L<schroeer@cpan.org>). Any feedback is appreciated.

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut  
