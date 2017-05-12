package Catmandu::Fix::markdown_to_html;
use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:is :check);
use Text::Markdown::Discount;

our $VERSION = "0.011";

has field => (
    is => 'ro' ,
    required => 1
);
around BUILDARGS => sub {
    my($orig,$class,$field) = @_;
    $orig->($class,field => $field);
};

sub emit {
    my($self,$fixer) = @_;

    my $perl = "";

    my $field = $fixer->split_path($self->field());
    my $key = pop @$field;

    $perl .= $fixer->emit_walk_path($fixer->var,$field,sub{
        my $var = shift;
        $fixer->emit_get_key($var,$key, sub {
            my $var = shift;
            "${var} = is_string(${var}) ? Text::Markdown::Discount::markdown(${var}) : \"\";";
        });
    });

    $perl;
}

=head1 NAME

Catmandu::Fix::markdown_to_html - converts markdown to html elements

=head1 SYNOPSIS

markdown_to_html('text_markdown')

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
