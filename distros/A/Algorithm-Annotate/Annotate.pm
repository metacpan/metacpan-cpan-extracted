package Algorithm::Annotate;
$VERSION = '0.10';
use strict;
use Algorithm::Diff qw(traverse_balanced);

=head1 NAME

Algorithm::Annotate - represent a series of changes in annotate form

=head1 SYNOPSIS

use Algorithm::Annotate;

my $ann = Algorithm::Annotate->new ();

$ann->add ($info1, \@seq1);

$ann->add ($info2, \@seq2);
$ann->add ($info3, \@seq3);

$result = $ann->result;

=head1 DESCRIPTION

Algorithm::Annotate generates a list that is useful for generating
output simliar to C<cvs annotate>.

=head1 TODO

Might parse diff output and accumulate them for generating the annotate list.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub init {
    my ($self, $info, $seq) = @_;
    $self->{lastseq} = $seq;
    $self->{annotate} = [map {$info} @$seq];
}

sub add {
    my ($self, $info, $seq) = @_;

    return $self->init ($info, $seq) unless $self->{lastseq};

    traverse_balanced( $self->{lastseq}, $seq,
		       { MATCH => sub {},
			 DISCARD_A =>
			 sub {
			     splice (@{$self->{annotate}}, $_[1], 1);
			 },
			 DISCARD_B =>
			 sub {
			     splice(@{$self->{annotate}}, $_[1], 0, $info);
			 },
			 CHANGE =>
			 sub {
			     $self->{annotate}[$_[1]] = $info;
			 },
		       } );

    $self->{lastseq} = $seq;
}

sub result {
    my $self = shift;
    return $self->{annotate};
}

1;

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
