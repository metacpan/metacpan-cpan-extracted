package BioX::Workflow::Command::run::Rules::Directives::Interpolate::Text;

use Moose::Role;
use namespace::autoclean;

use Text::Template;
use Try::Tiny;
use Safe;
use Storable qw(dclone);
use File::Spec;
use Memoize;
use File::Basename;

our $c = new Safe;
my $TEMPLATE_ERROR = 0;

has 'delimiter' => (
    is      => 'rw',
    isa     => 'Str',
    default => '{',
);

has 'sample_var' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => '{$sample}',
);

sub interpol_text_template {
    my $self = shift;
    my $source = shift;
    my $text = '';

    $TEMPLATE_ERROR = 0;
    ## TODO Move this to before
    #The $ is not always at the beginning
    if (exists $self->interpol_directive_cache->{$source} && $source !~ m/{/) {
        return $self->interpol_directive_cache->{$source};
    }

    ## If the source string does not have a '{', its just text
    if ($source !~ m/{/) {
        $self->interpol_directive_cache->{$source} = $source;
        return $source;
    }

    my $template = Text::Template->new(
        TYPE   => 'STRING',
        SOURCE => $source,
        SAFE   => $c,
    );

    my $fill_in = { self => \$self };

    $fill_in->{sample} = $self->sample if $self->has_sample;
    my @keys = keys %{$self};
    foreach my $key (@keys) {
        if (ref $self->{$key}) {
            $fill_in->{$key} = \$self->{$key};
        }
        else {
            $fill_in->{$key} = $self->{$key};
        }
    }

    $text = $template->fill_in(
        HASH    => $fill_in,
        BROKEN  => \&my_broken,
        PREPEND => "use File::Glob; use File::Slurp; use File::Basename;\n"
    );

    if ($TEMPLATE_ERROR) {
        $self->_ERROR(1);
        if ($source =~ m/self/ && $source !~ m/\$self/) {
            $text .= "######################################\nFound use of self without \$\n\n";
        }
    }
    $self->interpol_directive_cache->{$source} = $text;
    return $text;
}

sub interpol_directive {
    my $self = shift;
    my $source = shift;
    my $text = '';

    return $self->interpol_text_template($source);
}

# memoize('my_broken');

sub my_broken {
    my %args = @_;
    my $err_ref = $args{arg};
    my $text = $args{text};
    my $error = $args{error};

    $TEMPLATE_ERROR = 1;
    $error =~ s/via package.*//g;
    chomp($error);
    if ($error =~ m/Can't locate object method/) {
        $error .= "\n# Did you declare $text?";
    }

    return <<EOF;

###################################################
# The following errors were encountered:
# $text
# $error
####################################################
EOF
}

1;
