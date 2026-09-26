#
#  This file is part of ASPEER::MakeMaker::Markdown::Publish.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package ASPEER::MakeMaker::Markdown::Publish;


#  Compiler pragma and package variables
#
use strict qw(vars);
use vars qw($VERSION $VERSION_GIT_SHA $AUTHORITY @ISA);
use warnings;


#  Inherit the shared MakeMaker hook implementation. Actual site assembly and
#  publication remains in the backend-neutral publishing module.
#
use ASPEER::MakeMaker ();
use ASPEER::MakeMaker::Markdown::Pod ();
use ASPEER::MakeMaker::Markdown::Publish::MM ();
@ISA=qw(ASPEER::MakeMaker);


#  Version information
#
$AUTHORITY='cpan:ASPEER';
$VERSION='1.003';
$VERSION_GIT_SHA=do {local(@ARGV, $/, $_); @ARGV=($_=__FILE__.'.sha'); <> if -f $_};
chomp($VERSION_GIT_SHA) if defined($VERSION_GIT_SHA);


#  Done
#
1;


#======================================================================================================================

sub import {


    #  Install documentation maintenance before wrapping the same MakeMaker
    #  sections with publication targets.
    #
    my ($class, @section)=@_;
    ASPEER::MakeMaker::Markdown::Pod->import(@section);
    return ASPEER::MakeMaker::import($class, @section);

}

__END__

=begin markdown

# NAME

ASPEER::MakeMaker::Markdown::Publish - MakeMaker targets for Markdown publication

# SYNOPSIS

```perl
use ExtUtils::MakeMaker;
use ASPEER::MakeMaker::Markdown::Publish;

WriteMakefile(
    NAME         => 'Example',
    VERSION_FROM => 'lib/Example.pm',
    META_MERGE => {
        'meta-spec' => {version => 2},
        x_documentation => {
            publish => {
                module  => 'Markdown::Publish::MkDocs',
                sources => ['doc'],
                config  => 'doc/mkdocs/mkdocs.yml',
            },
        },
    },
);
```

# DESCRIPTION

This is a thin MakeMaker adapter. It reads `META_MERGE.x_documentation.publish`
from the live `WriteMakefile` arguments and passes the settings to
`Markdown::Publish` when a target is invoked. It does not assemble
documents, run a publishing engine, or update Git itself.

Importing this module also imports `ASPEER::MakeMaker::Markdown::Pod`, so the
generated Makefile includes its `doc` and `readme` maintenance targets alongside
the publication targets. The equivalent command-line activation is:

```text
perl -MASPEER::MakeMaker::Markdown::Publish Makefile.PL
```

The selected `module` is one of `Markdown::Publish::MkDocs`,
`::VitePress`, `::Docusaurus`, or `::Starlight`. One engine is active at a
time. Its `config` and other engine-specific options are top-level values
in the `publish` hash. Alternatively, set only `config_file` to a JSON file
containing the selected `module` and settings. That file is read when the
target runs, so edits do not require a regenerated Makefile.

Configuration supplied inline is encoded into the generated Makefile. The
targets do not re-run `Makefile.PL` to discover it.

# TARGETS

```text
doc
readme
publish_build
publish_serve
publish_gh
publish_gh-push
publish_cloudflare
```

`publish_build` prepares and renders the site. `publish_serve` starts the
selected engine's foreground local server. `publish_gh` builds, updates the
local publication branch, and does not contact a remote. `publish_gh-push`
performs the same operation, then pushes only that branch to `origin` without
forcing it. `publish_cloudflare`
builds and deploys the same site as Workers Static Assets using an authored
Wrangler configuration. Git branch publication and Cloudflare deployment are
independent; neither calls the other.

# CONFIGURATION

MkDocs is used when `module` is omitted. Set `module` in
`META_MERGE.x_documentation.publish` to select another engine, or set
`MARKDOWN_PUBLISH_MODULE` to override it at runtime.

Without `sources`, an existing `doc/` is the publication boundary. Only when
`doc/` is absent are module and executable sidecars the default. An explicit
`sources` list is exact. `output`, `name`, `base`, and `branch` are common settings;
see the selected engine module for its own options. For generated engine
configuration, `name` defaults to the `NAME` supplied to `WriteMakefile`. Set
it explicitly for a friendlier site title:

```perl
publish => {
    name => 'Example documentation',
},
```

An external `config_file` or an authored engine configuration remains
authoritative for its own site title.

For generated VitePress, Docusaurus, and Starlight configuration, `base` sets
the deployment path and must begin and end with `/`. When it is omitted,
`publish_gh` derives `/<repository>/` from the `origin` repository name, or
uses `/` for an `<owner>.github.io` repository. The inferred value applies
only to the GitHub Pages build. Set `base` explicitly when the published URL
uses a different path; authored engine configuration remains authoritative.

```perl
publish => {
    module => 'Markdown::Publish::VitePress',
    base   => '/example/',
},
```

Set `config_extend` to customise the selected engine's generated configuration
without replacing it. It is passed unchanged to `Markdown::Publish` and
cannot be combined with `config`. MkDocs accepts supplemental YAML; the Node
publishers accept the extension functions documented by their engine modules.

For Workers Static Assets, set `cloudflare => {config => 'wrangler.jsonc'}`
inside `publish`. This path selects a dedicated Worker configuration with its
name and compatibility date. Optionally set `wrangler` to the executable path
or `environment` to an authored Wrangler environment in the same `cloudflare`
hash. Wrangler uses its own login or environment for authentication; do not
put credentials in metadata. Deployment does not change Git.

# ERRORS

`x_documentation` and `x_documentation.publish` must be hash references when
supplied. Invalid configuration and failed target actions are fatal.

# SEE ALSO

`Markdown::Publish`, `ASPEER::MakeMaker::Markdown::Pod`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of ASPEER::MakeMaker::Markdown::Publish.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

ASPEER::MakeMaker::Markdown::Publish - MakeMaker targets for Markdown publication


=head1 SYNOPSIS


 use ExtUtils::MakeMaker;
 use ASPEER::MakeMaker::Markdown::Publish;

 WriteMakefile(
     NAME         => 'Example',
     VERSION_FROM => 'lib/Example.pm',
     META_MERGE => {
         'meta-spec' => {version => 2},
         x_documentation => {
             publish => {
                 module  => 'Markdown::Publish::MkDocs',
                 sources => ['doc'],
                 config  => 'doc/mkdocs/mkdocs.yml',
             },
         },
     },
 );

=head1 DESCRIPTION

This is a thin MakeMaker adapter. It reads C<META_MERGE.x_documentation.publish>
from the live C<WriteMakefile> arguments and passes the settings to
C<Markdown::Publish> when a target is invoked. It does not assemble
documents, run a publishing engine, or update Git itself.

Importing this module also imports C<ASPEER::MakeMaker::Markdown::Pod>, so the
generated Makefile includes its C<doc> and C<readme> maintenance targets alongside
the publication targets. The equivalent command-line activation is:


 perl -MASPEER::MakeMaker::Markdown::Publish Makefile.PL
The selected C<module> is one of C<Markdown::Publish::MkDocs>,
C<::VitePress>, C<::Docusaurus>, or C<::Starlight>. One engine is active at a
time. Its C<config> and other engine-specific options are top-level values
in the C<publish> hash. Alternatively, set only C<config_file> to a JSON file
containing the selected C<module> and settings. That file is read when the
target runs, so edits do not require a regenerated Makefile.

Configuration supplied inline is encoded into the generated Makefile. The
targets do not re-run C<Makefile.PL> to discover it.


=head1 TARGETS


 doc
 readme
 publish_build
 publish_serve
 publish_gh
 publish_gh-push
 publish_cloudflare
C<publish_build> prepares and renders the site. C<publish_serve> starts the
selected engine's foreground local server. C<publish_gh> builds, updates the
local publication branch, and does not contact a remote. C<publish_gh-push>
performs the same operation, then pushes only that branch to C<origin> without
forcing it. C<publish_cloudflare>
builds and deploys the same site as Workers Static Assets using an authored
Wrangler configuration. Git branch publication and Cloudflare deployment are
independent; neither calls the other.


=head1 CONFIGURATION

MkDocs is used when C<module> is omitted. Set C<module> in
C<META_MERGE.x_documentation.publish> to select another engine, or set
C<MARKDOWN_PUBLISH_MODULE> to override it at runtime.

Without C<sources>, an existing C<doc/> is the publication boundary. Only when
C<doc/> is absent are module and executable sidecars the default. An explicit
C<sources> list is exact. C<output>, C<name>, C<base>, and C<branch> are common settings;
see the selected engine module for its own options. For generated engine
configuration, C<name> defaults to the C<NAME> supplied to C<WriteMakefile>. Set
it explicitly for a friendlier site title:


 publish => {
     name => 'Example documentation',
 },
An external C<config_file> or an authored engine configuration remains
authoritative for its own site title.

For generated VitePress, Docusaurus, and Starlight configuration, C<base> sets
the deployment path and must begin and end with C</>. When it is omitted,
C<publish_gh> derives C<<< /<repository>/ >>> from the C<origin> repository name, or
uses C</> for an C<<< <owner>.github.io >>> repository. The inferred value applies
only to the GitHub Pages build. Set C<base> explicitly when the published URL
uses a different path; authored engine configuration remains authoritative.


 publish => {
     module => 'Markdown::Publish::VitePress',
     base   => '/example/',
 },
Set C<config_extend> to customise the selected engine's generated configuration
without replacing it. It is passed unchanged to C<Markdown::Publish> and
cannot be combined with C<config>. MkDocs accepts supplemental YAML; the Node
publishers accept the extension functions documented by their engine modules.

For Workers Static Assets, set C<<< cloudflare => {config => 'wrangler.jsonc'} >>>
inside C<publish>. This path selects a dedicated Worker configuration with its
name and compatibility date. Optionally set C<wrangler> to the executable path
or C<environment> to an authored Wrangler environment in the same C<cloudflare>
hash. Wrangler uses its own login or environment for authentication; do not
put credentials in metadata. Deployment does not change Git.


=head1 ERRORS

C<x_documentation> and C<x_documentation.publish> must be hash references when
supplied. Invalid configuration and failed target actions are fatal.


=head1 SEE ALSO

C<Markdown::Publish>, C<ASPEER::MakeMaker::Markdown::Pod>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This file is part of ASPEER::MakeMaker::Markdown::Publish. Copyright (c) 2026
Andrew Speer. This is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.

=cut
