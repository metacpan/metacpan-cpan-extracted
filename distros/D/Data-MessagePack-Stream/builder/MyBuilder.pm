package builder::MyBuilder;
use strict;
use warnings;
use base 'Module::Build::XSUtil';

use File::Spec::Functions qw(catfile catdir);
use Config;

sub new {
    my ($class, %argv) = @_;
    $class->SUPER::new(
        %argv,
        include_dirs => [catdir('msgpack-1.4.2', 'include')],
        generate_ppport_h => catfile('lib', 'Data', 'MessagePack', 'ppport.h'),
        cc_warnings => 1,
    );
}

sub _set_mtime {
    my $self = shift;
    open my $fh, "<", "builder/mtime.txt" or die;
    while (my $line = <$fh>) {
        next if $line =~ /^#/ || $line !~ /\S/;
        chomp $line;
        my ($file, $mtime) = split /\t/, $line, 2;
        $file = catfile(split /\//, $file);
        die "miss $file" if !-e $file;
        utime $mtime, $mtime, $file or die "utime $mtime, $mtime, $file: $!";
    }
}

sub _build_msgpack {
    my $self = shift;

    # We should restore original mtime in msgpack-1.4.2.tar.gz; otherwise end-users might be asked for having automake tools.
    $self->_set_mtime;

    my @opt = ('--disable-shared');
    push @opt, '--with-pic' if Config->myconfig =~ /(amd64|x86_64)/i;

    chdir "msgpack-1.4.2";
    my $ok = $self->do_system("./configure", @opt);
    $ok &&= $self->do_system($Config{make});
    chdir "..";
    $ok;
}

sub ACTION_code {
    my ($self, @argv) = @_;

    my $spec = $self->_infer_xs_spec(catfile("lib", "Data", "MessagePack", "Stream.xs"));
    my $archive = catfile("msgpack-1.4.2", "src", ".libs", "libmsgpackc.a");
    if (!$self->up_to_date($archive, $spec->{lib_file})) {
        $self->_build_msgpack or die;
        push @{$self->{properties}{objects}}, $archive; # XXX
    }

    $self->SUPER::ACTION_code(@argv);
}

1;
