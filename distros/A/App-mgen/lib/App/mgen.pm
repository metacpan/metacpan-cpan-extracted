package App::mgen;

use 5.008;
use utf8;
use strict;
our $VERSION = '0.16';

use Cwd;
use Carp ();
use IO::File;
use List::Util;
use File::Path;
use Pod::Usage;
use Time::Piece;
use Getopt::Long;

sub new {
    my $class = shift;

    my $self = bless {
        options => {

            # option list
            moose       => undef,
            mouse       => undef,
            moo         => undef,
            mo          => undef,
            m           => undef,
            immutable   => undef,
            autoclearn  => undef,
            signature   => undef,
            silent      => undef,
            dryrun      => undef,
            description => undef,
            author      => undef,
            email       => undef,
            path        => undef,
            current     => undef,
        },
        description => "",
        module_name => "",
        module_path => "",
        author      => "",
        email       => "",
    }, $class;

    return $self->_set_env->_set_options;
}

sub generate {
    my $self = shift;

    ## code generate

    # set header
    my $gen = $self->_gen_default;

    for my $attribute (qw/signature moose autoclearn immutable mouse moo mo m/) {
        my $call = "_gen_$attribute";
        $gen .= $self->$call if defined($self->{options}->{$attribute});
    }

    # set footer
    $gen .= $self->_gen_packend . $self->_gen_pod;

    ## file output
    my $path;
    if ( !$self->{options}->{dryrun} ) {
        if ( !$self->{options}->{current} ) {
            $path = $self->_create_dir if !$self->{options}->{current};
        } else {
            my @depth = split "::", $self->{module_name};
            $path = pop @depth;
            $path = sprintf "%s.pm", $path;
        }

        my $io = IO::File->new( $path, "w" ) || die $!;

        $io->print($gen);
        $io->close;
    }

    ## std output
    if ( !$self->{options}->{silent} ) {
        print "$gen\n";
        print "OUTPUT >> $path\n" if $path;
    }

    return $gen;
}

sub _set_env {
    my $self = shift;

    $self->{module_path} = $ENV{MGEN_ROOT}   ? $ENV{MGEN_ROOT}   : "";
    $self->{author}      = $ENV{MGEN_AUTHOR} ? $ENV{MGEN_AUTHOR} : "";
    $self->{email}       = $ENV{MGEN_EMAIL}  ? $ENV{MGEN_EMAIL}  : "";

    return $self;
}

sub _set_options {
    my $self = shift;

    # Set options
    my $options = {};
    my $ret     = GetOptions(
        'moose'         => \( $options->{moose} ),
        'mouse'         => \( $options->{mouse} ),
        'moo'           => \( $options->{moo} ),
        'mo'            => \( $options->{mo} ),
        'm'             => \( $options->{m} ),
        'immutable'     => \( $options->{immutable} ),
        'autoclearn'    => \( $options->{autoclearn} ),
        'signature'     => \( $options->{signature} ),
        'silent'        => \( $options->{silent} ),
        'dry-run'       => \( $options->{dryrun} ),
        'description=s' => \( $options->{description} ),
        'author=s'      => \( $options->{author} ),
        'email=s'       => \( $options->{email} ),
        'path=s'        => \( $options->{path} ),
        'current'       => \( $options->{current} ),
        help            => \&__pod2usage,
        version         => \&__version
    );

    # Set members
    $self->{options} = $options;

    # Set module name
    &__pod2usage unless @ARGV;
    $self->{module_name} = pop @ARGV;
    $self->{module_name} =~ s/\.pm$//g;

    # Set description
    $self->{description} = $self->{options}->{description}
      if $self->{options}->{description};

    # Set user status
    $self->{author} =
        $self->{options}->{author} ? $self->{options}->{author}
      : $self->{author}            ? $self->{author}
      :                              undef;
    $self->{email} =
        $self->{options}->{email} ? $self->{options}->{email}
      : $self->{email}            ? $self->{email}
      :                             undef;

    # If not exist path, set current directory. It is deprecated.
    $self->{module_path} = getcwd if !$self->{module_path};
    $self->{module_path} = $self->{options}->{path} if $self->{options}->{path};

    return $self;
}

sub _create_dir {
    my $self = shift;

    return if !$self->{module_path};

    my $module_name = $self->{module_name};
    $module_name =~ s/::/\//g;

    my ( $path, $file_path );
    $path = $file_path = sprintf "%s/%s", $self->{module_path}, $module_name;

    $path =~ s/\/\///g;                               # remove duplicates
    $path =~ s/\/\w+$//g;                             # remove module name
    $_    =~ s/[\r\n]//g for ( $path, $file_path );

    eval { mkpath($path); };
    if ($@) {
        Carp::croak "failed create directory : $@\n";
    }

    return "$file_path.pm";
}

sub _gen_pod {
    my $self = shift;

    my $name        = $self->_gen_name;
    my $author      = $self->_gen_author;
    my $description = $self->_gen_description;

    my $pod = <<"GEN_POD";
__END__

head1 NAME
$name
head1 DESCRIPTION
$description
head1 AUTHOR
$author
head1 SEE ALSO

head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
GEN_POD

    $pod =~ s/head1/=head1/g;
    return $pod;
}

sub _gen_name {
    my $self = shift;

    my $namespace   = $self->{module_name};
    my $description = $self->{description};

    <<"GEN_NAME";

$namespace - $description
GEN_NAME
}

sub _gen_description {
    my $self = shift;

    my $description = $self->{description} || return "";

    <<"GEN_DESCRIPTION";

$description
GEN_DESCRIPTION
}

sub _gen_default {
    my $self = shift;

    my $namespace = $self->{module_name};

    <<"GEN_DEFAULT";
package $namespace;

use strict;
use warnings;

GEN_DEFAULT
}

sub _gen_signature {
    my $self = shift;

    my $author =
        $self->{options}->{author} ? $self->{options}->{author}
      : $self->{author}            ? $self->{author}
      :                              undef;

    return unless defined($author);

    my $time = localtime;
    my $ymd  = $time->ymd;

    <<"GEN_SIGNATURE";
# $ymd $author

GEN_SIGNATURE
}

sub _gen_author {
    my $self = shift;

    return unless $self->{author};

    my $author = $self->{author} || "";
    my $email  = $self->{email}  || "";

    $email =~ s/(?:^((\w|\W)+))/E<lt>$1E<gt>/ if $email;

    <<"GEN_AUTHER";

$author $email
GEN_AUTHER
}

sub _gen_moose {
    my $self = shift;

    <<'GEN_MOOSE';
use Moose;
GEN_MOOSE
}

sub _gen_mouse {
    my $self = shift;
    <<'GEN_MOUSE';
use Mouse;
GEN_MOUSE
}

sub _gen_moo {
    my $self = shift;
    <<'GEN_MOO';
use Moo;
GEN_MOO
}

# TODO Not correctly implemented
sub _gen_mo {
    my $self = shift;
    <<'GEN_MO';
use Mo;
GEN_MO
}

# Perfect!
sub _gen_m {
    my $self = shift;
    <<'GEN_M';
use M;
GEN_M
}

sub _gen_autoclearn {
    my $self = shift;

    <<'GEN_AUTOCLEARN';
use namespace::autoclearn;
GEN_AUTOCLEARN
}

sub _gen_immutable {
    my $self = shift;

    <<'GEN_IMMUTABLE';

__PACKAGE__->meta->make_immutable;
GEN_IMMUTABLE
}

sub _gen_packend {
    my $self = shift;

    <<'GEN_PACKEND';

1;
GEN_PACKEND
}

sub __pod2usage {
    pod2usage(2);
}

sub __version {
    print "mgen ver $VERSION\n";
    exit;
}

1;

__END__

=head1 NAME

App::mgen - Generate the single module file

=head1 SYNOPSIS

mgen [options] [module_name]

    Options :
        --description=s Set description
        --author=s      Set author name
        --email=s       Set email
        --path=s        Set module root path
        --signature     Set signature. necessary set author and email
        --immutable     Use __PACKAGE__->meta->make_immutable
        --autoclearn    Use namespace::autoclearn
        --help          Output help
        --version       Output version
        --current       Create a module in current directory
        --moose         Use Moose
        --mouse         Use Mouse
        --moo           Use Moo
        --mo            Use Mo
        --m             Use M

        --dry-run
        --silent
    
    ENVs :
        MGEN_ROOT     Set default module root path
        MGEN_AUTHOR   Set default author name
        MGEN_EMAIL    Set default email

    e.g. :
        Generate standerd module
        $ mgen MyApp::Module

        Use Moose
        $ mgen --moose MyApp::Module

        Set description
        $ mgen --description="a module" MyApp::Module

        Set userdata (ENVs)
        $ export MGEN_ROOT=`pwd`
        $ export MGEN_AUTHOR="username"
        $ export MGEN_EMAIL="example@example.com"
        $ mgen MyApp::Module

        Set userdata (Options)
        $ mgen --path=`pwd` --author="username" --email="example@example.com" MyApp::Module
    
   mgen is supported various OO :
        Moose, Mouse, Moo, Mo, M
        Above all, I recommend M 

=head1 DESCRIPTION

App::mgen is generate the single module file.

=head1 AUTHOR

lapis_tw E<lt>lapis0896@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
