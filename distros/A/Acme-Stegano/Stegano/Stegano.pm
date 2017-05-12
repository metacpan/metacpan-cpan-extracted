# Anarion anarion@7a69ezine.org
package Acme::Stegano;
use strict;
use warnings;
use Tie::File;
use Carp;
use vars q/$VERSION/;

$VERSION = '0.02';

=head1 NAME

Acme::Stegano - Put some text inside another

=head1 SYNOPSIS

  use Acme::Stegano;

  # Create a stegano object passing a file you wish to inject

  my $st = Stegano->new("my-file.txt");
  $st->insert("This is a sample text");

  # nearby in some other part of code, someone could
  my $st = Stegano->new("my-file.txt");
  print $st->extract

=head1 DESCRIPTION

You can put some text inside another and it seems to remain the same.
Then you could extract the text doing the inverse operation. The idea was from
Damian Cownay in his Acme::Bleach.

=head1 SPECIAL THANKS

Well, this is based in the idea of Damian Conway used in Acme::Bleach, so thank it to him.

=head1 AUTHOR

Anarion: anarion@7a69ezine.org

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub new
{
        my ($class,$filename) = @_;
        my @file;
        tie @file, 'Tie::File', $filename
                or croak "Cant tie filename $filename: $!";
        bless \@file, $class
}

sub insert
{
        my ($self,$text) = @_;
        my ($max_str,$max_cont,@map_letters) = (0,0);
        my $binstr = unpack "b*", " $text";             # It must begin with 0
        $_ > $max_str and $max_str = $_ for map { length } @$self;
        while ($binstr =~ /((.)\2*)/g)
        {
                my $len = length($1);
                $max_cont = $len if $len > $max_cont;
                push(@map_letters,$len);
        }

        my @map_file = map { $max_str - length($_) > $max_cont } @$self;

        for (my $i=0;$i<@$self;$i++)
        {
                $self->[$i] .= " " x shift(@map_letters)
                        if $map_file[$i] and @map_letters;
        }
        carp "Text is not enougth large to insert all chars" if @map_letters;
        return ! @map_letters;
}

sub extract
{
        my $self = shift;
        my ($binstr,$i);
        for my $line (@$self)
        {
                $binstr .= ++$i % 2 ? 0 x length($1) : 1 x length($1)
                        if $line =~ s/( +)$//
        }
        return substr(pack("b*", $binstr),1)    # Delete our mark
}

1;

