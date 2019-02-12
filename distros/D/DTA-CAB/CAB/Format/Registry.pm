## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::Registry.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: registry for I/O formats

package DTA::CAB::Format::Registry;
use DTA::CAB::Persistent;
use DTA::CAB::Logger;
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Persistent DTA::CAB::Logger);

BEGIN {
  *isa = \&UNIVERSAL::isa;
  *can = \&UNIVERSAL::can;
}

##==============================================================================
## Constructors etc.

## $reg = DTA::CAB::Format::Registry->new(%args)
##  + %$obj, %args:
##    (
##     reg => [\%classReg, ...],               ##-- registered classes
##     short2reg => {$short=>\%classReg, ...}, ##-- short names to registry entries
##     base2reg  => {$base =>\%classReg, ...}, ##-- base names to registry entries
##    )
##  + each \%classReg is a HASH-ref of the form:
##    {
##     name          => $basename,      ##-- basename for the class (package name)
##     short         => $shortname,     ##-- short name for the class (default = package name suffix, lower-cased)
##     readerClass   => $readerClass,   ##-- default: $base
##     writerClass   => $writerClass,   ##-- default: $base
##     readerOpts    => \%readerOpts,   ##-- default: none
##     writerOpts    => \%writerOpts,   ##-- default: none
##     opts          => \%commonOpts,   ##-- default: none
##     filenameRegex => $regex,         ##-- filename regex for guessFilename()
##    }
sub new {
  my $that = shift;
  my $reg  = bless({
		    reg => [],
		    short2reg => {},
		    base2reg  => {},
		    @_,
		   }, ref($that)||$that);
  $reg->refresh();
  return $reg;
}

## $reg = $reg->clear()
##  + clears the registry
sub clear {
  my $reg = shift;
  @{$reg->{reg}} = qw();
  %{$reg->{short2reg}} = qw();
  %{$reg->{base2reg}} = qw();
  return $reg;
}

## $reg = $reg->refresh();
##  + re-registers all formats in $reg->{reg}
sub refresh {
  my $reg = shift;
  my @creg = @{$reg->{reg}};
  $reg->clear();
  $reg->register(%$_) foreach (reverse @creg);
  return $reg;
}

## $reg = $reg->compile(%opts)
##  + adds following keys to each registry item \%classReg:
##    (
##     reader => $readerObj,  ##-- = $classReg{readerClass}->new($reg->readerOpts($classReg,%opts))
##     writer => $writerObj,  ##-- = $classReg{writerClass}->new($reg->writerOpts($classReg,%opts))
##    )
sub compile {
  my $reg = shift;
  foreach (@{$reg->{reg}}) {
    $_->{reader} = $_->{readerClass}->new($reg->readerOpts($_),@_) if (can($_->{readerClass},'new'));
    $_->{writer} = $_->{writerClass}->new($reg->writerOpts($_),@_) if (can($_->{writerClass},'new'));
  }
  return $reg;
}

## \%classReg = $reg->register(%classReg)
##  + %classReg:
##    (
##     name          => $basename,      ##-- basename for the class (package name): REQUIRED
##     short         => $shortname,     ##-- short name for the class (default = package name suffix, lower-cased)
##     readerClass   => $readerClass,   ##-- default: $base
##     writerClass   => $writerClass,   ##-- default: $base
##     readerOpts    => \%readerOpts,   ##-- default: none
##     writerOpts    => \%writerOpts,   ##-- default: none
##     opts          => \%commonOpts,   ##-- default: none
##     filenameRegex => $regex,         ##-- filename regex for guessFilenameFormat()
##    )
sub register {
  my ($reg,%opts) = @_;
  ##
  if (!defined($opts{name})) {
    $reg->logwarn("register(): 'name' key required!");
    return undef;
  }
  $opts{readerClass} = $opts{name} if (!defined($opts{readerClass}));
  $opts{writerClass} = $opts{name} if (!defined($opts{writerClass}));
  if (!defined($opts{short})) {
    $opts{short} = lc($opts{name});
    $opts{short} =~ s/.*\:\://;
  }
  my $creg = {%opts};
  unshift(@{$reg->{reg}}, $creg);
  $reg->{short2reg}{$opts{short}} = $creg;
  $reg->{base2reg}{$opts{name}}   = $creg;
  return $creg;
}


##==============================================================================
## Methods: Access

## \%classReg_or_undef = $reg->lookup(%opts)
##  + Get the most recently registered entry for %opts, which may contain
##    (in order of decreasing priority):
##     class => $class,      ##-- short name, basename, or "DTA::CAB::Format::" suffix
##     file  => $filename,   ##-- attempt to guess format from $filename
sub lookup {
  my ($reg,%opts) = @_;
  if (defined($opts{class})) {
    ##-- lookup: by class name
    my $class = $opts{class};
    return $reg->{short2reg}{$class}     if ($reg->{short2reg}{$class});
    return $reg->{short2reg}{lc($class)} if ($reg->{short2reg}{lc($class)});
    return $reg->{base2reg}{$class}      if ($reg->{base2reg}{$class});
    ##
    $class = "DTA::CAB::Format::${class}" if (!isa($class,'DTA::CAB::Format'));
    #$that->logconfess("lookup(): unknown format class '$class'") if (!isa($class,'DTA::CAB::Format'));
    return $reg->{base2reg}{$class} if ($reg->{base2reg}{$class});
  }
  elsif (defined($opts{file})) {
    my $filename = $opts{file};
    foreach (@{$reg->{reg}}) {
      return $_ if (defined($_->{filenameRegex}) && $filename =~ $_->{filenameRegex});
    }
  }
  return undef;
}

## $fmt = $reg->newFormat($class_or_short_or_suffix, %opts)
##  + creates a new format of the registered base class matching $class_or_short_or_suffix;
##    backwards-compatible
sub newFormat {
  my ($reg,$class,%opts) = @_;
  my $creg = $reg->lookup(class=>$class,%opts);
  return undef if (!defined($creg));
  return $creg->{name}->new($reg->commonOpts($creg),%opts);
}

## %opts = $reg->commonOpts($creg)
##  + common class options
sub commonOpts {
  #my ($reg,$creg) = @_;
  return $_[1]{opts} ? %{$_[1]{opts}} : qw();
}

## %opts = $reg->readerOpts($creg)
sub readerOpts {
  return ($_[0]->commonOpts($_[1]), ($_[1]{readerOpts} ? %{$_[1]{readerOpts}} : qw()));
}

## %opts = $reg->writerOpts($creg)
## %opts = $reg->readerOpts($creg)
sub writerOpts {
  return ($_[0]->commonOpts($_[1]), ($_[1]{writerOpts} ? %{$_[1]{writerOpts}} : qw()));
}

## $class_or_undef = $reg->readerClass($class_or_short_or_suffix,%opts)
##  + get registered reader class for $class_or_short_or_suffix;  accepts $opts{file}
sub readerClass {
  my ($reg,$class,%opts) = @_;
  my $creg = $reg->lookup(class=>$class,%opts);
  return $creg ? $creg->{readerClass} : undef;
}

## $class_or_undef = $reg->writerClass($class_or_short_or_suffix,%opts)
##  + get registered writer class for $class_or_short_or_suffix; accepts $opts{file}
sub writerClass {
  my ($reg,$class,%opts) = @_;
  my $creg = $reg->lookup(class=>$class,%opts);
  return $creg ? $creg->{writerClass} : undef;
}

## $class_or_undef = $reg->formatClass($class_or_short_or_suffix,%opts)
##  + get registered common reader/writer class for $class_or_short_or_suffix; accepts $opts{file}
##  + returns undef if reader and writer classes for $class_or_short_or_suffix are distinct; accepts $opts{file}
sub formatClass {
  my ($reg,$class,%opts) = @_;
  my $creg = $reg->lookup(class=>$class,%opts);
  return $creg->{readerClass} if ($creg && ($creg->{readerClass}//'') eq ($creg->{writerClass}//''));
  return undef;
}

## $fmt = $reg->newReader(%opts)
##  + %opts may contain any %lookup options (class,file), and are
##    otherwise passed to CLASS->new()
sub newReader {
  my ($reg,%opts) = @_;
  my $creg = $reg->lookup(%opts);
  return undef if (!defined($creg));
  delete @opts{qw(class file)};
  return $creg->{readerClass}->new($reg->readerOpts($creg),%opts);
}

## $fmt = $reg->newWriter(%opts)
##  + special %opts:
##     class => $class,    ##-- classname or DTA::CAB::Format suffix
##     file  => $filename, ##-- attempt to guess format from filename
sub newWriter {
  my ($reg,%opts) = @_;
  my $creg = $reg->lookup(%opts);
  return undef if (!defined($creg));
  delete @opts{qw(class file)};
  return $creg->{writerClass}->new($reg->writerOpts($creg),%opts);
}

## $readerClass_or_undef = $CLASS_OR_OBJ->fileReaderClass($filename)
##  + backkwards-compatible wrapper for lookup(); attempts to guess reader class name from $filename
sub fileReaderClass {
  my ($reg,$filename) = @_;
  my $creg = $reg->lookup(file=>$filename);
  return defined($creg) ? $creg->{readerClass} : undef;
}

## $readerClass_or_undef = $CLASS_OR_OBJ->fileWriterClass($filename)
##  + backwards-compatible wrapper for lookup(); attempts to guess writer class name from $filename
sub fileWriterClass {
  my ($reg,$filename) = @_;
  my $creg = $reg->lookup(file=>$filename);
  return defined($creg) ? $creg->{writerClass} : undef;
}

## \%classReg_or_undef = $reg->guessFilenameFormat($filename)
##   + backwards-compatible wrapper for $reg->lookup(file=>$filename)
sub guessFilenameFormat {
  my ($reg,$file) = @_;
  return $reg->lookup(file=>$file);
}

## \%classReg_or_undef = $reg->short2reg($shortname)
##  + gets registry entry for short name $shortname
sub short2reg {
  return $_[0]{short2reg}{$_[1]};
}

## \%classReg_or_undef = $reg->base2reg($basename)
##  + gets registry entry for class basename $basename
sub base2reg {
  return $_[0]{base2reg}{$_[1]};
}

##========================================================================
## Storable stuff

## ($serialized, $ref1, ...) = $obj->STORABLE_freeze($cloning)
sub STORABLE_freeze {
  my ($obj,$cloning) = @_;
  return ('',[map { {%$_,(defined($_->{filenameRegex}) ? (filenameRegex=>"$_->{filenameRegex}") : qw())} } @{$obj->{reg}}]);
}

## $fsm = STORABLE_thaw($fsm, $cloning, $serialized, $ref1,...)
sub STORABLE_thaw {
  my ($obj,$cloning,$ser,$classes) = @_;
  $obj->clear();
  @{$obj->{reg}} = @$classes;
  $obj->refresh();
  return $obj;
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::Registry - registry for DTA::CAB I/O formats

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::Registry;
 
 ##========================================================================
 ## Constructors etc.
 
 $reg = DTA::CAB::Format::Registry->new(%args);
 $reg = $reg->clear();
 $reg = $reg->refresh();
 $reg = $reg->compile(%opts);
 \%classReg = $reg->register(%classReg);
 
 ##========================================================================
 ## Methods: Access
 
 \%classReg_or_undef = $reg->lookup(%opts);
 $fmt = $reg->newFormat($class_or_short_or_suffix, %opts);
 
 $class_or_undef = $reg->readerClass($class_or_short_or_suffix);
 $class_or_undef = $reg->writerClass($class_or_short_or_suffix);
 $fmt = $reg->newReader(%opts);
 $fmt = $reg->newWriter(%opts);
 
 $readerClass_or_undef = $CLASS_OR_OBJ->fileReaderClass($filename);
 $readerClass_or_undef = $CLASS_OR_OBJ->fileWriterClass($filename);
 \%classReg_or_undef = $reg->guessFilenameFormat($filename);
 
 \%classReg_or_undef = $reg->short2reg($shortname);
 \%classReg_or_undef = $reg->base2reg($basename);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Format::Registry provides an object-oriented API for maintainence
and easy access to a set of L<DTA::CAB::Format|DTA::CAB::Format> subclasses.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Registry: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $reg = DTA::CAB::Format::Registry->new(%args);

%$obj, %args:

  reg => [\%classReg, ...],               ##-- registered classes
  short2reg => {$short=>\%classReg, ...}, ##-- short names to registry entries
  base2reg  => {$base =>\%classReg, ...}, ##-- base names to registry entries

each \%classReg is a HASH-ref of the form:

  name          => $basename,      ##-- basename for the class (package name)
  short         => $shortname,     ##-- short name for the class (default = package name suffix, lower-cased)
  readerClass   => $readerClass,   ##-- default: $base   ##-- NYI
  writerClass   => $writerClass,   ##-- default: $base   ##-- NYI
  filenameRegex => $regex,         ##-- filename regex for guessFilename()

See also L</register>.

=item refresh

 $reg = $reg->clear();

Clears the registry.

=item refresh

 $reg = $reg->refresh();

Re-registers all formats in $reg-E<gt>{reg}.

=item compile

 $reg = $reg->compile(%opts);

Adds the following keys to each registry item \%classReg:

 reader => $readerObj,  ##-- = $classReg{readerClass}->new(%opts)
 writer => $writerObj,  ##-- = $classReg{writerClass}->new(%opts)


=item register

 \%classReg = $reg->register(%classReg);

%classReg:

 name          => $basename,      ##-- basename for the class (package name): REQUIRED
 short         => $shortname,     ##-- short name for the class (default = package name suffix, lower-cased)
 readerClass   => $readerClass,   ##-- default: $base   ##-- NYI
 writerClass   => $writerClass,   ##-- default: $base   ##-- NYI
 filenameRegex => $regex,         ##-- filename regex for guessFilenameFormat()

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::Registry: Methods: Access
=pod

=head2 Methods: Access

=over 4

=item lookup

 \%classReg_or_undef = $reg->lookup(%opts);

Get the most recently registered entry for %opts, which may contain
(in order of decreasing priority):

 class => $class,      ##-- short name, basename, or "DTA::CAB::Format::" suffix
 file  => $filename,   ##-- attempt to guess format from $filename

=item newFormat

 $fmt = $reg->newFormat($class_or_short_or_suffix, %opts);

Creates a new format of the registered base class matching $class_or_short_or_suffix;
backwards-compatible.

=item readerClass

 $class_or_undef = $reg->readerClass($class_or_short_or_suffix);

Get registered reader class for $class_or_short_or_suffix

=item writerClass

 $class_or_undef = $reg->writerClass($class_or_short_or_suffix);

Get registered writer class for $class_or_short_or_suffix

=item newReader

 $fmt = $reg->newReader(%opts);

Create and return a new reader object.
%opts may contain any %lookup options (class,file), and are
otherwise passed to READERCLASS-E<gt>new()

=item newWriter

 $fmt = $reg->newWriter(%opts);

Create and return a new writer object.
%opts may contain any %lookup options (class,file), and are
otherwise passed to WRITERCLASS-E<gt>new().

=item fileReaderClass

 $readerClass_or_undef = $CLASS_OR_OBJ->fileReaderClass($filename);

Backkwards-compatible wrapper for lookup(); attempts to guess reader class name from $filename.

=item fileWriterClass

 $readerClass_or_undef = $CLASS_OR_OBJ->fileWriterClass($filename);

Backwards-compatible wrapper for lookup(); attempts to guess writer class name from $filename.

=item guessFilenameFormat

 \%classReg_or_undef = $reg->guessFilenameFormat($filename);

Backwards-compatible wrapper for $reg-E<gt>lookup(file=E<gt>$filename).

=item short2reg

 \%classReg_or_undef = $reg->short2reg($shortname);

Gets registry entry for short name $shortname.

=item base2reg

 \%classReg_or_undef = $reg->base2reg($basename);

Gets registry entry for class basename $basename.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...

=cut
