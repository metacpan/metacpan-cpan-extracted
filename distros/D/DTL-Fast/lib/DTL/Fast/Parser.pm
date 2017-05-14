package DTL::Fast::Parser;
use strict;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Renderer';

use DTL::Fast::Expression;
use DTL::Fast::Text;
use DTL::Fast::Template;
use DTL::Fast qw(count_lines);

sub new
{
    my ( $proto, %kwargs ) = @_;

    die $proto->get_parse_error('no directory arrays passed into constructor')
        if (not $kwargs{dirs}
            or ref $kwargs{dirs} ne 'ARRAY')
    ;

    die $proto->get_parse_error('no raw chunks array passed into constructor')
        if (not $kwargs{raw_chunks}
            or ref $kwargs{raw_chunks} ne 'ARRAY')
    ;

    $kwargs{safe} //= 0;

    my $self = $proto->SUPER::new(%kwargs)->parse_chunks();;

    delete @{$self}{raw_chunks};

    return $self;
}

sub parse_chunks
{
    my ( $self ) = @_;
    while( scalar @{$self->{raw_chunks}} )
    {
        $self->add_chunk( $self->parse_next_chunk());
    }
    return $self;
}

sub parse_next_chunk
{
    my ( $self ) = @_;

    my $chunk = shift @{$self->{raw_chunks}};
    my $chunk_lines = count_lines($chunk);

    if (
        $chunk =~ /^
            \{\{\s*   # open sequence 
            ([^\s].*?) # variable name or value $1
            \s*\}\}   # close sequence 
            $/xs
    )
    {
        if ($1 eq 'block.super')
        {
            require DTL::Fast::Tag::BlockSuper;
            $chunk = DTL::Fast::Tag::BlockSuper->new(
                ''
                , dirs            => $self->{dirs}
                , _open_tag_lines => $chunk_lines
            );
        }
        else
        {
            $chunk = DTL::Fast::Variable->new($1);
            $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines;
        }
    }
    elsif
    (
        $chunk =~ /^
            \{\%\s*     # open sequence 
            ([^\s]+?)   # tag keyword $1
            (?:
            \s+     # spaces
            (.*?)   # parameters $2
            )?
            \s*\%\}     # close sequence 
            $/xs
    )
    {
        $chunk = $self->parse_tag_chunk(lc $1, $2, $chunk_lines);
    }
    elsif
    (
        $chunk =~ /^\{\#.*\#\}$/s
    )
    {
        $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines;
        $chunk = undef;
    }
    elsif ($chunk ne '')
    {
        $chunk = DTL::Fast::Text->new( $chunk);
        $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines;
    }
    else
    {
        $chunk = undef;
    }

    return $chunk;
}

sub parse_tag_chunk
{
    my ( $self, $tag_name, $tag_param, $chunk_lines ) = @_;

    my $result = undef;

    # dynamic module loading
    if (
        not exists $DTL::Fast::TAG_HANDLERS{$tag_name}
            and exists $DTL::Fast::KNOWN_TAGS{$tag_name}
    )
    {
        require Module::Load;
        Module::Load::load($DTL::Fast::KNOWN_TAGS{$tag_name});
        $DTL::Fast::LOADED_MODULES{$DTL::Fast::KNOWN_TAGS{$tag_name}} = time;
    }

    # handling tag
    if (exists $DTL::Fast::TAG_HANDLERS{$tag_name})
    {
        $result = $DTL::Fast::TAG_HANDLERS{$tag_name}->new(
            $tag_param
            , raw_chunks      => $self->{raw_chunks}
            , dirs            => $self->{dirs}
            , _open_tag_lines => $chunk_lines
        );
    }
    else # not found
    {
        my $full_tag_name = join ' ', grep $_, ($tag_name, $tag_param);

        if (# block tag parsing error
            $self->isa('DTL::Fast::Tag')
                and not $self->isa('DTL::Fast::Tag::Simple')
        )
        {
            warn $self->get_parse_warning(
                    sprintf( 'unknown tag {%% %s %%}', $full_tag_name )
                    , 'Possible reasons' => sprintf( <<'_EOM_'
typo in tag name
duplicated close tag {%% %1$s %%}
unopened close tag {%% %1$s %%}
undisclosed block tag %3$s
_EOM_
                        , $tag_name // 'undef'
                        , $DTL::Fast::Template::CURRENT_TEMPLATE_LINE // 'unknown'
                        , $self->open_tag_syntax_with_line_number()
                    )
                );
        }
        else # template parsing error
        {
            warn $self->get_parse_warning(
                    sprintf( 'unknown tag {%% %s %%}', $full_tag_name )
                    , 'Possible reasons' => sprintf( <<'_EOM_'
typo, duplicated or unopened close tag {%% %1$s %%} at line %2$s
_EOM_
                        , $tag_name // 'undef'
                        , $DTL::Fast::Template::CURRENT_TEMPLATE_LINE // 'unknown'
                    )
                );
        }

        $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines;

        $result = DTL::Fast::Text->new();
    }

    return $result;
}

1;
