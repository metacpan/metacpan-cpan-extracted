package DTL::Fast::Entity;
use strict;
use utf8;
use warnings FATAL => 'all';
# prototype for template entity. Handling current line and current template references

use Scalar::Util qw(weaken);
use Carp qw(confess);

sub new
{
    my ( $proto, %kwargs ) = @_;

    $proto = ref $proto || $proto;

    $DTL::Fast::Template::CURRENT_TEMPLATE->{modules}->{$proto} = $proto->VERSION // DTL::Fast->VERSION;

    my $self = bless { %kwargs }, $proto;

    $self->remember_template;

    return $self;
}

sub remember_template
{
    my ($self) = @_;

    $self->{_template} = $DTL::Fast::Template::CURRENT_TEMPLATE;
    $self->{_template_line} = $DTL::Fast::Template::CURRENT_TEMPLATE_LINE;
    weaken $self->{_template};

    return $self;
}

sub get_parse_error
{
    my ($self, $message, @messages) = @_;

    return $self->compile_error_message(
        'Parsing error' => $message // 'undef'
        , Template      => $DTL::Fast::Template::CURRENT_TEMPLATE->{file_path}
        , Line          => $DTL::Fast::Template::CURRENT_TEMPLATE_LINE
        , @messages
    );
}

sub get_parse_warning
{
    my ($self, $message, @messages) = @_;

    return $self->compile_error_message(
        'Parsing warning' => $message // 'undef'
        , Template        => $DTL::Fast::Template::CURRENT_TEMPLATE->{file_path}
        , Line            => $DTL::Fast::Template::CURRENT_TEMPLATE_LINE
        , @messages
    );
}

sub get_render_error
{
    my ($self, $context, $message, @messages) = @_;

    my @params = (
        'Rendering error' => $message // 'undef'
        , Template        => $self->{_template}->{file_path}
        , Line            => $self->{_template_line}
        , @messages
    );

    confess "No context passed for rendering error generator." unless ($context);

    if (
        exists $context->{ns}->[- 1]->{_dtl_include_path}
            and ref $context->{ns}->[- 1]->{_dtl_include_path} eq 'ARRAY'
            and scalar @{$context->{ns}->[- 1]->{_dtl_include_path}} > 1
    ) # has inclusions, appending stack trace
    {
        push @params, 'Stack trace' => join( "\n", reverse @{$context->{ns}->[- 1]->{_dtl_include_path}});
    }

    return $self->compile_error_message( @params );
}

# format error message from key=>val pair
sub compile_error_message
{
    my ($self, @messages) = @_;

    die 'Odd parameters in messages array'
        if (scalar(@messages) % 2);

    # calculating max padding
    my $padding = 0;
    for (my $i = 0; $i < scalar @messages; $i += 2)
    {
        my $length = length $messages[$i];
        $padding = $length if ($length > $padding);
    }

    my $result = '';
    while ( scalar @messages )
    {
        my $key = shift @messages // 'undef';
        my $value = shift @messages // 'undef';

        chomp($value);

        my $key_length = length $key;

        $result .= sprintf
            '%s%s: '
            , ' ' x ($padding - $key_length)
            , $key;

        my @value = split /\n+/, $value;
        $result .= shift @value;
        $result .= "\n";

        foreach my $value (@value)
        {
            $result .= (' ' x ($padding + 2)).$value."\n";
        }
    }
    return $result;
}

1;
