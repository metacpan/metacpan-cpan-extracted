package Acme::SafetyGoggles;

use warnings;
use strict;
use Carp;
use Filter::Simple;
use Text::Diff ();

$Carp::Internal{'Filter::Simple'}++;
our $VERSION = '0.06';

no warnings 'unopened';
no warnings 'redefine';
*DIAG = $ENV{ACME_SAFETYGOGGLES_DIAG} ? *STDERR : *DEVNULL;

my ($state, $diff);
sub state { $state }
sub diff  { $diff  }

sub _set_current {
  print DIAG "A::SG::_set_current => \n\n\n==========\n$_\n==========\n\n\n\n";
  our $current;
  $current = $_ if length($_);
}



CHECK {
  print DIAG "A::SG::CHECK\n";
  &apply_safety_goggles;
}

BEGIN {
  our @caller = caller(2);
  # caller(0) and caller(1) both refer to this BEGIN block
  print DIAG "A::SG::BEGIN => @caller[0..2]\n";
}

FILTER {
  print DIAG "A::SG::FILTER\n";
  _set_current;
};

{
  package Filter::Simple;

  # hijack  Filter::Simple::filter_add  to make filtered code
  # available to this module.

  *Filter::Simple::filter_add_ORIG = \&Filter::Simple::filter_add;

  *Filter::Simple::filter_add = sub ($) {
    my $code = shift;
    Filter::Simple::filter_add_ORIG(
	sub {
	  print Acme::SafetyGoggles::DIAG "IN F::S::fa\n";
	  my $count = $code->();
	  Acme::SafetyGoggles::_set_current;
	  return $count;
	} );
  }
}

sub apply_safety_goggles {

  our @caller;
  our $current;

print DIAG "applying safety googles\n";

  FILTER { _set_current };

  my ($pkg, $file, $l) = @caller;

  if ($file eq '-e') {
    carp "Acme::SafetyGoggles cannot protect against code in an '-e' construction";
    return;
  }

  my $vh;
  unless (open $vh, '<', $file) {
    carp "Acme::SafetyGoggles: cannot read source file $file ! $!\n";
    return;
  }
  my $original = '';
  my $original2 = '';
  while (my $line = <$vh>) {
    last if $line =~ /^__END__$/;
    $original .= $line;
    $original2 .= $line;
    $original2 = "" if $line =~ /^use\s+Acme::SafetyGoggles\b/;
  }
  close $vh;

  $diff = Text::Diff::diff(\$original2, \$current, { STYLE => 'OldStyle' } );
  $diff &&= Text::Diff::diff(\$original, \$current, { STYLE => 'OldStyle' } );

  # it is ok if the original file contains extra lines at the top, ending
  # with the call to the source filter.
  #
  #   Example:
  #
  #   1,3d0
  #   < #!/usr/bin/perl
  #   < # this is my program with source filtering
  #   < use The::Source::Filter;

  $diff =~ s{
	      ^\d+(?:,\d+)?d0\s*\n
	      (?:<.*\n)*
	      <\s*use\s+\S+.*\n
	    }{}x;

  if ($diff) {
    print DIAG "A::SG::asg: source code is unsafe\n";
    $state = "unsafe";
    carp "File $file has been source filtered!\n", $diff, "===\n";
  } else {
    print DIAG "A::SG::asg: source code is safe\n";
    $state = "safe";
  }
};

=head1 NAME

Acme::SafetyGoggles - Protects programmer's eyes from source filtering

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

    $ perl -MAcme::SafetyGoggles possibly_dangerous_script.pl

=head1 DESCRIPTION

Is some module you imported using source filtering? If the
answer is yes, or if the answer is "I don't know", then
you can't trust the code in front of your own eyes! 

That's why you should always use patent-pending 
C<Acme::SafetyGoggles> in your untrusted Perl code. 
C<Acme::SafetyGoggles> compares your original source file
with the code that is actually going to be run, and
alerts you to any differences. 

=head1 SUBROUTINES/METHODS

=head2 state

=head2 Acme::SafetyGoggles->state

Returns this module's assessment of whether the source code
of the current program has been modified. Return value is
either C<"safe"> or C<"unsafe">.

=head2 diff

=head2 Acme::SafetyGoggles->diff

If source code modification has been detected, returns the
result of the C<Text::Diff::diff> call between the pure and
the modified source. This output will remind you of the
output of the Unix C<diff> command.

=head1 BUGS AND LIMITATIONS

C<Acme::SafetyGoggles> can only (maybe) protect you from
source filtering. It is not designed or warranted to 
protect you from improper use of any other potentially
dangerous or evil Perl construction.

C<Acme::SafetyGoggles> does not operate on code specified by
perl's C<-e> command line option.

C<Acme::SafetyGoggles> may yield a false positive if the input
turns source code filtering on and off with calls to
C<use XXX::SourceFilter> ... C<no XXX::SourceFilter>, or
in other files where the source filter has a limited scope.

    trustable_code();
    use The::Source::Filter;
    some_code_you_cant_trust();
    no The::Source::Filter;
    more_trustable_code();


    trustable_code();
    {
        use The::Source::Filter;
        some_code_you_cant_trust();
    }
    more_trustable_code();

=cut

# How would we handle this case?  Match a section of $original beginning
# after a  "use Some::Filter;"  statement and before a  "no Some::Filter;"
# statement?

=pod

This module really only works on source filters that already use
the L<Filter::Simple> mechanism. Even then, there are probably
still a lot of ways to source filter the code so that it won't be
detected by this module. 

=cut

# If we could intercept the source code in the Filter::Util::Call,
# package, we could detect even more source code manipulation.  
# Filter::Util::Call has some XS, though. So is this possible? Feasible?

=pod

Please report any other bugs or feature requests to 
C<bug-acme-safetygoggles at rt.cpan.org>, or through the web interface 
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-SafetyGoggles>.  
I will be notified, and then you'll automatically be given a commit bit
for this distribution on PAUSE. Um, I mean that you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::SafetyGoggles


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-SafetyGoggles>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-SafetyGoggles>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-SafetyGoggles>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-SafetyGoggles/>

=back

=head1 ACKNOWLEDGEMENTS

Inspired by comments on source filtering from stackoverflow.com's Ether:
http://stackoverflow.com/questions/2818155/#2819871

=head1 LICENSE AND COPYRIGHT

Copyright 2010,2013 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Acme::SafetyGoggles
