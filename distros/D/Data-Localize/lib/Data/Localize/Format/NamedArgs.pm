package Data::Localize::Format::NamedArgs;
use Moo;

extends 'Data::Localize::Format';

sub format {
    my ($self, $lang, $value, $args) = @_;

    return $value unless ref $args eq 'HASH';

    $value =~ s/\{\{([^}]+)\}\}/ $args->{ $1 } || '' /ex;
    return $value;
}

1;

__END__

=head1 NAME

Data::Localize::Format::NamedArgs - Process Lexicons With Named Args (As Opposed To Positional Args)

=head1 SYNOPSIS

    # "Hello {{name}}" -> "Hello, John"
    $loc->localize( "lexicon_key", { name => "John" } );

=head1 METHODS

=head2 format

=cut
