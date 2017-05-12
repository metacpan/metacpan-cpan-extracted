use strict;
use warnings;
use Module::Build;
use Devel::CheckLib;

check_lib_or_exit(
    lib => 'gssapi_krb5',
    header =>
      [ qw<gssapi.h gssapi/gssapi.h gssapi/gssapi_generic.h
           gssapi/gssapi_krb5.h gssapi/gssapi_ext.h>
       ],
);

my $builder = Module::Build->new
  (
   dist_name           => 'Catalyst-Authentication-Credential-GSSAPI',
   license             => 'apache',
   dist_author         => 'Daniel Ruoso <druoso@bloomberg.net>',
   dist_version_from   => 'lib/Catalyst/Authentication/Credential/GSSAPI.pm',
   dynamic_config      => 1,
   configure_requires  =>
   { 'Module::Build' => '0.39',
     'Devel::CheckLib' => 0 },
   requires            =>
   { perl              => '5.10.0' },
   extra_linker_flags  => '-lgssapi_krb5',
   needs_compiler      => 1,
   xs_files            =>
   { 'lib/Catalyst/Authentication/Credential/GSSAPI.xs' =>
     'lib/Catalyst/Authentication/Credential/GSSAPI.xs',
   },
   meta_merge =>
   { resources =>
     { 'repository' =>
       'https://github.com/bloomberg/Catalyst-Authentication-Credential-GSSAPI',
     },
   },
  );
$builder->create_build_script();


__END__


Copyright 2015 Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

