package DTL::Fast::Template;
use parent 'DTL::Fast::Parser';
use strict;
use utf8;
use warnings FATAL => 'all';

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use DTL::Fast::Tags;
use DTL::Fast::Filters;
use Scalar::Util qw/weaken/;

our $CURRENT_TEMPLATE;      # global variable for linking  modules
our $CURRENT_TEMPLATE_LINE; # global variable for source line number

#@Override
sub new
{
    my ( $proto, $template, %kwargs ) = @_;
    $template //= '';

    $kwargs{raw_chunks} = _get_raw_chunks($template);
    $kwargs{dirs} //= [ ];             # optional dirs to look up for includes or parents
    $kwargs{file_path} //= 'inline';
    $kwargs{perl} = $];
    $kwargs{blocks} = { };
    $kwargs{modules} //= {
        'DTL::Fast' => $DTL::Fast::VERSION,
    };

    my $self = $proto->SUPER::new(%kwargs);

    return $self;
}

#@Override self-linking
sub remember_template
{
    my ($self) = @_;

    $self->{_template} = $self;
    $self->{_template_line} = 1;
    weaken $self->{_template};

    return $self;
}

#@Override
sub parse_chunks
{
    my ( $self ) = @_;

    my ( $current_template_backup, $current_template_line_backup ) = ($CURRENT_TEMPLATE, $CURRENT_TEMPLATE_LINE);
    ($CURRENT_TEMPLATE, $CURRENT_TEMPLATE_LINE) = ($self, 1);

    $self->SUPER::parse_chunks();

    ($CURRENT_TEMPLATE, $CURRENT_TEMPLATE_LINE) = ($current_template_backup, $current_template_line_backup);
    return $self;
}

my $reg = qr/(
    \{\#.+?\#\}
    |\{\%.+?\%\}
    |\{\{.+?\}\}
    )/xs;

sub _get_raw_chunks
{
    my ( $template ) = @_;

    my $result = [ split $reg, $template ];

    return $result;
}

#@Override
sub render
{
    my ( $self, $context ) = @_;

    $context //= { };

    if (ref $context eq 'HASH')
    {
        $context = DTL::Fast::Context->new($context);
    }
    elsif (
        defined $context
            and ref $context ne 'DTL::Fast::Context'
    )
    {
        die  "Context must be a DTL::Fast::Context object or a HASH reference";
    }

    $context->push_scope();

    $context->{ns}->[- 1]->{_dtl_ssi_dirs} = $self->{ssi_dirs} if ($self->{ssi_dirs});
    $context->{ns}->[- 1]->{_dtl_url_source} = $self->{url_source} if ($self->{url_source});

    my $template_path = $self->{file_path};

    if (not exists $context->{ns}->[- 1]->{_dtl_include_path})  # entry point
    {
        $context->{ns}->[- 1]->{_dtl_include_path} = [ ];
        $context->{ns}->[- 1]->{_dtl_include_files} = { };
    }
    else    # check for recursion, shouldn't this be in the include tag?
    {
        if (exists $context->{ns}->[- 1]->{_dtl_include_files}->{$template_path})
        {
            # recursive inclusion
            die sprintf("Recursive inclusion detected:\n%s\n"
                    , join( "\n includes ", @{$context->{ns}->[- 1]->{_dtl_include_path}}, $template_path)
                );
        }
    }

    $context->{ns}->[- 1]->{_dtl_include_files}->{$template_path} = 1;
    push @{$context->{ns}->[- 1]->{_dtl_include_path}}, $template_path;

    my $result;
    if ($self->{extends}) # has parent template
    {
        my @descendants = ();
        my $current_descendant = $self;
        my %inheritance = ();

        while( $current_descendant->{extends} )
        {
            push @descendants, $current_descendant;
            $inheritance{$current_descendant->{file_path}} = 1;

            my $parent_template_name = $current_descendant->{extends}->render($context);

            die sprintf(
                    "Unable to resolve parent template name for %s"
                    , $current_descendant->{file_path}
                ) if (not $parent_template_name);

            $current_descendant = get_template(
                $parent_template_name
                , dirs => $self->{dirs}
            );

            if (defined $current_descendant)
            {
                if ($inheritance{$current_descendant->{file_path}})
                {
                    die  sprintf(
                            "Recursive inheritance detected:\n%s\n"
                            , join(
                                "\n inherited from ",
                                (map {$_->{file_path}} @descendants),
                                $current_descendant->{file_path}
                            )
                        );
                }
            }
            else
            {
                die  sprintf( "Couldn't found a parent template: %s in one of the following directories: %s"
                        , $parent_template_name
                        , join( ', ', @{$self->{dirs}})
                    );
            }
        }

        push @descendants, $current_descendant;
        $context->{ns}->[- 1]->{_dtl_descendants} = \@descendants;
        $context->{ns}->[- 1]->{_dtl_rendering_template} = $current_descendant;
        $result = $current_descendant->SUPER::render($context);

    }
    else
    {
        delete $context->{ns}->[- 1]->{_dtl_descendants};
        $context->{ns}->[- 1]->{_dtl_rendering_template} = $self;
        $result = $self->SUPER::render($context);
    }

    pop @{$context->{ns}->[- 1]->{_dtl_include_path}};
    delete $context->{ns}->[- 1]->{_dtl_include_files}->{$template_path};

    $context->pop_scope();

    return $result;
}

1;
