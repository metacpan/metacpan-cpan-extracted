package Code::TidyAll::Plugin::Perl::AlignMooseAttributes;
BEGIN {
  $Code::TidyAll::Plugin::Perl::AlignMooseAttributes::VERSION = '0.01';
}
use Text::Aligner qw(align);
use List::Util qw(max);
use strict;
use warnings;
use base qw(Code::TidyAll::Plugin);

my $marker = '__AlignMooseAttributes_no_tidy';

sub preprocess_source {
    my ( $self, $source ) = @_;

    # Hide 'has' one-liners behind comments
    $source =~ s/^( has .* \) \s* \; )$/\# $marker $1/gmx;

    return $source;
}

sub postprocess_source {
    my ( $self, $source ) = @_;

    # Reveal 'has' lines
    $source =~ s/^\# $marker //gm;

    # For each group of 'has' one-liners: sort, remove multiple spaces and align equal signs
    $source =~ s/((^ has \s+ \' .*? \) \s* \; \s* \n)+)/process_attr_block($1)/gmex;

    return $source;
}

sub process_attr_block {
    my ($block) = @_;
    my @lines = grep { /\S/ } split( "\n", $block );
    my @attrs = map { /has\s+'([^\']+)'/; $1 } @lines;
    my $max_length = max( map { length($_) } @attrs );
    foreach my $line (@lines) {
        $line =~ s/  +/ /g;
        $line =~
          s/(?:has \s+ '([^\']+)') \s* => \s* \( \s* (.*?) \s* \) \s* ;/"has '$1'" . scalar(' ' x ($max_length - length($1))) . " => ( $2 );"/ex;
        $line =~ s/=> \(\s*\)/=> \(\)/;
        $line =~ s/,\s+\)/ \)/;
    }
    return join( "", sort(map { "$_\n" } @lines) ) . "\n";
}

1;



=pod

=head1 NAME

Code::TidyAll::Plugin::Perl::AlignMooseAttributes - Sort and align Moose-style
attributes with tidyall

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Code::TidyAll::Plugin::Perl::AlignMooseAttributes;

=head1 DESCRIPTION

This L<tidyall|tidyall> plugin sorts and aligns consecutive Moose-style
attribute lines. e.g. this:

    has 'namespace' => ( is => 'ro', isa => 'Str', default => 'Default' );
    has 'expires_at' => ( is => 'rw', default => CHI_Max_Time );
    has 'storage' => ( is => 'ro' );
    has 'label' => ( is => 'rw', lazy_build => 1 );
    has 'chi_root_class' => ( is => 'ro' );

becomes this:

    has 'chi_root_class' => ( is => 'ro' );
    has 'expires_at'     => ( is => 'rw', default => CHI_Max_Time );
    has 'label'          => ( is => 'rw', lazy_build => 1 );
    has 'namespace'      => ( is => 'ro', isa => 'Str', default => 'Default' );
    has 'storage'        => ( is => 'ro' );

Only consecutive attributes, each on a single line, will be affected.
Multi-line attributes will not be affected.

This plugin has a preprocess step that hides these lines to prevent perltidy
from splitting them into multiple lines.

=head1 SUPPORT AND DOCUMENTATION

Questions and feedback are welcome, and should be directed to the author.

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Code-TidyAll-Plugin-Perl-AlignMooseAttributes
    bug-code-tidyall-plugin-perl-alignmooseattributes@rt.cpan.org

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-code-tidyall-plugin-perl-alignmooseattributes
    git clone git://github.com/jonswar/perl-code-tidyall-plugin-perl-alignmooseattributes.git

=head1 SEE ALSO

L<perltidy|perltidy>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

