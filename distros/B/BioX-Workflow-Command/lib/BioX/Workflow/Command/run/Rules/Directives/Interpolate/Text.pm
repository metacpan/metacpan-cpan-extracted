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

sub interpol_directive {
    my $self   = shift;
    my $source = shift;
    my $text   = '';

    #The $ is not always at the beginning
    if ( exists $self->interpol_directive_cache->{$source} && $source !~ m/{/ )
    {
        return $self->interpol_directive_cache->{$source};
    }

    if ( $source !~ m/{/ ) {
        $self->interpol_directive_cache->{$source} = $source;
        return $source;
    }

    my $template = Text::Template->new(
        TYPE   => 'STRING',
        SOURCE => $source,
        SAFE   => $c,
    );

    my $fill_in = { self => \$self };

    #TODO reference keys by value instead of $self->
    # my @keys = keys %{$self};
    # $fill_in->{INPUT} = $self->INPUT;
    $fill_in->{sample} = $self->sample if $self->has_sample;

    $text = $template->fill_in(
        HASH    => $fill_in,
        BROKEN  => \&my_broken,
        PREPEND => "use File::Glob; use File::Basename;\n"
    );

    $self->interpol_directive_cache->{$source} = $text;
    return $text;
}

memoize('my_broken');

sub my_broken {
    my %args    = @_;
    my $err_ref = $args{arg};
    my $text    = $args{text};
    my $error   = $args{error};
    $error =~ s/via package.*//g;
    chomp($error);
    if ( $error =~ m/Can't locate object method/ ) {
        $error .= "\n# Did you declare $text?";
    }

    return <<EOF;

###################################################
# The following errors were encountered:
# $text
# $error
###################################################
EOF
}

1;
