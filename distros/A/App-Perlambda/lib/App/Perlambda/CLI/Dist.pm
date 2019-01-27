package App::Perlambda::CLI::Dist;

use strict;
use warnings;
use utf8;
use File::Path qw/rmtree/;
use File::Spec;

use App::Perlambda::Util qw(parse_options get_current_perl_version);

sub run {
    my ($self, @args) = @_;

    my $clean;
    my $perl_version;
    parse_options(
        \@args,
        'c|clean'     => \$clean,
        'container=s' => \$perl_version,
    );

    if (scalar(@args) < 2) {
        die "invalid argument has come. please see the doc: `perlambda help dist`\n";
    }
    my $root_dir = File::Spec->rel2abs($args[0]);
    my $dist_zip = $args[1];

    my $CONTAINER_BASE_DIR = '/tmp/func';
    my $CONTAINER_NAME = 'moznion/lambda-perl-layer-foundation';
    unless ($perl_version) {
        $perl_version = get_current_perl_version();
        print "[INFO] use default `conttainer_tag`\n";
    }
    print "[INFO] use `conttainer_tag`: $perl_version\n";

    my $container = "${CONTAINER_NAME}:${perl_version}";

    my $cpanfile = "$root_dir/cpanfile"; # TODO support to specify `cpanfile`

    my $carton_install_cmd = ':';
    if (-f $cpanfile) {
        $carton_install_cmd = '/opt/bin/carton install';
    }

    if ($clean) {
        my $vendor_dir = "${root_dir}/local/";
        my $dist_file = "${root_dir}/${dist_zip}";
        print "[INFO] clean mode is enable. it removes following: '$dist_file', '$vendor_dir'";

        unlink $dist_file if -f $dist_file;
        rmtree $vendor_dir if -d $vendor_dir;
    }

    my $shell_cmd = <<"EOS";
cd ${CONTAINER_BASE_DIR} || exit 1 \\
  && ${carton_install_cmd} \\
  && zip -r ${CONTAINER_BASE_DIR}/${dist_zip} .
EOS

    system(<<"EOS") == 0 or die "failed docker execution: $!\n";
docker run --rm \\
  -v ${root_dir}:${CONTAINER_BASE_DIR} \\
  $container \\
  sh -c '$shell_cmd'
EOS
}

1;

__END__

=encoding utf8

=head1 NAME

App::Perlambda::CLI::Dist - Make a zip archive for Lambda function

=head1 SYNOPSIS

    $ perlambda dist [-c|--clean] [--container=<container-tag-version>] <source path> <dist zip file name>

=head1 DESCRIPTION

This command makes a zip archive for Lambda function.

This command uses Docker to make a zip archive. Please see also: L<https://hub.docker.com/r/moznion/lambda-perl-layer-foundation/>.

=head1 COMMANDLINE OPTIONS

=head2 C<-c|--clean> (B<Optional>)

B<Default>: C<false>

If this parameter is active, this command removes a pre-built zip archive and a vendor directory (i.e. C<local/>) before making a zip archive.

=head2 C<--container> (B<Optional>)

B<Default>: version of running perl

The version of perl runtime. This value will be used on specifying the container version for making a zip. You have to specify this parameter as C<5_xx> (e.g. C<5_26> and C<5.28>).

=head1 REQUIREMENTS

=over 4

=item * Perl 5.26 or later

=item * Docker

=back

=head1 LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

moznion E<lt>moznion@gmail.comE<gt>

=cut

