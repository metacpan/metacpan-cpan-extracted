<a id="table-of-contents" class="anchor" aria-label="Permalink: Table of Contents" href="#table-of-contents"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">Table of Contents</h1>
<ul>
<li><a href="#name">NAME</a></li>
<li><a href="#synopsis">SYNOPSIS</a></li>
<li><a href="#description">DESCRIPTION</a></li>
<li><a href="#version">VERSION</a></li>
<li><a href="#features">FEATURES</a></li>
<li>
<a href="#modulinos">MODULINOS</a>
<ul>
<li><a href="#why-modulinos">Why Modulinos?</a></li>
<li><a href="#the-bash-wrapper">The Bash Wrapper</a></li>
<li><a href="#create-modulino">create-modulino</a></li>
<li><a href="#modulino%5Cwrapper">MODULINO_WRAPPER</a></li>
</ul>
</li>
<li>
<a href="#quick-start">QUICK START</a>
<ul>
<li><a href="#single-module-application">Single-Module Application</a></li>
<li><a href="#role-based-application">Role-Based Application</a></li>
</ul>
</li>
<li>
<a href="#role-based-architecture">ROLE-BASED ARCHITECTURE</a>
<ul>
<li><a href="#the-yaml-manifest">The YAML Manifest</a></li>
<li><a href="#command-values">Command Values</a></li>
<li><a href="#roles-with-no-commands">Roles With No Commands</a></li>
<li><a href="#activating-role-based-architecture">Activating Role-Based Architecture</a></li>
<li><a href="#the-inherited-main">The Inherited main()</a></li>
<li><a href="#distributing-the-manifest">Distributing the Manifest</a></li>
<li><a href="#not-a-framework">Not a Framework</a></li>
<li><a href="#validation-defaults-and-configuration">Validation, Defaults, and Configuration</a></li>
<li><a href="#when-to-use">When to Use</a></li>
<li><a href="#the-init-run-lifecycle">The init-run Lifecycle</a></li>
<li><a href="#%22opt-in%22-default-command">"opt-in" Default Command</a></li>
<li><a href="#$autohelp-and-$autodefault"><code>$AUTO_HELP</code> and <code>$AUTO_DEFAULT</code></a></li>
</ul>
</li>
<li><a href="#constants">CONSTANTS</a></li>
<li><a href="#additional-notes">ADDITIONAL NOTES</a></li>
<li>
<a href="#customizing-help-output">CUSTOMIZING HELP OUTPUT</a>
<ul>
<li><a href="#helpsections"><code>help_sections</code></a></li>
</ul>
</li>
<li>
<a href="#internal-commands">INTERNAL COMMANDS</a>
<ul>
<li><a href="#-generate-completion">-generate-completion</a></li>
<li><a href="#-dump-spec">-dump-spec</a></li>
<li><a href="#-scaffold">-scaffold</a></li>
<li><a href="#-migrate">-migrate</a></li>
</ul>
</li>
<li>
<a href="#methods-and-subroutines">METHODS AND SUBROUTINES</a>
<ul>
<li><a href="#new">new</a></li>
<li><a href="#command">command</a></li>
<li><a href="#command%5Cargs">command_args</a></li>
<li><a href="#commands-required">commands (required)</a></li>
<li><a href="#main">main</a></li>
<li><a href="#run">run</a></li>
<li>
<a href="#get%5Cargs">get_args</a>
<ul>
<li><a href="#with-names">With names</a></li>
<li><a href="#with-no-names">With no names</a></li>
</ul>
</li>
<li><a href="#init">init</a></li>
</ul>
</li>
<li><a href="#using-package-variables">USING PACKAGE VARIABLES</a></li>
<li>
<a href="#command-line-options">COMMAND LINE OPTIONS</a>
<ul>
<li><a href="#set%5Cargs">set_args</a></li>
</ul>
</li>
<li><a href="#command-arguments">COMMAND ARGUMENTS</a></li>
<li><a href="#custom-error-handler">CUSTOM ERROR HANDLER</a></li>
<li><a href="#setting-default-values-for-options">SETTING DEFAULT VALUES FOR OPTIONS</a></li>
<li>
<a href="#adding-usage-to-your-scripts">ADDING USAGE TO YOUR SCRIPTS</a>
<ul>
<li><a href="#custom-help-method">Custom help() Method</a></li>
</ul>
</li>
<li><a href="#adding-additional-setters">ADDING ADDITIONAL SETTERS</a></li>
<li>
<a href="#logging">LOGGING</a>
<ul>
<li><a href="#colored-output">Colored Output</a></li>
<li><a href="#per-command-log-levels">Per Command Log Levels</a></li>
</ul>
</li>
<li><a href="#faq">FAQ</a></li>
<li>
<a href="#aliasing-options-and-commands">ALIASING OPTIONS AND COMMANDS</a>
<ul>
<li><a href="#how-option-aliases-work">How option aliases work</a></li>
<li><a href="#how-command-aliases-work">How command aliases work</a></li>
<li><a href="#usage-examples">Usage examples</a></li>
<li><a href="#recommendations">Recommendations</a></li>
</ul>
</li>
<li>
<a href="#errorsexit-codes">ERRORS/EXIT CODES</a>
<ul>
<li><a href="#exit-codes">Exit Codes</a></li>
</ul>
</li>
<li><a href="#license-and-copyright">LICENSE AND COPYRIGHT</a></li>
<li><a href="#see-also">SEE ALSO</a></li>
<li><a href="#author">AUTHOR</a></li>
</ul>
<a id="name" class="anchor" aria-label="Permalink: NAME" href="#name"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">NAME</h1>
<p>CLI::Simple - a minimalist object oriented base class for CLI applications</p>
<a id="synopsis" class="anchor" aria-label="Permalink: SYNOPSIS" href="#synopsis"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">SYNOPSIS</h1>
<pre><code>#!/usr/bin/env perl

package MyScript;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans :chars);
use CLI::Simple qw($AUTO_HELP $AUTO_DEFAULT);

use parent qw(CLI::Simple);

caller or exit __PACKAGE__-&gt;main();

sub execute {
  my ($self) = @_;

  # retrieve a CLI option   
  my $file = $self-&gt;get_file;
  ...
}

sub list { 
  my ($self) = @_

  # retrieve a command argument
  my ($file) = $self-&gt;get_args();
  ...
}

sub main {

  # Disable auto-default for single commands, enable auto-help
  $AUTO_DEFAULT = 0;
  $AUTO_HELP = 1;

  my $cli = MyScript-&gt;new(
   option_specs    =&gt; [ qw( help format=s file=s) ],
   default_options =&gt; { format =&gt; 'json' }, # set some defaults
   extra_options   =&gt; [ qw( content ) ], # non-option, setter/getter
   commands        =&gt; { execute =&gt; \&amp;execute, list =&gt; \&amp;list,  }
   alias           =&gt; { options =&gt; { fmt =&gt; 'format' }, commands =&gt; { ls =&gt; 'list' } },
  );

  return $cli-&gt;run();
}

1;
</code></pre>
<p># role-based CLI Application (2.0.0)</p>
<p># create a YAML manifest <code>my-script.yml</code> in your project root:</p>
<pre><code>---
commands:
  frobnicate: My::Script::Role::Frobnicate
  list:       My::Script::Role::List
options:
  - help|h
  - verbose|v
  - output|o=s
</code></pre>
<p># create a main module</p>
<pre><code>package My::Script;

use CLI::Simple qw(:roles);
use parent qw(CLI::Simple);

our $VERSION = '1.0.0';

caller or exit __PACKAGE__-&gt;main;

1;
</code></pre>
<p># create implementation roles</p>
<pre><code>package My::Script::Role::Frobnicate;

use Role::Tiny;
use CLI::Simple::Constants qw(:booleans);

sub cmd_frobnicate {
  my ($self) = @_;
  ...
  return $SUCCESS;
}

1;
</code></pre>
<a id="description" class="anchor" aria-label="Permalink: DESCRIPTION" href="#description"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">DESCRIPTION</h1>
<p><a href="https://github.com/rlauer6/CLI-Simple/actions/workflows/build.yml"><img src="https://github.com/rlauer6/CLI-Simple/actions/workflows/build.yml/badge.svg" alt="CLI-Simple" style="max-width: 100%;"></a></p>
<p>Tired of writing the same 'ol boilerplate code for command line
scripts? Want a standard, simple way to create a Perl script that
takes options and commands?  <code>CLI::Simple</code> makes it easy to create
scripts that take <em>options</em>, <em>commands</em> and <em>arguments</em>.</p>
<p><code>CLI::Simple</code> is designed around the <em>modulino</em> pattern - Perl
modules that can be executed directly as scripts. See <a href="#modulinos">"MODULINOS"</a>.</p>
<p>For common constant values (like <code>$TRUE</code>, <code>$DASH</code>, or <code>$SUCCESS</code>), see
<a href="https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AConstants" rel="nofollow">CLI::Simple::Constants</a>, which pairs naturally with this module.</p>
<p>Version 2.0.0 introduces optional role-based architecture for applications
that have outgrown a single module. Declare your commands and options in a
YAML manifest, implement each command in a dedicated <a href="https://metacpan.org/pod/Role%3A%3ATiny" rel="nofollow">Role::Tiny</a> role, and
<code>CLI::Simple</code> handles composition, dispatch, and lifecycle automatically.
Your main module shrinks to a single line:</p>
<pre><code>caller or exit __PACKAGE__-&gt;main;
</code></pre>
<p>Not ready for a full refactor? Start smaller. The built-in <code>-dump-spec</code>
command introspects your existing module and writes a YAML manifest that
makes your configuration data-driven without moving a single line of
implementation code. Adopt roles incrementally, one command at a time.</p>
<p>When you are ready to scaffold a full role-based project, <code>-scaffold</code>
generates role stubs, a slimmed main module, and inter-module dependencies
from your manifest. Feed the resulting tarball to
<a href="https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper" rel="nofollow">CPAN::Maker::Bootstrapper</a> and you have a complete, buildable CPAN
distribution in one step.</p>
<a id="version" class="anchor" aria-label="Permalink: VERSION" href="#version"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">VERSION</h1>
<p>This documentation refers to version 2.2.0.</p>
<a id="features" class="anchor" aria-label="Permalink: FEATURES" href="#features"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">FEATURES</h1>
<ul>
<li>accept command line arguments ala <a href="https://metacpan.org/pod/Getopt%3A%3ALong" rel="nofollow">Getopt::Long</a>
</li>
<li>supports commands and command arguments</li>
<li>automatically add a logger</li>
<li>global or custom log levels per command</li>
<li>easily add usage notes</li>
<li>automatically create setter/getters for your script</li>
<li>low dependency profile</li>
<li>optional role-based architecture via YAML manifest</li>
<li>built-in scaffolding tools for migrating legacy scripts to roles</li>
<li>bash completion script generation for modulino wrappers</li>
<li>optional pager support for help output via <a href="https://metacpan.org/pod/IO%3A%3APager" rel="nofollow">IO::Pager</a>
</li>
<li>customizable help sections via <code>help_sections</code>
</li>
</ul>
<a id="modulinos" class="anchor" aria-label="Permalink: MODULINOS" href="#modulinos"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">MODULINOS</h1>
<p>A <em>modulino</em> is a Perl module that can also be run directly as a
script. The term was coined by Brian D. Foy and the pattern is simple:</p>
<pre><code>caller or exit __PACKAGE__-&gt;main();
</code></pre>
<p>When the file is <code>require</code>d or <code>use</code>d by another module, <code>caller</code>
returns the calling package and the expression short-circuits -
<code>main()</code> is never called. When the file is executed directly by Perl,
<code>caller</code> returns false and <code>main()</code> runs. The same file serves as
both a reusable module and an executable script.</p>
<p><code>CLI::Simple</code> is designed around this pattern. Every <code>CLI::Simple</code>
application is expected to be a modulino. The framework's lifecycle,
internal commands, bash completion, and scaffolding tools all assume
this dual-use design.</p>
<a id="why-modulinos" class="anchor" aria-label="Permalink: Why Modulinos?" href="#why-modulinos"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Why Modulinos?</h2>
<p>The modulino pattern offers several advantages over a traditional
script:</p>
<ul>
<li>
<strong>Testable</strong> - your script logic lives in a proper Perl module
that can be <code>use</code>d in test files without executing <code>main()</code>
</li>
<li>
<strong>Reusable</strong> - other scripts and modules can <code>use</code> your
modulino and call its methods directly</li>
<li>
<strong>Introspectable</strong> - tools like <code>-dump-spec</code> and
<code>-generate-completion</code> can load your modulino and inspect its live
state without running it as a script</li>
<li>
<strong>Installable</strong> - modulinos distribute cleanly as CPAN modules
with full man page support via <a href="https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper" rel="nofollow">CPAN::Maker::Bootstrapper</a>
</li>
</ul>
<a id="the-bash-wrapper" class="anchor" aria-label="Permalink: The Bash Wrapper" href="#the-bash-wrapper"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">The Bash Wrapper</h2>
<p>Perl modulinos are invoked via a thin bash wrapper script that locates
the installed module file and passes all arguments through to Perl:</p>
<pre><code>#!/usr/bin/env bash
#-*- mode: sh; -*-

MODULINO_WRAPPER=my-script
MODULE_NAME=My::Script
MODULE_PATH=$(MODULE_PATH="${MODULE_NAME//:://}.pm" \
  perl -M$MODULE_NAME -e 'print $INC{$ENV{MODULE_PATH}};')

MODULINO_WRAPPER=$MODULINO_WRAPPER perl $MODULE_PATH "$@"
</code></pre>
<p>The wrapper locates the installed <code>.pm</code> file via <code>%INC</code> and sets
<code>MODULINO_WRAPPER</code> in the environment so <code>CLI::Simple</code> knows the
name of the script the user actually typed. This is used by
<code>-generate-completion</code> to name the bash completion function correctly
and by <a href="https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper" rel="nofollow">CPAN::Maker::Bootstrapper</a> to create man page symlinks.</p>
<a id="create-modulino" class="anchor" aria-label="Permalink: create-modulino" href="#create-modulino"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">create-modulino</h2>
<p><code>CLI::Simple</code> ships with a <code>create-modulino</code> tool that generates the
bash wrapper for any <code>CLI::Simple</code> modulino:</p>
<pre><code># create wrapper using module name convention (My::Script -&gt; my-script)
create-modulino -m My::Script

# install to a specific directory
create-modulino -m My::Script -i /usr/local/bin

# use a custom wrapper name
create-modulino -m My::Script -a my-alias -i /usr/local/bin
</code></pre>
<p><code>create-modulino</code> is itself a modulino - an example of the pattern it
creates. The bash wrapper template lives in its <code>__DATA__</code> section,
keeping the tool entirely self-contained.</p>
<p>If you are building a CPAN distribution, <a href="https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper" rel="nofollow">CPAN::Maker::Bootstrapper</a>
integrates <code>create-modulino</code> into the <code>make modulino</code> target,
generating and installing the wrapper as part of the build process.</p>
<a id="modulino_wrapper" class="anchor" aria-label="Permalink: MODULINO_WRAPPER" href="#modulino_wrapper"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">MODULINO_WRAPPER</h2>
<p>The <code>MODULINO_WRAPPER</code> environment variable tells <code>CLI::Simple</code> the
name of the wrapper script that invoked the modulino. It is set by the
wrapper and used by:</p>
<ul>
<li>
<code>-generate-completion</code> - to name the bash completion function
and <code>complete</code> target correctly</li>
<li>Man page symlinks via <a href="https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper" rel="nofollow">CPAN::Maker::Bootstrapper</a> - so
<code>man my-script</code> resolves to the module's man page</li>
</ul>
<p>If <code>MODULINO_WRAPPER</code> is not set, <code>CLI::Simple</code> infers the script
name from the module name by convention - <code>My::Script</code> becomes
<code>my-script</code>. Set it explicitly when the wrapper name does not follow
this convention.</p>
<a id="quick-start" class="anchor" aria-label="Permalink: QUICK START" href="#quick-start"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">QUICK START</h1>
<a id="single-module-application" class="anchor" aria-label="Permalink: Single-Module Application" href="#single-module-application"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Single-Module Application</h2>
<p>The simplest way to use <code>CLI::Simple</code> is to subclass it and define
your commands as methods in the same module:</p>
<pre><code>package My::Script;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);

use parent qw(CLI::Simple);

caller or exit __PACKAGE__-&gt;main;

sub cmd_frobnicate {
  my ($self) = @_;
  my $output = $self-&gt;get_output;
  ...
  return $SUCCESS;
}

sub main {
  __PACKAGE__-&gt;new(
    option_specs =&gt; [ qw( help|h verbose|v output|o=s ) ],
    commands     =&gt; { frobnicate =&gt; \&amp;cmd_frobnicate },
  )-&gt;run;
}

1;
</code></pre>
<a id="role-based-application" class="anchor" aria-label="Permalink: Role-Based Application" href="#role-based-application"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Role-Based Application</h2>
<p>For larger applications, declare your commands and options in a YAML
manifest and implement each command in a dedicated <a href="https://metacpan.org/pod/Role%3A%3ATiny" rel="nofollow">Role::Tiny</a> role.
Your main module becomes a single declaration:</p>
<pre><code>package My::Script;

use strict;
use warnings;

use CLI::Simple qw(:roles);
use parent qw(CLI::Simple);

our $VERSION = '1.0.0';

caller or exit __PACKAGE__-&gt;main;

1;
</code></pre>
<p><strong>Naming convention:</strong> The YAML manifest filename is derived from your
module name - <code>My::Script</code> looks for <code>my-script.yml</code> in the
distribution share directory. You must package the spec file with your
distribution.</p>
<p>The manifest maps commands to roles:</p>
<pre><code>---
commands:
  frobnicate: My::Script::Role::Frobnicate
  list:       My::Script::Role::List
options:
  - help|h
  - verbose|v
  - output|o=s
</code></pre>
<p>Each role implements one or more commands:</p>
<pre><code>package My::Script::Role::Frobnicate;

use Role::Tiny;
use CLI::Simple::Constants qw(:booleans);

sub cmd_frobnicate {
  my ($self) = @_;
  ...
  return $SUCCESS;
}

1;
</code></pre>
<p>To easily generate the directory structure, role stubs, and build
files for this architecture, <code>CLI::Simple</code> provides a built-in
<code>-scaffold</code> tool.</p>
<p>See <a href="#scaffold">"-scaffold"</a> for detailed instructions on generating a role-based
project tarball from a monolithic script or a YAML manifest. For a
comprehensive guide on transitioning your application, see
<a href="#role-based-architecture">"ROLE-BASED ARCHITECTURE"</a>.</p>
<a id="role-based-architecture" class="anchor" aria-label="Permalink: ROLE-BASED ARCHITECTURE" href="#role-based-architecture"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">ROLE-BASED ARCHITECTURE</h1>
<p><code>CLI::Simple</code> 2.0.0 introduces an optional role-based architecture
for applications that have grown beyond a single module. Commands are
implemented in dedicated <a href="https://metacpan.org/pod/Role%3A%3ATiny" rel="nofollow">Role::Tiny</a> roles and declared in a YAML
manifest. <code>CLI::Simple</code> composes the roles, builds the dispatch
table, and provides an inherited <code>main()</code> - potentially reducing your
main module to a single declaration.</p>
<a id="the-yaml-manifest" class="anchor" aria-label="Permalink: The YAML Manifest" href="#the-yaml-manifest"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">The YAML Manifest</h2>
<p>The manifest is a YAML file that declares your commands, options, and
defaults. By convention the filename is derived from your module name:</p>
<pre><code>My::Script        -&gt;  my-script.yml
CPAN::Maker::Bootstrapper  -&gt;  cpan-maker-bootstrapper.yml
</code></pre>
<p><code>CLI::Simple</code> locates the manifest via <a href="https://metacpan.org/pod/File%3A%3AShareDir" rel="nofollow">File::ShareDir</a> using the
distribution name derived from the module name. The manifest must be
installed as part of the distribution - it cannot be loaded from an
arbitrary location.</p>
<p><em>Security note: The manifest is loaded exclusively from the
distribution share directory via <a href="https://metacpan.org/pod/File%3A%3AShareDir" rel="nofollow">File::ShareDir</a>. A manifest that
was not installed as part of the distribution cannot be loaded. This
provides the same security model as Perl module loading itself.</em></p>
<p>A minimal manifest:</p>
<pre><code>---
commands:
  frobnicate: My::Script::Role::Frobnicate
  list:       My::Script::Role::List
options:
  - help|h
  - verbose|v
  - output|o=s
</code></pre>
<p>A complete manifest with all supported keys:</p>
<pre><code>---
commands:
  frobnicate: My::Script::Role::Frobnicate
  list:       My::Script::Role::List
  default:    cmd_frobnicate
options:
  - help|h
  - verbose|v
  - output|o=s
default_options:
  verbose: 0
extra_options:
  - dbh
  - config_data
</code></pre>
<a id="command-values" class="anchor" aria-label="Permalink: Command Values" href="#command-values"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Command Values</h2>
<p>Each command in the manifest maps to either a role class name or a
sub name:</p>
<ul>
<li>
<p><strong>Role class name</strong> (contains <code>::</code>) - the role is composed
into your main module and the method <code>cmd__command_</code> is resolved
from the role. <code>code-review</code> resolves to <code>cmd_code_review</code>.</p>
</li>
<li>
<p><strong>Sub name</strong> - resolved directly via <code>can()</code> on your class.
Use this for alias commands that point to an existing method:</p>
<pre><code>  default: cmd_frobnicate
</code></pre>
</li>
</ul>
<a id="roles-with-no-commands" class="anchor" aria-label="Permalink: Roles With No Commands" href="#roles-with-no-commands"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Roles With No Commands</h2>
<p>Some roles provide framework behavior rather than commands - for
example an <code>init()</code> method for startup validation. Since these roles
have no command entry in the manifest they must be composed manually
in your main module:</p>
<pre><code>package My::Script;

use CLI::Simple qw(:roles);
use Role::Tiny::With;
use parent qw(CLI::Simple);

with 'My::Script::Role::Init';

caller or exit __PACKAGE__-&gt;main;

1;
</code></pre>
<p><em>Note: A future version of <code>CLI::Simple</code> will support an
<code>extra_roles</code> key in the manifest to handle this automatically.</em></p>
<a id="activating-role-based-architecture" class="anchor" aria-label="Permalink: Activating Role-Based Architecture" href="#activating-role-based-architecture"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Activating Role-Based Architecture</h2>
<p>Add <code>:roles</code> to your <code>use CLI::Simple</code> statement:</p>
<pre><code>use CLI::Simple qw(:roles);
</code></pre>
<p>This triggers manifest loading at compile time. The manifest is
located using the fallback chain described above. Roles are composed
into your class and the dispatch table is built before <code>new()</code> is
called.</p>
<a id="the-inherited-main" class="anchor" aria-label="Permalink: The Inherited main()" href="#the-inherited-main"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">The Inherited main()</h2>
<p>When using <code>:roles</code>, your class inherits <code>main()</code> from
<code>CLI::Simple</code>. It reads the manifest, constructs the object with the
manifest's options and dispatch table, and calls <code>run()</code>:</p>
<pre><code>caller or exit __PACKAGE__-&gt;main;
</code></pre>
<p>Override <code>main()</code> in your subclass only if you need to add behaviour
that cannot be expressed in the manifest or <code>init()</code>.</p>
<a id="distributing-the-manifest" class="anchor" aria-label="Permalink: Distributing the Manifest" href="#distributing-the-manifest"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Distributing the Manifest</h2>
<p>Add the manifest to your distribution's share
directory. <code>CPAN::Maker</code> users can add it <code>extra-files</code> in
<code>buildspec.yml</code> so it is installed into the share directory:</p>
<pre><code>extra-files:
  - share:
    - my-script.yml
</code></pre>
<p>During development the manifest is found via <code>%INC</code>. After
installation it is found via <a href="https://metacpan.org/pod/File%3A%3AShareDir" rel="nofollow">File::ShareDir</a>. No code changes
required between the two environments.
=head1 PHILOSOPHY AND DESIGN PRINCIPLES</p>
<p><code>CLI::Simple</code> is intentionally minimalist. It provides just enough
structure to build command-line tools with subcommands, option
parsing, and help handling -- but without enforcing any particular
framework or lifecycle.</p>
<a id="not-a-framework" class="anchor" aria-label="Permalink: Not a Framework" href="#not-a-framework"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Not a Framework</h2>
<p>This module is not <a href="https://metacpan.org/pod/App%3A%3ACmd" rel="nofollow">App::Cmd</a>, <a href="https://metacpan.org/pod/MooseX%3A%3AGetopt" rel="nofollow">MooseX::Getopt</a>, or a full
application toolkit.  Instead, it offers:</p>
<ul>
<li>An object-oriented base class with a clean <code>run()</code> dispatcher</li>
<li>Command-line parsing via <code>Getopt::Long</code>
</li>
<li>Built-in logging via <code>Log::Log4perl</code>
</li>
<li>Subclass hooks like <code>init()</code> for setup and validation</li>
<li>Optional role-based architecture via YAML manifest for larger applications</li>
</ul>
<p>The philosophy is: provide just enough infrastructure, then get out of your way.</p>
<a id="validation-defaults-and-configuration" class="anchor" aria-label="Permalink: Validation, Defaults, and Configuration" href="#validation-defaults-and-configuration"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Validation, Defaults, and Configuration</h2>
<p><code>CLI::Simple</code> does not impose a validation model. You may:</p>
<ul>
<li>Use <code>Getopt::Long</code> features (e.g., type constraints, default values)</li>
<li>Write your own validation logic in <code>init()</code>
</li>
<li>Throw exceptions, emit usage, or exit early at any point</li>
</ul>
<p>The lifecycle is explicit and under your control. You decide how much structure
you want to add on top of it.</p>
<a id="when-to-use" class="anchor" aria-label="Permalink: When to Use" href="#when-to-use"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">When to Use</h2>
<p><code>CLI::Simple</code> is ideal for:</p>
<ul>
<li>Internal tools and admin scripts</li>
<li>Bootstrapped CLIs where you don't want a framework</li>
<li>Users who want to subclass a clean, minimal interface</li>
<li>Applications that have grown beyond a single module and benefit from
role-based command composition</li>
</ul>
<p>For interactive CLI handling or complex command trees, consider
<a href="https://metacpan.org/pod/App%3A%3ACmd" rel="nofollow">App::Cmd</a> or <a href="https://metacpan.org/pod/CLI%3A%3AFramework" rel="nofollow">CLI::Framework</a>.</p>
<a id="the-init-run-lifecycle" class="anchor" aria-label="Permalink: The init-run Lifecycle" href="#the-init-run-lifecycle"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">The init-run Lifecycle</h2>
<ul>
<li>
<p><strong>Phase 0: Internal Commands</strong></p>
<p>Before anything else, <code>CLI::Simple</code> checks <code>@ARGV</code> for internal
commands prefixed with <code>-</code>. If one is found it executes immediately
and exits. See <a href="#internal-commands">"INTERNAL COMMANDS"</a>.</p>
</li>
<li>
<p><strong>Phase 1: Manifest Loading</strong></p>
<p>For role-based applications using <code>use CLI::Simple qw(:roles)</code>, the
YAML manifest is loaded at compile time during <code>import</code>. Roles are
composed into the calling class and the dispatch table is built before
<code>new()</code> is ever called. Single-module applications skip this phase
entirely.</p>
</li>
<li>
<p><strong>Phase 2: Initialization (<code>new</code> =</strong> <code>init</code>)&gt;</p>
<p>The constructor parses command-line arguments via <code>Getopt::Long</code>,
creates accessors for all options, and calls your <code>init()</code> method.
Inside <code>init()</code>, your application has full access to the parsed options
and arguments. This phase is the ideal hook for all final setup tasks,
such as:</p>
<ul>
<li>Validating command-line arguments.</li>
<li>Loading configuration files based on a <code>--config</code> option.</li>
<li>Dynamically overriding the command (e..g, <code>$self-&gt;command('new_default')</code>).</li>
<li>Performing any setup required <strong>before</strong> a command is run.</li>
</ul>
</li>
<li>
<p><strong>Phase 3: Execution (<code>run</code>)</strong></p>
<p>Dispatches to the command method determined during initialization.</p>
</li>
</ul>
<a id="opt-in-default-command" class="anchor" aria-label="Permalink: &quot;opt-in&quot; Default Command" href="#opt-in-default-command"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">"opt-in" Default Command</h2>
<p>By design, <code>CLI::Simple</code> <strong>does not impose a default command</strong>.
This provides total flexibility for the application author:</p>
<ul>
<li>
<strong>You Can Set a Default:</strong> If your application needs a default
command (e.g., to run <code>help</code> when no command is given), you can set
<code>$AUTO_HELP</code>, explicitly set the <code>default</code> command in the <code>command</code>
hash you pass to the constructor or use <code>command()</code> to set one
inside the <code>init()</code> method.</li>
<li>
<strong>You Can Have No Default:</strong> If you do <strong>not</strong> set a default,
<code>run()</code> will simply do nothing and return cleanly if no command
is provided on the command line.</li>
</ul>
<p>This "no default by default" behavior is what enables a powerful
"setup-only" execution mode. A user can run your script <em>without</em>
specifying a command. This will:</p>
<ul>
<li>
<ol>
<li>Run the entire <code>new()</code> / <code>init()</code> phase, performing all setup.</li>
</ol>
</li>
<li>
<ol start="2">
<li>Call <code>run()</code>, which will find no command and exit cleanly.</li>
</ol>
</li>
</ul>
<p>This provides an ideal hook for applications that need to perform
"on-demand initialization" (e.g., seeding a database, authenticating)
by checking for a specific flag inside <code>init()</code>, without also
triggering an unwanted command.</p>
<p>In role-based applications using a YAML manifest, a <code>default</code> command
that aliases another command should map to the sub name directly rather
than a role class:</p>
<pre><code>commands:
  default: cmd_install
  install: My::Module::Role::Installer
</code></pre>
<div class="markdown-heading"><h2 class="heading-element">
<code>$AUTO_HELP</code> and <code>$AUTO_DEFAULT</code>
</h2><a id="auto_help-and-auto_default" class="anchor" aria-label="Permalink: $AUTO_HELP and $AUTO_DEFAULT" href="#auto_help-and-auto_default"><span aria-hidden="true" class="octicon octicon-link"></span></a></div>
<p>Two package variables can be used to further control the lifecycle. By
default, the framework provides no default command as explained in the
sections above. Some scripters may want default behaviors that assume
a command or provide usage if no command is provided.</p>
<ul>
<li>
<p><code>$AUTO_HELP</code></p>
<p>Set the package variable <code>$AUTO_HELP</code> to a true value if you want
<code>CLI::Simple</code> to provide help when no command is provided.</p>
<p>default: false</p>
</li>
<li>
<p><code>$AUTO_DEFAULT</code></p>
<p>Set the package variable <code>$AUTO_DEFAULT</code> to a true value if you want
<code>CLI::Simple</code> to automatically select a command if you have only 1
command defined and no command is provided on the command line. When
true, it will prepend the single command name to the argument list,
allowing any subsequent arguments to be correctly parsed as args for
that command.</p>
<p>default: false</p>
</li>
<li>
<p><code>$PAGER</code></p>
<p>Set the package variable <code>$PAGER</code> to a true value to route help
output through <a href="https://metacpan.org/pod/IO%3A%3APager" rel="nofollow">IO::Pager</a> when <code>--help</code> is invoked. When enabled,
<code>IO::Pager</code> selects an appropriate pager (<code>less</code>, <code>more</code>, etc.)
based on the <code>PAGER</code> environment variable, falling back to a sensible
default. Set to false to suppress pager use and write help directly to
STDOUT.</p>
<pre><code>  use CLI::Simple qw($PAGER);
  $PAGER = 0;  # disable pager
</code></pre>
<p>default: true</p>
<p>Note: <a href="https://metacpan.org/pod/IO%3A%3APager" rel="nofollow">IO::Pager</a> must be installed for pager support. If it is not
available, help output is written directly to STDOUT regardless of the
value of <code>$PAGER</code>.</p>
</li>
</ul>
<a id="constants" class="anchor" aria-label="Permalink: CONSTANTS" href="#constants"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">CONSTANTS</h1>
<p><code>CLI::Simple</code> does not define its own constants directly, but it is often used
in conjunction with <a href="https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AConstants" rel="nofollow">CLI::Simple::Constants</a>, which provides a collection of
exportable values commonly needed in command-line scripts.</p>
<p>These include:</p>
<ul>
<li>Boolean flags like <code>$TRUE</code>, <code>$FALSE</code>, <code>$SUCCESS</code>, and <code>$FAILURE</code>
</li>
<li>Common character tokens such as <code>$COLON</code>, <code>$DASH</code>, <code>$EQUALS_SIGN</code>, etc.</li>
<li>Log level names compatible with <a href="https://metacpan.org/pod/Log%3A%3ALog4perl" rel="nofollow">Log::Log4perl</a>
</li>
</ul>
<p>To use them in your script:</p>
<pre><code>use CLI::Simple::Constants qw(:all);
</code></pre>
<a id="additional-notes" class="anchor" aria-label="Permalink: ADDITIONAL NOTES" href="#additional-notes"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">ADDITIONAL NOTES</h1>
<ul>
<li>All options are case insensitive</li>
<li>See <a href="https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AUtils" rel="nofollow">CLI::Simple::Utils</a> to learn about additional utilities
useful when writing scripts, including <code>choose</code>, <code>slurp</code>, and <code>dmp</code>.</li>
<li>
<code>%INTERNAL_COMMANDS</code> is a package variable - subclasses can
add their own internal commands by pushing entries into the hash before
calling <code>new()</code>.</li>
</ul>
<a id="customizing-help-output" class="anchor" aria-label="Permalink: CUSTOMIZING HELP OUTPUT" href="#customizing-help-output"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">CUSTOMIZING HELP OUTPUT</h1>
<div class="markdown-heading"><h2 class="heading-element"><code>help_sections</code></h2><a id="help_sections" class="anchor" aria-label="Permalink: help_sections" href="#help_sections"><span aria-hidden="true" class="octicon octicon-link"></span></a></div>
<p>By default <code>CLI::Simple</code> passes a standard set of POD section names to
<a href="https://metacpan.org/pod/Pod%3A%3AUsage" rel="nofollow">Pod::Usage</a> when rendering help output:</p>
<pre><code>SYNOPSIS DESCRIPTION/Commands DESCRIPTION/Options OPTIONS USAGE
</code></pre>
<p>You can override this by passing an array of sections names during construction.</p>
<pre><code>my $cli = CLI::Simple-&gt;new( help_sections =&gt; [qw(SYNOPSIS COMMANDS OPTIONS)], ...);
</code></pre>
<p>You must do this during construction or add <code>help_sections</code> to your
<code>extra_options</code> and set the defaults for <code>help_sections</code>:</p>
<pre><code>my $cli = CLI::Simple-&gt;new(
  commands        =&gt; $commands,
  extra_options   =&gt; [ qw(help_sections) ],
  default_options =&gt; { help_sections =&gt; [qw(SYNOPIS COMMANDS OPTIONS)] },
  option_specs    =&gt; \@option_specs
);
</code></pre>
<p>Section names follow <a href="https://metacpan.org/pod/Pod%3A%3AUsage" rel="nofollow">Pod::Usage</a> conventions. Subsections are
specified with a <code>/</code> separator, e.g. <code>DESCRIPTION/Commands</code> renders
only the <code>Commands</code> subsection under <code>=head1 DESCRIPTION</code>.</p>
<a id="internal-commands" class="anchor" aria-label="Permalink: INTERNAL COMMANDS" href="#internal-commands"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">INTERNAL COMMANDS</h1>
<p><code>CLI::Simple</code> reserves command names beginning with <code>-</code> for its own
use. These commands are intercepted before option parsing begins and
execute immediately, bypassing the normal lifecycle entirely. See
<a href="#the-init-run-lifecycle">"The init-run Lifecycle"</a>.</p>
<p>Internal commands are dispatched via the <code>%INTERNAL_COMMANDS</code> package
variable:</p>
<pre><code>our %INTERNAL_COMMANDS = (
  '-generate-completion' =&gt; \&amp;_cmd_generate_completion,
  '-dump-spec'           =&gt; \&amp;_cmd_dump_spec,
  '-scaffold'            =&gt; \&amp;_cmd_scaffold,
  '-migrate'             =&gt; \&amp;_cmd_migrate,
);
</code></pre>
<p>Subclasses can add their own internal commands by extending the hash
before <code>new()</code> is called:</p>
<pre><code>our %INTERNAL_COMMANDS = (
  %CLI::Simple::INTERNAL_COMMANDS,
  '-my-command' =&gt; \&amp;_cmd_my_command,
);
</code></pre>
<a id="-generate-completion" class="anchor" aria-label="Permalink: -generate-completion" href="#-generate-completion"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">-generate-completion</h2>
<p>Generates a bash completion script for the script's commands and
options, derived from the live object state. Bash completions are a
feature that allows the shell to automatically finish commands, file
paths, and options when you press the Tab key.</p>
<pre><code>my-script -generate-completion &gt; \
  ~/.local/share/bash-completion/completions/my-script
</code></pre>
<p>After generating the bash completion script, source it in your current
shell to test:</p>
<pre><code>source ~/.local/share/bash-completion/completions/my-script
</code></pre>
<p>Test by typing your script name followed by a space and pressing Tab.
You should see the available commands. To verify option completion,
type <code>--</code> and press Tab.</p>
<p>To make completions permanent, most systems automatically source files
placed in <code>~/.local/share/bash-completion/completions/</code> when
<code>bash-completion</code> 2.x is installed. If your system does not pick
them up automatically, add the following to your <code>~/.bashrc</code>:</p>
<pre><code>source ~/.local/share/bash-completion/completions/my-script
</code></pre>
<p>Alternatively, place the generated file in the system-wide completion
directory (requires root):</p>
<pre><code>my-script -generate-completion &gt; \
  /etc/bash_completion.d/my-script
</code></pre>
<p>The script name is taken from the first argument if provided, then
<code>MODULINO_WRAPPER</code> if set, then inferred from the module name. If the
inferred name cannot be found in <code>PATH</code>, a warning is issued but the
completion script is still generated.</p>
<p><em>Note: If you created the modulino with the supplied
<code>create-modulino</code> tool <code>MODULINO_WRAPPER</code> is already set inside the
bash script that invokes the modulino.</em></p>
<ul>
<li>
<p>Case 1: Your modulino wrapper and module name are aligned</p>
<p>The modulino script <code>my-modulino</code> refers to My::Modulino</p>
<pre><code>  my-modulino -generate-completion
</code></pre>
</li>
<li>
<p>Case 2: Your modulino wrapper was created using <code>create-modulino</code></p>
<p>The modulino script <code>my-alias</code> refers to My::Modulino. They are not
aligned however <code>MODULINO_WRAPPER</code> is set by the bash wrapper.</p>
<pre><code>  my-alias -generate-completion
</code></pre>
</li>
<li>
<p>Case 3: Your modulino is an alias not created by <code>create-modulino</code></p>
<p>The script name <code>my-alias</code> is not aligned with your module name
<code>My::Module</code> and your modulino wrapper does not set
<code>MODULINO_WRAPPER</code>. The <code>-generate-completion</code> script called by
your custom wrapper most likely only resolves the program name as the path to
your Perl module:</p>
<pre><code>  path-to-modules/My/Module.pm
</code></pre>
<p>...in this case you need to supply the alias name or set
<code>MODULINO_WRAPPER</code> in the environment.</p>
<pre><code>  my-alias -generate-completion my-alias
</code></pre>
</li>
</ul>
<a id="-dump-spec" class="anchor" aria-label="Permalink: -dump-spec" href="#-dump-spec"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">-dump-spec</h2>
<p>Introspects the running modulino and writes a YAML manifest to the
current directory. The filename is derived from the module name by
convention.</p>
<pre><code>my-script -dump-spec           # sub names - baby step toward roles
my-script -dump-spec roles     # role class names - full commitment
</code></pre>
<p>Without the <code>roles</code> argument, commands map to their existing sub
names so the manifest can be used immediately without moving any
code. With <code>roles</code>, commands map to derived role class names suitable
for use with <code>-scaffold</code>.</p>
<p>Alias commands - those whose coderef resolves to a sub name that does
not match the command key - are always written as sub names regardless
of mode.</p>
<a id="-scaffold" class="anchor" aria-label="Permalink: -scaffold" href="#-scaffold"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">-scaffold</h2>
<p>Generates a role-based project tarball from the running modulino or
from an explicit spec file.</p>
<p>There are basically three architectures you can employ when you build a
<code>CLI::Simple</code> based application. An application that contains all of
the options, command specifications and the command subroutines
themselves in one package is the simplest.  This monolithic
architeture looks something like this:</p>
<pre><code>package FooBar;

use strict;
use warning;

use parent qw(CLI::Simple);

caller or exit __PACKAGE__-&gt;main();

sub cmd_foo {
}

sub cmd_bar {
}

sub main {
  return __PACKAGE__-&gt;new(commands =&gt; { foo =&gt; \&amp;cmd_foo, bar =&gt; \&amp;cmd_bar,
                          options =&gt; [ qw(h|help infile|i=s) ],
                         )-&gt;run;
}

1;
</code></pre>
<p>However, a better architecture as your application gets more
complicated is to use a role (e.g using <a href="https://metacpan.org/pod/Role%3A%3ATiny" rel="nofollow">Role::Tiny</a> for each
command. In a hybrid role/monolith you split the commands into
separate files and compose them into your package.</p>
<pre><code>package FooBar::Foo;

use Role::Tiny;

sub cmd_foo { };

1;

package FooBar::Bar;

use Role::Tiny;

sub cmd_bar { };

1;

package FooBar;

use strict;
use warnings;

use Role::Tiny::With;
with 'FooBar::Foo';
with 'FooBar::Bar';

sub main {
  return __PACKAGE__-&gt;new(commands =&gt; { foo =&gt; \&amp;cmd_foo, bar =&gt; \&amp;cmd_bar,
                          options =&gt; [ qw(h|help infile|i=s) ],
                         )-&gt;run;
}
</code></pre>
<p>The third architecture uses role based command files and a YAML file
that contains all of your options and command specifications. You
include that file (named after your package), with the distribution.</p>
<pre><code>---
commands:
  foo: FooBar::Foo
  bar: Foobar::Bar
options:
  - help|h
  - infile|i=s
</code></pre>
<p>Your true role based application then becomes:</p>
<pre><code>package FooBar;

use CLI::Simple qw(:roles);
use parent qw(CLI::Simple);

caller or exit __PACKAGE__-&gt;main;

1;
</code></pre>
<p>The <code>-scaffold</code> command can take a monolithic application or a YAML
file like the one above and create the project hierarchy for a role
based application. The command will create a tarball that contains
role stubs, a slimmed main module with extracted POD (if your monolith
contained any), a <code>project.mk</code> with inter-module dependencies, and
the YAML manifest.</p>
<p>If you've turned your monolith's package into a modulino:</p>
<pre><code>my-script -scaffold                        # introspect live module
</code></pre>
<p>...or use <code>cli-simple</code> if you have a .yml file.</p>
<pre><code>cli-simple -scaffold my-script.yml         # scaffold from spec file
</code></pre>
<p>The tarball will be named <code>my-script-roles.tar.gz</code> by convention (the
lower case snake cased version of the class name). The name is used to
infer the class name. If your filename is different than the
classes you want to scaffold, you will need to edit the files.</p>
<p>Extract the content to a directory and start editing. If you feed the tarball
to <a href="https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper" rel="nofollow">CPAN::Maker::Bootstrapper</a> via the <code>import-scaffold</code> command you can
produce a complete buildable CPAN distribution.</p>
<a id="-migrate" class="anchor" aria-label="Permalink: -migrate" href="#-migrate"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">-migrate</h2>
<p>Combines <code>-dump-spec roles</code> and <code>-scaffold</code> in a single step.</p>
<pre><code>my-script -migrate
</code></pre>
<p>Writes the YAML manifest then generates the role-based tarball. Use
this when you are ready for a full migration and do not need to inspect
or edit the manifest first. If you want to review or adjust the
manifest before scaffolding, run <code>-dump-spec</code> and <code>-scaffold</code>
separately.</p>
<a id="methods-and-subroutines" class="anchor" aria-label="Permalink: METHODS AND SUBROUTINES" href="#methods-and-subroutines"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">METHODS AND SUBROUTINES</h1>
<a id="new" class="anchor" aria-label="Permalink: new" href="#new"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">new</h2>
<pre><code>new( args )
</code></pre>
<p>Instantiates a new <code>CLI::Simple</code> instance, parses options, optionally
initializes logging, and makes options available via dynamically
generated accessors.</p>
<p><em>Note: The <code>new()</code> constructor uses <a href="https://metacpan.org/pod/Getopt%3A%3ALong" rel="nofollow">Getopt::Long</a>'s <code>GetOptions</code>,
which directly modifies <code>@ARGV</code> by removing any recognized
options. The remaining elements of <code>@ARGV</code> are treated as the command
name and its arguments.</em></p>
<p><code>args</code> is a hash or hash reference containing the following keys:</p>
<ul>
<li>
<p>abbreviations</p>
<p>A boolean that determines whether abbreviated command names are allowed.</p>
<p>When true, the <code>run()</code> method will treat the provided command as a prefix
and compare it to the keys in the command hash. If exactly one match is
found, it will be used. If more than one match is found, or if no match is
found, <code>run()</code> will throw an exception.</p>
<p>This allows for convenient shorthand like:</p>
<pre><code>  mytool disable-sched    # expands to 'disable-scheduled-task'
</code></pre>
<p>default: false</p>
</li>
<li>
<p>commands (required)</p>
<p>A hash mapping command names to either a subroutine reference or an
array reference.</p>
<p>If an array reference is used, the first element must be a subroutine
reference and the second should be a valid log level. (See
<a href="#per-command-log-levels">"Per Command Log Levels"</a>.)</p>
<p>Example:</p>
<pre><code>  {
    send          =&gt; \&amp;send_message,
    receive       =&gt; \&amp;receive_message,
    list_messages =&gt; [ \&amp;list_messages, 'error' ],
  }
</code></pre>
<p>If your script does not use command names, you may set a <code>default</code> key
to the subroutine or method to run:</p>
<pre><code>  { default =&gt; \&amp;main }
</code></pre>
<p>If no default is provided, the behavior is controlled by the
<code>$AUTO_DEFAULT</code> and <code>$AUTO_HELP</code> package variables.</p>
<p>Setting <code>$AUTO_DEFAULT</code> to true when your <code>commands</code> hash
contains only a single command, will cause that command to be run
automatically when no command name is given on the command line. This
allows you to treat the program like a single-command tool, where
arguments can be passed directly without explicitly naming the
command.</p>
</li>
<li>
<p>default_options (optional)</p>
<p>A hash reference providing default values for options. These values
apply if the corresponding option is not given on the command line.</p>
</li>
<li>
<p>extra_options (optional)</p>
<p>An array reference of names for additional accessors you want to create,
even if they are not part of <code>option_specs</code>.</p>
<p>Example:</p>
<pre><code>  extra_options =&gt; [ qw(foo bar baz) ]
</code></pre>
</li>
<li>
<p>option_specs (optional)</p>
<p>An array reference of option specifications, as accepted by
<a href="https://metacpan.org/pod/Getopt%3A%3ALong" rel="nofollow">Getopt::Long</a>. These define the command-line options your program
recognizes.</p>
</li>
<li>
<p>validate_command</p>
<p>Normally, <code>CLI::Simple</code> will validate the command and throw an
exception if the command has not been registered. You can prevent this
behavior by setting this attribute to a non-true value.</p>
<p>Typically you might use this to allow a script to assume a default
command and allow arguments. For example suppose you have a script
<code>foo</code> with a command "get" with arguments:</p>
<pre><code>  foo get something
</code></pre>
<p>...but want to allow users to also do:</p>
<pre><code>  foo something
</code></pre>
<p>To do this you should follow this recipe:</p>
<pre><code>  sub init {
    my ($self) = @__;

    my @args = $self-&gt;get_args;

    if ( ! @args ) {
      $self-&gt;command_args($self-&gt;command()); # set the args to the command
      $self-&gt;command('get'); # set the command to your default
    }
    else {
      die "ERROR: unknown command\n"
        if !$self-&gt;commands-&gt;{$self-&gt;command}; # validate the command
    }
    ...
    return;
  }
</code></pre>
<p><em>NOTE: This only works if your commands have a deterministic number
of arguments. For example you might always require at least 1
argument. If you have no arguments as in the above recipe you would
assume command is the argument to your default command.</em></p>
</li>
</ul>
<a id="command" class="anchor" aria-label="Permalink: command" href="#command"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">command</h2>
<pre><code>command
command(command)
</code></pre>
<p>Get or sets the command to execute. Usually this is the first argument
on the command line after all options have been parsed. There are
times when you might want to override the argument. You can pass a new
command that will be executed when you call the <code>run()</code> method.</p>
<a id="command_args" class="anchor" aria-label="Permalink: command_args" href="#command_args"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">command_args</h2>
<pre><code>my $args = $self-&gt;command_args();
</code></pre>
<p>Get or sets the argument list. Similar to <code>get_args</code> when no
arguments are passed except it returns an array reference.</p>
<p>To replace or add to the argument list, pass an array or list.</p>
<pre><code>my $args = $self-&gt;command_args;
$self-&gt;command_args(@{$args}, 'foo');
</code></pre>
<a id="commands-required" class="anchor" aria-label="Permalink: commands (required)" href="#commands-required"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">commands (required)</h2>
<pre><code>commands
commands(command, handler)
</code></pre>
<p>Returns the hash you passed in the constructor as <code>commands</code> or can
be used to insert a new command into the <code>commands</code> hash. <code>handler</code>
should be a code reference.</p>
<pre><code>commands(foo =&gt; sub { return 'foo' });
</code></pre>
<a id="main" class="anchor" aria-label="Permalink: main" href="#main"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">main</h2>
<pre><code>__PACKAGE__-&gt;main;
</code></pre>
<p>For role-based applications, <code>main</code> is inherited from <code>CLI::Simple</code>
and reads the YAML manifest loaded during <code>import</code>. It constructs the
object with the manifest's options, default options, extra options, and
dispatch table, then calls <code>run()</code>.</p>
<p>In a role-based modulino the entire <code>main</code> sub reduces to:</p>
<pre><code>caller or exit __PACKAGE__-&gt;main;
</code></pre>
<p>For single-module applications, override <code>main</code> in your subclass as
usual.</p>
<a id="run" class="anchor" aria-label="Permalink: run" href="#run"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">run</h2>
<p>Execute the script with the given options, commands and arguments. The
<code>run</code> method interprets the command line and passes control to your
command subroutines. Your subroutines should return a 0 for success
and a non-zero value for failure.  This error code is passed to the
shell as the script return code.</p>
<a id="get_args" class="anchor" aria-label="Permalink: get_args" href="#get_args"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">get_args</h2>
<p>Return the arguments that follow the command.</p>
<pre><code>get_args(NAME, ... )     # with names
get_args()               # raw positional args
</code></pre>
<a id="with-names" class="anchor" aria-label="Permalink: With names" href="#with-names"><span aria-hidden="true" class="octicon octicon-link"></span></a><h3 class="heading-element">With names</h3>
<ul>
<li>In scalar context, returns a hash reference mapping each NAME to
the corresponding positional argument.</li>
<li>In list context, returns a flat list of <code>(name =</code> value)&gt; pairs.</li>
</ul>
<p>Example:</p>
<pre><code>sub send_message {
  my ($self) = @_;

  my %args = $self-&gt;get_args(qw(message email));

  _send_message($args{message}, $args{email});
}
</code></pre>
<p>When you call <code>get_args</code> with a list of names, values are assigned in
order: the first name gets the first argument, the second name gets the
second argument, and so on. If you only want specific positions, you may
use <code>undef</code> as a placeholder:</p>
<pre><code>my %args = $self-&gt;get_args('message', undef, 'cc');  # args 1 and 3
</code></pre>
<p>If there are fewer positional arguments than names, the remaining names
are set to <code>undef</code>. Extra positional arguments (beyond the provided
names) are ignored.</p>
<a id="with-no-names" class="anchor" aria-label="Permalink: With no names" href="#with-no-names"><span aria-hidden="true" class="octicon octicon-link"></span></a><h3 class="heading-element">With no names</h3>
<ul>
<li>In scalar context returns an array reference containing the
command's positional arguments.</li>
<li>In list context returns a list containing the command's
positional arguments.</li>
</ul>
<a id="init" class="anchor" aria-label="Permalink: init" href="#init"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">init</h2>
<p>If you define your own <code>init()</code> method, it will be called by the
constructor. Use this method to perform any actions you require before
you execute the <code>run()</code> method.</p>
<a id="using-package-variables" class="anchor" aria-label="Permalink: USING PACKAGE VARIABLES" href="#using-package-variables"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">USING PACKAGE VARIABLES</h1>
<p>You can pass the necessary parameter required to implement your
command line scripts in the constructor or some people prefer to see
them clearly defined in the code. Accordingly, you can use package
variables with the same name as the constructor arguments (in upper
case).</p>
<pre><code>our $OPTION_SPECS = [
  qw(
    help|h
    log-level=s|L
    debug|d
  )
];

our $COMMANDS = {
  foo =&gt; \&amp;foo,
  bar =&gt; \&amp;bar,
};
</code></pre>
<p>Subclasses can also extend the built-in internal commands by adding
entries to <code>%INTERNAL_COMMANDS</code>:</p>
<pre><code>our %INTERNAL_COMMANDS = (
  %CLI::Simple::INTERNAL_COMMANDS,
  '-my-command' =&gt; \&amp;_cmd_my_command,
);
</code></pre>
<a id="command-line-options" class="anchor" aria-label="Permalink: COMMAND LINE OPTIONS" href="#command-line-options"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">COMMAND LINE OPTIONS</h1>
<p>Command-line options are defined using <a href="https://metacpan.org/pod/Getopt%3A%3ALong" rel="nofollow">Getopt::Long</a>-style
specifications. You pass these into the constructor via the
<code>option_specs</code> parameter:</p>
<pre><code>my $cli = CLI::Simple-&gt;new(
  option_specs =&gt; [ qw( help|h foo-bar=s log-level=s ) ]
);
</code></pre>
<p>In your command subroutines, you can access these values using
automatically generated getter methods:</p>
<pre><code>$cli-&gt;get_foo();
$cli-&gt;get_log_level();
</code></pre>
<p>Option names that contain dashes (<code>-</code>) are automatically converted to
snake_case for the accessor methods. For example:</p>
<pre><code>option_specs =&gt; [ 'foo-bar=s' ]
</code></pre>
<p>...results in:</p>
<pre><code>$cli-&gt;get_foo_bar();
</code></pre>
<a id="set_args" class="anchor" aria-label="Permalink: set_args" href="#set_args"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">set_args</h2>
<p>Resets the positional arguments.</p>
<pre><code>$self-&gt;set_args(qw(foo 1));
</code></pre>
<p>This method overrides the positional arguments originally passed to
the script. You can achieve the same behavior by calling the
<code>get_args</code> in scalar context and modifying the reference.</p>
<pre><code>my $args = $self-&gt;get_args;
$args-&gt;[1] = '2';
</code></pre>
<p>Use this technique when you want don't want to alter the entire set of
arguments.</p>
<a id="command-arguments" class="anchor" aria-label="Permalink: COMMAND ARGUMENTS" href="#command-arguments"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">COMMAND ARGUMENTS</h1>
<p>If your commands accept positional arguments, you can retrieve them
using the <code>get_args</code> method.</p>
<p>You may optionally provide a list of argument names, in which case the
arguments will be returned as a hash (or hashref in scalar context)
with named values.</p>
<p>Example:</p>
<pre><code>sub send_message {
  my ($self) = @_;

  my %args = $self-&gt;get_args(qw(phone_number message));

  send_sms_message($args{phone_number}, $args{message});
}
</code></pre>
<p>If you call <code>get_args()</code> without any argument names, it simply
returns all remaining arguments as a list:</p>
<pre><code>my ($phone_number, $message) = $self-&gt;get_args;
</code></pre>
<p><em>Note: When called with names, <code>get_args</code> returns a hash in list
context and a hash reference in scalar context.</em></p>
<a id="custom-error-handler" class="anchor" aria-label="Permalink: CUSTOM ERROR HANDLER" href="#custom-error-handler"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">CUSTOM ERROR HANDLER</h1>
<p>By default, <code>CLI::Simple</code> will exit if <code>GetOptions</code> returns a false
value, indicating an error while parsing options. You can override this
behavior in one of two ways:</p>
<ul>
<li>
<p>Set <code>$CLI::Simple::GETOPT_EXIT_ON_ERROR</code> to a false value.</p>
<p>This disables automatic exiting and lets your program decide what to do
after an option-parsing failure.</p>
</li>
<li>
<p>Provide an <code>error_handler</code> callback in the constructor.</p>
<pre><code>  my $cli = CLI::Simple-&gt;new(
    commands        =&gt; \%commands,
    default_options =&gt; \%default_options,
    extra_options   =&gt; \@extra_options,
    option_specs    =&gt; \@option_specs,
    abbreviations   =&gt; $TRUE,
    error_handler   =&gt; sub {
      my ($msg) = @_;
      print {*STDERR} $msg;
      return $TRUE;   # continue processing
    },
  );
</code></pre>
<p>The error handler is called with the error message from <code>GetOptions</code>.
It must return a boolean: a true value allows processing to continue,
while a false value causes <code>CLI::Simple</code> to exit immediately.</p>
</li>
</ul>
<a id="setting-default-values-for-options" class="anchor" aria-label="Permalink: SETTING DEFAULT VALUES FOR OPTIONS" href="#setting-default-values-for-options"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">SETTING DEFAULT VALUES FOR OPTIONS</h1>
<p>To assign default values to your options, pass a hash reference as the
<code>default_options</code> argument to the constructor. These values will be
used unless explicitly overridden by the user on the command line.</p>
<p>Example:</p>
<pre><code>my $cli = CLI::Simple-&gt;new(
  default_options =&gt; { foo =&gt; 'bar' },
  option_specs    =&gt; [ qw(foo=s bar=s) ],
  commands        =&gt; {
    foo =&gt; \&amp;foo,
    bar =&gt; \&amp;bar,
  },
);
</code></pre>
<p>Defaulted options are accessible through their corresponding getter
methods, just like options set via the command line.</p>
<a id="adding-usage-to-your-scripts" class="anchor" aria-label="Permalink: ADDING USAGE TO YOUR SCRIPTS" href="#adding-usage-to-your-scripts"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">ADDING USAGE TO YOUR SCRIPTS</h1>
<p>To provide built-in usage/help output, include a <code>=head1 USAGE</code>
section in your script's POD:</p>
<pre><code>=head1 USAGE

  usage: myscript [options] command args

  Options
  -------
  --help, -h      Display help
  ...
</code></pre>
<p>If the user supplies the command <code>help</code>, or the <code>--help</code> option,
<code>CLI::Simple</code> will display this section automatically:</p>
<pre><code>perl myscript.pm --help
perl myscript.pm help
</code></pre>
<a id="custom-help-method" class="anchor" aria-label="Permalink: Custom help() Method" href="#custom-help-method"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Custom help() Method</h2>
<p>If you need full control over the help output, you can define a custom
<code>help</code> method and assign it as a command:</p>
<pre><code>commands =&gt; {
  help =&gt; \&amp;help,
  ...
}
</code></pre>
<p>This is useful if your module follows the modulino pattern and you
want to present usage information that differs from the embedded
POD. Without a custom handler, <code>CLI::Simple</code> defaults to displaying the
<code>USAGE</code> POD section.</p>
<a id="adding-additional-setters" class="anchor" aria-label="Permalink: ADDING ADDITIONAL SETTERS" href="#adding-additional-setters"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">ADDING ADDITIONAL SETTERS</h1>
<p>All command-line options are automatically available through getter
methods named <code>get_*</code>.</p>
<p>If you need to create additional accessors (getters and setters) for
values that are not derived from the command line, use the
<code>extra_options</code> parameter.</p>
<p>This is useful for passing runtime configuration or computed values
throughout your application.</p>
<p>Example:</p>
<pre><code>my $cli = CLI::Simple-&gt;new(
  default_options =&gt; { foo =&gt; 'bar' },
  option_specs    =&gt; [ qw(foo=s bar=s) ],
  extra_options   =&gt; [ qw(biz buz baz) ],
  commands        =&gt; {
    foo =&gt; \&amp;foo,
    bar =&gt; \&amp;bar,
  },
);
</code></pre>
<p>This will generate <code>get_biz</code>, <code>set_biz</code>, <code>get_buz</code>, etc., for
internal use.</p>
<a id="logging" class="anchor" aria-label="Permalink: LOGGING" href="#logging"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">LOGGING</h1>
<p><code>CLI::Simple</code> integrates with <a href="https://metacpan.org/pod/Log%3A%3ALog4perl" rel="nofollow">Log::Log4perl</a> to provide structured
logging for your scripts.</p>
<p>To enable logging, call the class method <code>use_log4perl()</code> in your
module or script:</p>
<pre><code>__PACKAGE__-&gt;use_log4perl(
  level  =&gt; 'info',
  config =&gt; $log4perl_config_string
);
</code></pre>
<p>If you do not explicitly include a <code>log-level</code> option in your
<code>option_specs</code>, CLI::Simple will automatically add one for you.</p>
<p>Once enabled, you can access the logger instance via:</p>
<pre><code>my $logger = $self-&gt;get_logger;
</code></pre>
<p>This logger supports the standard Log4perl methods like <code>info</code>,
<code>debug</code>, <code>warn</code>, etc.</p>
<a id="colored-output" class="anchor" aria-label="Permalink: Colored Output" href="#colored-output"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Colored Output</h2>
<p>Pass <code>color =&gt; 1</code> to <code>use_log4perl()</code> to default your script to
colorized log output using a built-in appender, instead of supplying
your own <code>config</code>:</p>
<pre><code>__PACKAGE__-&gt;use_log4perl(
  level =&gt; 'info',
  color =&gt; 1,
);
</code></pre>
<p>Colorizing requires <a href="https://metacpan.org/pod/Term%3A%3AANSIColor" rel="nofollow">Term::ANSIColor</a>. If it isn't installed,
<code>CLI::Simple</code> quietly falls back to uncolored output rather than
failing - <code>color =&gt; 1</code> is a request, not a hard dependency.</p>
<p>If you'd like the person running your script to be able to override
that default from the command line, add <code>color!</code> to your
<code>option_specs</code>:</p>
<pre><code>my @option_specs = qw(
  color!
  ...
);
</code></pre>
<p>This gives you <code>--color</code> and <code>--no-color</code> for free. Whichever way
<code>use_log4perl()</code> set the default, an explicit flag on the command
line always wins; if neither <code>--color</code> nor <code>--no-color</code> is passed,
your <code>use_log4perl()</code> setting is left alone. Declaring <code>color!</code> is
therefore safe to add at any time - it only changes behavior for
scripts whose users actually pass the flag.</p>
<p><em>Note: <code>color</code> and <code>config</code> are mutually exclusive -
<code>use_log4perl()</code> dies if you pass both. <code>color</code> is specifically for
using <code>CLI::Simple</code>'s own built-in colorized appender; if you need a
custom config, write it to include coloring yourself rather than
passing <code>color =&gt; 1</code>.</em></p>
<a id="per-command-log-levels" class="anchor" aria-label="Permalink: Per Command Log Levels" href="#per-command-log-levels"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Per Command Log Levels</h2>
<p>Some commands may require more verbose logging than others. For
example, certain commands might perform complex actions that benefit
from detailed logs, while others are designed solely to produce clean,
structured output.</p>
<p>To assign a custom log level to a command, use an array reference as
the value for that command in the commands hash passed to the
constructor.</p>
<p>The array reference should contain at least two elements:</p>
<ul>
<li>A code reference to the command subroutine</li>
<li>A log level string: one of 'trace', 'debug', 'info', 'warn',
'error', or 'fatal'</li>
</ul>
<p>Example:</p>
<pre><code>CLI::Simple-&gt;new(
  option_specs    =&gt; [qw( help format=s )],
  default_options =&gt; { format =&gt; 'json' },  # set some defaults
  extra_options   =&gt; [qw( content )],       # non-option, setter/getter
  commands        =&gt; {
    execute =&gt; \&amp;execute,
    list    =&gt; [ \&amp;list, 'error' ],
  }
)-&gt;run;
</code></pre>
<p><em>TIP: add other elements to the array for your command to process.</em></p>
<p><em>Note: Per-command log levels are not currently supported in the YAML
manifest. Define them programmatically by overriding <code>main()</code> if needed.</em></p>
<a id="faq" class="anchor" aria-label="Permalink: FAQ" href="#faq"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">FAQ</h1>
<ul>
<li>
<p>How do I execute startup code before my command runs?</p>
<p>Implement an <code>init()</code> method in your class. The <code>new()</code> constructor
will invoke this method before returning and before <code>run()</code> is
executed.</p>
<p>Your <code>init()</code> method will have access to all options and
arguments. Logging will also be initialized, so you can use
<code>get_logger()</code> to emit messages.</p>
</li>
<li>
<p>Do I need to implement commands?</p>
<p>No. If your script doesn't support multiple commands, you can specify
a <code>default</code> key instead:</p>
<pre><code>  commands =&gt; { default =&gt; \&amp;main }
</code></pre>
</li>
<li>
<p>Must I subclass <code>CLI::Simple</code>?</p>
<p>No. You can use it procedurally or functionally.</p>
</li>
<li>
<p>How do I turn my class into a script?</p>
<p>Use the modulino pattern: create a class that checks whether it is
being invoked directly:</p>
<pre><code>  package MyScript;

  caller or exit __PACKAGE__-&gt;main();

  sub main {
    ...
  }
</code></pre>
<p>This lets the file be used as both a module and an executable script.</p>
</li>
<li>
<p>How do I migrate an existing script to role-based architecture?</p>
<p>Run the built-in <code>-dump-spec</code> command to generate a YAML manifest from
your existing script, then <code>-scaffold</code> to generate role stubs:</p>
<pre><code>  my-script -dump-spec        # generates my-script.yml
  my-script -scaffold         # generates my-script-roles.tar.gz
</code></pre>
<p>See <a href="#role-based-architecture">"ROLE-BASED ARCHITECTURE"</a> for the full migration workflow.</p>
</li>
<li>
<p>How do I start a new role-based project from scratch?</p>
<p>Write a YAML manifest and use the <code>cli-simple</code> wrapper to scaffold it:</p>
<pre><code>  cli-simple -scaffold my-script.yml
</code></pre>
<p>See <a href="#role-based-architecture">"ROLE-BASED ARCHITECTURE"</a> for the manifest format.</p>
</li>
<li>
<p>How do I enable bash completion for my script?</p>
<p>Your script must be invoked via a bash modulino wrapper with
<code>MODULINO_WRAPPER</code> set. Then run:</p>
<pre><code>  my-script -generate-completion &gt; \
    ~/.local/share/bash-completion/completions/my-script
</code></pre>
<p>Wrappers generated by <a href="https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper" rel="nofollow">CPAN::Maker::Bootstrapper</a> set
<code>MODULINO_WRAPPER</code> automatically.</p>
</li>
<li>
<p>How do I add my own internal commands?</p>
<p>Add entries to <code>%INTERNAL_COMMANDS</code> before calling <code>new()</code>:</p>
<pre><code>  our %INTERNAL_COMMANDS = (
    %CLI::Simple::INTERNAL_COMMANDS,
    '-my-command' =&gt; \&amp;_cmd_my_command,
  );
</code></pre>
</li>
</ul>
<a id="aliasing-options-and-commands" class="anchor" aria-label="Permalink: ALIASING OPTIONS AND COMMANDS" href="#aliasing-options-and-commands"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">ALIASING OPTIONS AND COMMANDS</h1>
<p><code>CLI::Simple</code> lets you define short, human-friendly aliases for both
option names and command names. Use the <code>alias</code> parameter to <code>new():</code></p>
<pre><code>my $app = CLI::Simple-&gt;new(
  option_specs    =&gt; [ qw(config=s verbose!) ],
  commands        =&gt; { list =&gt; \&amp;list, execute =&gt; \&amp;execute },
  alias =&gt; {
    options  =&gt; { cfg =&gt; 'config', v =&gt; 'verbose' },
    commands =&gt; { ls  =&gt; 'list'   }
  },
);
</code></pre>
<a id="how-option-aliases-work" class="anchor" aria-label="Permalink: How option aliases work" href="#how-option-aliases-work"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">How option aliases work</h2>
<ul>
<li>
<p>Spec tail is copied automatically</p>
<p>You only name the canonical option in <code>option_specs</code>. For each alias,
<code>CLI::Simple</code> finds the canonical option's spec tail (for example
<code>=s</code>, <code>:i</code>, <code>!</code>, <code>+</code>) and appends it to the alias. In the example
above, <code>cfg</code> behaves as if you had written <code>cfg=s</code>, and <code>v</code> behaves
as if you had written <code>v!</code>.</p>
<p><em>Note: If your option includes a one-letter short-cut and the alias
does not start with the same letter it will not be automatically
enabled as a short-cut.</em></p>
</li>
<li>
<p>Accessors are created for both names</p>
<p>Accessors are generated from all option names (canonical and aliases),
with '-' normalized to '_'. In the example, both <code>get_config()</code> and
<code>get_cfg()</code> are available.</p>
</li>
<li>
<p>Values are mirrored after parsing</p>
<p>After option parsing and normalization, values are mirrored so either
name can be used consistently. If both the canonical name and its alias
are provided on the command line, the alias wins and becomes the final
value for both names.</p>
</li>
<li>
<p>No duplicate injection</p>
<p>If the alias already exists in <code>option_specs</code>, it will not be injected
again; value mirroring still occurs.</p>
</li>
<li>
<p>Errors are explicit</p>
<p>If an alias points at a canonical option that does not exist,
<code>CLI::Simple</code> croaks with a clear error.</p>
</li>
<li>
<p>Case sensitivity</p>
<p><code>Getopt::Long</code> is used with <code>:config no_ignore_case</code>, so option names
(and therefore aliases) are case sensitive by default.</p>
</li>
</ul>
<a id="how-command-aliases-work" class="anchor" aria-label="Permalink: How command aliases work" href="#how-command-aliases-work"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">How command aliases work</h2>
<ul>
<li>
<p>Simple mapping</p>
<p>Provide <code>alias =</code> { commands =&gt; { alias =&gt; canonical } }&gt; to map an alias
to an existing command. In the example, <code>ls</code> dispatches to the <code>list</code>
command.</p>
</li>
<li>
<p>Applied before abbreviations</p>
<p>Aliases are installed before command abbreviation resolution. If you
enable abbreviations, they apply to the full set of command names,
including any aliases.</p>
</li>
<li>
<p>Errors are explicit</p>
<p>If an alias points at a command that does not exist, <code>CLI::Simple</code> croaks
with a clear error.</p>
</li>
</ul>
<a id="usage-examples" class="anchor" aria-label="Permalink: Usage examples" href="#usage-examples"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Usage examples</h2>
<pre><code># Using an option alias
script.pl --cfg app.json execute

# Using a command alias
script.pl ls
</code></pre>
<p>After parsing, both <code>get_config()</code> and <code>get_cfg()</code> will return the
same value. If the user passes both <code>--config</code> and <code>--cfg</code>, the value
from <code>--cfg</code> (the alias) is used.</p>
<p><em>Note: In role-based applications using a YAML manifest, command
aliases are expressed by mapping the alias command directly to the
target sub name rather than a role class. See <a href="#role-based-architecture">"ROLE-BASED ARCHITECTURE"</a>.</em></p>
<a id="recommendations" class="anchor" aria-label="Permalink: Recommendations" href="#recommendations"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Recommendations</h2>
<ul>
<li>
<p>Keep the canonical spec single-named</p>
<p>Define a single canonical name in <code>option_specs</code> and add other spellings
via <code>alias</code>. Avoid multi-name specs like <code>config|cfg=s</code>; use <code>alias</code>
instead.</p>
</li>
<li>
<p>Document your precedence</p>
<p>If you prefer the alias name to win when both are supplied, enforce
that in your application or adjust the mirroring order. By default, the
canonical name wins.</p>
</li>
</ul>
<a id="errorsexit-codes" class="anchor" aria-label="Permalink: ERRORS/EXIT CODES" href="#errorsexit-codes"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">ERRORS/EXIT CODES</h1>
<p>When you execute the <code>run()</code> method it passes control to the method
that implements the command specified on the command line. Your method
is expected to return 0 for success or an error code that you can pass
to the shell on exit.</p>
<pre><code>exit CLI::Simple-&gt;new(commands =&gt; { foo =&gt; \&amp;cmd_foo })-&gt;run();
</code></pre>
<a id="exit-codes" class="anchor" aria-label="Permalink: Exit Codes" href="#exit-codes"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Exit Codes</h2>
<p><code>CLI::Simple</code> uses conventional exit codes so that calling scripts
can distinguish between normal completion and error conditions.</p>
<ul>
<li>
<p>'0'</p>
<p>Successful completion of a command (<code>SUCCESS</code>).</p>
</li>
<li>
<p>'1'</p>
<p>General usage error, such as <code>--help</code> display via <code>pod2usage</code>, or an
invalid command line (<code>FAILURE</code>).</p>
</li>
<li>
<p>'2'</p>
<p>Option parsing failure, such as an unrecognized option or invalid
argument (also reported as <code>FAILURE</code>).</p>
</li>
<li>
<p>Any other code</p>
<p>If a user-supplied command callback explicitly calls <code>exit()</code> or
returns a numeric value other than 0 - 2, that code is passed through
unchanged to the shell. This allows application-specific exit codes.</p>
</li>
</ul>
<a id="license-and-copyright" class="anchor" aria-label="Permalink: LICENSE AND COPYRIGHT" href="#license-and-copyright"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">LICENSE AND COPYRIGHT</h1>
<p>This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See
<a href="https://dev.perl.org/licenses/" rel="nofollow">https://dev.perl.org/licenses/</a> for more information.</p>
<a id="see-also" class="anchor" aria-label="Permalink: SEE ALSO" href="#see-also"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">SEE ALSO</h1>
<p><a href="https://metacpan.org/pod/Getopt%3A%3ALong" rel="nofollow">Getopt::Long</a>, <a href="https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AConstants" rel="nofollow">CLI::Simple::Constants</a>, <a href="https://metacpan.org/pod/CLI%3A%3ASimple%3A%3AUtils" rel="nofollow">CLI::Simple::Utils</a>,
<a href="https://metacpan.org/pod/Pod%3A%3AUsage" rel="nofollow">Pod::Usage</a>, <a href="https://metacpan.org/pod/App%3A%3ACmd" rel="nofollow">App::Cmd</a>, <a href="https://metacpan.org/pod/CLI%3A%3AFramework" rel="nofollow">CLI::Framework</a>, <a href="https://metacpan.org/pod/Role%3A%3ATiny" rel="nofollow">Role::Tiny</a>,
<a href="https://metacpan.org/pod/CPAN%3A%3AMaker%3A%3ABootstrapper" rel="nofollow">CPAN::Maker::Bootstrapper</a></p>
<a id="author" class="anchor" aria-label="Permalink: AUTHOR" href="#author"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">AUTHOR</h1>
<p>Rob Lauer - <a href="mailto:rlauer@treasurersbriefcase.com">rlauer@treasurersbriefcase.com</a></p>
