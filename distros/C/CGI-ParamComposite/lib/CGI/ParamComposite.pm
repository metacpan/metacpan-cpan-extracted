=head1 NAME

CGI::ParamComposite - Convert .-delimited CGI parameters to Perl classes/objects

=head1 SYNOPSIS

  use CGI;
  use CGI::ParamComposite;
  my $q = CGI->new();
  $q->param(-name=>'food.vegetable',-value=>['tomato','spinach']);
  $q->param(-name=>'food.meat',     -value=>['pork','beef','fish']);
  $q->param(-name=>'food.meat.pork',-value=>'bacon');

  my $c = CGI::ParamComposite->new( cgi => $q );

  #Dumper([$composite->roots()]) returns (minor formatting):
  $VAR1 = {
    'food' => {
      'meat' => [
        'pork',
        'beef',
        'fish'
      ],
      'vegetable' => [
        'tomato',
        'spinach'
      ]
    }
  };

  #either way, these calls now work:
  my($market) = %{ $composite->param() };
  ref($market);                                       #returns HASH
  keys(%{ $market->{food} });                         #returns ('meat','vegetable')

  #note that food.meat.pork with throw an error b/c a higher level key, food.meat,
  #has already had its value set.  the keys are evaluated from least to most
  #specific (measured by namespace depth, or number of dots)

=head1 DESCRIPTION

I needed this for a fairly large single-CGI script application that I was working on.
It was a script that had been actively, organically growing for 4+ years, and was
getting very difficult to track the undocumented 50+ CGI parameters that were being
passed, some of them dynamically generated, and almost all with very short names.

I wanted a way to organize the parameters, to make it easier to set up some simple
guidelines for how to maintain parameters, and how to make sure they were accessable
in a consistent manner.  I decided to use a hierarchical, dot-delimited convention
similar to what you seen in some programming languages.  Now if I see a parameter
like:

  /my.cgi?navigation.instructions=1

I can pretty quickly guess, after not looking at the code for days/weeks/months, that
this value is somehow affecting the instructions on the Gbrowse navigation page.  In
my opinion, this is superior to:

  /my.cgi?ins=0

which had the same effect in an earlier version of the code (negated logic :o).

=head1 SEE ALSO

L<CGI>

=head1 AUTHOR

Allen Day, E<lt>allenday@ucla.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Allen Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=head1 METHODS

=cut

package CGI::ParamComposite;

use strict;
use CGI;
use Data::Dumper;
use constant DEBUG => 0;
our $VERSION = '0.02';

my $self = undef;

=head2 new()

 Usage   : my $c = CGI::ParamComposite->new( populate => 1 , package => 'My::Param' );
           my @roots = $c->roots(); #these are what you're after
 Function: builds and returns a new CGI::ParamComposite object.  calls L</init()>,
           which is where all the action happens.
 Returns : a CGI::ParamComposite instance
 Args    : all optional:
             cgi         - a CGI object from which params() are retrieved.
             populate    - should the objects returned by L</roots()> be fleshed out?
                           defaults to false, this is fastest.
             package     - prefix to attach to new symbols.  see L</package()> for
                           details.

=cut

sub new {
  my($class,%arg) = @_;
  return $self if defined($self);

  $self = bless {}, $class;
  $self->init(%arg);
  return $self;
}

=head2 init()

 Usage   : $obj->init(%arg);
 Function: initializes a CGI::ParamComposite object.  this includes
           registration of new packages, package constructors, and
           package accessors into the Perl symbol table.
 Returns : true on success.
 Args    : none.  this is an internal method called by L</new()>.


=cut

sub init {
  my($self,%arg) = @_;

  $self->cgi($arg{cgi} || new CGI);

  return unless $self->cgi->param();

  my %result = ();

  foreach my $p (sort {depth($a) <=> depth($b)} $self->cgi->param()){
    my @path = split '\.', $p;

    my @val = $self->cgi->param($p);

    follow(\@val,\%result,\@path,@path);
  }

  $self->param(\%result);

}

=head1 ACCESSORS

=head2 cgi()

 Usage   : $obj->cgi($newval)
 Function: holds a CGI instance.  this is instantiated by L</init()>,
           if you don't provide a value.
 Returns : value of cgi (a CGI object)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub cgi {
  my($self,$val) = @_;
  $self->{'cgi'} = $val if defined($val);
  return $self->{'cgi'};
}

=head2 param()

 Usage   : $hashref = $obj->param($newval)
 Function: get a hahsref of the treeified CGI parameters
 Returns : a hashref
 Args    : none


=cut

sub param {
  my($self,$val) = @_;
  $self->{'param'} = $val if defined($val);
  return $self->{'param'};
}


=head1 INTERNAL METHODS

You donn't need to touch these.

=head2 depth()

 Usage   : internal method, used for sorting CGI params based
           on the depth of their namespace.  this makes sure
           the created symbols return the right thing (child
           objects or simple scalars)

=cut

sub depth {
  my $string = shift;
  my @parts = split '\.', $string;
  return scalar(@parts);
}

=head2 follow()

 Usage   : $obj->follow($value,$hashref,@path);
 Function: internal method.  recurses into $hashref foreach element of
           @path, and sets the value of $path[-1] to $value.  for
           example:

           @path  = qw(foo bar baz);
           $value  = 'boo';
           $result = {};
           follow($value,$result,@path);
           $result->{foo}->{bar}->{baz}; #evaluates as 'boo'

 Returns : n/a
 Args    : 1. value to set
           2. hash to assign value into
           3. an array defining location of value in hash


=cut

sub follow {
  my($v,$r,$p,@path) = @_;
  my $next = shift @path;
  if(@path) {
    $r->{$next} ||= {};
    follow($v,$r->{$next},$p,@path);
  } else {
    if(ref($r) eq 'HASH'){
      $r->{$next} = $v;
    } else {
      my @q = @$p;
      pop @q;
      warn sprintf("ignoring %s=%s, value of %s already set to %s",
                   join('.',(@$p)),$v,
                   join('.',(@q)), $r
                   );
    }
  }
}

1;
