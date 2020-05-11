use strict;
use ModPerl::MM ();

ModPerl::MM::WriteMakefile
  (
   'NAME'         => 'Apache2::ModProxyPerlHtml',
   'VERSION_FROM' => 'ModProxyPerlHtml.pm',
   'LICENSE'      => 'Artistic',
   'PREREQ_PM'    => { 'Apache2::Connection' => 0, },
   'CONFIGURE_REQUIRES' => { 'ModPerl::MM' => 0, },
   'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
   'AUTHOR'       => 'Gilles Darold (gilles at darold dot net)',
   'ABSTRACT'     => 'Apache2/mod_perl2 module replacement for mod_proxy_html.c ',
   'META_MERGE'   => {
	'meta-spec' => { version => 2 },
	resources  => {
		homepage => 'http://modproxyhtml.darold.net/',
		repository  => {
			type => 'git',
			git => 'https://github.com/darold/modproxyperlhtml.git',
			web => 'https://github.com/darold/modproxyperlhtml',
		},
	},
    }
  );


