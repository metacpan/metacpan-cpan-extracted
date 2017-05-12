package Algorithm::Accounting::Report;
use Spiffy -Base;
our $VERSION = '0.02';

sub process {
    my ($occhash,$field_groups,$group_occ) = @_;
    for(keys %{$occhash}) {
        $self->report_occurrence_percentage($_,$occhash);
    }
    for(0..@{$field_groups}-1) {
        $self->report_field_group_occurrence_percentage($_,$field_groups,$group_occ);
    }
}

__END__
=head1 NAME

Algorithm::Accounting::Report - report generating of Algorithm::Accounting result

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
