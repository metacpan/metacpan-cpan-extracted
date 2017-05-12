use strict;
use warnings;

package Code::TidyAll::Plugin::SortLines::Naturally;
$Code::TidyAll::Plugin::SortLines::Naturally::VERSION = '0.000003';
use Moo;
extends 'Code::TidyAll::Plugin';

use Unicode::Collate::Locale ();

has 'locale' => ( is => 'ro', default => 'en_US' );

sub transform_source {
    my ( $self, $source ) = @_;

    my $collator = Unicode::Collate::Locale->new( locale => $self->locale );
    return
        join( "\n", $collator->sort( grep {/\S/} split( /\n/, $source ) ) )
        . "\n";
}

1;

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::SortLines::Naturally - Sort lines of a file using Unicode::Collate::Locale

=head1 VERSION

version 0.000003

=head1 SYNOPSIS

   # In configuration:

   [SortLines::Naturally]
   select = .ispell* **/.gitignore

=head1 DESCRIPTION

Sorts the lines of a file; whitespace lines are discarded. Useful for files
containing one entry per line, such as C<.svnignore>, C<.gitignore>, and
C<.ispell*>.

=head1 CONFIGURATION

=over

=item locale

The locale to use for collation. Defaults to "en_US".

=back

=head1 ACKNOWLEDGEMENTS

This code was essentially pilfered from L<Code::TidyAll::Plugin::SortLines>

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Sort lines of a file using Unicode::Collate::Locale

