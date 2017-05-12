package App::Seacan;

# Semantic Vesioning: http://semver.org/
# Not sure if I want to use v-string, but I do want to follow
# semvar as a convention.
our $VERSION = "0.1.0";

use Mo qw<required coerce>;
use File::Path qw<make_path>;
use TOML qw<from_toml>;

sub join_path { join "/", @_ };

has config => (
    required => 1,
    coerce => sub {
        my $c = $_[0];
        if (!ref($c) && -f $c) {
            open(my $fh, "<:utf8", $c) or die $!;
            local $/ = undef;
            $c = from_toml( scalar <$fh> );
        }
        $c->{perl}{installed_as} //= "seacan";

        return $c;
    }
);

sub seacan_perlbrew_root {
    my $self = shift;
    return join_path($self->config->{seacan}{output}, "perlbrew");
}

sub seacan_perl {
    my $self = shift;
    return join_path( $self->seacan_perlbrew_root, "perls", $self->config->{perl}{installed_as}, "bin", "perl" );
}

sub perl_is_installed {
    my $self = shift;
    my $perlbrew_root_path = join_path($self->config->{seacan}{output}, "perlbrew");
    return 0 unless -d $perlbrew_root_path;
    my $perl_executable = join_path($perlbrew_root_path, "perls", $self->config->{perl}{installed_as}, "bin", "perl");
    if (my $r = -f $perl_executable) {
        say STDERR "perl is installed: $perl_executable";
        return 1;
    }
    return 0;
}

sub install_perl {
    my $self = shift;

    my $perlbrew_root_path = $self->seacan_perlbrew_root;
    make_path( $perlbrew_root_path ) unless -d $perlbrew_root_path;

    for (keys %ENV) {
        delete $ENV{$_} if /\APERLBREW_/;
    }
    delete $ENV{PERL_CPANM_OPT};
    delete $ENV{PERL_LOCAL_LIB_ROOT};
    delete $ENV{PERL_MB_OPT};
    delete $ENV{PERL_MM_OPT};
    delete $ENV{PERL5LIB};

    $ENV{PERLBREW_ROOT} = $perlbrew_root_path;

    system("curl -L https://install.perlbrew.pl | bash") == 0 or die $!;
    my $perlbrew_command = join_path($perlbrew_root_path, "bin", "perlbrew");
    system($perlbrew_command, "install", $self->config->{perl}{version}, "--as", $self->config->{perl}{installed_as}) == 0 or die $!;
    system($perlbrew_command, "install-cpanm", "--force");
}

sub install_cpan {
    my $self = shift;
    my $cpanm_command = join_path( $self->seacan_perlbrew_root, "bin", "cpanm");
    my $perl_command = $self->seacan_perl;

    $, = " ";
    system($perl_command, $cpanm_command, "--notest", "-L", join_path($self->config->{seacan}{output}, "local"), "--installdeps", $self->config->{seacan}{app} ) == 0 or die $!;
}

sub copy_app {
    my $self = shift;
    my $target_directory = join_path($self->config->{seacan}{output}, "app");
    my $source_directory = $self->config->{seacan}{app};

    make_path($target_directory);
    $source_directory =~ s{/+$}{};

    system("rsync", "-8vPa", $source_directory, $target_directory) == 0 or die;
}

sub create_launcher {
    # Instead of giving a very long command to the user
    # a launcher script is generated.
    # app_name and main_script could be added to the configuration
    # so we can add the info directly instead of "guessing" it
    # through a regex.

    my $self = shift;
    my $output = $self->config->{seacan}{output};

    # The launcher script goes into bin of the target directory
    my $target_directory = join_path($output, 'bin');

    my $app_name = $self->config->{seacan}{app_name};
    if ( !$app_name ) {
        # This is a hack to determine the application name from the
        # output value of the config in case it wasn't provided

        $app_name = $output;
        $app_name =~ s/^.+\/(.+?)$/$1/;
    }

    # Apps following the CPAN guidelines have a lib directory with the
    # modules. Adding this to the PERL5LIB allows to run this distributions
    # without installing them.
    my $app_lib =  join_path($output, 'app', $app_name, 'lib');
    my $launcher = join_path($target_directory, $app_name);
    make_path($target_directory);
    open(my $fh, ">:utf8", $launcher) or die $!;
    print $fh "#!/bin/bash\n";
    print $fh "PERL5LIB=$output/local/lib/perl5:$app_lib\n";
    print $fh "export PERL5LIB\n";
    # String "app" shouldn't be hardcoded and be part of the config
    # app.pl will not be the likely name of the main script.
    print $fh "$output/perlbrew/perls/seacan/bin/perl $output/app/$app_name/bin/$app_name \$@\n";
    close $fh or die($!);
    chmod(0755, $launcher) or die($!);
}

sub run {
    my $self = shift;
    $self->install_perl unless $self->perl_is_installed;
    $self->install_cpan;
    $self->copy_app;
    $self->create_launcher;
}

1;

=encoding utf-8

=head1 NAME

Seacan - A tool to prepare a self-contained app directory.

=head1 DESCRIPTION

Read the README file for now. L<https://github.com/gugod/Seacan/blob/master/README.md>

=head1 COPYRIGHT

Copyright (c) 2016 Kang-min Liu C<< <gugod@gugod.org> >>.

=head1 LICENCE

The MIT License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
