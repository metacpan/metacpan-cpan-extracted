package B::RecDeparse;

use 5.008_001;

use strict;
use warnings;

use B ();

use Config;

use base qw<B::Deparse>;

=head1 NAME

B::RecDeparse - Deparse recursively into subroutines.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    # Deparse recursively a Perl one-liner :
    $ perl -MO=RecDeparse,deparse,@B__Deparse_opts,level,-1 -e '...'

    # Or a complete Perl script :
    $ perl -MO=RecDeparse,deparse,@B__Deparse_opts,level,-1 x.pl

    # Or a single code reference :
    use B::RecDeparse;

    my $brd = B::RecDeparse->new(
     deparse => \@B__Deparse_opts,
     level   => $level,
    );
    my $code = $brd->coderef2text(sub { ... });

=head1 DESCRIPTION

This module extends L<B::Deparse> by making it recursively replace subroutine calls encountered when deparsing.

Please refer to L<B::Deparse> documentation for what to do and how to do it.
Besides the constructor syntax, everything should work the same for the two modules.

=head1 METHODS

=head2 C<new>

    my $brd = B::RecDeparse->new(
     deparse => \@B__Deparse_opts,
     level   => $level,
    );

The L<B::RecDeparse> object constructor.
You can specify the underlying L<B::Deparse> constructor arguments by passing a string or an array reference as the value of the C<deparse> key.
The C<level> option expects an integer that specifies how many levels of recursions are allowed : C<-1> means infinite while C<0> means none and match L<B::Deparse> behaviour.

=cut

use constant {
 # p31268 made pp_entersub call single_delim
 FOOL_SINGLE_DELIM =>
     ("$]" >= 5.009_005)
  || ("$]" <  5.009 and "$]" >= 5.008_009)
  || ($Config{perl_patchlevel} && $Config{perl_patchlevel} >= 31268)
};

sub _parse_args {
 if (@_ % 2) {
  require Carp;
  Carp::croak('Optional arguments must be passed as key/value pairs');
 }
 my %args = @_;

 my $deparse = $args{deparse};
 if (defined $deparse) {
  if (!ref $deparse) {
   $deparse = [ $deparse ];
  } elsif (ref $deparse ne 'ARRAY') {
   $deparse = [ ];
  }
 } else {
  $deparse = [ ];
 }

 my $level = $args{level};
 $level    = -1  unless defined $level;
 $level    = int $level;

 return $deparse, $level;
}

sub new {
 my $class = shift;
 $class = ref($class) || $class || __PACKAGE__;

 my ($deparse, $level) = _parse_args(@_);

 my $self = bless $class->SUPER::new(@$deparse), $class;

 $self->{brd_level} = $level;

 return $self;
}

sub _recurse {
 return $_[0]->{brd_level} < 0 || $_[0]->{brd_cur} < $_[0]->{brd_level}
}

sub compile {
 my @args = @_;

 my $bd = B::Deparse->new();
 my ($deparse, $level) = _parse_args(@args);

 my $compiler = $bd->coderef2text(B::Deparse::compile(@$deparse));
 $compiler =~ s/
  ['"]? B::Deparse ['"]? \s* -> \s* (new) \s* \( ([^\)]*) \)
 /B::RecDeparse->$1(deparse => [ $2 ], level => $level)/gx;
 $compiler = eval 'sub ' . $compiler;
 die if $@;

 return $compiler;
}

sub init {
 my $self = shift;

 $self->{brd_cur}  = 0;
 $self->{brd_sub}  = 0;
 $self->{brd_seen} = { };

 $self->SUPER::init(@_);
}

my $key = $; . __PACKAGE__ . $;;

if (FOOL_SINGLE_DELIM) {
 my $oldsd = *B::Deparse::single_delim{CODE};

 no warnings 'redefine';
 *B::Deparse::single_delim = sub {
  my $body = $_[2];

  if ((caller 1)[0] eq __PACKAGE__ and $body =~ s/^$key//) {
   return $body;
  } else {
   $oldsd->(@_);
  }
 }
}

sub deparse_sub {
 my $self = shift;
 my $cv   = $_[0];

 my $name;
 unless ($cv->CvFLAGS & B::CVf_ANON()) {
  $name = $cv->GV->SAFENAME;
 }

 local $self->{brd_seen}->{$name} = 1 if defined $name;
 return $self->SUPER::deparse_sub(@_);
}

sub pp_entersub {
 my $self = shift;

 my $body = do {
  local $self->{brd_sub} = 1;
  $self->SUPER::pp_entersub(@_);
 };

 $body =~ s/^&\s*(\w)/$1/ if $self->_recurse;

 return $body;
}

sub pp_refgen {
 my $self = shift;

 return do {
  local $self->{brd_sub} = 0;
  $self->SUPER::pp_refgen(@_);
 }
}

sub pp_srefgen {
 my $self = shift;

 return do {
  local $self->{brd_sub} = 0;
  $self->SUPER::pp_srefgen(@_);
 }
}

sub pp_gv {
 my $self = shift;

 my $gv   = $self->gv_or_padgv($_[0]);
 my $cv   = $gv->FLAGS & B::SVf_ROK ? $gv->RV : undef;
 my $name = $cv ? $cv->NAME_HEK || $cv->GV->NAME : $gv->NAME;
 $cv    ||= $gv->CV;
 my $seen = $self->{brd_seen};

 my $body;
 if (!$self->{brd_sub} or !$self->_recurse or $seen->{$name} or !$$cv
     or !$cv->isa('B::CV') or $cv->ROOT->isa('B::NULL')) {
  $body = $self->SUPER::pp_gv(@_);
 } else {
  $body = do {
   local @{$self}{qw<brd_sub brd_cur>} = (0, $self->{brd_cur} + 1);
   local $seen->{$name} = 1;
   'sub ' . $self->indent($self->deparse_sub($cv));
  };

  if (FOOL_SINGLE_DELIM) {
   $body = $key . $body;
  } else {
   $body .= '->';
  }
 }

 return $body;
}

=pod

The following functions and methods from L<B::Deparse> are reimplemented by this module :

=over 4

=item *

C<compile>

=item *

C<init>

=item *

C<deparse_sub>

=item *

C<pp_entersub>

=item *

C<pp_refgen>

=item *

C<pp_srefgen>

=item *

C<pp_gv>

=back

Otherwise, L<B::RecDeparse> inherits all methods from L<B::Deparse>.

=head1 EXPORT

An object-oriented module shouldn't export any function, and so does this one.

=head1 DEPENDENCIES

L<perl> 5.8.1.

L<Carp> (standard since perl 5), L<Config> (since perl 5.00307) and L<B::Deparse> (since perl 5.005).

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-b-recdeparse at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=B-RecDeparse>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc B::RecDeparse

Tests code coverage report is available at L<http://www.profvince.com/perl/cover/B-RecDeparse>.

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009,2010,2011,2013,2014,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of B::RecDeparse
