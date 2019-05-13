package Alien::LibBigWig;
$Alien::LibBigWig::VERSION = '0.4.3';

use strict;
use warnings;

use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME
    Alien::LibBigWig - Fetch/build/stash libBigWig headers and libs from https://github.com/dpryan79/libBigWig

=head1 SYNOPSIS

  Example of finding the headers and library that Alien::HTSlib installed.

       $ENV{LIBBIGWIG_DIR} || (
          can_load(
              modules => { 'Alien::LibBigWig' => undef, 'File::ShareDir' => undef }
          ) &&
          File::ShareDir::dist_dir('Alien-LibBigWig') );


=head1 DESCRIPTION

  Download, build, and install the libBigWig C headers and libraries into a
  well-known location, "File::ShareDir::dist_dir('Alien-LibBigWig')", from
  whence other packages can make use of them.

  The version installed will be version 0.4.3.

=head1 COPYRIGHT AND LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut
