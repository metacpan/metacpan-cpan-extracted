use strict;
use warnings;

package App::Skeletor;

use Getopt::Long::Descriptive;
use File::Share 'dist_dir';
use Module::Runtime 'use_module';
use Path::Tiny;
use Template::Tiny;
use File::HomeDir;
use JSON::PP;

our $VERSION = '0.005';

sub getopt_spec {
  return (
    'skeletor %o',
    ['template|t=s', 'Namespace of the project templates', { required=>1 }],
    ['as|p=s', 'Target namespace of the new project', { required=>1 }],
    ['directory|d=s', 'Where to build the new project (default: cwd)', {default=>Path::Tiny->cwd}],
    ['author|a=s', 'Primary author for the project', { required=>1 }],
    ['year|y=i', 'Copyright year (default: current year)', {default=>(localtime)[5]+1900}],
    ['overwrite|o', 'overwrite existing files' ],
  );
}
sub path_to_share {
  my $project_template = shift;
  my $tmp;
  unless(eval { use_module $project_template }) {
    # cant use, assume not loaded.
    $tmp = Path::Tiny->tempdir;
    print "Template $project_template is not installed, creating temporary install into $tmp";
    `curl -L https://cpanmin.us | perl - --metacpan -l $tmp $project_template`;
    eval "use lib '$tmp/lib/perl5'";    
    use_module $project_template || die "Can't install and use $project_template";
  }
  $project_template=~s/::/-/g;
  my $ret = path(dist_dir($project_template), 'skel');
  return ($ret, $tmp);
}

sub template_as_name {
  my $name_proto = shift;
  $name_proto=~s/::/-/g;
  return $name_proto;
}

sub run {
  my ($class, @args) = @_;

  ## Look in homedir and grab any options
  if(-e(my $saved_options_path = path(File::HomeDir->my_home, '.skeletor.json'))) {
    print "Found user options at: $saved_options_path\n";
    my $json_opts = decode_json($saved_options_path->slurp);
    @args = (@args, %$json_opts);
  }

  local @ARGV = @args;

  my ($desc ,@spec) = getopt_spec;
  my ($opt, $usage) = describe_options($desc, @spec, {getopt_conf=>['pass_through']});
  my ($path_to_share, $tmp) = path_to_share($opt->template);

  ## Templates can add or override options
  if($opt->template->can('extra_getopt_spec')) {
    my @new_spec = (@spec, $opt->template->extra_getopt_spec);
    local @ARGV = @args;
    ($opt, $usage) = describe_options($desc, @new_spec);
  }

  my %template_var_names =  (
    (map { $_->{name} => $opt->${\$_->{name}} } @{$usage->{options}}),
    name => template_as_name($opt->as),
    namespace => $opt->as,
    project_fullpath => do {my $path = path(split('::', $opt->as)); "$path" },
    name_lowercase => lc(template_as_name($opt->as)),
    name_lc => lc(template_as_name($opt->as)),
    name_lowercase_underscore => do {
      my $val = lc(template_as_name($opt->as));
      $val=~s/-/_/g; $val;
    },
    name_lc_underscore => do {
      my $val = lc(template_as_name($opt->as));
      $val=~s/-/_/g; $val;
    },
  );

  my $tt = Template::Tiny->new(TRIM => 1);

  $path_to_share->visit(sub {
    my ($path, $stuff) = @_;
    return if $path=~m/\.DS_Store/g;
    my $expanded_path = $path;
    my $target_path = path($opt->directory, $expanded_path->relative($path_to_share));
    my (@vars) = ($target_path=~m/__(?:(?![__]_).)+__/g);
    foreach my $var(@vars) {
      my ($key) = ($var=~m/^__(\w+)__$/);
      my $subst = $template_var_names{$key} || die "$key not a defined variable";
      $target_path=~s/${var}/$subst/g;
    }

    $target_path = path($target_path);

    if(-e $target_path && !$opt->overwrite) {
      print "$target_path exists, skipping (set --overwrite to rebuild)\n";
      return;
    }
    
    if($expanded_path->is_file) {
      $expanded_path->parent->mkpath;
      if("$path"=~/\.ttt$/) {
        my $data = $expanded_path->slurp;
        $tt->process(\$data, \%template_var_names, \my $out);
        my ($new_target_path) = ("$target_path" =~m/^(.+)\.ttt$/);
        path($new_target_path)->touchpath;
        my $fh = path($new_target_path)->openw;
        print $fh $out;
        close($fh);
        path($new_target_path)->chmod($expanded_path->stat->mode);

      } else {
        $expanded_path->copy($target_path);
      }
    } elsif($path->is_dir) {
      $target_path->mkpath;
    } else {
      print "Don't know want $path is!";
    }
  }, {recurse=>1});
}

caller(1) ? 1 : run(@ARGV);

=head1 NAME

App::Skeletor - Bootstrap a new project from a shared template

=head1 SYNOPSIS

From the commandline:

    skeletor --template Skeltor::Template::Example \
      --as Local::MyApp \
      --directory ~/new_projects \
      --author 'John Napiorkowski <jjnapiork@cpan.org>' \
      --year 2015

Bootstrap from URL hosted version:

    curl -L bit.ly/app-skeletor | perl - \
      --template Skeletor::Template::Example \
      --as Local::MyApp \
      --author 'test author'

(Assumes you have `curl` installed, as it is on many modern unix-like systems).

=head1 DESCRIPTION

When initially setting up a project (like a website build using L<Catalyst> or
an application that uses L<DBIx::Class>) there is often a number of boilerplate
files and directories you need to create before beginning the true work of
application building.  Additionally, during general development certain types
of repeated tasks may occur which would benefit from automation, such as adding
new controllers to L<Catalyst> or new tables in L<DBIx::Class>.  For these types
of activities you may find having a code generator speeds up some of the grunt
work and promotes uniformity of design.  L<App::Skeltor> is such a code generator.

The core design is simple.  You install L<App::Skeltor> and any of the code
patterns on CPAN that you wish to derive projects from (typically using the
L<Skeltor::Template::*> namespace, but you can use any namespace, and project
patterns can be attached to any arbitirary CPAN module).  You then can use the
'skeletor' commandline application to generate code into a target directory,
using expansion variables to customize how the directories and files are created.

For example if you wish to build a new project called C<Local::MyApp> which is
based off the L<Skeletor::Template::Example> project, you'd install that distribution
(via L<cpanminus> or whichever tool you prefer) and then type something like the
following:

    skeletor --template Skeltor::Template::Example \
      --as Local::MyApp \
      --directory ~/new_projects \
      --author 'John Napiorkowski <jjnapiork@cpan.org>' \
      --year 2015

This would create a new project which consists of directories and files that have been
generated and customized based on the commandline options given.

Alternatively you may use the URL hosted version of L<App::Skeletor> which will always
track the most current release.  This allows you to use the tool without installing it
first, making it useful for bootstrapping new development environments:

    curl -L bit.ly/app-skeletor | perl - \
      --template Skeletor::Template::Example \
      --as Local::MyApp \
      --author 'test author'

This assumes a working internet connection as well as some version of Perl installed
and the C<curl> commandline tool installed.  In general this should be true for most
Unix and Unixlike systems.  However running an application directly off the internet
this way may violate your companies security policies (and some so common sense) so
use this option with caution.

B<NOTE> C<directory> and C<year> are optional, and default to the current working directory
and current year respectively.  Some project templates may define additional configuration
options, you should review the documentation.

B<NOTE> Template distributions may define custom options for the commandline tool.  You
should review its documentation to make sure you are using it properly.

B<NOTE> If you specify a template that is not currently installed, L<App::Skeletor> will
download it and install it to a temporary area for one time use.  When the application
exits, the temporary install is cleaned up.

=head1 PERMISSIONS

As best as we can we try to replicat user/group/world read/write permissions defined
in the template files to the project generated files.

=head1 GLOBAL CONFIGURATION

You may store repeated or common configuration options in ~/skeletor.json, for example:

    cat ~/.skeletor.json 
    {
      "--author": "John Nap"
    }

Then when you build a project the '--author' option will be preloaded.

=head1 COMPARISON WITH SIMILAR TOOLS

Other similar boilerplate code generators exist on CPAN.  For example L<Catalyst::Devel> has a
commandline tool for creating a simple L<Catalyst> project.  L<Dancer2>, L<Mojolicious>
also have dedicated project builders.  L<App::Skeletor> differs from those
approaches in that it is detached from a particular project domain and thus can
be more generically useful.  This should give the community the chance for people
to suggest their favorite approach to bootstrapping a project without forcing people
to accept default options they don't like (current approach tends to be one size fits
no one).

When comparing L<App::Skeletor> to similar generic code builders like L<Dist::Zilla>
minting profiles, the main different is that L<App::Skeletor> is dependency manager
agnostic (doesn't require L<Dist::Zilla>).  I think its also a lot more simple than
a minting profile.

L<App::Skeletor> is probably more comparable with tools like L<Module::Starter> which
at this time are more mature tools.  If L<App::Skeltor> has tool many rough edges you
may wish to take a look.  At this point the main comparison is that I think the way
a project skelton is created and organized is significantly easier to understand (famous
last words I know :) ).  Also L<App::Skeltor> can be run directly from the URL hosted
version, if you are not afraid of that!

=head1 ARGUMENTS

The following configuration options are available, which are used as template
variables and directory/file path expansions.

=head2 template

This is the namespace of the distribution containing the templates for generating
a new project.  For example, L<Skeletor::Template::Example>.

If the distribution is not already installed into your @INC, we will download it
and install it into a temporary directory.  After generating files the temporary
install is deleted.  Obviously you need a working internet connection for this
feature to work.

=head2 namespace

=head2 as

The new project Perl namespace, as you might use it in a 'package' declaration.
For example "Local::MyApp".  Use this to declare the base package for your new
project.

=head2 name

Derived from L</as>.  We substitute '::' for '-' to create a project
'name' that is normalized to the CPAN specification.  For example 'Local-MyApp'

=head2 name_lowercase

=head2 name_lc

Same as L</name> but using lowercased characters via 'lc'.  For example 'local-myapp'.

=head2 name_lowercase_underscore

=head2 name_lc_underscore

Same as L<name> but using lowercase characters via 'lc' and substituting all
'-' characters with '_'.  For example 'local_myapp'.

=head2 project_fullpath

Given a L</as> like "Local::My::App":

When used as an expansion for a directory expands to a nest of
directories such as "Local/My/App".  Directories will be created as needed.

When used as an expansion for a filename, expands directories as needed and
creates a terminal file as needed such as "Local/My/App". Extensions are
preserved, for example "${namespace_fullpath}.pm" becomes "Local/My/App.pm".

When used as a variable in a template, resolves to a L<Path::Tiny> object that
points to the directory+filename as already described.

=head2 author

Used in templates, set to the project author.

=head2 year

Year information for setting project copyright, etc.  Default is current year.

=head1 BUILDING A TEMPLATE

An L<App::Skeletor> template is just a CPAN module under any namespace you like
(athough Skeletor::Template::* is not a terrible place to put one to make it
easier for people to find) with a share/skel directory which should contain
asset files (files copied to a new project without alteration), project templates
(files that are copied to a new project but are first processed thru L<Template::Tiny>
to customize them) and directories.  Directory names may also contain expansion
variables in order to customize directory layout.

There is a reasonable complex example on CPAN under the namespace
L<Skeletor::Template::Example> which you may refer to as a somewhat complex
template that includes all the mentioned types of data.  You may find reviewing
the example to be a faster way to understand how to make your own project templates.

Here is a very simple template with explanation to get you started.  The example
namespace given is mythical and does not exist on CPAN.  In this example a path
ending in '/' indicates a directory.

    Local-Skeltor-Template-MyTemplate/
      Makefile.PL
      lib/
        Local/
          Skeletor/
            Template/
              MyTemplate.pm
      share/
        skel/
          __name__/
            dist.ini.ttt
            lib/
              __project_fullpath__.pm.ttt
              __project_fullpath__/
                Web.pm.ttt
            t/
              basic.t.ttt
            share/
              image.jpg
              docs.txt

So first of all you should note that the template is just a normal CPAN module that
declares its installation process and has a file (in this case under
'lib/Local/Skeletor/Template/MyTemplate.pm') that should be used to describe what
the skeleton does.  Also note that you may include skeleton template files under
any CPAN module you wish, it doesn't need to be stand alone.

The main work happens under 'share/skel/' which is the root directory that
L<App::Skeletor> uses when finding a template pattern.  The way it works is
that we traverse the filesystem recursively and copy directories and files from
the project template share/skel/ to the target directory, performing any
template expansions as needed.  Template variable are defined above.  We
expand directories and files by matching a template variable in the path
using a similar approach as we do variable interpolation in a string.  for
example a directory called "__name__" would expand to the project name variable
(which is derived from the L</as> commandline option.

In the case where you need to combine a template variable with other characters
you may do so as in the example "__project_fullpath__.pm.ttt".

Any file ending in '.ttt' is considered a template and is processed via L<Template::Tiny>
expanding variables as described in the previous section.  We trucate the '.ttt' as
part of the conversion process so a file template "myapp.pm.ttt" becomes 'myapp.pm'
in the build directory.

=head1 CUSTOMIZING TEMPLATE VARIABLES

When you create you template distribution the bulk of you code will go under 
C<share/skel>.  However you may use distribution module (the file for example
in C<lib/Skeletor/Template/MySpecialTemplate.pm>) to customize aspects of the 
build process.  The following methods may be defined in your distribution module.

=head2 extra_getopt_spec

This method is called in class context and should return an array of options as
L<Getopt::Long::Descriptive> describes for C<@opt_spec> (the second of the three
arguments one passes to 'describe_options'.  You may use this to add custom 
template and file expansion variables to your template.

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
