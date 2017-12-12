#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;

use App::PerlShell;
#use Text::ParseWords;    # quotewords()

my %opt;
my ( $opt_help, $opt_man, $opt_versions );

GetOptions(
#    '' => \$opt{interact},    # lonesome dash is interactive test from STDIN
    'e|execute=s@' => \$opt{execute},
    'E|exit!'      => \$opt{exit},
    'Include=s@'   => \$opt{include},
    'lexical!'     => \$opt{lexical},
    'P|package=s'  => \$opt{package},
    'p|prompt=s'   => \$opt{prompt},
    'session=s'    => \$opt{session},
#    'words!'       => \$opt{words},
    'help!'     => \$opt_help,
    'man!'      => \$opt_man,
    'versions!' => \$opt_versions
) or pod2usage( -verbose => 0 );

pod2usage( -verbose => 1 ) if defined $opt_help;
pod2usage( -verbose => 2 ) if defined $opt_man;

if ( defined $opt_versions ) {
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

if ( defined $opt{package} ) {
    $params{package} = $opt{package};
    $params{execute} = "use $params{package};\n";
}

if ( defined $opt{execute} ) {
    for ( @{$opt{execute}} ) {
        $params{execute} .= $_;
        if ( $params{execute} !~ /;$/ ) {
            $params{execute} .= ';';
        }
        $params{execute} .= "\n";
    }
}

$params{execute} .= 'exit;' if defined $opt{exit};
$params{lexical} = 1             if defined $opt{lexical};
$params{prompt}  = $opt{prompt}  if defined $opt{prompt};
$params{session} = $opt{session} if defined $opt{session};

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
    skipvars => [qw(%LexPersist:: %ModRefresh:: %ShellCommands:: $AUTOLOAD)]
);
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

Creates an interactive Perl shell.

=head1 OPTIONS

 -E                   Exit after -e commands complete.
 --exit

 -e                   Valid Perl to execute.  Multiple valid Perl  
 --execute            statements (semicolon-separated) and multiple 
                      -e allowed.

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

=cut

 -w                   Treat each element of args as a separate 
 --words              entry for @ARGV.

=pod

 --help               Print Options and Arguments.
 --man                Print complete man page.
 --versions           Print Modules, Perl, OS, Program info.

=head1 ORDER

=over 4

=item 1

Prepend any -I paths to @INC.

=item 2

Set -P package.  If provided, set -e to "use E<lt>packageE<gt>".

=item 3

Add any additional -e arguments to -e.

=item 4

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

Copyright (c) 2015 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
