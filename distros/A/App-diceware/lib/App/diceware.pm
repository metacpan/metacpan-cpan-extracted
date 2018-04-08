package App::diceware;

use strict;
use warnings;

our $VERSION = '0.01';

use File::Share ':all';
use Crypt::Rijndael;
use Crypt::URandom;
use Data::Entropy qw(with_entropy_source);
use Data::Entropy::Algorithms qw(rand_int);
use Data::Entropy::RawSource::CryptCounter;
use Data::Entropy::Source;

sub new {
    my ($class, $arg_ref) = @_;
    my $self = $arg_ref // {};
    bless $self, $class;
    $self->_init();
    return $self;
}

sub _dice {
    my ($self) = shift;
    my $dice = with_entropy_source(
        $self->{entropy},
        sub {
            rand_int(6) + 1;
        }
    );
    return $dice;
}

sub _init {
    my ($self) = shift;
    $self->{language} //= 'en';
    $self->{wordlist} = $self->_load_wordlist();
    $self->{entropy}  = $self->_build_entropy();
    return;
}

sub _load_wordlist {
    my ($self) = shift;
    die "language not supported" unless $self->{language} =~ m/^(de|en)$/xms;
    my $file = dist_file('App-diceware', "wordlist_$self->{language}.tsv");
    open(my $fh, '<:encoding(UTF-8)', $file)
        or die "Couldn't open '$file': $!";
    my $wordlist;
    while (my $line = <$fh>) {
        chomp $line;
        my ($key, $value) = split /\t/, $line, 2;
        $wordlist->{$key} = $value;
    }
    return $wordlist;
}

sub passphrase {
    my ($self, $arg_ref) = @_;
    my $length = $arg_ref->{length} // 5;
    my @passwords;
    for (my $i = 0; $i < $length; $i++) {
        my $key;
        for (0 .. 4) {
            $key .= $self->_dice();
        }
        push @passwords, $self->{wordlist}->{$key};
    }
    if ($arg_ref->{pretty}) {
        return join '-', @passwords;
    }
    return join '', @passwords;
}

sub _build_entropy {
    my $self = shift;
    return Data::Entropy::Source->new(
        Data::Entropy::RawSource::CryptCounter->new(
            Crypt::Rijndael->new(Crypt::URandom::urandom(32))
        ),
        "getc"
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

App::diceware - A simple Diceware passphrase generator.


=begin markdown

[![Build Status](https://travis-ci.org/jorol/App-diceware.png)](https://travis-ci.org/jorol/App-diceware)
[![Coverage Status](https://coveralls.io/repos/jorol/App-diceware/badge.png?branch=master)](https://coveralls.io/r/jorol/App-diceware?branch=master)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/App-diceware.png)](http://cpants.cpanauthors.org/dist/App-diceware)
[![CPAN version](https://badge.fury.io/pl/App-diceware.png)](http://badge.fury.io/pl/App-diceware)

=end markdown

=head1 SYNOPSIS

  # via command line
  $ diceware.pl
  earthlinghandbookspiltunwillingappendage
  $ diceware.pl --language en --length 2 --pretty
  earthling-handbook

  # in Perl
  use App::diceware;

  my $diceware = App::diceware->new({language => 'en'});
  my $passphrase = diceware->passphrase({length => 5, pretty => 1});

=head1 DESCRIPTION

App::diceware is a simple Diceware passphrase generator. It supports English 
and German wordlists.

=head1 AUTHOR

Johann Rolschewski E<lt>jorol@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018- Johann Rolschewski

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Diceware|https://en.wikipedia.org/wiki/Diceware>

=cut
