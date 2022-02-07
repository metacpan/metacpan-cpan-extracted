#
# This file is part of App-Cme
#
# This software is Copyright (c) 2014-2022 by Dominique Dumont <ddumont@cpan.org>.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Run a cme script

package App::Cme::Command::run ;
$App::Cme::Command::run::VERSION = '1.037';
use strict;
use warnings;
use v5.20;
use File::HomeDir;
use Path::Tiny;
use Config::Model;
use Log::Log4perl qw(get_logger :levels);
use YAML::PP;

use Encode qw(decode_utf8);

use App::Cme -command ;

use base qw/App::Cme::Common/;
use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures experimental::smartmatch/;


my $__test_home = '';
# used only by tests
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _set_test_home { $__test_home = shift; return;}

my $home = $__test_home || File::HomeDir->my_home;

my @script_paths = map {path($_)} (
    "$home/.cme/scripts",
    "/etc/cme/scripts/",
);

push @script_paths, path($INC{"Config/Model.pm"})->parent->child("Model/scripts") ;

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "arg=s@"  => "script argument. run 'cme run <script> -doc' for possible arguments" ],
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        [ "commit|c:s" => "commit change with passed message" ],
        [ "cat" => "Show the script file" ],
        [ "no-commit|nc!" => "skip commit to git" ],
        [ "doc!"    => "show documention of script" ],
        [ "list!"   => "list available scripts" ],
        $class->cme_global_options,
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->check_unknown_args($args);
    return;
}

sub usage_desc {
  my ($self) = @_;
  my $desc = $self->SUPER::usage_desc; # "%c COMMAND %o"
  return "$desc [ script ] [ -args foo=12 [ -args bar=13 ]";
}

sub description {
    my ($self) = @_;
    return $self->get_documentation;
}

sub check_script_arguments ($self, $opt, $script_name) {
    if ($opt->{list} or not $script_name) {
        my @scripts;
        foreach my $path ( @script_paths ) {
            next unless $path->is_dir;
            push @scripts, grep { ! /~$/ } $path->children();
        }
        say $opt->{list} ? "Available scripts:" : "Missing script argument. Choose one of:";
        say map {"- ".$_->basename."\n"} @scripts ;
        return 0;
    }
    return 1;
}

sub find_script_file ($self, $script_name) {
    my $script;
    if ($script_name =~ m!/!) {
        $script = path($script_name);
    }
    else {
        # check script in known locations
        foreach my $path ( @script_paths ) {
            next unless $path->is_dir;
            $script = $path->child($script_name);
            last if $script->is_file;
        }
    }

    die "Error: cannot find script $script_name\n" unless $script->is_file;

    return $script;
}

# replace variables with command arguments or eval'ed variables or env variables
## no critic (Subroutines::ProhibitManyArgs)
sub replace_var_in_value ($user_args, $script_var, $default, $missing, $vars) {
    my $var_pattern = qr~(?<!\\) \$([a-zA-Z]\w+) (?!\s*{)~x;

    foreach ($vars->@*) {
        # change $var but not \$var, not $var{} and not $1
        s~ $var_pattern
         ~ $user_args->{$1} // $script_var->{$1} // $ENV{$1} // $default->{$1} // '$'.$1 ~xeg;

        # register vars without replacements
        foreach my $var (m~ $var_pattern ~xg) {
            $missing->{$var} = 1 ;
        }

        # now change \$var in $var
        s!\\\$!\$!g;
    }
    return;
}

sub parse_script_lines ($script, $lines) {
    # provide default values
    my %default ;
    my @load;
    my @doc;
    my @code;
    my @var;
    my $commit_msg ;
    my $app;
    my $line_nb = 0;

    # check content, store app
    while ($lines->@*) {
        my $line = shift $lines->@*;
        $line_nb++;
        $line =~ s/#.*//; # remove comments
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        my ($key,@value);

        if ($line =~ /^---\s*(\w+)$/) {
            $key = $1;
            while ($lines->[0] !~ /^---/) {
                $lines->[0] =~ s/#.*//; # remove comments
                push @value,  shift $lines->@*;
            }
        }
        elsif ($line eq '---') {
            next;
        }
        else {
            ($key,@value) = split /[\s:]+/, $line, 2;
        }

        next unless $key ; # empty line

        for ($key) {
            when (/^app/) {
                $app = $value[0];
            }
            when ('var') {
                push @var, [ $line_nb, @value ];
            }
            when ('default') {
                # multi-line default value is not supported
                my ($dk, $dv) = split /[\s:=]+/, $value[0], 2;
                $default{$dk} = $dv;
            }
            when ('code') {
                die "Error line $line_nb: Cannot mix code and load section\n" if @load;
                push @code, @value;
            }
            when ('doc') {
                push @doc, @value;
            }
            when ('load') {
                die "Error line $line_nb: Cannot mix code and load section\n" if @code;
                push @load, @value;
            }
            when ('commit') {
                $commit_msg = join "\n",@value;
            }
            default {
                die "Error in file $script line $line_nb: unexpected '$key' instruction\n";
            }
        }
    }

    return {
        app => $app,
        doc => \@doc,
        code => \@code,
        commit_msg => $commit_msg,
        default => \%default,
        load => \@load,
        var => \@var,
    }
}

sub process_script_vars ($user_args, $data) {
    # $var is used in eval'ed strings
    my %var;

    # find if all variables are accounted for
    $data->{missing} = {};

    # %args can be used in var section of a script. A new entry in
    # added in %missing if the script tries to read an undefined value
    tie my %args, 'App::Cme::Run::Var',$data->{missing}, $data->{default};
    %args = $user_args->%*;

    my $var = delete $data->{var} // [];
    foreach my $eval_data ($var->@*) {
        my ($line_nb, @value);
        if (ref $eval_data) {
            # coming from text format
            ($line_nb, @value) = $eval_data->@*;
            # eval'ed string comes from system file, not from user data
            my $res = eval ("@value") ; ## no critic (ProhibitStringyEval)
            die "Error in var specification line $line_nb: $@\n" if $@;
        }
        else {
            # coming from YAML format
            my $res = eval ($eval_data) ; ## no critic (ProhibitStringyEval)
            die "Error in var specification: $@\n" if $@;
        }
    }

    replace_var_in_value($user_args, \%var, $data->{default},$data->{missing}, $data->{doc});
    replace_var_in_value($user_args, \%var, $data->{default},$data->{missing}, $data->{load});

    $data->{values} = {$data->{default}->%*, %var, $user_args->%*};

    return $data;
}

sub parse_script ($script, $content, $user_args) {
    my $lines->@* =  split /\n/,$content;

    given ($lines->[0]) {
        when (/Format: perl/i) {
            ## no critic (ProhibitStringyEval)
            my $data = eval($content);
            die "Error in script $script (Perl format): $@\n" if $@;
            foreach my $forbidden (qw/load var default/) {
                die "Unexpected '$forbidden\ section in Perl format script $script\n" if $data->{$forbidden};
            }
            die "Unexpected 'code' section in Perl format script $script. Please use a sub section.\n" if $data->{code};
            return $data;
        }
        when (/Format: yaml/i) {
            my $ypp = YAML::PP->new;
            my $data = $ypp->load_string($content);
            foreach my $key (qw/doc code load var/) {
                next unless defined $data->{$key};
                next if ref $data->{$key} eq 'ARRAY';
                $data->{$key} = [ $data->{$key} ]
            }
            if ($data->{default} and ref $data->{default} ne 'HASH') {
                die "default spec must be a hash ref, not a ", ref $data->{default} // 'scalar', "\n";
            }
            $data = process_script_vars ($user_args, $data);
            return $data;
        }
        default {
            my $data = parse_script_lines ($script, $lines);
            $data = process_script_vars ($user_args, $data);
            return $data;
        }
    }

}

sub execute {
    my ($self, $opt, $app_args) = @_;

    # cannot use logger until Config::Model is initialised

    # see Debian #839593 and perlunicook(1) section X 13
    @$app_args = map { decode_utf8($_, 1) } @$app_args;

    my $script_name = shift @$app_args;

    return unless $self->check_script_arguments($opt, $script_name);

    my $script = $self->find_script_file($script_name);

    my $content = $script->slurp_utf8;

    if ($opt->{cat}) {
        print $content;
        return;
    }

    # parse variables passed on command line
    my %user_args = map { split '=',$_,2; } @{ $opt->{arg} };

    if ($content =~ m/^#!/ or $content =~ /^use/m) {
        splice @ARGV, 0,2; # remove 'run script' arguments
        my $done = eval $script->slurp_utf8."\n1;\n"; ## no critic (BuiltinFunctions::ProhibitStringyEval)
        die "Error in script $script_name: $@\n" unless $done;
        return;
    }

    my $script_data = parse_script($script, $content, \%user_args);
    my $commit_msg = $script_data->{commit_msg};

    if ($opt->doc) {
        say join "\n", $script_data->{doc}->@*;
        say "will commit with message: '$commit_msg'" if $commit_msg;
        return;
    }

    if (my @missing = sort keys $script_data->{missing}->%*) {
        die "Error: Missing variables '". join("', '",@missing)."' in command arguments for script $script\n"
            ."Please use option '".join(' ', map { "-arg $_=xxx"} @missing)."'\n";
    }

    $self->process_args($opt, [ $script_data->{app}, $app_args->@* ]);

    # override commit message. may also trigger a commit even if none
    # is specified in script
    if ($opt->{commit}) {
        $commit_msg = $opt->{commit};
    }

    # check if workspace and index are clean
    if ($commit_msg and not $opt->{no_commit}) {
        ## no critic(InputOutput::ProhibitBacktickOperators)
        my $r = `git status --porcelain --untracked-files=no`;
        die "Cannot run commit command in a non clean repo. Please commit or stash pending changes: $r\n"
            if $r;
    }

    $opt->{_verbose} = 'Loader' if $opt->{verbose};

    # call loads
    my ($model, $inst, $root) = $self->init_cme($opt,$app_args);
    foreach my $load_str ($script_data->{load}->@*) {
        $root->load($load_str);
    }

    if ($script_data->{code}) {
        my $to_run = '';
        while (my ($name, $value) = each $script_data->{values}->%*) {
            $to_run .= "my \$$name = '$value';\n";
        }
        $to_run .= join("\n",$script_data->{code}->@*);
        my $res = eval($to_run); ## no critic (ProhibitStringyEval)
        die "Error in code specification: $@\ncode is: \n$to_run\n" if $@;
    }

    if ($script_data->{sub}) {
        $script_data->{sub}->($root, \%user_args);
    }

    unless ($inst->needs_save) {
        say "No change were applied";
        return;
    }

    $self->save($inst,$opt) ;

    # commit if needed
    if ($commit_msg and not $opt->{no_commit}) {
        system(qw/git commit -a -m/, $commit_msg);
    }

    return;
}

package App::Cme::Run::Var; ## no critic (Modules::ProhibitMultiplePackages)
$App::Cme::Run::Var::VERSION = '1.037';
require Tie::Hash;

## no critic (ClassHierarchies::ProhibitExplicitISA)
our @ISA = qw(Tie::ExtraHash);

sub FETCH {
    my ($self, $key) = @_ ;
    my ($h, $missing, $default) = @$self;
    my $res = $h->{$key} // $default->{$key} ;
    $missing->{$key} = 1 unless defined $res;
    return $res // '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::run - Run a cme script

=head1 VERSION

version 1.037

=head1 SYNOPSIS

 $ cat ~/.cme/scripts/remove-mia
 doc: remove mia from Uploaders. Require mia parameter
 # declare app to configure
 app: dpkg
 # specify one or more instructions
 load: ! control source Uploaders:-~/$mia$/
 # commit the modifications with a message (git only)
 commit: remove MIA dev $mia

 $ cme run remove-mia -arg mia=longgone@d3bian.org

 # cme run can also use environment variables
 $ cat ~/.cme/scripts/add-me-to-uploaders
 app: dpkg-control
 load: source Uploaders:.push("$DEBFULLNAME <$DEBEMAIL>")

 $ cme run add-me-to-uploaders
 Reading package lists... Done
 Building dependency tree
 Reading state information... Done
 Changes applied to dpkg-control configuration:
 - source Uploaders:3: '<undef>' -> 'Dominique Dumont <dod@debian.org>'

 # show the script documentation
 $ cme run remove-mia -doc
 remove mia from Uploaders. require mia parameter

 # list scripts
 $ cme run -list
 Available scripts:
 - update-copyright
 - add-me-to-uploaders

=head1 DESCRIPTION

Run a script written for C<cme>

A script passed by name is searched in C<~/.cme/scripts>,
C</etc/cme/scripts> or C</usr/share/perl5/Config/Model/scripts>.
E.g. with C<cme run foo>, C<cme> loads either C<~/.cme/scripts/foo>,
C</etc/cme/scripts/foo> or
C</usr/share/perl5/Config/Model/scripts/foo>

No search is done if the script is passed with a path
(e.g. C<cme run ./foo>)

C<cme run> accepts scripts written with different syntaxes:

=over

=item in text

For simple script, this text specifies the target app, the doc,
optional variables and a load string used by L<Config::Model::Loader> or
Perl code.

=item YAML

Like text above, but using Yaml syntax.

=item Perl data structure

Writing Perl code in a text file or in a YAML field can be painful as
Perl syntax is not highlighted. With a Perl data structure, a cme
script specifies the target app, the doc, optional variables, and a
perl subroutine (see below).

=item plain Perl script

C<cme run> can also run plain Perl script. This is syntactic sugar to
avoid polluting global namespace, i.e. there's no need to store a
script using L<cme function|Config::Model/cme> in C</usr/local/bin/>.

=back

When run, this script:

=over

=item *

opens the configuration file of C<app>

=item *

applies the modifications specified with C<load> instructions or the Perl code.

=item *

save the configuration files

=item *

commits the result if C<commit> is specified (either in script or on command line).

=back

See L<App::Cme::Command::run> for details.

=head1 Syntax of text format

The script accepts instructions in the form:

 key: value

The key line can be repeated when needed.

Multi line values can also be:

 --- key
 multi line value
 ---

The script accepts the following instructions:

=over

=item app

Specify the target application. Must be one of the application listed
by C<cme list> command. Mandatory. Only one C<app> instruction is
allowed.

=item default

Specify default values that can be used in C<load> or C<var> sections.

For instance:

 default: name=foobar

=item var

Use Perl code to specify variables usable in this script. The Perl
code must store data in C<%var> hash. For instance:

    var: my @l = localtime; $var{year} =  $l[5]+1900;

The hash C<%args> contains the variables passed with the C<-arg>
option. Reading a value from C<%args> which is not set by user
triggers a missing option error. Use C<exists> if you need to test if
a argument was set by user:

    var: $var{foo} = exists $var{bar} ? $var{bar} : 'default' # good
    var: $var{foo} = $var{bar} || 'default' # triggers a "missing arg" error

=item load

Specify the modifications to apply using a string as specified in
L<Config::Model::Loader>. This string can contain variable
(e.g. C<$foo>) which are replaced by command argument (e.g. C<-arg
foo=bar>) or by a variable set in var: line (e.g. C<$var{foo}> as set
above) or by an environment variable (e.g. C<$ENV{foo}>)

=item code

Specify Perl code to run. See L</code section> for details.

=item commit

Specify that the change must be committed with the passed commit
message. When this option is used, C<cme> raises an error if used on a
non-clean workspace. This option works only with L<git>.

=back

All instructions can use variables like C<$stuff> whose value can be
specified with C<-arg> options, with a Perl variable (from C<var:>
section explained above) or with an environment variable:

For instance:

  cme run -arg var1=foo -arg var2=bar

transforms the instruction:

  load: ! a=$var1 b=$var2

in

  load: ! a=foo b=bar

=head2 Example

Here's an example from L<libconfig-model-dpkg-perl scripts|https://salsa.debian.org/perl-team/modules/packages/libconfig-model-dpkg-perl/-/blob/master/lib/Config/Model/scripts/add-me-to-uploaders>:

  doc: add myself to Uploaders
  app: dpkg-control
  load: source Uploaders:.insort("$DEBFULLNAME <$DEBEMAIL>")
  commit: add $DEBEMAIL to Uploaders

=head2 Code section

The code section can contain variable (e.g. C<$foo>) which are replaced by
command argument (e.g. C<-arg foo=bar>) or by a variable set in var:
line (e.g. C<$var{foo}> as set above).

When evaluated the following variables are also set:

=over

=item $root

Root node of the configuration (See L<Config::Model::Node>)

=item $inst

Configuration instance (See L<Config::Model::Instance>)

=item $commit_msg

Message used to commit the modification.

=back

Since the code is run in an C<eval>, other variables are available
(like C<$self>) to shoot yourself in the foot.

For example:

 app:  popcon
 ---code
 $root->fetch_element('MY_HOSTID')->store($to_store);
 ---

=head1 Syntax of YAML format

This format is intented for people not wanting to user the text format
above. It supoorts the same parameters as the text format.

For instance:

 # Format: YAML
 ---
 app: popcon
 default:
   defname: foobar
 var: "$var{name} = $args{defname}"
 load: "! MY_HOSTID=$name"

=head1 Syntax of Perl format

This format is intended for more complex script where using C<load>
instructions is not enough.

This script must then begin with C<# Format: perl> and specifies a
hash. For instance:

 # Format: perl
 {
      app => 'popcon', # mandatory
      doc => "Use --arg to_store=a_value to store a_value in MY_HOSTID',
      commit => "control: update Vcs-Browser and Vcs-Git"
      sub => sub ($root, $arg) { $root->fetch_element('MY_HOSTID')->store($arg->{to_store}); }
 }

C<$root> is the root if the configuration tree (See L<Config::Model::Node>).
C<$arg> is a hash containing the arguments passed to C<cme run> with C<-arg> options.

The C<sub> parameter value must be a sub ref. Its parameters are
C<$root> (a L<Config::Model::Node> object containing the root of the
configuration tree) and C<$arg> (a hash ref containing the keys and
values passed to C<cme run> wiht C<--arg> options).

Note that this format does not support C<var>, C<default> and C<load>
parameters as you can easily achieve the same result with Perl code.

=head1 Options

=head2 list

List available scripts and exits.

=head2 arg

Arguments for the cme scripts which are used to substitute variables.

=head2 doc

Show the script documentation. (Note that C<--help> options show the
documentation of C<cme run> command)

=head2 cat

Pop the hood and show the content of the script.

=head2 commit

Like the commit instruction in script. Specify that the change must be
committed with the passed commit message.

=head2 no-commit

Don't commit to git (even if the above option is set)

=head2 verbose

Show effect of the modify instructions.

=head1 Common options

See L<cme/"Global Options">.

=head1 Examples

=head2 update copyright years in C<debian/copyright>

 $ cme run update-copyright -cat
 app: dpkg-copyright
 load: Files:~ Copyright=~"s/2016,?\s+$name/2017, $name/g"
 commit: updated copyright year of $name

 $ cme run update-copyright -arg "name=Dominique Dumont"
 cme: using Dpkg::Copyright model
 Changes applied to dpkg-copyright configuration:
 - Files:"*" Copyright: '2005-2016, Dominique Dumont <dod@debian.org>' -> '2005-2017, Dominique Dumont <dod@debian.org>'
 - Files:"lib/Dpkg/Copyright/Scanner.pm" Copyright:
 @@ -1,2 +1,2 @@
 -2014-2016, Dominique Dumont <dod@debian.org>
 +2014-2017, Dominique Dumont <dod@debian.org>
   2005-2012, Jonas Smedegaard <dr@jones.dk>

 [master ac2e6410] updated copyright year of Dominique Dumont
  1 file changed, 2 insertions(+), 2 deletions(-)

=head2 update VcsGit in debian/control

 $ cme run set-vcs-git  -cat
 doc: update control Vcs-Browser and Vcs-git from git remote value
 doc: parameters: remote (default is origin)
 doc:
 doc: example:
 doc:  cme run set-vcs-git
 doc:  cme run set-vcs-git -arg remote=debian
 
 app: dpkg-control
 default: remote: origin
 
 var: chomp ( $var{url} = `git remote get-url $args{remote}` ) ;
 var: $var{url} =~ s!^git@!https://!;
 var: $var{url} =~ s!(https?://[\w.]+):!$1/!;
 var: $var{browser} = $var{url};
 var: $var{browser} =~ s/.git$//;
 
 load: ! source Vcs-Browser="$browser" Vcs-Git="$url"
 commit: control: update Vcs-Browser and Vcs-Git

This script can also be written using multi line instructions:

 $ cme run set-vcs-git  -cat
 --- doc
 update control Vcs-Browser and Vcs-git from git remote value
 parameters: remote (default is origin)
 
 example:
  cme run set-vcs-git
  cme run set-vcs-git -arg remote=debian
 ---
 
 app: dpkg-control
 default: remote: origin
 
 --- var
 chomp ( $var{url} = `git remote get-url $args{remote}` ) ;
 $var{url} =~ s!^git@!https://!;
 $var{url} =~ s!(https?://[\w.]+):!$1/!;
 $var{browser} = $var{url};
 $var{browser} =~ s/.git$//;
 ---
 
 load: ! source Vcs-Browser="$browser" Vcs-Git="$url"
 commit: control: update Vcs-Browser and Vcs-Git

=head1 SEE ALSO

L<cme>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2022 by Dominique Dumont <ddumont@cpan.org>.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
