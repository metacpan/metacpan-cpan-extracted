package CWB::CQP::More::Parallel;
$CWB::CQP::More::Parallel::VERSION = '0.08';
use 5.006;
use strict;
use warnings;

use base 'CWB::CQP::More';
use Try::Tiny;

=encoding utf-8

=head1 NAME

CWB::CQP::More::Parallel - CWP::CQP::More tweaked for parallel corpora

=head1 SYNOPSIS

   use CWB::CQP::More::Parallel;

   my $cwb = CWB::CQP::More::Parallel->new( { utf8 => 1} );


=head1 DESCRIPTION

CWB::CQP::More prepared for parallel corpora.

=cut

sub new {
    shift; # class
    my $ops = ref $_[0] eq "HASH" ? shift : {};
    $ops->{parallel} = 1;
    __PACKAGE__->SUPER::new($ops, @_);
}

=head2 change_corpus

Change current active parallel corpus. Pass the corpus name as the
first argument, and the target corpus as second argument. If this one
is ommited, the target language will be automatically selected (can
misbehave for multilanguage corpora).

=cut

sub change_corpus {
    my ($self, $cname, $tname) = @_;

    my $details = $self->corpora_details($cname);
    die "Can not find details for corpus $cname." unless defined $details;

    my $target;
    if (defined($tname)) {
        if (exists($details->{attribute}{a}{lc $tname})) {
            $target = lc $tname;
        } elsif (exists($details->{attribute}{a}{uc $tname})) {
            $target = uc $tname;
        } else {
            die "Can't find an aligned corpus named $tname";
        }
    } else {
        ($target) = keys %{ $details->{attribute}{a} };
    }

    die "This does not seems a parallel corpus." unless defined $target;

    $cname = uc $cname;
    $self->exec("$cname;");
    $self->annotation_show($target);
}


=head2 cat

This method uses the C<cat> method to return a result set. The first
mandatory argument is the name of the result set. 

B<NOT YET SUPPORTED:> Second and Third
arguments are optional, and correspond to the interval of matches to
return.

Returns empty list on any error.
On success returns list of pairs.

=cut

sub cat {
    my ($self, $id, $from, $to) = @_;  # , $from, $to) = @_;
    my $extra = "";
    $extra = "$from $to" if defined($from) && defined($to);
    my @ans;
    try {
        @ans = $self->exec("cat $id $extra;");
    } catch {
        @ans = ();
    };

    my @fans;
    while (@ans) {
        my $left  = shift @ans;
        my $right = shift @ans;
        push @fans, [$left,$right];
    }

    return @fans;
}

=head1 SEE ALSO

CWB::CQP::More

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Alberto Manuel Brandão Simões

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut



1;
__END__

