package Acme::Metification;

use 5.006;
use strict;
use warnings;

use vars qw /$VERSION/;
$VERSION = '1.01';

use Filter::Simple;

# Call the filter routine supplied by Filter::Simple.
# It is time to read the Filter::Simple man page now if you
# haven't done so yet.

# Then pray :) This is ugly.

FILTER_ONLY
   all  => \&_filter_all,     # Used to get the source code lines
   code => \&_filter_recurse, # Used to filter recursive replacements
                             # of limited depth
   code => \&_filter_meta;#,    # Used to filter replacements
#   all => sub {my $co=0;my $c=$_;$c=~s/\n/$co++."\n"/sge;print $c;$_};

my @src_lines;

sub _filter_all {
   if (@src_lines) {
      die "Filter invoked multiple times. Not supported in this version!";
   }
   @src_lines = split /\n/;

   $_;
};


sub _filter_meta {
   while (
          s{^\s*meta\s*(.*)}{
                               _replace_meta($1)
                            }mge
         ) {}
}

sub _filter_recurse {

    while (
       s{^\s*recursemeta\s*depth\s*\=\>\s*(\d+)\s*,\s*(.+)}!
          my $depth = $1-1;
          my $rep = _replace_meta($2);
          if ($depth > 0) {
             $rep =~ s{^\s*recursemeta\s*depth\s*\=\>\s*(\d+)\s*,\s*(.+)}|
                "recursemeta depth => " . ($depth) . ", $2"
             |mge;
          } else { $rep =~ s{^\s*recursemeta\s*depth\s*\=\>\s*(\d+)\s*,\s*(.+)}||mg }
         $rep;
       !mge
    ) {}
}

sub _replace_meta {
   my $match = shift;
   $match =~ /(\d+)\s*,\s*(\d+)/ or $match =~ /(\d+)/;

   my ($start, $end) = ($1, $2);

   return '' if not defined $start;

   $start = int $start;
   $start = @src_lines + $start if $start < 0;
   $start = $#src_lines if $start > $#src_lines;

   return $src_lines[$start] if not defined $end;

   $end   = int $end;
   $end   = @src_lines + $end if $end   < 0;
   $end   = $#src_lines if $end > $#src_lines;

   ($start, $end) = ($end, $start) if $start > $end;

   return join "\n", (@src_lines[($start .. $end)]);
}

1;

__END__

=pod

=head1 NAME

Acme::Metification - Give Perl the power of Metaprogramming!

=head1 SYNOPSIS

  use Acme::Metification;
  # This is line 0
  
  sub faculty {
     my $no = shift;
     my $fac = 1;
     $fac *= ($no--);
     return $fac if $no == 0;
     recursemeta depth => 100, 5, 7
     # ^^ insert lines 5 to 7 up to 100 times
     return $fac;
  }
  
  print faculty(4); # prints 24 after quite some time

=head1 NOTE

Do not, I repeat, do not use in production code. But then again, the
features are useless, so you wouldn't anyway.

=head1 DESCRIPTION

This module gives you some meta-programming abilites within Perl.
It uses source filters to do evil things with your source.

The module allows the use of two new functions. They must
appear on separate lines in your code:

=head2 meta

Syntax:

  meta [line_no1], [line_no2]

C<meta> replaces itself with the code lines ranging from
[line_no1] to [line_no2]. The first line after
"use Acme::Metification;" is considered line 0.

Of course, those lines may contain C<meta> or C<recursemeta>
directives, so beware of deep recursion.

=head2 recursemeta

Similar to C<meta> with some exceptions. Syntax:

  recursemeta depth => [depth], [line_no1], [line_no2]

[depth] is the maximum depth to recurse into in case
C<recursemeta> directives are inserted. However,
C<meta> directives will be recursed into deeply.

=head1 EXAMPLES

=over 4

=item Execute examples from POD docs

  use Acme::Metification;
  
  # Execute code from pod docs:
  
  meta 9, 11
  
  =pod
  
  =head1 Example
  
    foreach (0..5) {
      print "Acme::Metification rocks!\n";
    }
  
  =cut

=item Transform slow recursion into blazingly fast code!

  use Acme::Metification;
  
  sub faculty {
     my $no = shift;
     my $fac = 1;
     $fac *= ($no--);
     return $fac if $no == 0;
     recursemeta depth => 100, 4, 6
     return $fac;
  }
  
  print faculty(4);

=back

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2006 Steffen Mueller. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Filter::Simple> by Damian Conway

=cut
