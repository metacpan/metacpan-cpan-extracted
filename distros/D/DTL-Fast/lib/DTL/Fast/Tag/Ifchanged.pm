package DTL::Fast::Tag::Ifchanged;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag';

$DTL::Fast::TAG_HANDLERS{ifchanged} = __PACKAGE__;

use DTL::Fast::Expression::Operator::Binary::Eq;

#@Override
sub get_close_tag { return 'endifchanged'; }

#@Override
sub parse_parameters
{
    my $self = shift;

    $self->add_branch();

    if ($self->{parameter})
    {
        $self->{watches} = $self->parse_sources($self->{parameter});
    }
    else
    {
        $self->{watch_content} = 1;
    }

    return $self;
}


#@Override
sub add_chunk
{
    my $self = shift;
    my $chunk = shift;

    $self->{branches}->[- 1]->add_chunk($chunk);

    return $self;
}

#@Override
sub parse_tag_chunk
{
    my ( $self, $tag_name, $tag_param, $chunk_lines ) = @_;

    my $result = undef;

    if ($tag_name eq 'else')
    {
        $self->add_branch();
        $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines;
    }
    else
    {
        $result = $self->SUPER::parse_tag_chunk($tag_name, $tag_param, $chunk_lines);
    }

    return $result;
}

#@Override
sub render
{
    my $self = shift;
    my $context = shift;
    my $result = '';

    my $forloop = $context->{ns}->[- 1]->{forloop};

    if (defined $forloop)
    {
        if ($self->{watch_content}) # slow behavior
        {
            $result = $self->{branches}->[0]->render($context);
            if (
                $forloop->{first}                             # first pass
                    or $result ne $self->{last_iteration_content} # content changed
            )
            {
                $self->{last_iteration_content} = $result;
            }
            elsif (scalar @{$self->{branches}} > 1)
            {
                $result = $self->{branches}->[1]->render($context);
            }
            else
            {
                $result = '';
            }
        }
        else
        {
            if ($forloop->{first}) # first pass
            {
                $self->update_preserved($context);
                $result = $self->{branches}->[0]->render($context);
            }
            else
            {
                if ($self->watches_changed($context))
                {
                    $result = $self->{branches}->[0]->render($context);
                    $self->update_preserved($context);
                }
                elsif (scalar @{$self->{branches}} > 1)
                {
                    $result = $self->{branches}->[1]->render($context);
                }
            }
        }
    }
    else
    {
        warn "ifchanged tag can be rendered only inside for loop";
    }

    return $result;
}

sub watches_changed
{
    my $self = shift;
    my $context = shift;
    my $result = 0;

    for (my $i = 0; $i < scalar @{$self->{watches}}; $i++)
    {
        my $watch = $self->{watches}->[$i]->render($context);
        my $preserve = $self->{preserved}->[$i];

        if (not DTL::Fast::Expression::Operator::Binary::Eq::dispatch($self, $watch, $preserve))
        {
            $result = 1;
            last;
        }
    }
    return $result;
}


sub update_preserved
{
    my $self = shift;
    my $context = shift;

    $self->{preserved} = [ ];

    foreach my $watch (@{$self->{watches}})
    {
        push @{$self->{preserved}}, $watch->render($context);
    }

    return $self;
}

sub add_branch
{
    my $self = shift;

    $self->{branches} //= [ ];
    push @{$self->{branches}}, DTL::Fast::Renderer->new();
    return $self;
}

1;
