use strict;
use warnings;
package BioX::Workflow::Command::run::Rules::Directives::Interpolate::Jinja;

use Moose::Role;
use namespace::autoclean;

use IPC::Cmd qw[can_run run];
use Try::Tiny;
use Safe;
use Storable qw(dclone);
use File::Spec;
use Memoize;
use File::Basename;
use File::Temp qw/tempfile/;
use File::Slurp;

my $TEMPLATE_ERROR = 0;

has 'sample_var' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => '{{ sample }}',
);

has 'delimiter' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => '{'
);

sub interpol_directive {
    my $self = shift;
    my $source = shift;
    my $text = '';

    $TEMPLATE_ERROR = 0;
    if (exists $self->interpol_directive_cache->{$source} && $source !~ m/{/) {
        return $self->interpol_directive_cache->{$source};
    }

    ## If the source string does not have a '{', its just text
    if ($source !~ m/{/) {
        $self->interpol_directive_cache->{$source} = $source;
        return $source;
    }

    my ($tfh, $tfilename) = tempfile();
    my ($jfh, $jfilename) = tempfile();

    my $json = $self->serialize_to_json($jfilename);
    write_file($tfilename, $source);
    #
    my $cmd = 'biosails-biox-render.py -j ' . $jfilename . ' -t ' . $tfilename;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) =
        run(command => $cmd, verbose => 0);
    ##TODO Add condition statements for success/not success
    map {chomp $_;
        $_} @{$stdout_buf};

    my $data = join('', @{$stdout_buf});

    ##If its the same and it has a $sign, its probably a perl expression
    if ($data eq $source && $data =~ m/\$/){
       return $self->interpol_text_template($source);
    }
    return join('', @{$stdout_buf});
}

1;
