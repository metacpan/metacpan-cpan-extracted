package App::PerlFuzzyTokenFinder::MatchedPosition;
use strict;
use warnings;
use Carp qw(croak);

# args:
#   filename: Str
#   line_number: Num
#   statement: PPI::Statement, should be cloned with PPI::Statement#clone
sub new {
    my ($class, %args) = @_;

    my $filename = delete $args{filename};
    croak "filename required" unless defined $filename;

    my $line_number = delete $args{line_number};
    croak "line_number required" unless defined $line_number;

    my $statement = delete $args{statement};
    croak "statement required" unless defined $statement;

    bless +{
        filename    => $filename,
        line_number => $line_number,
        statement   => $statement,
    };
}

# getter
sub filename { shift->{filename} }
sub line_number { shift->{line_number} }
sub statement { shift->{statement} }

sub format_for_print {
    my $self = shift;

    sprintf "%s:%d:%s", $self->filename, $self->line_number, $self->statement->content;
}

1;
__END__

=head1 NAME

App::PerlFuzzyTokenFinder::MatchedPosition

=head1 DESCRIPTION

App::PerlFuzzyTokenFinder::MatchedPosition is an object representing found position with App::PerlFuzzyTokenFinder.

=head1 LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

utgwkk E<lt>utagawakiki@gmail.comE<gt>

=cut
