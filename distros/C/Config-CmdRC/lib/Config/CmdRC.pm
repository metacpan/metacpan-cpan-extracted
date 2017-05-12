package Config::CmdRC;
use strict;
use warnings;
use File::Spec;
use Config::Simple;
use Hash::Merge qw/merge/;

our $VERSION = '0.07';

our $RC;

our $RC_DIRS = ($^O =~ m!Win32!) ? [
    # TODO: better windows support
    '.',
    $ENV{CMDRC_DIR},
    $ENV{HOME},
] : [
    # TODO: Are these common configuration directories?
    '.',
    $ENV{CMDRC_DIR},
    $ENV{HOME},
    '/etc',
];

sub import {
    my $class = shift;

    my $caller_class = caller;

    $class->read(@_);

    {
        no strict 'refs'; ## no critic
        *{"${caller_class}::RC"} = \&RC;
    }
}

sub read {
    my $self = shift;

    my ($file, $dir, $loader) = _get_args(@_);

    if ( my $user_rc_file = _get_user_rcfile() ) {
        $file = $user_rc_file;
    }

    my %hash;
    for my $d ( @{_array($dir)}, @{$RC_DIRS} ) {
        next unless $d;
        for my $f ( @{_array($file)} ) {
            my $path = File::Spec->catfile($d, $f);
            if (-e $path) {
                my $config = $loader->($path);
                %hash = %{ merge(\%hash, $config) };
            }
        }
    }

    return $RC = \%hash;
}

sub _get_user_rcfile {
    return unless @ARGV;

    my $f = 0;
    my @rcfiles;
    for my $opt (@ARGV) {
        if ($f && $opt) {
            push @rcfiles, $opt;
            $f = 0;
        }
        elsif ($opt && $opt eq '--rc') {
            $f = 1;
        }
    }

    return \@rcfiles if @rcfiles;
}

sub _get_args {
    my ($file, $dir, $loader);
    if (@_ == 1) {
        $file = shift;
    }
    else {
        my %arg = @_;
        $file = $arg{file} || []; # TODO: Is default file name needed?
        $dir  = $arg{dir}  || [];
        $loader = $arg{loader};
    }

    $loader = $loader ? $loader : sub {
        my $path = shift;
        my $config = Config::Simple->new($path);
        return $config->vars;
    };

    return($file, $dir, $loader);
}

sub _array {
    my $v = shift;
    return (ref $v eq 'ARRAY') ? $v : [$v];
}

sub RC { $RC }

1;

__END__

=head1 NAME

Config::CmdRC - read rcfile for CLI tools


=head1 SYNOPSIS

easy way

    use Config::CmdRC qw/.foorc/;

    # Function `RC` has been exported.
    warn RC->{bar};

specific options

    use Config::CmdRC (
        dir  => ['/path/to/rcdir', '/path/to/other/rcdir'],
        file => ['.foorc', '.barrc'],
    );


=head1 DESCRIPTION

C<Config::CmdRC> is the module for automatically reading rcfile in a CLI tool.
If you just only use C<Config::CmdRC> with C<rcfile name>, you can get configure parameters as C<RC> function.

By default, C<Config::CmdRC> searches a configuration file in below directories(for UNIX/Linux).

    .
    $ENV{CMDRC_DIR}
    $ENV{HOME}
    /etc

And then, your specified directories will be searched.

If many configuration files are found out, the anterior configuration file will never be lost.

Example:

    use Config::CmdRC (
        dir  => ['/path/to/1', '/path/to/2'],
        file => ['.rc1', '.rc2'],
    );

The parameters of configuration file in '/path/to/1' overwrite parameters of '/path/to/2'.
And the parameters of '.rc1' overwrite parameters of '.rc2'.

=head2 CUSTOM CONFIG LOADER

In Default, C<Config::CmdRC> uses L<Config::Simple> for reading configuration file.

Of course, you can use original configuration loader like below.

    use Config::Any;

    use Config::CmdRC (
        file   => 'share/custom.yml',
        loader => sub {
            my $path = shift;
            my $cfg = Config::Any->load_files({
                files => [$path],
                use_ext => 1,
            });
            return $cfg->[0]{$path};
        },
    );

=head1 EXPORTS

=head2 RC

All configuration values are got from C<RC> function. It's exported automatically.

=head2 read($rc_file_path)

To read configuration file


=head1 CAVEAT

Default search directories for rcfile may be changed in the future.


=head1 SEE ALSO

L<Config::Find>


=head1 REPOSITORY

Config::CmdRC is hosted on github
<http://github.com/bayashi/Config-CmdRC>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
