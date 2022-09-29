#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;

use App::PerlShell;

#use Text::ParseWords;    # quotewords()

my %opt;

GetOptions(

    # '' => \$opt{interact},    # lonesome dash is interactive test from STDIN
    'e|execute=s@' => \$opt{execute},
    'E|exit!'      => \$opt{exit},
    'feature=s'    => \$opt{feature},
    'Include=s@'   => \$opt{include},
    'lexical!'     => \$opt{lexical},
    'P|package=s'  => \$opt{package},
    'p|prompt=s'   => \$opt{prompt},
    'session=s'    => \$opt{session},
    'V|verbose!'   => \$opt{verbose},
    # 'words!'       => \$opt{words},
    'help!'        => \$opt{help},
    'man!'         => \$opt{man},
    'versions!'    => \$opt{versions}
) or pod2usage( -verbose => 0 );

pod2usage( -verbose => 1 ) if defined $opt{help};
pod2usage( -verbose => 2 ) if defined $opt{man};

if ( defined $opt{versions} ) {
    print
      "\nModules, Perl, OS, Program info:\n",
      "  $0\n",
      "  Version               $App::PerlShell::VERSION\n",
      "    strict              $strict::VERSION\n",
      "    warnings            $warnings::VERSION\n",
      "    Getopt::Long        $Getopt::Long::VERSION\n",
      "    Pod::Usage          $Pod::Usage::VERSION\n",
##################################################
      # Start Additional USE
##################################################
      #      "    Text::ParseWords    $Text::ParseWords::VERSION\n",
##################################################
      # End Additional USE
##################################################
      "    Perl version        $]\n",
      "    Perl executable     $^X\n",
      "    OS                  $^O\n",
      "\n\n";
    exit;
}

my %params;
if ( defined $opt{include} ) {
    my @temp;
    for ( @{$opt{include}} ) {
        push @temp, $_;
    }
    unshift @INC, @temp;
}

# Must be here to `use package` BEFORE any -e args
if ( defined $opt{package} ) {
    $params{package} = $opt{package};
    $params{execute} = "use $params{package};\n";
}

my $homedir = $ENV{HOME};
if ( $^O eq 'MSWin32' ) {
    $homedir = $ENV{USERPROFILE};
}

sub parse_plshrc {
    my ($file) = @_;

    if ( -e "$file" ) {
        open my $fh, '<', "$file"
          or die "$0: cannot open `$file': $!";
        my @lines = <$fh>;
        close $fh;
        for (@lines) {
            chomp $_;
            $params{execute} .= $_;
            if ( $params{execute} !~ /;$/ ) {
                $params{execute} .= ';';
            }
            $params{execute} .= "\n";
        }
    }
}

parse_plshrc("$homedir/.plshrc");
parse_plshrc(".plshrc");

if ( defined $opt{execute} ) {
    for ( @{$opt{execute}} ) {
        $params{execute} .= $_;
        if ( $params{execute} !~ /;$/ ) {
            $params{execute} .= ';';
        }
        $params{execute} .= "\n";
    }
}

if ( defined $opt{prompt} ) {
    $params{prompt} = $opt{prompt};
    $params{execute} .= "\$ENV{PERLSHELL_PROMPT}='$opt{prompt}';\n";
}

# Must be here again to add to end of execute to override .plshrc setting
# of package with the command line -P if specified
if ( defined $opt{package} ) {
    $params{execute} .= "\$ENV{PERLSHELL_PACKAGE}='$opt{package}';\n";
}

if ( defined $opt{feature} ) {
    $opt{feature} =~ s/^[v]//;
    if ( $opt{feature} =~ /^\d\./ ) {
        $opt{feature} = ":" . $opt{feature};
    }

    # append direct set to end of execute to override .plshrc setting of
    # feature with the command line -f if specified
    $params{execute} .= "\$ENV{PERLSHELL_FEATURE}='$opt{feature}';\n";
} else {
    $opt{feature} = ":default";
}
$params{feature} = $opt{feature};

$params{execute} .= 'exit;' if defined $opt{exit};
$params{lexical} = 1             if defined $opt{lexical};
$params{session} = $opt{session} if defined $opt{session};
$params{verbose} = $opt{verbose} if defined $opt{verbose};

# if ( defined $opt{interact} ) {
#     my @temp;
#     if ( defined $opt{words} ) {
#         while (<STDIN>) {
#             chomp $_;
#             my @p = parse_line( '\s+', 0, $_ );
#             push @temp, @p;
#         }
#         if ( !defined $temp[$#temp] ) {
#             pop @temp;
#         }
#     } else {
#         while (<STDIN>) {
#             chomp $_;
#             push @temp, $_;
#         }
#     }
#     $params{argv} = \@temp;
# }

my $shell = App::PerlShell->new( %params,
    skipvars => [qw(%LexPersist:: %ModRefresh:: %Plugin:: $AUTOLOAD)] );
$shell->run();

__END__

########################################################
# Start POD
########################################################

=head1 NAME

PLSH - Perl Shell

=head1 SYNOPSIS

 plsh [options] [args]

=head1 DESCRIPTION

Creates an interactive Perl shell.  Startup configuration commands written
in Perl syntax can be stored in '.plshrc' file in HOME directory (e.g., C<$HOME>
on Linxu, C<%USERPROFILE%> on Windows) which will initialize the Perl Shell on
every startup.

=head1 OPTIONS

 -E                   Exit after -e commands complete.
 --exit

 -e                   Valid Perl to execute.  Multiple valid Perl
 --execute            statements (semicolon-separated) and multiple
                      -e allowed.

 -f                   Perl feature set to use.  Example: ":5.10"
 --feature            DEFAULT:  (or not specified) ":default"

 -I dir               Specify directory to prepend @INC.  Multiple
 --Include            -I allowed.

 -l                   Require "my" for all variables.
 --lexical            Requires Lexical::Persistence, fails if not found.

 -P package           Package to use as namespace.  Will:
 --package              use `package';
                      before any -e arguments.

 -p prompt            Prompt for the shell.
 --prompt

 -s file              Session command log file.
 --session

 -V                   Output verbose initialization information.
 --verose

=cut

 -w                   Treat each element of args as a separate
 --words              entry for @ARGV.

=pod

 --help               Print Options and Arguments.
 --man                Print complete man page.
 --versions           Print Modules, Perl, OS, Program info.

=head1 CONFIGURATION

An example '.plshrc' file.

    use App::PerlShell::Plugin::Macros;

    # do not require a semicolon to terminate each line
    $ENV{PERLSHELL_SEMIOFF}=1;
    # turn on feature 5.10 (use feature ':5.10';)
    $ENV{PERLSHELL_FEATURE}=":5.10";

    # override the `version` command
    no warnings 'redefine'; *App::PerlShell::version = sub { print "MyVersion" }

=head1 ORDER

Command line options -f, -p, -P override .'plshrc'.

=over 4

=item 1

Prepend any -I paths to @INC.

=item 2

Set -P package.  If provided, set -e to "use E<lt>packageE<gt>".

=item 3

Add any commmands from '$HOME/.plshrc' file if exists in HOME directory.

=item 4

Add any commmands from '.plshrc' file if exists in working directory.

=item 5

Add any additional -e arguments to -e.

=item 6

If -E, add "exit;" to end of -e.

=back

=head1 EXAMPLES

The following two examples accomplish the same thing.

=head2 Command Line

 plsh.pl -e "print join ' ', @ARGV;" -E hello world

=head2 Interactive

 C:\> plsh.pl
 Perl> print "hello world";
 Perl> exit;

=head1 SEE ALSO

L<App::PerlShell>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2015-2022 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
