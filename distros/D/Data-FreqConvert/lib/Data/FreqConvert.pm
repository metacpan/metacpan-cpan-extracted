=head1 NAME

Data::FreqConvert - converts variables to scalars holfding frequencys of keys in values

=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use  Data::FreqConvert;
    use  Data::Printer;

    my $data = Data::FreqConvert->new();

    my %a = ("a"=>1,"b"=>1,"c"=>1);
    my $a = {"a"=>1,"b"=>1,"c"=>1,"a"=>3};
    my @a = ("a","b","c","a");
    my $b = "a\nb\nc\nc";

    my $r = $data->freq($b);
    p $r;

    $r = $data->freq(\@a);
    p $r;

    $r = $data->freq($a);
    p $r;

=cut

package Data::FreqConvert;

use strict;
use warnings;

use Data::Freq;
use Data::Dumper;
use Data::Printer;
use IO::Capture::Stdout;
our $VERSION = "0.01";

  sub new {
      my $class = shift;
      my (%params) = @_;

      my $self = {};
      bless $self, $class;

      return $self;
  }

  sub  trim  {

    my  $string  =  shift;
    $string  =  ""  unless  $string;
    $string  =~  s/^\s+//;
    $string  =~  s/\s+$//;
    $string  =~  s/\t//;
    $string  =~  s/^\s//;
    $string  =~  s/^->//;
    $string  =~  s/^=>//;
    return  $string;
  }

  sub prepArg {
      my $self = shift;
      my ($arg) = @_;
      my $ref = ref $arg;
      my @return = ();

      if($ref =~ /HASH/) {
          @return = keys %$arg;
      }
      elsif($ref =~ /ARRAY/) {
          @return = @$arg;
      }else{

      @return = split("\n",$arg);
      }

      return @return;

  }


  sub freq {
      my ($self,$arg) = @_;
      my @set = $self->prepArg($arg);
      my $data = Data::Freq->new();
      foreach my $n( @set){
        $data->add($n);
       }

  my  $capture =  IO::Capture::Stdout->new;
      $capture->start;
      $data->output();
      $capture->stop();

    my $ret = {};
    my @buffer =  reverse grep{/\w|\d/}$capture->read;

    my $last = "";
    foreach my $z(@buffer){

         $z = trim($z);

         if($z !~ m/^\d/) {
            $ret->{$z}="";
            $last = $z;
         }

         else {
         $ret->{$last}=$z;
         }



    }

    return $ret;
}

=head1 AUTHOR

Mahiro Ando, C<< <santex at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Hagen Geissler

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
