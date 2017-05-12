package Attribute::Tie;
#
# $Id: Tie.pm,v 0.2 2009/02/08 09:00:12 dankogai Exp $
#
use 5.008001;
use strict;
use warnings;
use Attribute::Handlers;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;

our %MOD2TIE;
our %SIGIL = qw/HASH % ARRAY @ SCALAR $/;
our $ERROR = \&error;

sub seterror {
    my $pkg = shift;
    $ERROR =
        ref $_[0] eq 'CODE' ? $_[0]
      : $_[0] ? \&error
      : sub { }
}

sub load {
    my ($mod2tie, $ref) = @_;
    return $MOD2TIE{$mod2tie} if $MOD2TIE{$mod2tie};
    {   # Maybe you don't need to load at all
	no strict 'refs';
	my $type =  ref $ref;
	return $MOD2TIE{$mod2tie} = $mod2tie 
	    if defined &{$mod2tie . "::TIE$type" };
	return $MOD2TIE{$mod2tie} = 'Tie::'.$mod2tie
	    if defined &{'Tie::'. $mod2tie . "::TIE$type"};
    }
    # DB_File, et al.
    eval qq{ require $mod2tie };
    return $MOD2TIE{$mod2tie} = $mod2tie unless $@;

    # Anything else
    eval qq{ require Tie::$mod2tie };
    return $MOD2TIE{$mod2tie} = 'Tie::'.$mod2tie unless $@;

    # Report Failure and die
    my ( $pkg, $file, $line ) = caller(4);
    die "Neither $mod2tie nor Tie::$mod2tie is available",
      " at $file line $line\n";
}

sub error {
    my ( $ref, $mod2tie, @tiearg ) = @_;
    my ( $pkg, $file,    $line )   = caller(4);
    my $s = $SIGIL{ ref $ref };
    die "tie(", join( ", ", $s . ref $ref, qq('$mod2tie'), @tiearg ),
      ") failed : $! at $file line $line\n";
}

sub UNIVERSAL::Tie : ATTR {
    my ( $pkg, $sym, $ref, $attr, $data, $phase ) = @_;
    my @tiearg = ref $data ? @$data : ($data);
    my $mod2tie = Attribute::Tie::load(shift @tiearg, $ref);
    my $obj =
        ref $ref eq 'HASH'   ? tie %$ref, $mod2tie, @tiearg
      : ref $ref eq 'ARRAY'  ? tie @$ref, $mod2tie, @tiearg
      : ref $ref eq 'SCALAR' ? tie $$ref, $mod2tie, @tiearg
      :   die "cannot tie to data type: ", ref $ref;
    $Attribute::Tie::ERROR->( $ref, $mod2tie, @tiearg ) if !$obj;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Attribute::Tie - Tie via Attribute

=head1 SYNOPSIS

  use Attribute::Tie;
  my %hash   : Tie('Hash::Yours', args ...);
  my @array  : Tie('Array::Yours', args ...);
  my $scalar : Tie('Scalar::Yours', args ...);

=head1 DESCRIPTION

Attribute::Tie allows you to tie variables via attribute.  This is
more intuitive than

  tie my %hash, "Tie::Hash::Yours", args ... or die "$!";

The first argument to C<Tie()> is the name of the module to which you
want to tie the variable.  You can omit 'Tie' therein.

  my %db  : Tie('DB_File', ....); # ties to DB_File;
  my @fie : Tie('File', ...);     # ties to Tie::File;

You do not have to C<use Tie::Whatever>; Attribute::Tie does it for you.

=head2 Attribute::Tie vs Attribute::Handlers' autotie

I wrote this module for two reasons:

=over 2

=item semantics

L<Attribute::Handlers> offers an alternate approach via autotie.  That
looks like this.

  use Attribute::Handlers autotie => { File => 'Tie::File' };
  my @array : File('array.txt');

Which is handy but it hides the fact that the variable is actually
tied.  I want the attribute name to reflect what is really done to the
variable.

=item error handling

unlike most attributes, C<tie>-ing variable may fail.  This is
especially true for modules that tie variables to external files.  But
autotie does not trap the error; it just leaves the variable untied.
Consider this.

  use Attribute::Handlers autotie => { File => 'Tie::File' };
  my @array : File('/nonexistent/nowhere.txt');

Of course you can check the error like this.

  tied(@array) or die $!

or this:

  my @array : File('/nonexistent/nowhere.txt') or die $!;

First one is error-prone and the second one is unnatural because
setting attribute is not assignment.  When the error happens, it
should croak before the attribute is 'set', or fails to be set.

On the other hand, Attribute::Tie dies on failure by default.

  my @array : Tie('File', '/nonexistent/nowhere.txt');
  # you die here!

=back

=head2 CUSTOM ERROR HANDLER

By default, Attribute::Tie dies on failure as follows.

  tie(%HASH, 'SDBM_File', ./_none_/db, 514, 438) failed : 
  No such file or directory at t/04-error.t line 12

You can change this behavior via C<< Attribute::Tie->seterror() >>.

  # sets the error handler
  Attribute::Tie->seterror(sub{ die @_ });

  # disables error handling like Attribute::Handler's autotie
  Attribute::Tie->seterror(sub{});

   Attribute::Tie->seterror(0);
  # restores default handler
  Attribute::Tie->seterror(1);

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<perltie>, L<Attribute::Handlers>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
