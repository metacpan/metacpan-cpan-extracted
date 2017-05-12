package Bio::HTS::File;

use Bio::HTS;

require Exporter;

our @ISA = qw/Exporter/;
our @EXPORT = qw/hts_open hts_close/;

1;

__END__

=head1 NAME

Bio::HTS::File - XS module providing an interface to c htsFile structs

=head1 SYNOPSIS

    use Bio::HTS::File qw(hts_open hts_close);

    my $hts = hts_open("test.bed.gz");
 
    sub DESTROY {
        hts_close($hts);
    }

=head1 DESCRIPTION

By itself this module is pretty useless, you'll probably use it with
other modules under HTS (currently only Tabix exists)

=head2 Methods

=over 12

=item C<hts_open>

Returns a pointer to the htsFile C struct. You must call hts_close
before the returned pointer goes out of scope or memory won't be freed

=item C<hts_close>

Close a htsFile struct

=back

=head1 LICENSE

Licensed under the terms of the GNU AFFERO GENERAL PUBLIC LICENSE (AGPL)

=head1 COPYRIGHT

Copyright 2015 Congenica Ltd.

=head1 AUTHOR

Alex Hodgkins

=cut
