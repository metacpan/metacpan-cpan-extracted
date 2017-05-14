package DTL::Fast::Tag;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Parser';

use DTL::Fast;
use DTL::Fast::Template;

sub new
{
    my ( $proto, $parameter, %kwargs ) = @_;
    $parameter //= '';

    $parameter =~ s/^\s+|\s+$//gs;

    $kwargs{parameter} = $parameter;

    return $proto->SUPER::new(%kwargs);
}

sub parse_parameters {return shift;}

sub parse_chunks
{
    my ( $self ) = @_;
    $self->parse_parameters();

    $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $self->{_open_tag_lines}
        if ($self->{_open_tag_lines});

    return $self->SUPER::parse_chunks();
}

sub get_close_tag
{
    my ( $self ) = @_;
    die sprintf(
            "ABSTRACT method get_close_tag, must be overriden in %s"
            , ref $self
        );
}

# Close tag processor
sub parse_tag_chunk
{
    my ( $self, $tag_name, $tag_param, $chunk_lines ) = @_;

    my $result = undef;

    if ($tag_name eq $self->get_close_tag)
    {
        $self->{raw_chunks} = [ ]; # this stops parsing
        $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines;
    }
    else
    {
        $result = $self->SUPER::parse_tag_chunk($tag_name, $tag_param, $chunk_lines);
    }

    return $result;
}

# returns restored opening tag
sub open_tag_syntax
{
    my ($self) = @_;

    return join( ' ',
        grep(
            $_
            , (
            '{%'
            , $DTL::Fast::KNOWN_SLUGS{ref $self}
            , $self->{parameter}
            , '%}'
        )
        )
    );
}

# returns restored opening tag
sub open_tag_syntax_with_line_number
{
    my ($self) = @_;
    return $self->open_tag_syntax().' at line '.($self->{_template_line} // 'unknown');
}

sub get_block_parse_error
{
    my ($self, $message) = @_;
    return $self->get_parse_error(
        $message,
        Block => sprintf(
            '%s at line %s'
            , ref $self
            , $self->{_template_line} // 'unknown'
        )
    );
}

1;
