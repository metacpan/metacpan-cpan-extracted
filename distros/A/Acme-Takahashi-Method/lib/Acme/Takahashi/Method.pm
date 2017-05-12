package Acme::Takahashi::Method;

use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.1 $ =~ /(\d+)/g;
our $DEBUG = 0;

sub make_slide{
    my ($src, $columns, $rows) = @_;
    open my $in, "<:raw", $src or die "$src:$!";
    my $counter = 0;
    my $vspace = "\n" x ($rows/2 - 1);
    while(defined(my $line = <$in>)){
	$line =~ q/^use Acme::Takahashi::Method/ and next;
	$line =~ s/#.*//;
	$line =~ /^$/ and next;
	my $slide = "$src." . $counter++;
	$DEBUG and warn $slide;
	my $hspace = " " x (($columns - length($line))/2);
	my $next   =  sprintf(qq(do "$src.%d";), $counter);
	my $page      = "# $counter";
	my $pagespace = " " x ($columns - length($next) - length($page));
	open my $out, ">:raw", $slide or die "$slide : $!";
	print $out 
	    $vspace, $hspace, $line, $vspace, $next, $pagespace, $page, "\n";
	close $out;
    }
    return $counter;
}

sub do_slides{
    my $src = shift;
    do qq($src);
}

sub clobber{
   my ($src, $columns, $rows) = @_;
   use Config;
   my $vspace = "\n" x ($rows/2 - 1);
   my $line = "# $src";
   my $hspace = " " x (($columns - length($line))/2);
   my $next   =  qq(do "$src.0";);
   my $thisperl = $Config{perlpath};
   open my $out, ">:raw", $src or die "$src : $!";
   print $out "#!", $thisperl,
       $vspace, $hspace, $line, $vspace, $next, "\n";
   close $out;
}

sub show_slides{
    my ($src, $nslides) = @_;
    for my $slide ($src, map { "$src.$_" } (0 .. $nslides-1)){
	system "clear";
	open my $in, "<:raw", $slide or die "$slide : $!";
	print <$in>;
	close $in;
	my $key = getc;
    }
    system "clear";
}

sub import{
    my $pkg = shift;
    my %arg = @_;
    #use Data::Dumper;
    #print Dumper \%args;
    my $columns = $arg{columns} || 80;
    my $rows    = $arg{rows}    || 24;
    my $show_slide = !$arg{noslideshow} || 1;
    $arg{debug} and $DEBUG = 1;
    my $nslides = make_slide($0, $columns, $rows);
    clobber($0, $columns, $rows) unless $arg{noclobber};
    show_slides($0, $nslides) if $show_slide;
    do_slides($0) unless $arg{noexec};
    exit;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Acme::Takahashi::Method - turns your script into slides accordingly to the Takahashi Method

=head1 SYNOPSIS

  use Acme::Takahashi::Method;
  # and the rest of your codes.

=head1 DESCRIPTION

The Takahashi Method L<http://www.rubycolor.org/takahashi/> is a
strong, powerful and impressive method that makes your presentation
something unforgettable.  This module makes your script as impressive
as those presentations.

Seeing is believing.  try

  cp eg/fact.pl
  perl -Ilib fact.pl 10

and see what I mean.

=head2 IMPORT DIRECTIVES

This module supports directives below.  You can set as many directives
as you like as follows;

  use Acme::Takahashi::Method columns => 132, rows => 50, noxec => 1;

=over 2

=item columns

Default is 80.  If you have larger terminals try

  use Acme::Takahashi::Method columns => 132;

or something.

=item rows

Default is 24.  If you have larger terminals try

  use Acme::Takahashi::Method columns => 50;

or something.

=item noslideshow

By default, this module plays a slide show before it executes.  If you
only need to make slides, turn this on as

  use Acme::Takahashi::Method noslideshow => 1;

=item noclobber

By default, this module clobbers your original script.  If you don't want this kind of tragedy, 

  use Acme::Takahashi::Method noclobber => 1;

You still get nice slides.

=item noexec

If you just want to make slides and don't want to run scripts, do

  use Acme::Takahashi::Method noexec => 1;

=back

=head2 EXPORT

Are you kidding ?

=head1 CAVEATS

=over 2

=item no branches

Hey, you are making slides and slides are not suppose to branch!

=item no loops

Hey, don't make slides boring by repeating over and over.
If you need to EXECUTE loops use labels and C<goto>.  Here is an example.

  loop: 
  $result *= $n--;
  goto loop unless $n <= 1;

=item no braces that spans beyond lines

Natually a slide that only contains C<{> and C<}> are boring as hell.
If you need braces make it fit into one line.

  do { stuff } while(cond); # ok

  do {
    stuff;
  }
  while(cond);              # perfectly NG

=back

=head1 SEE ALSO

The Takahashi Method (Japanese)
L<http://www.rubycolor.org/takahashi/>

L<Acme>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

To be honest with you, I am too ashamed to insist copyright on this
kind of stuff :)

=cut
