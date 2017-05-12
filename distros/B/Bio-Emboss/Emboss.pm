package Bio::Emboss;

use 5.000;
use strict;
use Carp;

require Exporter;
require DynaLoader;
# use AutoLoader;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
@ISA = qw(Exporter
	DynaLoader);

# --- link methods in sub-classes to subs in Bio::Emboss
require Bio::Emboss::Methods;


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bio::Emboss ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => \@Bio::Emboss::Methods::ALL_METHODS,
		 'acd' => \@Bio::Emboss::Methods::ACD_METHODS );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = '5.0.0.1';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Bio::Emboss::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

bootstrap Bio::Emboss $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Bio::Emboss - Write EMBOSS programs in Perl

=head1 SYNOPSIS

  use Bio::Emboss qw(:all);

  embInitPerl("seqret", \@ARGV); 
  
  $seqall = ajAcdGetSeqall("sequence"); 
  $seqout = ajAcdGetSeqoutall("outseq"); 
  
  while ($seqall->ajSeqallNext($seq)) {
      $seqout->ajSeqAllWrite ($seq);
  }

=head1 DESCRIPTION

This module allows Perl programmers to access functions of the
EMBOSS (European Molecular Biology Open Software Suite) package. 

=head1 USAGE

You can use this module in an object oriented way or not. I.e. the
EMBOSS function 

  AjBool       ajSeqallNext (AjPSeqall seqall, AjPSeq* retseq);

can be used from Perl in the following ways:

  $ok = $seqall->ajSeqallNext ($retseq);

I<or>

  $ok = Bio::Emboss::ajSeqallNext ($seqall, $retseq);

I<or>

  # --- with use Bio::Emboss ":all"
  $ok = ajSeqallNext ($seqall, $retseq);


C<AjPxxx> types are translated into Perl references, blessed into the
package C<Bio::Emboss::xxx>. This allows the object oriented notation
seen above.

Functions expecting pointers to variables, because the
function changes the value of this variable don't need
pointers/references from Perl. I.e.

  (AjPSeqall seqall, AjPSeq* retseq);

translates to

  ($seqall, $retseq)

B<Known problem>: Some C prototypes are ambiguous for Perl: (int*) can
mean a pointer to an integer value (because the functions changes the
value), B<OR> it can be an array of integers.
Depending on the meaning a different translation into Perl needs to be
done.

(In PerlXS, in the first case "&" instead of "*" is used for
the prototype of the function. In the second case, the "&" must not be
used. See L<perlxs/"The & Unary Operator">)

=head1 START

Because Perl provides the command-line in C<$0> and C<@ARGV> (and not
C<argc> and C<argv> like in C),
two convenience functions have been implemented to start an EMBOSS
application from Perl.

=over 4

=item B<embInitPerl($program_name, \@ARGV)>

Can be used instead of C<embInit(char *pgm, ajint argc, char *argv[])>

=item B<ajGraphInitPerl($program_name, \@ARGV)>

Can be used instead of C<ajGraphInit(char *pgm, ajint argc, char *argv[])>

=back

=head1 EXPORT

None by default.

Available export tags are: 

=over 4

=item I<:all>

With this export tag, all available functions in this module are
copied into the callers namespace.

=item I<:acd>

Export C<ajAcdGet...> functions only.

=back


=head1 SEE ALSO

http://emboss.sourceforge.net/

perldoc Bio::Emboss::Ajax  (if installed)

Examples in the t/ subdirectory of the
Bio::Emboss source tree.

=head1 AUTHOR

Peter Ernst, E<lt>pernst@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2006 by Peter Ernst

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
