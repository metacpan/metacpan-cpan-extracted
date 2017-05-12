package Data::Encoder::Data::Dumper;

use strict;
use warnings;
use Carp ();
use Data::Dumper ();

sub new {
    my ($class, $args) = @_;
    $args ||= {};
    bless { %$args }, __PACKAGE__;
}

sub encode {
    my ($self, $stuff, @args) = @_;
    local $Data::Dumper::Terse  = 1;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Indent = 0;
    my $dumper = Data::Dumper->new([$stuff], @args);
    for my $method (keys %$self) {
        $dumper->$method($self->{$method});
    }
    return $dumper->Dump;
}

sub decode {
    my ($self, $stuff, @args) = @_;
    local $@;
    my $res = eval $stuff; ## no critic
    Carp::croak $@ if $@;
    return $res;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Data::Encoder::Data::Dumper - Data::Encoder gateway for Data::Dumper

=head1 SYNOPSIS

  use Data::Encoder;
  
  my $encoder = Data::Encoder->load('Data::Dumper');
  my $dumped = $encoder->encode({ foo => bar });
  my $hash = $encoder->decode($dumped);
  
  my $encoder = Data::Encoder->load('Data::Dumper', { SortKeys => 1 });
  my $dumped = $encoder->encode($data);
  ## $dumper = Data::Dumper->new([$data]);
  ## $dumper->SortKeys(1);
  ## $dumper->Dump;

=head1 AUTHOR

xaicron E<lt>xaicron {at} cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2010 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Data::Dumper>

=cut
