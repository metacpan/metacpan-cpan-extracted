package Acme::Want5000trillion;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

my $languages = {
    "ja" => "5000兆円欲しい！",
    "en" => "I want 5000 trillion yen!",
    "th" => "ฉันต้องการ 5000000000000000 เยน!",
    "cn" => "我想五千万亿日元!",
    "it" => "Voglio 5000 trilioni di yen!",
};


sub say{
    my $self = shift;
    my $lang = shift // "ja";
    $lang = "ja" if (! exists($languages->{$lang}));
    return "$languages->{$lang}";
}


sub new {
    my ($class,%parameters) = @_;

    my $self = bless ({},ref($class) || $class);

    return $self;
}


1;
__END__

=encoding utf-8

=head1 NAME

Acme::Want5000trillion - I want 5000trillion yen.

=head1 SYNOPSIS

    use Acme::Want5000trillion;
    my $want = Acme::Want5000trillion->new;

    print $want->say(); #5000兆円欲しい!


=head1 DESCRIPTION

Acme::Want5000trillion is Japanese twitter famous words.
I want 5000 trillion yen.

This module correspondence some languages.

- ja 
- en
- th
- cn
- it 

=head1 LICENSE

Copyright (C) AnaTofuZ.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

AnaTofuZ E<lt>e155730@ie.u-ryukyu.ac.jpE<gt>

=cut

