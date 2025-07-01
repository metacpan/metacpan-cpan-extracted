package Bio::MUST::Core::Roles::Commentable;
# ABSTRACT: Commentable Moose role for storable objects
$Bio::MUST::Core::Roles::Commentable::VERSION = '0.251810';
use Moose::Role;

use autodie;
use feature qw(say);

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:files);


has 'comments' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    default  => sub { [] },
    handles  => {
        count_comments => 'count',
          all_comments => 'elements',
         join_comments => 'join',
          add_comment  => 'push',
          get_comment  => 'get',
       insert_comment  => 'unshift',
    },
);



sub header {
    my $self = shift;

    return "#\n" x 2 unless $self->count_comments;
    return '# ' . $self->get_comment(0) . "\n#\n" if $self->count_comments == 1;
    return '# ' . $self->join_comments("\n# ") . "\n";
}


sub is_comment {
    my $self  = shift;
    my $line  = shift;
    my $regex = shift // $COMMENT_LINE;

    # store comments from file header
    # TODO: prevent addition of further comments (after first data line)
    my ($shebang, $comment) = $line =~ $regex;
    if ($shebang) {                     # strip starting '#' and spaces
        $self->add_comment($comment) if $comment;
        return 1;
    }
    return 0;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Roles::Commentable - Commentable Moose role for storable objects

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 header

=head2 is_comment

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
