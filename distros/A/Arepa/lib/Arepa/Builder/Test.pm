package Arepa::Builder::Test;

use strict;
use warnings;

use Carp;
use Cwd;
use File::Basename;

use Arepa;

use base qw(Arepa::Builder);

our $last_build_log = undef;
sub last_build_log {
    return $last_build_log;
}

sub do_init {
    my ($self, $builder) = @_;
    return 1;
}

sub do_compile_package_from_dsc {
    my ($self, $dsc_file, %user_opts) = @_;
    my %opts = (output_dir => '.', %user_opts);

    my $basename = basename($dsc_file);
    $basename =~ s/\.dsc$//go;
    my $extra_version = $opts{bin_nmu} ? "+b1" : "";
    my $package_file_name = "$basename$extra_version\_all.deb";
    open F, ">$opts{output_dir}/$package_file_name";
    print F "Fake contents of the package\n";
    close F;
    $last_build_log = "Building $package_file_name. Not.\n";
    return 1;
}

sub do_compile_package_from_repository {
    my ($self, $package, $version, %user_opts) = @_;
    my %opts = (output_dir => '.', %user_opts);

    my $extra_version = $opts{bin_nmu} ? "+b1" : "";
    my $package_file_name = "$package\_$version$extra_version\_all.deb";
    open F, ">$opts{output_dir}/$package_file_name";
    print F "Fake contents of the package\n";
    close F;
    $last_build_log = "Building $package_file_name. Not.\n";
    return 1;
}

sub do_create {
    my ($self, $builder_dir, $mirror, $distribution) = @_;
    return 1;
}

1;

__END__

=head1 AUTHOR

Esteban Manchado Velázquez <estebanm@opera.com>.

=head1 LICENSE AND COPYRIGHT

This code is offered under the Open Source BSD license.

Copyright (c) 2010, Opera Software. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item

Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

=item

Neither the name of Opera Software nor the names of its contributors may
be used to endorse or promote products derived from this software without
specific prior written permission.

=back

=head1 DISCLAIMER OF WARRANTY

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
