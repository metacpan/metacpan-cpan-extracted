#
# This file is part of App-Cme
#
# This software is Copyright (c) 2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
# ABSTRACT: Run a cme script

package App::Cme::Command::run ;
$App::Cme::Command::run::VERSION = '1.023';
use strict;
use warnings;
use 5.10.1;
use File::HomeDir;
use Path::Tiny;
use Config::Model;
use Log::Log4perl qw(get_logger :levels);

use Encode qw(decode_utf8);

use App::Cme -command ;

use base qw/App::Cme::Common/;

my $logger = get_logger("Cme::run");

my $__test_home = '';
sub _set_test_home { $__test_home = shift; }

my $home = $__test_home || File::HomeDir->my_home;

my @script_paths = map {path($_)} (
    "$home/.cme/scripts",
    "/etc/cme/scripts/",
);

push @script_paths, path($INC{"Config/Model.pm"})->parent->child("Model/scripts") ;

sub opt_spec {
    my ( $class, $app ) = @_;
    return ( 
        [ "arg=s@"  => "fix only a subset of a configuration tree" ],
        [ "backup:s"  => "Create a backup of configuration files before saving." ],
        [ "quiet!"  => "Suppress progress messages" ],
        [ "doc!"    => "show documention of script" ],
        [ "list!"   => "list available scripts" ],
        $class->cme_global_options,
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->check_unknown_args($args);
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

sub execute {
    my ($self, $opt, $app_args) = @_;

    # see Debian #839593 and perlunicook(1) section X 13
    @$app_args = map { decode_utf8($_, 1) } @$app_args;

    if ($opt->{list}) {
        my @scripts;
        foreach my $path ( @script_paths ) {
            next unless $path->is_dir;
            push @scripts, grep { ! /~$/ } $path->children();
        }
        say "Available scripts:";
        say map {"- ".$_->basename."\n"} @scripts ;
        return;
    }

    my $script_name = shift @$app_args;
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

    $logger->info("Running script $script");

    my $content = $script->slurp_utf8;

    # parse variables passed on command line
    my %user_args = map { split '=',$_,2; } @{ $opt->{arg} };

    if ($content =~ m/^#!/ or $content =~ /^use/m) {
        splice @ARGV, 0,2; # remove 'run script' arguments
        $logger->info("Running script $script with perl");
        eval $script->slurp_utf8;
        die "Error in script $script_name: $@\n" if $@;
        return;
    }

    $logger->info("Running script $script");
    my %var;

    # find if all variables are accounted for
    my %missing ;

    # %args can be used in var section of a script. A new entry in
    # added in %missing if the script tries to read an undefined value
    tie my %args, 'App::Cme::Run::Var', \%missing;
    %args = %user_args;

    # replace variables with command arguments or eval'ed variables or env variables
    my $replace_var = sub {
        # change $var but not \$var
        $_[0] =~ s~ (?<!\\) \$(\w+) (?!\s*{) ~ $user_args{$1} // $var{$1} // $ENV{$1} // '$'.$1~xeg;

        # register vars without replacements
        map { $missing{$_} = 1 ;} ($_[0] =~ m~ (?<!\\) \$(\w+) ~xg);

        # now change \$var in $var
        $_[0] =~ s!\\\$!\$!g;
    };

    my @lines =  split /\n/,$content;
    my @load;
    my @doc;
    my $commit_msg ;
    my $line_nb = 0;

    # check content, store app
    foreach my $line ( @lines ) {
        $line_nb++;
        $line =~ s/#.*//; # remove comments
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        my ($key,$value) = split /[\s:]+/, $line, 2;

        next unless $key ; # empty line

        $replace_var->($value) unless $key eq 'var';

        if ($key =~ /^app/) {
            unshift @$app_args, $value;
        }
        elsif ($key eq 'var') {
            $logger->trace("Eval var expression: $value");
            my $res = eval ($value) ;
            die "Error in var specification line $line_nb: $@\n" if $@;
            $logger->debug("Eval var result: $res");
        }
        elsif ($key eq 'doc') {
            push @doc, $value;
        }
        elsif ($key eq 'load') {
            push @load, $value;
        }
        elsif ($key eq 'commit') {
            $commit_msg = $value;
        }
        else {
            die "Error in file $script line $line_nb: unexpected '$key' instruction\n";
        }
    }

    if ($opt->doc) {
        say join "\n", @doc;
        return;
    }

    if (my @missing = sort keys %missing) {
        die "Error: Missing variables '". join("', '",@missing)."' in command arguments for script $script\n"
            ."Please use option '".join(' ', map { "-arg $_=xxx"} @missing)."'\n";
    }

    $self->process_args($opt, $app_args);

    # check if workspace and index are clean
    if ($commit_msg) {
        my $r = `git status --porcelain`;
        die "Cannot run commit command in a non clean repo. Please commit or stash pending changes: $r"
            if $r;
    }

    # call loads
    my ($model, $inst, $root) = $self->init_cme($opt,$app_args);
    map { $root->load($_) } @load;

    $self->save($inst,$opt) ;

    # commit if needed
    if ($commit_msg) {
        system(qw/git commit -a -m/, $commit_msg);
    }
}

package App::Cme::Run::Var;
$App::Cme::Run::Var::VERSION = '1.023';
require Tie::Hash;

our @ISA = qw(Tie::ExtraHash);

sub FETCH {
    my ($self, $key) = @_ ;
    my ($h,$missing) = @$self;
    $missing->{$key} = 1 unless defined $h->{$key};
    return $h->{$key} // '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Cme::Command::run - Run a cme script

=head1 VERSION

version 1.023

=head1 SYNOPSIS

 $ cat ~/.cme/scripts/remove-mia
 doc: remove mia from Uploders. Require mia parameter
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
 remove mia from Uploders. require mia parameter

 # list scripts
 $ cme run -list
 Available scripts:
 - update-copyright
 - add-me-to-uploaders

=head1 DESCRIPTION

Run a script written with cme DSL (Design specific language) or in
plain Perl.

A script passed by name is searched in C<~/.cme/scripts>,
C</etc/cme/scripts> or C</usr/share/perl5/Config/Model/scripts>.
E.g. with C<cme run foo>, C<cme> loads either C<~/.cme/scripts/foo>,
C</etc/cme/scripts/foo> or
C</usr/share/perl5/Config/Model/scripts/foo>

No search is done if the script is passed with a path
(e.g. C<cme run ./foo>)

C<cme run> can also run plain Perl script. This is syntactic sugar to
avoid polluting global namespace, i.e. there's no need to store a
script using L<cme function|Config::Model/cme> in C</usr/local/bin/>.

When run, this script:

=over

=item *

opens the configuration file of C<app>

=item *

applies the modifications specified with C<load> instructions

=item *

save the configuration files

=item *

commits the result if C<commit> is specified.

=back

See L<App::Cme::Command::run> for details.

=head1 Syntax

The script accepts instructions in the form:

 key: value

The script accepts the following instructions:

=over

=item app

Specify the target application. Must be one of the application listed
by C<cme list> command. Mandatory. Only one C<app> instruction is
allowed.

=item var

Use Perl code to specify variables usable in this script. The Perl
code must store data in C<%var> hash. For instance:

    perl: my @l = localtime; $var{year} =  $l[5]+1900;

The hash C<%args> contains the variables passed with the C<-arg>
option. Reading a value from C<%args> which is set by the user
triggers an error.

=item load

Specify the modifications to apply using a string as specified in
L<Config::Model::Loader>

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

=head1 Options

=head2 list

List available scripts and exits.

=head2 arg

Arguments for the cme scripts which are used to substitute variables.

=head2 doc

Show the script documentation. (Note that C<--help> options show the
documentation of C<cme run> command)

=head1 Common options

See L<cme/"Global Options">.

=head1 Examples

=head2 update copyright years in C<debian/copyright>

 $ cat ~/.cme/scripts/update-copyright
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

=head1 SEE ALSO

L<cme>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
