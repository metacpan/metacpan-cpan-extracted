package Bio::RetrieveAssemblies::RefWeak;
$Bio::RetrieveAssemblies::RefWeak::VERSION = '1.1.5';
use Moose;
with('Bio::RetrieveAssemblies::RemoteSpreadsheetRole');

# ABSTRACT: Get the blacklist of accession numbers from refweak


has 'url' => ( is => 'ro', isa => 'Str', default => 'https://raw.githubusercontent.com/refweak/refweak/master/refweak.tsv' );
has 'accession_column_index'  => ( is => 'ro', isa => 'Int',     default => 0 );
has 'accession_column_header' => ( is => 'ro', isa => 'Str',     default => "accession" );
has 'accessions'              => ( is => 'ro', isa => 'HashRef', lazy    => 1, builder => '_build_accessions' );

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::RetrieveAssemblies::RefWeak - Get the blacklist of accession numbers from refweak

=head1 VERSION

version 1.1.5

=head1 SYNOPSIS

Get the blacklist of accession numbers from refweak

    use Bio::RetrieveAssemblies::RefWeak;
    my $obj = Bio::RetrieveAssemblies::RefWeak->new();
    my %accessions_hash  = $obj->accessions();

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
