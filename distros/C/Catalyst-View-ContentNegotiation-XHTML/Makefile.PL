use inc::Module::Install 0.91;
use strict;
use warnings;

BEGIN {
    if ($Module::Install::AUTHOR) {
        require Module::Install::AuthorRequires;
        require Module::Install::AuthorTests;
    }
}

name 'Catalyst-View-ContentNegotiation-XHTML';
all_from 'lib/Catalyst/View/ContentNegotiation/XHTML.pm';

requires 'Catalyst::Runtime';
requires 'Catalyst::View::TT';
requires 'HTTP::Negotiate';
requires 'MRO::Compat';
requires 'MooseX::Types::Structured';
requires 'MooseX::Types::Moose';

test_requires 'Catalyst::Action::RenderView';
test_requires 'Test::WWW::Mechanize::Catalyst';
test_requires 'Test::More';

if ($Module::Install::AUTHOR) {
  author_requires 'Test::Pod' => 1.14;
  author_requires 'Test::Pod::Coverage' => 1.04;
  author_requires 'Test::Spelling' => 0.11;
  if ($^O eq 'darwin') {
      my $osx_ver = `/usr/bin/sw_vers -productVersion`;
      chomp $osx_ver;

      # TAR on 10.4 wants COPY_EXTENDED_ATTRIBUTES_DISABLE
      # On 10.5 (Leopard) it wants COPYFILE_DISABLE
      my $attr = $osx_ver eq '10.5' ? 'COPYFILE_DISABLE' : 'COPY_EXTENDED_ATTRIBUTES_DISABLE';

      makemaker_args(dist => { PREOP => qq{\@if [ "\$\$$attr" != "true" ]; then}.
                                        qq{ echo "You must set the ENV variable $attr to true,"; }.
                                        ' echo "to avoid getting resource forks in your dist."; exit 255; fi' });
  }
  author_tests 't/author';
}
auto_install;
resources repository => 'git://git.shadowcat.co.uk/catagits/Catalyst-View-ContentNegotiation-XHTML.git';

WriteAll();

