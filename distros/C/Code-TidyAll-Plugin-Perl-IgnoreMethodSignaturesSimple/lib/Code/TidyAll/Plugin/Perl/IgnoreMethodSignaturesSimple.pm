package Code::TidyAll::Plugin::Perl::IgnoreMethodSignaturesSimple;
$Code::TidyAll::Plugin::Perl::IgnoreMethodSignaturesSimple::VERSION = '0.03';
use strict;
use warnings;
use base qw(Code::TidyAll::Plugin);

sub preprocess_source {
    my ( $self, $source ) = @_;

    $source =~
      s/^\h*(method|func)\s+(\w+)([^\{]+)\{/$self->_munged_sub($1, $2, $3)/gme;

    return $source;
}

sub postprocess_source {
    my ( $self, $source ) = @_;

    foreach my $id ( keys( %{ $self->{saves} } ) ) {
        my ( $keyword, $name, $rest ) = @{ $self->{saves}->{$id} };
        for ( $name, $rest ) { s/^\s+//; s/\s+$// }

        # Blank parens if no params list
        #
        $rest = '()' if $rest !~ /\S/;

        # No space inside parens
        #
        $rest =~ s/\(\s+/\(/;
        $rest =~ s/\s+\)/\)/;

        $source =~ s/sub MUNGED_${id}_/$keyword $name $rest/;
    }

    return $source;
}

sub _munged_sub {
    my ( $self, $keyword, $name, $rest ) = @_;

    my $id = $self->_unique_id;
    $self->{saves}->{$id} = [ $keyword, $name, $rest ];
    return "sub MUNGED_${id}_ {";
}

my $unique_id = 0;

sub _unique_id {
    return join( '_', time, $unique_id++ );
}

1;

__END__

=pod

=head1 NAME

Code::TidyAll::Plugin::Perl::IgnoreMethodSignaturesSimple - Prep
Method::Signatures::Simple directives for perltidy and perlcritic

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Code::TidyAll::Plugin::Perl::IgnoreMethodSignaturesSimple

=head1 DESCRIPTION

This L<tidyall|tidyall> plugin uses a preprocess/postprocess step to convert
L<Method::Signatures::Simple|Method::Signatures::Simple> (C<method> and
C<function>) to specially marked subroutines so that L<perltidy|perltidy> and
L<perlcritic|perlcritic> will treat them as such, and then revert them
afterwards.

The postprocess step also adds an empty parameter list if none is there. e.g.
this

    method foo {

becomes

    method foo () {

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

This software is copyright (c) 2012 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
