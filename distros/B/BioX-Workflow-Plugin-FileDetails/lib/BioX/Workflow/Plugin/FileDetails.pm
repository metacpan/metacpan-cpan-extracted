package BioX::Workflow::Plugin::FileDetails;

our $VERSION = '0.11';

use Moose::Role;
use List::Uniq ':all';
use Data::Dumper;

has 'collect_outdirs' => (
    traits  => ['Array'],
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {[]},
    handles => {
        add_collect_outdirs     => 'push',
        has_collect_outdirs     => 'count',
    },
);

after 'process_template' => sub {
    my $self = shift;
    my $data = shift;

    $self->add_collect_outdirs($self->outdir);
    $self->add_collect_outdirs($self->indir);

    @{$self->collect_outdirs} = uniq(@{$self->collect_outdirs}) if $self->has_collect_outdirs;
};

after 'write_pipeline' => sub {
    my $self = shift;

    print <<EOF;

#
# Starting FileDetails Plugin
#

EOF
    foreach my $outdir (@{$self->collect_outdirs}){
        my $cmd = "filedetails.pl --check_dir ".$outdir;
        print "\n";
        print "filedetails.pl --check_dir ".$outdir;
        print "\n\n";
    }

    print <<EOF;

#
# Ending FileDetails Plugin
#
EOF

};

1;
__END__

=encoding utf-8

=head1 NAME

BioX::Workflow::Plugin::FileDetails - Get metadata for files in directories
processed by L<BioX::Workflow>

=head1 SYNOPSIS

List your plugins in your workflow.yml file

    ---
    plugins:
        - FileDetails
    global:
        - indir: /home/user/gemini
        - outdir: /home/user/gemini/gemini-wrapper
        - file_rule: (.vcf)$|(.vcf.gz)$
        - infile:
    #So On and So Forth

=head1 DESCRIPTION

BioX::Workflow::Plugin::FileDetails is a plugin for L<BioX::Workflow>. It gets
metadata for files in directories processed by L<BioX::Workflow> including MD5,
size, human readable size, date created, last accessed, and last modified.

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 Acknowledgements

This modules continuing development is supported by NYU Abu Dhabi in the Center for Genomics and Systems Biology.
With approval from NYUAD, this information was generalized and put on bitbucket, for which
the authors would like to express their gratitude.

=head1 COPYRIGHT

Copyright 2015- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
