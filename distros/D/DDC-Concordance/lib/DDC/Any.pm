#-*- Mode: CPerl -*-

## File: DDC::Any.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + DDC Query utilities: wrap DDC::XS or DDC::PP
##======================================================================

package DDC::Any;
use DDC::Concordance;
use Carp qw(carp confess);
use strict;

our @ISA = qw();
our $VERSION = $DDC::Concordance::VERSION;

##======================================================================
## Globals

our $WHICH = undef;
our ($COMPILER);

##======================================================================
## Overrides

## $CQuery = DDC::Any->parse($qstr)
##  + convenience wrapper, re-implemented here b/c it uses the __PACKAGE__ keyword
sub parse {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  $COMPILER = DDC::Any::CQueryCompiler->new() if (!$COMPILER);
  return $COMPILER->ParseQuery(@_);
}

## $version = DDC::Any->library_version()
##  + returns extended version string
sub library_version {
  return undef if (!defined($WHICH));
  return "$WHICH / " . $WHICH->can('library_version')->();
}


## $obj = DDC::Any::Object->new(@args)
##  + override calls "real" subclass new() method
package DDC::Any::Object;
sub new {
  my $that  = shift;
  my $class = ref($that)||$that;
  $class   =~ s/^DDC::Any::/${DDC::Any::WHICH}::/;
  return $class->new(@_);
};

##======================================================================
## Import
package DDC::Any;

##--------------------------------------------------------------
## $bool = PACKAGE->have_xs()
##  + attempts to load DDC::XS, and returns true if it is available in a suitable version
our $MIN_XS_VERSION = 0.15;
sub have_xs {
  shift if (UNIVERSAL::isa($_[0],__PACKAGE__));
  eval "use DDC::XS;" if (!$INC{'DDC/XS.pm'});
  return 0 if (!$INC{'DDC/XS.pm'});
  (my $xs_version = ($DDC::XS::VERSION||0)) =~ s/[^0-9\.]//g;
  return ($xs_version && $xs_version >= $MIN_XS_VERSION);
}

##--------------------------------------------------------------
## \%dst_stash = mapstash($src,$dst,%opts)
##  + %opts:
##     inherit => $which ##-- tweak inheritance; (0:don't, >0:$dst ISA $src, <0:$src ISA $dst)
##     deep    => $bool, ##-- walk package tree? (default: true)
##     ignore  => $re,   ##-- ignore fully qualified source-symbols matching $re (default:none)
sub mapstash {
  my ($src0,$dst0,%opts) = @_;
  my $inherit = $opts{inherit} || 0;
  my $deep    = exists($opts{deep}) ? $opts{deep} : 1;
  my $ignore  = $opts{ignore};
  $ignore     = qr{$ignore} if (!ref($ignore));
  my @queue = ([$src0,$dst0]);
  no strict 'refs';
  while (@queue) {
    my ($src,$dst) = @{shift @queue};
    #print STDERR "mapping $src -> $dst\n";
    my $src_stash = \%{"${src}::"};
    my $dst_stash = \%{"${dst}::"};
    while (my ($src_sym,$src_glob)=each %$src_stash) {
      if ($ignore && "${src}::${src_sym}" =~ $ignore) {
	##-- ignored
	next;
      }
      if ($deep && $src_sym =~ /::$/) {
	##-- sub-package
	$src_sym =~ s/::$//;
	$dst_stash->{"${src_sym}::"} = *{"${dst}::${src_sym}::"};
	push(@queue, ["${src}::${src_sym}","${dst}::${src_sym}"]);
      }
      elsif ($src_sym eq 'ISA') {
	##-- copy inheritance
	@{"${dst}::ISA"} = map {(my $isa=$_)=~s/^\Q${src0}\E\b/${dst0}/; $isa} @{"${src}::ISA"};
      }
      else {
	##-- anything else: copy
	$dst_stash->{$src_sym} = $src_glob;
      }
    }

    if ($inherit > 0) {
      push(@{"${dst}::ISA"}, $src);	##-- tweak inheritance: $dst ISA $src
    } elsif ($inherit < 0) {
      push(@{"${src}::ISA"}, $dst);	##-- tweak inheritance: $src ISA $dst
    }
  }

  return \%{"${dst0}::"};
}


##--------------------------------------------------------------
## import guts

## $WHICH = PACKAGE->import(@requests)
sub import {
  my $that = shift;

  ##-- parse user request
  my $which = $WHICH;
  my %alias = ('xs'=>'DDC::XS', pp=>'DDC::PP', any=>'', default=>'');
  foreach (@_) {
    if (/^:(\S+)$/i) {
      $which = lc($1);
      $which = $alias{$which} if (exists($alias{$which}));
    }
  }

  ##-- sanity check(s)
  if ($which) {
    return $WHICH if ($which eq 'none'); ##-- don't map back-end (yet)
    if ($WHICH) {
      carp(__PACKAGE__ . "::import() cannot override current back-end '$WHICH' -- ignoring user request '$which'")
	if ($WHICH ne $which);
      return $WHICH;
    }
  }

  ##-- be safe anyways
  undef $WHICH;
  undef $COMPILER;

  ##-- load back-end
  if (!$which || $which eq 'DDC::XS') {
    if (!$that->have_xs()) {
      die("DDC::Any::import(): failed to load DDC::XS back-end: $@") if (($which||'') eq 'DDC::XS');
    } else {
      $which = 'DDC::XS';
    }
  }
  if (!$which || $which eq 'DDC::PP') {
    eval "use DDC::PP;" if (!$INC{'DDC/PP.pm'});
    if (!$INC{'DDC/PP.pm'}) {
      die("DDC::Any::import(): failed to load DDC::PP back-end: $@") if (($which||'') eq 'DDC::PP');
    } else {
      $which = 'DDC::PP';
    }
  }
  die("DDC::Any::import(): failed to load any back-end") if (!$which);

  ##-- map back-end
  $WHICH = $which;
  mapstash($WHICH=>'DDC::Any', deep=>1, inherit=>-1, ignore=>qr{${WHICH}::(?:VERSION|COMPILER|parse|import|library_version|.*::new)$});
  return $WHICH;
}


1; ##-- be happy

__END__

##======================================================================
## Docs
=pod

=head1 NAME

DDC::Any - abstract wrapper for DDC::XS or DDC::PP

=head1 SYNOPSIS

 ##=====================================================================
 ## Preliminaries
 use DDC::Any;		##-- use DDC::XS if available, otherwise DDC::PP
 use DDC::Any ':xs';	##-- force DDC::XS back-end
 use DDC::Any ':pp';	##-- force DDC::PP back-end
 use DDC::Any ':none';	##-- don't load or bind a back-end yet (call import() yourself later)

 ##=====================================================================
 ## Package Variables
 my $which = $DDC::Any::WHICH;	##-- either 'DDC::XS' or 'DDC::PP'

 ##=====================================================================
 ## Usage
 ##  ... address any DDC::(XS|PP)::* thingy as DDC::Any::*
 my $query = DDC::Any->parse("foo && bar && !baz");
 print $query->toStringFull();
 print $query->isa('DDC::Any::CQuery') ? "yup\n" : "nope\n";

=cut

##======================================================================
## Description
=pod

=head1 DESCRIPTION

This module provides a unified API for parsing and manipulation of DDC search engine queries,
using either L<DDC::XS|DDC::XS> or L<DDC::PP|DDC::PP> as a back-end.
Using this package will walk the symbol table of the selected back-end namespace and
recursively map variables, methods, and sub-packages to the C<DDC::Any> namespace,
thus the class C<DDC::Any::CQToken> will be mapped to either
C<DDC::XS::CQToken> or C<DDC::PP::CQToken>, depending on the back-end.
Additionally, back-end subpackages will be modified to inherit from the associated
C<DDC::Any> subpackage, so that that you can generically test for inheritance using
for exanple C<UNIVERSAL::isa($query,'DDC::Any::CQToken')> on a C<$query> object
of an appropriate back-end type.  You can specify either C<:xs> or C<:pp> in the
argument-list to C<use> (rsp. C<DDC::Any-E<gt>import()>) in order to force
use of a particular back-end.

=cut

##======================================================================
## Footer
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

DDC originally by Alexey Sokirko.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2016, Bryan Jurish.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1),
DDC::XS(3perl),
DDC::PP(3perl)

=cut
